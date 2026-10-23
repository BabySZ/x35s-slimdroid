# 构建可用配方 (第7轮修复 —— 之前一直失败的原因已定位)

## 症状
```
dex2oatd64 E dex2oat.cc:2579] Cannot lock profiles: Failed to lock file
  'out/soong/.intermediates/frameworks/base/services/services/android_common/dexpreopt/profile.prof':
  Bad file descriptor
ninja: build stopped: subcommand failed.
```

## 根因 (源码级)
```
art/libartbase/base/scoped_flock.cc:63
    int operation = block ? LOCK_EX : (LOCK_EX | LOCK_NB);
    int flock_result = TEMP_FAILURE_RETRY(flock(file->Fd(), operation));   <- EBADF
art/dex2oat/dex2oat.cc:2574
    profile_file = LockedFile::Open(profile_file_.c_str(), O_RDONLY, true, &error);
```
`out` 是 NFS (`10.9.8.7:/srv/share/Ubuntu`)。
Linux NFS 客户端用 POSIX 记录锁模拟 `flock(2)`：`LOCK_EX -> F_WRLCK`，
而内核对**只读 fd** 上的 `F_WRLCK` 返回 `EBADF`。
本地 ext4 走真正的 flock 系统调用，不检查 fd 读写模式，故正常。

## 修复: 两个环境变量必须同时给

```bash
cd /data/aosp
export LC_ALL=C
export LD_PRELOAD=/data/rmx35k_work/flock_nfs_shim.so
export ALLOW_NINJA_ENV=true          # ★ 关键: 不加这个, sollya 会清掉 LD_PRELOAD
source build/envsetup.sh
lunch aosp_rm35k-userdebug
m -j10 services
```

**为什么两个都要**: 只给 `LD_PRELOAD` 时，Soong 的构建沙箱/环境净化会把
它从子进程环境里剔除，shim 不生效（实测 rc=1，仍然是 Bad file descriptor）。
`ALLOW_NINJA_ENV=true` 让 ninja 保留父进程环境变量。

## 已验证
```
2026-09-29 15:38  m -j10 services  ->  rc=0  (16 秒)
[100% 6/6] Copy: out/target/product/rm35k/system/framework/oat/arm64/services.odex
Cannot lock profiles 出现次数 = 0
```

## 对照 (证明这两个变量是必要且充分的)
| 命令 | rc | Cannot lock profiles |
|---|---|---|
| `m services` (裸) | 1 | 1 |
| `LD_PRELOAD=... m services` | 1 | 1 |
| `LD_PRELOAD=... ALLOW_NINJA_ENV=true m services` | **0** | **0** |

## 注意
- `m` 是 envsetup 定义的 **shell 函数**，`timeout m ...` 或
  `bash -c 'm ...'` 都会报 `m: command not found`。
  必须在**同一个 shell** 里先 `source build/envsetup.sh` 再直接 `m`。
- shim 源码在 `/data/rmx35k_work/flock_nfs_shim.c`（内含完整原理说明）。
