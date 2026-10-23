/*
 * zedkeys — RMX35K 掌机「退出游戏」组合键守护进程
 *
 * 背景: 本机手柄没有 Back/Home/Menu 键, 退出模拟器游戏只能靠系统 UI,
 *       体验极差。VOL+ 与 VOL- 是本机唯一一组空闲可组合的按键。
 *
 * 行为: 同时按下 VOL+ 和 VOL- → 注入一次 KEYCODE_ESCAPE。
 *
 * ── 为什么是 ESCAPE 而不是 BACK (2026-09-30 改) ──
 * 原来注入 KEYCODE_BACK(4), 在多数应用里等效于"返回", 但**在 RetroArch 里
 * 完全无效**。逐层核实如下 (证据见 R31_ZEDKEYS_ESC.md):
 *   - RetroArch 的 Android 键映射表 rarch_key_map_android
 *     (input/input_keymaps.c:1553) **没有 AKEYCODE_BACK 这一项**,
 *     所以 BACK 永远翻译不出 RETROK_* 键值, 也就碰不到
 *     retroarch.cfg:254 的 input_exit_emulator = "escape" 绑定。
 *   - 更隐蔽的是 android_input.c 里的 alias: 对非 gamepad/joystick 来源,
 *     BACK 会被**顺带**置成 AKEYCODE_X, 于是它在 RetroArch 里其实变成了
 *     「RetroPad 的 A 键」, 而不是"没反应"。
 *   - 反观 USB 键盘的 ESC: Generic.kl:23 `key 1 ESCAPE` →
 *     AKEYCODE_ESCAPE(111) → input_keymaps.c:1560
 *     { AKEYCODE_ESCAPE, RETROK_ESCAPE } → 命中 exit 绑定, 能退游戏。
 * 结论: ESC 在绝大多数场景与 BACK 通用 (用户已确认可接受), 且是 RetroArch
 * 唯一认的退出键, 故统一注入 ESC。
 *
 * 设计要点:
 *  1) 被动监听 /dev/input/event2 (zed_keyboard), **不使用 EVIOCGRAB**。
 *     老方案用 EVIOCGRAB 独占设备, 会导致系统收不到音量键, 必须自己
 *     用 `service call audio` 重造音量逻辑, 又脆又难维护。被动监听
 *     让原生音量功能完全不受影响 (同按两键时音量增减大致抵消)。
 *  2) 通过 /dev/uinput 注入, 不依赖 `input` 命令或 shell。
 *  3) 去抖: 两个键都松开后才重新武装, 避免长按连发。
 *  4) 组合时间窗: 两键落下间隔需 < COMBO_WINDOW_MS, 防止
 *     "先按住 VOL+ 再按 VOL-" 这类误触发。
 *  5) 设备丢失 (热插拔/重启) 自动重连, 不退出。
 */

#include <errno.h>
#include <fcntl.h>
#include <linux/input.h>
#include <linux/uinput.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <time.h>
#include <unistd.h>

#define DEV_INPUT       "/dev/input/event2"
#define DEV_UINPUT      "/dev/uinput"
#define COMBO_WINDOW_MS 500     /* 两键落下最大间隔 */
#define ESC_TAP_US      50000   /* ESC 按下到松开保持 50ms */

static int g_verbose = 0;

static void logmsg(const char *fmt, ...)
{
    if (!g_verbose)
        return;
    va_list ap;
    va_start(ap, fmt);
    vfprintf(stderr, fmt, ap);
    va_end(ap);
    fputc('\n', stderr);
}

static int64_t now_ms(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (int64_t)ts.tv_sec * 1000 + ts.tv_nsec / 1000000;
}

/* ---------- uinput: 建立一个只发送 KEY_ESC 的虚拟键盘 ---------- */
static int uinput_open(void)
{
    int fd = open(DEV_UINPUT, O_WRONLY | O_NONBLOCK);
    if (fd < 0) {
        fprintf(stderr, "zedkeys: 打开 %s 失败: %s\n", DEV_UINPUT, strerror(errno));
        return -1;
    }

    if (ioctl(fd, UI_SET_EVBIT, EV_KEY) < 0 ||
        ioctl(fd, UI_SET_KEYBIT, KEY_ESC) < 0) {
        fprintf(stderr, "zedkeys: UI_SET_*BIT 失败: %s\n", strerror(errno));
        close(fd);
        return -1;
    }

    struct uinput_setup usetup;
    memset(&usetup, 0, sizeof(usetup));
    usetup.id.bustype = BUS_VIRTUAL;
    usetup.id.vendor  = 0x1234;
    usetup.id.product = 0x5678;
    usetup.id.version = 1;
    snprintf(usetup.name, UINPUT_MAX_NAME_SIZE, "zedkeys-virtual");

    if (ioctl(fd, UI_DEV_SETUP, &usetup) < 0 ||
        ioctl(fd, UI_DEV_CREATE) < 0) {
        fprintf(stderr, "zedkeys: UI_DEV_SETUP/CREATE 失败: %s\n", strerror(errno));
        close(fd);
        return -1;
    }

    /* 给内核/输入子系统一点时间完成设备注册 */
    usleep(300000);
    logmsg("zedkeys: uinput 虚拟键盘已创建");
    return fd;
}

static void emit(int fd, uint16_t type, uint16_t code, int32_t val)
{
    struct input_event ie;
    memset(&ie, 0, sizeof(ie));
    ie.type  = type;
    ie.code  = code;
    ie.value = val;
    if (write(fd, &ie, sizeof(ie)) < 0)
        logmsg("zedkeys: 注入 write 失败: %s", strerror(errno));
}

/* 注入一次 ESC 点击 */
static void tap_esc(int fd)
{
    emit(fd, EV_KEY, KEY_ESC, 1);
    emit(fd, EV_SYN, SYN_REPORT, 0);
    usleep(ESC_TAP_US);
    emit(fd, EV_KEY, KEY_ESC, 0);
    emit(fd, EV_SYN, SYN_REPORT, 0);
    logmsg("zedkeys: >>> 注入 KEYCODE_ESCAPE");
}

int main(int argc, char **argv)
{
    if (argc > 1 && strcmp(argv[1], "-v") == 0)
        g_verbose = 1;

    int ufd = -1;
    /* /dev/uinput 可能在 late_start 时尚未就绪, 重试而非直接退出 */
    for (int i = 0; i < 30 && ufd < 0; i++) {
        ufd = uinput_open();
        if (ufd < 0) {
            if (i == 0)
                fprintf(stderr, "zedkeys: uinput 未就绪, 重试中...\n");
            sleep(2);
        }
    }
    if (ufd < 0) {
        fprintf(stderr, "zedkeys: 无法建立 uinput 设备, 退出\n");
        return 1;
    }

    int vup = 0, vdown = 0;          /* 当前按键按下状态 */
    int64_t up_t = 0, down_t = 0;    /* 各自落下时刻 */
    int armed = 1;                   /* 是否允许再次触发 */

    for (;;) {
        int fd = open(DEV_INPUT, O_RDONLY);
        if (fd < 0) {
            logmsg("zedkeys: 打开 %s 失败: %s, 2s 后重试", DEV_INPUT, strerror(errno));
            sleep(2);
            continue;
        }
        logmsg("zedkeys: 开始监听 %s", DEV_INPUT);

        /* 设备重新打开时复位状态, 避免残留按键导致误触发 */
        vup = vdown = 0;
        armed = 1;

        struct input_event ev;
        for (;;) {
            ssize_t n = read(fd, &ev, sizeof(ev));
            if (n < 0) {
                if (errno == EINTR)
                    continue;
                logmsg("zedkeys: read 失败: %s, 重连", strerror(errno));
                break;
            }
            if (n != sizeof(ev))
                continue;
            if (ev.type != EV_KEY)
                continue;
            if (ev.code != KEY_VOLUMEUP && ev.code != KEY_VOLUMEDOWN)
                continue;

            int pressed = (ev.value != 0);   /* 1=按下 2=长按重复 0=松开 */
            int64_t t = now_ms();

            if (ev.code == KEY_VOLUMEUP) {
                vup = pressed;
                if (pressed && ev.value == 1) up_t = t;
            } else {
                vdown = pressed;
                if (pressed && ev.value == 1) down_t = t;
            }

            /* 任一键松开 → 重新武装 */
            if (!vup || !vdown) {
                armed = 1;
                continue;
            }

            /* 两键同时按下 */
            if (!armed)
                continue;

            int64_t gap = (up_t > down_t) ? (up_t - down_t) : (down_t - up_t);
            if (up_t && down_t && gap <= COMBO_WINDOW_MS) {
                tap_esc(ufd);
                armed = 0;   /* 等两键都松开才再次触发 */
            } else {
                logmsg("zedkeys: 两键间隔 %lldms 超窗, 忽略", (long long)gap);
                armed = 0;
            }
        }
        close(fd);
    }
    return 0;
}
