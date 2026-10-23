/*
 * flock_nfs_shim.c —— 修复 NFS 上 flock(LOCK_EX) 对只读 fd 失败 (EBADF) 的问题
 * ============================================================================
 * 背景 (已用 2x2 对照实验证明):
 *   | 文件系统              | O_RDONLY + LOCK_EX | O_RDWR + LOCK_EX |
 *   |-----------------------|--------------------|------------------|
 *   | NFS (local_lock=none) | ✘ EBADF            | ✔ 成功           |
 *   | ext4 (/data)          | ✔ 成功             | ✔ 成功           |
 *
 *   Linux NFS 客户端用 POSIX 记录锁 (fcntl F_SETLK) 模拟 flock(2);
 *   LOCK_EX -> F_WRLCK, 而内核对只读 fd 上的 F_WRLCK 返回 EBADF。
 *   本地文件系统走真正的 flock 系统调用, 不检查 fd 的读写模式, 故正常。
 *
 *   命中点: AOSP dex2oat 用 `LockedFile::Open(profile, O_RDONLY, ...)`
 *   (art/dex2oat/dex2oat.cc:2574), 内部 flock(fd, LOCK_EX) 在 NFS 上必然 EBADF,
 *   导致 "Cannot lock profiles ... Bad file descriptor" 构建失败。
 *
 * 本 shim 的策略 (不改变调用方语义):
 *   1. 先调用真正的 flock()。成功 → 直接返回, 零行为差异。
 *   2. 仅当真正 flock 因 EBADF 失败时, 才通过 /proc/self/fd/N 以 O_RDWR
 *      重新打开同一个文件, 在那个"影子 fd"上取得排他锁, 并让影子 fd
 *      存活到进程结束 (flock 锁属于打开文件描述, 与具体 fd 无关,
 *      因此对本文件仍是一把真实的排他锁)。
 *   3. 原 fd 的访问模式与文件偏移完全不受影响 (复制而非 dup2),
 *      调用方后续 read() 行为与原来完全一致。
 *   4. flock(fd, LOCK_UN) 会一并释放影子锁。
 *
 * 任何其它错误码 / 其它操作一律原样透传给真正的 flock。
 */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

/* 影子 fd 表: 保存因 EBADF 而额外打开的 fd, 使其锁在进程存活期间一直有效。 */
#define SHIM_MAX 256
static int g_shadow[SHIM_MAX];
static int g_shadow_fd[SHIM_MAX];   /* 与 g_shadow 平行的“原 fd”记录, 用于 LOCK_UN */
static int g_shadow_n = 0;

static int (*real_flock)(int, int) = NULL;

static void shim_init(void) {
    if (!real_flock) {
        real_flock = (int (*)(int, int))dlsym(RTLD_NEXT, "flock");
    }
}

/* 在影子 fd 上取得锁; 成功返回 0, 失败返回 -1 并设 errno。 */
static int shadow_lock(int fd, int operation) {
    char path[64];
    snprintf(path, sizeof(path), "/proc/self/fd/%d", fd);

    int sfd = open(path, O_RDWR | O_CLOEXEC);
    if (sfd < 0) {
        /* 有些文件确实不可写 (如只读挂载); 退回 O_RDONLY 再试一次。 */
        sfd = open(path, O_RDONLY | O_CLOEXEC);
        if (sfd < 0) {
            return -1;
        }
    }

    if (real_flock(sfd, operation) != 0) {
        int saved = errno;
        close(sfd);
        errno = saved;
        return -1;
    }

    if (g_shadow_n < SHIM_MAX) {
        g_shadow[g_shadow_n] = sfd;
        g_shadow_fd[g_shadow_n] = fd;
        g_shadow_n++;
    } else {
        /* 表满: 不能丢失锁, 也不泄漏; 直接保留 fd (不关闭)。
         * 实际构建中 flock 调用极少, 不会达到上限。 */
        fprintf(stderr, "[flock_nfs_shim] shadow table full, keeping fd %d\n", sfd);
    }
    return 0;
}

/* 查找并摘除 fd 对应的影子条目; 返回影子 fd, 未找到返回 -1。 */
static int shadow_take(int fd) {
    for (int i = 0; i < g_shadow_n; i++) {
        if (g_shadow_fd[i] == fd) {
            int sfd = g_shadow[i];
            g_shadow[i] = g_shadow[g_shadow_n - 1];
            g_shadow_fd[i] = g_shadow_fd[g_shadow_n - 1];
            g_shadow_n--;
            return sfd;
        }
    }
    return -1;
}

int flock(int fd, int operation) {
    shim_init();

    if (!real_flock) {
        errno = ENOSYS;
        return -1;
    }

    /* ---- LOCK_UN: 必须先处理影子锁, 否则真实 fd 上的 unlock 会“成功”
     * 却不释放影子 fd 持有的独占锁, 造成同一进程内的锁泄漏。---- */
    if (operation & LOCK_UN) {
        int sfd = shadow_take(fd);
        if (sfd >= 0) {
            real_flock(sfd, LOCK_UN);   /* 释放影子锁 */
            close(sfd);
            return 0;
        }
        return real_flock(fd, operation);   /* 无影子: 原样透传 */
    }

    /* 已经被本 shim 用影子锁持有: 直接视为成功 (与 flock 的重复加锁语义一致)。 */
    for (int i = 0; i < g_shadow_n; i++) {
        if (g_shadow_fd[i] == fd) {
            return 0;
        }
    }

    int rc = real_flock(fd, operation);
    if (rc == 0) {
        return 0;   /* 正常路径: 行为与原生完全一致 */
    }

    int saved = errno;

    /* 仅在“只读 fd 上请求排他锁”这一 NFS 特有失败上介入。
     * 保留 LOCK_NB: 非阻塞语义必须原样传递, 否则调用方会意外阻塞。 */
    if (saved == EBADF && (operation & LOCK_EX)) {
        if (shadow_lock(fd, operation) == 0) {
            return 0;
        }
    }

    errno = saved;
    return -1;
}
