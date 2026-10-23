# R32 —— zedkeys 改注入 ESC + TF 卡挂载故障根因

日期: 2026-09-30
设备: RMX35K (rk3566_rm700k), AOSP 11, 序列号 7b264ab2a454303

---

## 概要

两件事:
1. **zedkeys 从注入 BACK 改为注入 ESC**(用户要求), 已构建/刷机/实机功能验证通过。
2. **TF 卡不挂载的根因**: 我 R31 刷 super 时把设备 `/vendor` 的两个补丁
   (fstab 的 `encryptable`、init 的 `noSuspend`) **覆盖回原厂**了 —— 因为那两个
   补丁当初**只写进了设备 raw /vendor, 从未进构建树**。已修复, 并把补丁补进
   构建源, 防止复发。

---

## 一、zedkeys: BACK → ESC

### 1.1 为什么改 (用户观察到的现象)

用户实测: 音量组合键在别的应用能"返回", **在 RetroArch 里退不出游戏**;
而 USB 键盘的 ESC 能退出。逐层核实源码后确认为两条完全不同的链路:

| 环节 | USB 键盘 ESC (能退出) | 旧的 zedkeys (退不出) |
|---|---|---|
| 内核键码 | `KEY_ESC` = 1 | `KEY_BACK` = 158 |
| keylayout | `Generic.kl:23` `key 1 ESCAPE` | `Generic.kl:180` `key 158 BACK` |
| Android keycode | `AKEYCODE_ESCAPE` = **111** | `AKEYCODE_BACK` = **4** |
| RetroArch 映射表 | `input_keymaps.c:1560` `{AKEYCODE_ESCAPE, RETROK_ESCAPE}` ✔ | **表里没有 AKEYCODE_BACK** ✘ |
| 退出绑定 | `retroarch.cfg:254` `input_exit_emulator="escape"` 命中 | 永远翻译不出 RETROK_*, 碰不到绑定 |

### 1.2 一个容易误判的点 (我自曝并纠正)

`rarch_key_map_android` 表 (`input_keymaps.c:1553` 起, 111 行) 里搜
`AKEYCODE_BACK` 时, 朴素的 `grep AKEYCODE_BACK` 会命中 **`AKEYCODE_BACKSLASH`**
(`:32`) 这个**子串假阳性**, 得出"表里有 BACK"的错误结论。用词边界重测:

```
$ grep -cE '\bAKEYCODE_ESCAPE\b'    → 1     （:1560 活跃条目）
$ grep -cE '\bAKEYCODE_BACK\b'      → 0     ← 确实没有
$ grep -cE '\bAKEYCODE_BACKSLASH\b' → 1     ← 之前误命中的就是它
```

### 1.3 更隐蔽的一层: BACK 在 RetroArch 里会变成「A 键」

`android_input.c` 的 `android_input_poll_event_type_key()` 有别名逻辑:

```c
bool alias_back_as_x =
      (source & AINPUT_SOURCE_GAMEPAD)  != AINPUT_SOURCE_GAMEPAD
   && (source & AINPUT_SOURCE_JOYSTICK) != AINPUT_SOURCE_JOYSTICK;
...
case AKEY_EVENT_ACTION_DOWN:
    BIT_SET(buf, keysym);
    if (keysym == AKEYCODE_BACK && alias_back_as_x)
        BIT_SET(buf, AKEYCODE_X);            /* BACK 顺带置上 X */
```

zedkeys 的虚拟设备 `Sources: 0x00000101` (纯 KEYBOARD, 既非 GAMEPAD 也非
JOYSTICK) → `alias_back_as_x = true` → `AKEYCODE_X` → `input_keymaps.c:59`
`{AKEYCODE_X, RETROK_x}` → `retroarch.cfg:1428 input_player1_a = "x"`。
**所以它在 RetroArch 里不是"没反应", 而是被当成了 RetroPad 的 A 键。**

### 1.4 改动内容

`device/rockchip/rm35k/zedkeys/zedkeys.c` (已确认为**真正生效**的源,
见 §二 的教训):

| 位置 | 改动 |
|---|---|
| `:7` 头部注释 | 行为改为"注入 KEYCODE_ESCAPE", 并写明为何不是 BACK (含行号) |
| `ESC_TAP_US` | 原 `BACK_TAP_US`, 值仍 50000 |
| `uinput_open()` | `UI_SET_KEYBIT, KEY_BACK` → **`KEY_ESC`** |
| `tap_back()` → `tap_esc()` | `emit(EV_KEY, KEY_BACK, …)` → **`KEY_ESC`**, 日志字符串同步 |
| 调用点 | `tap_back(ufd)` → `tap_esc(ufd)` |

`device/rockchip/rm35k/zedkeys/zedkeys.rc`: 顶部注释同步更新 (说明为何用 ESC)。

### 1.5 验证 (三层, 逐层加严)

**① 源码静态自检**
```
$ grep -nE "KEY_BACK|KEYCODE_BACK|tap_back|BACK_TAP" zedkeys.c zedkeys.rc
仅剩 4 处, 全在解释性注释里 (说明"原为 BACK")
$ grep -nE "KEY_ESC|ESC_TAP|tap_esc" zedkeys.c
uinput_open: UI_SET_KEYBIT, KEY_ESC / tap_esc: emit KEY_ESC ×2 / 调用点 tap_esc(ufd)
```

**② 构建产物**
```
$ strings out/.../vendor/bin/zedkeys | grep KEYCODE
zedkeys: >>> 注入 KEYCODE_ESCAPE          ← 不再是 BACK
```

**③ 实机 uinput 能力表 (决定性)**
```
$ getevent -pl | grep -A2 zedkeys-virtual
  name:     "zedkeys-virtual"
    KEY (0001): KEY_ESC                    ← 只有 ESC(bit1), 无 BACK(bit158)
```
对比改前该设备能力表为 `KEY_BACK`。uinput 的 `UI_SET_KEYBIT` 决定设备声明哪些
键, 这是编译期常量落到运行时的直接体现。

**④ 实机功能测试 (端到端)**
用 `sendevent` 在 `/dev/input/event2` 上模拟"VOL+ 与 VOL- 几乎同时按下再松开",
同时抓 `/dev/input/event4` (zedkeys-virtual):
```
[41.468612] EV_KEY  KEY_ESC     DOWN
[41.468612] EV_SYN  SYN_REPORT
[41.518724] EV_KEY  KEY_ESC     UP
[41.518724] EV_SYN  SYN_REPORT
```
间隔 50.1 ms, 与 `ESC_TAP_US = 50000` 吻合。

**⑤ 双向负对照 (方法学要求)**
| 操作 | event4 输出 | 判定 |
|---|---|---|
| VOL+ 与 VOL- 同时 | `KEY_ESC DOWN/UP` | 正确触发 ✔ |
| **只按 VOL+** | 空 | 正确不触发 ✔ |
| **只按 VOL-** | 空 | 正确不触发 ✔ |

单键不触发证明"必须同时按"的判据仍成立, 且说明测的确实是组合逻辑而非噪声。

### 1.6 副作用评估
- 音量功能未受影响 (zedkeys 不改用 `EVIOCGRAB`, 仅被动读, 仍为设计要点 1)。
- 用户已认可"绝大多数场景 ESC 与 BACK 通用"。
- 若将来发现某应用只认 BACK, 可改为**同时注入 ESC+BACK**(两行 emit), 本
  改动已留清晰位置。

---

## 二、TF 卡不挂载: 根因与修复

### 2.1 症状
```
$ adb shell ls /storage/
emulated  self                      ← 缺 06B3-D7DD
$ adb shell getprop vold.has_adoptable
0                                   ← 修复后本应为 1
```

### 2.2 根因 (确证)

设备 `/vendor/etc/fstab.rk30board` 的 md5 退回了**原厂值**:
```
设备实测 : b6d2e43dbcfffa6b492abb11a19ffdf3   = 原厂 stock
应有补丁 : 81ec1ced934d5d3ec40a1330fe982d57   = voldmanaged=sdcard1:auto,encryptable=userdata
```

**是我 R31 刷 `super_r31.img` 覆盖的。** 关键机制:

> 那两个补丁 (2026-09-30 白天为"挂载 TF 卡"和"允许深度休眠"而打)
> **当初只写进了设备的 raw `/vendor` 分区, 从未写入构建树**。
> `super` 里含 `vendor` 分区 → 重刷 super 就把它们冲掉了。

构建树当时仍是原厂:
```
$ md5sum vendor/rockchip/rm35k/etc/fstab.rk30board
b6d2e43dbcfffa6b492abb11a19ffdf3   ← stock
```

连锁反应 (为什么表现为"卡不挂载"):
```
fstab 缺 encryptable=userdata
  → vold process_config() 不再给该卷设 kAdoptable
  → vold.has_adoptable=0
  → StorageManagerService 不把它当 VISIBLE 卷
  → 不建立 FUSE 会话, /storage/06B3-D7DD 不出现
（但内核已识别卡、vold 也 fsck 通过、/mnt/media_rw/06B3-D7DD 有挂载）
```
内核侧证明卡是好的:
```
[0.491070] mmcblk3: mmc3:0001 acer 58.2 GiB
[...]      FAT-fs (mmcblk3p1): Volume was not properly unmounted...
vold: Filesystem check completed OK
vold: /dev/block/vold/public:179,1: UUID="06B3-D7DD" TYPE="vfat"
```
即**卡与 vold 都正常, 纯粹是 fstab 契约丢了**。

### 2.3 顺带发现: 挂起补丁也被冲掉了
```
$ md5sum /vendor/etc/init/hw/init.rk356x.rc
a203e5e70ad3aad1c33826454ce73570   = 原厂 stock
$ grep -n noSuspend /vendor/etc/init/hw/init.rk356x.rc
27: write /sys/power/wake_lock "PowerManagerService.noSuspend"     ← 又生效了
$ cat /sys/power/wake_lock
PowerManagerService.noSuspend        ← 深度休眠被禁止
$ cat /sys/power/suspend_stats/success
0
```
即 R31 刷机把 R30 验证过的"能深度休眠"成果一起回退了。同一个根因。

### 2.4 修复: 补丁写入构建树 (治本)

**关键纠错 —— 我最初改错了文件。** `init.rk356x.rc` 在树里有两份:
```
device/rockchip/rm35k/init/init.rk356x.rc     ← 真正生效
vendor/rockchip/rm35k/etc/init/hw/init.rk356x.rc  ← 未被任何规则引用
```
全树只有**一条**复制规则, 且用的是前者:
```
$ grep -rn "init\.rk356x\.rc" device/rockchip/rm35k/*.mk vendor/rockchip/rm35k/*.mk
device/rockchip/rm35k/common.mk:146: $(LOCAL_PATH)/init/init.rk356x.rc:$(TARGET_COPY_OUT_VENDOR)/...
```
(我的第一版只改了 vendor 那份, 那样构建出来**仍是 stock**, 会被静默吞掉。
已两份都改为补丁版。)

最终落地的补丁 (均有 stock 备份):
| 构建源文件 | stock md5 | 补丁 md5 |
|---|---|---|
| `vendor/rockchip/rm35k/etc/fstab.rk30board` | b6d2e43d… | **81ec1ced…** |
| `device/rockchip/rm35k/init/init.rk356x.rc` | a203e5e7… | **e8962d84…** |
| `vendor/rockchip/rm35k/etc/init/hw/init.rk356x.rc` (未被引用, 保持一致) | a203e5e7… | **e8962d84…** |

备份 (回滚用):
`src_backup_r31_fstab.rk30board`、`src_backup_r31_device_init.rk356x.rc`、
`src_backup_r31_init.rk356x.rc` (均在 `/data/rmx35k_work/`)。

### 2.5 构建产物验证 (打包前)
```
$ grep -n cts_gts.status out/.../vendor/etc/init/hw/init.rk356x.rc
63:on property:cts_gts.status=true          ← 63=补丁, 62=stock (决定性行号判据)
$ grep -c encryptable out/.../vendor/etc/fstab.rk30board
2                                          ← 期望 2
$ md5sum out/.../vendor/etc/fstab.rk30board out/.../vendor/etc/init/hw/init.rk356x.rc
81ec1ced934d5d3ec40a1330fe982d57 / e8962d844ea56e37b0836712cc88f24d
```

### 2.6 super 内验证 (刷写前)
从 `super_r32.img` 用 `lpunpack` 解出 `vendor.img`, 再 `debugfs cat` 取文件算 md5:
```
/etc/fstab.rk30board          81ec1ced934d5d3ec40a1330fe982d57  ✔
/etc/init/hw/init.rk356x.rc   e8962d844ea56e37b0836712cc88f24d  ✔
/bin/zedkeys                  存在 (11840 B, 新时间戳)
system: /bin/wificond         缺失 ✔ (R31 成果保持)
```
注意 `lpunpack` 往返校验中 **vendor 前缀 md5 已变化**
(`faa531e4` → `036c86e7`), 与"vendor 内容确实改了"一致。

### 2.7 刷机后实机验收
```
vold.has_adoptable = 1                      ← 期望 1 ✔
/storage/  = 06B3-D7DD  emulated  self      ← 卡回来了 ✔
wake_lock  = []                             ← 空, 深度休眠恢复 ✔
cts_gts.status 在 63 行                     ← 补丁生效 ✔
```

**TF 卡完整 FUSE 链 (6 条挂载全齐)**:
```
/dev/block/vold/public:179,1 → /mnt/media_rw/06B3-D7DD      (vfat)
/dev/fuse → /mnt/user/0/06B3-D7DD
/dev/fuse → /mnt/installer/0/06B3-D7DD
/dev/fuse → /mnt/androidwritable/0/06B3-D7DD
/dev/fuse → /storage/06B3-D7DD                              ← 用户可见路径
/dev/block/vold/public:179,1 → /mnt/pass_through/0/06B3-D7DD
```
**数据完好**: 17 个顶层条目 (AURKNIX/Alarms/Android/…/t.txt), 与刷机前一致;
`AURKNIX/easyrpg` 下 **6 个 `.nomedia` 全部还在**。

**MediaStore 重新收录** (证明是完整的挂载流程, 不只是 mount):
```
StorageManagerService: Volume public:179,1 broadcasting mounted to UserHandle{0}
MediaStore: Examining volume public:179,1 with name 06b3-d7dd and state mounted
```

---

## 三、回归检查 (r32 刷机后)

| 项 | 结果 |
|---|---|
| `FATAL EXCEPTION` | **0** |
| `am_crash` | **0** |
| SystemUI / system_server pid | 458 / 352 (稳定) |
| `sys.boot_completed` | 1 |
| wificond 进程 / 二进制 | 0 / 缺失 (R31 成果保持) |
| WiFi 特性 | 0 (红线 ✔) |
| `sys.gmali.version` | `g2p0-01eac0-x-8@0` (GPU/Vulkan 红线 ✔) |
| `vulkan.rk356x.so` | 在位 ✔ |

---

## 四、教训 (已写进构建源注释)

1. **写进设备 raw 分区的补丁必须有构建树副本** —— 否则任何一次 super 重刷都会
   静默回退。本轮两处故障 (TF 卡 + 深度休眠) 都是这一个原因。
2. **同名文件可能有多个副本, 只有被 `PRODUCT_COPY_FILES` 引用的那份生效** ——
   改前必须 `grep -rn` 确认引用链, 否则改了个寂寞且构建不报错。
3. **子串 grep 会骗人** —— `AKEYCODE_BACK` 命中 `AKEYCODE_BACKSLASH`; 用 `\b` 词边界。
4. **uinput 的 `UI_SET_KEYBIT` 是验证注入键码的最佳判据** —— `getevent -pl`
   直接显示设备声明的键集合, 比反汇编 stripped 二进制可靠。

---

## 五、复现命令

```bash
# 构建 (zedkeys + vendor + system)
cd /data/rmx35k_work && bash build.sh zedkeys vendorimage systemimage
# 打包 super
bash build_super_r32.sh
# 刷写
bash flash_r32_super.sh --yes

# zedkeys 验证 (三层)
adb shell 'getevent -pl | grep -A2 zedkeys-virtual'      # 应只列 KEY_ESC
adb shell 'strings /vendor/bin/zedkeys | grep KEYCODE'   # 应显示 KEYCODE_ESCAPE
# 功能测试: 模拟组合键后抓 event4
adb shell 'getevent -lt /dev/input/event4 & \
  sendevent /dev/input/event2 1 115 1; sendevent /dev/input/event2 0 0 0; \
  sendevent /dev/input/event2 1 114 1; sendevent /dev/input/event2 0 0 0; \
  sleep 1; \
  sendevent /dev/input/event2 1 115 0; sendevent /dev/input/event2 0 0 0; \
  sendevent /dev/input/event2 1 114 0; sendevent /dev/input/event2 0 0 0'

# TF 卡验证
adb shell 'getprop vold.has_adoptable; ls /storage/'
adb shell 'cat /sys/power/wake_lock'                     # 应为空
```

---

## 六、文件清单

| 文件 | 说明 |
|---|---|
| `device/rockchip/rm35k/zedkeys/zedkeys.c` | BACK → ESC (核心改动) |
| `device/rockchip/rm35k/zedkeys/zedkeys.rc` | 注释同步 |
| `vendor/rockchip/rm35k/etc/fstab.rk30board` | 补丁 (.nomedia 的 TF 卡挂载契约) |
| `device/rockchip/rm35k/init/init.rk356x.rc` | 补丁 (深度休眠) —— **真正生效的那份** |
| `vendor/rockchip/rm35k/etc/init/hw/init.rk356x.rc` | 同上, 保持一致 |
| `/data/rmx35k_work/src_backup_r31_*.{rk30board,rk356x.rc}` | 三份构建源 stock 备份 |
| NFS `super_r32.img` (md5 `feb0c5f1…`) | 成品镜像 |
| `/data/rmx35k_work/r32_flash_evidence/` | 刷写日志 |
