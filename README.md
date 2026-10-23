# x35s-slimdroid

**POWKIDDY X35s (RKX35K / rk3566_rm700k) 精简版 Android 11**

为 LCD 掌机定制的 AOSP 11 构建。目标：**极致省电 + 极快启动 + 只保留游戏所需能力**。

> 实测成绩：**休眠一周，电量仍剩 20% 以上**；自检结束后 **5 秒内**出现启动动画。

---

## 目录

- [这是什么](#这是什么)
- [处理的缘由](#处理的缘由)
- [实测优化成果](#实测优化成果)
- [为什么这么做（对比 AURKNIX）](#为什么这么做对比-aurknix)
- [退出游戏：同时按 VOL+ / VOL-](#退出游戏同时按-vol--vol-)
- [存储布局：App 装哪里](#存储布局app-装哪里)
- [备份原机固件与救砖](#备份原机固件与救砖)
- [仓库内容](#仓库内容)
- [刷机方法](#刷机方法)
- [Logo 自定义方法](#logo-自定义方法)
- [构建方法](#构建方法)
- [已知取舍](#已知取舍)
- [文档索引](#文档索引)

---

## 这是什么

RKX35K 是一台 640×480 LCD 掌机（MIPI DSI 4-lane 面板），主控 RK3566，运行 AOSP 11。
原厂系统面向通用平板设计，带着大量本机用不到的组件：WiFi 守护进程、蜂窝电话栈、
GPS、摄像头 HAL、32 位 zygote、debug 版 ART、二十几个 RK 预装 APK……

本项目把这些**逐一识别、证实无依赖后移除**，并为手柄场景补上专属支持。

### 硬件要点

| 项目 | 值 |
|---|---|
| 主控 | RK3566 (`rk3566_rm700k`) |
| 屏幕 | 640×480 LCD，MIPI DSI 4-lane（`simple-panel-dsi`） |
| RAM | ~974 MB |
| 无线 | **无 WiFi / 无蓝牙模组 / 无 GNSS / 无蜂窝** |
| 输入 | 内置手柄 `zed_joystick`（ABCD + 投币 + 开始 + 十字键）+ 专用退出键 |
| 侧键 | VOL±、电源 |

---

## 处理的缘由

### 为什么精简

这台设备的核心矛盾是：**无线电全缺的硬件，跑着按"联网平板"假设搭起来的系统**。
每一条用不到的常驻服务都在消耗三样东西：内存、启动时间、电量。

精简不是随手删，而是**先证明"确实没依赖"，再动手**。每条删除都附证据链，见 [已知取舍](#已知取舍)。

### 手柄/按键相关的两处修复

**1. 十字键（Generic.kl）**

内核把 d-pad 上报为 `BTN_DPAD_*`(544-547)，而 AOSP 自带的 `Generic.kl` 没有这几条，
导致 Android 侧根本收不到 `AKEYCODE_DPAD_*`。
补上 4 条映射后十字键才可用（见
`build-patches/aosp/frameworks/base/data/keyboards/Generic.kl:447-453`）。

**2. 天马(Pegasus) 启动 RetroArch 丢失配置**

这是一个**极隐蔽的坑**，值得单独说：

- 现象：从天马进游戏 → 画面全屏、无虚拟手柄、**方向键失效**；但 ABCD/投币/开始都正常。
- 直接进 RetroArch 一切正常。
- 根因：天马生成的启动命令只传了 `-e ROM` 和 `-e LIBRETRO` 两个参数，**漏传 `-e CONFIGFILE`**。
  RetroArch 的 Android 端必须靠这个 extra 才能定位用户配置 `retroarch.cfg`；
  漏了就退回内置默认值 → 全屏、无虚拟手柄、方向键失效。
- 为什么 ABCD 还能用：手柄映射存在独立的 autoconfig 文件 `zed_joystick.cfg` 里，
  与 `retroarch.cfg` 无关，所以看似"手柄半好半坏"，极具迷惑性。
- 修复：给 21 个 `*.metadata.pegasus.txt` 的 launch 行补上 `-e CONFIGFILE`。
  该参数是 [Pegasus 官方文档](https://pegasus-frontend.org/docs/user-guide/platform-android/)中
  RetroArch 标准启动命令的一部分。
- 生成器 `es2pegasus.py` 已同步修正，避免将来重新生成时复发。

---

## 实测优化成果

| 指标 | 结果 |
|---|---|
| 休眠一周电量 | **剩余 20% 以上** |
| 自检结束 → 启动动画出现 | **< 5 秒** |
| 移除的常驻进程 | wificond 等 |
| zygote | 单架构 `zygote64`（省去 32 位预载，实测省 ~75 MB 常驻内存 + 消除 465ms 启动锁争用） |

---

## 为什么这么做（对比 AURKNIX）

AURKNIX 是本机常用的另一套方案——把整套系统装在 **TF 卡**上，从 TF 启动 Linux/游戏系统。
本固件则把 Android 放进 **eMMC**，只在 TF 卡上放游戏 ROM。

**核心差别：系统跑在哪种存储介质上。**

| | 本固件（eMMC 启动） | AURKNIX（TF 卡启动） |
|---|---|---|
| 系统所在介质 | 板载 eMMC（eMMC 5.x，HS200 接口） | TF 卡（UHS-I） |
| 顺序读 | eMMC 5.x 规范理论上限 200 MB/s，实际通常 100–250 MB/s | UHS-I 上限 104 MB/s，普通卡实际 20–90 MB/s |
| 4K 随机读（影响 App 冷启动、dex 加载、sqlite） | 通常 10–40 MB/s | 通常 1–5 MB/s（无 A1/A2 标的卡更低） |
| 系统完整性 | 只读 super，掉电不易损坏 | 卡上系统可写，拔卡/掉电易伤 |
| 拔卡影响 | 拔了 TF 只是 ROM 没了，系统照常 | 拔了卡系统直接没了 |

说明：上表为**规范/典型值**，未在本机做过逐卡实测（设备侧无基准工具），
具体数值随卡的品牌与等级浮动。但量级差距是确定性的：**4K 随机读写是 App 体验最敏感的
指标，eMMC 在这一项上比普通 TF 卡高出一个数量级**。这也是 Android 系统必须放 eMMC
的原因——Framework、ART、dexopt、应用数据库全是海量小文件随机 IO，放 TF 上会明显卡顿。

**所以分工是：系统 + App 在 eMMC，ROM 在 TF 卡。** ROM 是大文件顺序读，TF 完全够用，
而且可热插拔换游戏库；eMMC 的小文件随机 IO 性能留给系统真正需要它的地方。

---

## 退出游戏：同时按 VOL+ / VOL-

本机手柄**没有** Back / Home / Menu 键，退出模拟器游戏原本只能靠系统 UI，体验很差。
VOL+ 和 VOL- 是本机唯一一组空闲可组合的按键，于是做成组合键：

> **同时按住 VOL+ 和 VOL- → 触发一次「返回/退出」**（注入 `KEYCODE_ESCAPE`）

实现在 `device/rockchip/rm35k/zedkeys/zedkeys.c`（220 行 C，无外部依赖）：

**设计要点**

| 要点 | 说明 |
|---|---|
| 被动监听 | 监听 `/dev/input/event2`，**不用 `EVIOCGRAB`**——不抢设备，原生音量调节完全不受影响 |
| 组合窗口 | 两键落下间隔需 < 500 ms（`COMBO_WINDOW_MS`），防止"先按住一个再按另一个"误触发 |
| 去抖 | 两键都松开后才重新武装，长按不连发 |
| 注入方式 | 走 `/dev/uinput` 虚拟键盘，不依赖 `input` 命令 |
| 热插拔 | 设备丢失自动重连，不退出 |

**为什么注入 ESCAPE 而不是 BACK（一个隐蔽的坑）**

最初版本注入 `KEYCODE_BACK`，在多数应用里等效"返回"，但**在 RetroArch 里完全无效**：

- RetroArch 的 Android 键映射表 `rarch_key_map_android`（`input/input_keymaps.c:1553`）
  **没有 `AKEYCODE_BACK`** 这一项，BACK 永远翻不出 `RETROK_*`，碰不到
  `retroarch.cfg:254` 的 `input_exit_emulator = "escape"` 绑定。
- 更隐蔽的是 `android_input.c` 里的 alias 逻辑：对非 gamepad 来源，BACK 会被**顺带**
  置成 `AKEYCODE_X`——它在 RetroArch 里其实变成了**RetroPad 的 A 键**，不是"没反应"。
- 反观 ESC：`Generic.kl:23 key 1 ESCAPE` → `AKEYCODE_ESCAPE(111)` →
  `input_keymaps.c:1560 { AKEYCODE_ESCAPE, RETROK_ESCAPE }` → 命中 exit 绑定，能退游戏。

ESC 在绝大多数场景与 BACK 通用，且是 RetroArch 唯一认的退出键，故统一注入 ESC。

---

## 存储布局：App 装哪里

eMMC 只有 4 GB（`004GE0`，7733248 扇区 ≈ 3.69 GiB），必须精打细算。
出厂分区把大量空间浪费在几乎用不到的 `backup`/`cache` 上，本固件重新分配了这些空间：

| 分区 | 出厂 | 本固件 | 说明 |
|---|---|---|---|
| `backup` | 384 MiB | **8 MiB** | fstab 未引用，纯浪费 |
| `cache` | 384 MiB | **16 MiB** | Android 11 已基本不用 cache 分区 |
| `super` | 1532 MiB | **1344 MiB** | 动态分区（system/system_ext/vendor/product/odm） |
| **`userdata`** | **1294 MiB** | **2249 MiB** | **= `/data`，App 装这里，+955 MiB** |
| `recovery` | 76 MiB | 76 MiB | 起点 LBA 与出厂**完全相同**，刻意锁死保证救援通道 |

**给你的使用建议：**

> **App 装 eMMC，ROM 放 TF 卡。**

- 应用安装包会落到 `/data/app`（即 `userdata` 分区，本固件已扩到 2249 MiB），
  **不占 super**，所以装 App 不会把系统挤爆。
- eMMC 的 4K 随机 IO 远快于 TF，App 冷启动、dex 加载、数据库读写都受益。
- ROM（动辄几十上百 MB 的大文件）是顺序读，放 TF 卡毫无压力，且**换游戏库不用动系统**——
  拔卡在电脑上拷即可。
- `super` 里 5 个分区运行时全是只读挂载，只有重新 `lpmake` 改固件才会变，不会越用越满。

---

## 备份原机固件与救砖

### 为什么必须先备份

本机 eMMC 上的 `uboot`/`trust`/`security` 三个分区是**原厂专属**，一旦写坏就只剩
MaskRom 强刷（需要 Rockchip 官方工具与专用固件，普通用户很难拿到）。所以：

> **刷机前先备份整盘，留一条"随时回原厂"的路。**

### 备份方法（Android 可启动时）

前提：`adb` 可用，设备已 root（本固件默认 userdebug，`adb root` 即可）。

```bash
adb root
adb wait-for-device

# 1. 整盘 dump (4GB, 走 USB 约几分钟, 必须先确认有足够磁盘空间)
adb shell 'dd if=/dev/block/mmcblk2 bs=4M' > RMX35K_factory_full.img

# 2. 核对大小 (应为 3,959,422,976 字节 = 7733248 扇区 × 512)
ls -l RMX35K_factory_full.img

# 3. 计算并记录 md5 (校验用, 务必保存)
md5sum RMX35K_factory_full.img > RMX35K_factory_full.md5
```

**注意：**

- 必须写整盘 `/dev/block/mmcblk2`（含 GPT），不要只 dump 单分区——
  单分区丢了 GPT 布局就回不去了。
- 本机 eMMC 是 7733248 扇区（3.69 GiB），写出来的镜像就是这么大，别怀疑。
- 备份**含 userdata（用户数据快照）**。若想"干净回原厂"，恢复时只刷静态分区即可，
  `/data` 交给系统首次启动重建。

**逐分区备份（可选，更省空间）：**

```bash
# 列出分区名
adb shell 'ls /dev/block/by-name/'
# 按需 dump, 例:
adb shell 'dd if=/dev/block/by-name/super bs=4M' > super_factory.img
adb shell 'dd if=/dev/block/by-name/boot  bs=4M' > boot_factory.img
```

### 备份文件清单（我们已留存）

| 文件 | 大小 | md5 | 内容 |
|---|---|---|---|
| `mmcblk2_full.img` | 3,959,422,976 B | `ed364c9dae3585fa1d2dea6608e6bb1b` | 原厂整盘（含音量键+指示灯修复） |
| `gpt_head_40sectors.bin` | 20480 B | — | GPT 头 LBA0-39 |
| `partitions_byname.txt` | — | — | 分区表快照 |
| `MD5SUMS.txt` | — | — | 全部文件校验和 |

（位于 NFS `RMX35K_整机备份_20260924/`，含 `fixes/` 子目录的音量键/指示灯补丁资产）

---

### 救砖：TF 卡启动 AURKNIX 恢复固件

**适用场景**：Android 起不来了、adb 连不上、卡 logo、刷坏 super/boot。
**原理**：本机的 `security`/`uboot`/`trust` 分区从未被改写，所以芯片级引导永远活着，
**硬件不会砖**。TF 卡上的 AURKNIX 有自己的引导，可以直接从 TF 启动一个 Linux，
从系统内部把 eMMC 整盘写回。

#### 第 0 步：准备恢复镜像

把备份的整盘镜像（`mmcblk2_full.img` 或你自己的 `RMX35K_factory_full.img`）
复制到 TF 卡的 **STORAGE 分区**根目录。AURKNIX 的 TF 卡有多个分区，STORAGE 是数据分区。

若没有现成 TF 卡，用 `install_to_tf.sh` 制作：

```bash
# 在 Linux PC 上 (需要一张 >= 64G 的 TF 卡, 因为要装 4G 恢复镜像)
sudo ./install_to_tf.sh /dev/sdX --flash      # 先写 AURKNIX, 再注入恢复包
# 或卡上已有 AURKNIX 时:
sudo ./install_to_tf.sh /dev/sdX              # 只注入恢复包
```

#### 第 1 步：改写启动脚本（核心）

AURKNIX 从 TF 启动后会执行 `/storage/.config/autostart/` 下的所有脚本。
**这就是改写点**——放一个恢复脚本进去，开机就自动刷写 eMMC：

```bash
# 在 PC 上, TF 卡的 STORAGE 分区挂载为 /media/user/STORAGE (路径按实际调整)
mount /dev/sdX3 /mnt/tf        # STORAGE 分区序号视分区表而定
cat > /mnt/tf/.config/autostart/00-emmc-restore.sh <<'EOS'
#!/bin/bash
#  RMX35K eMMC 整盘恢复 — 由 AURKNIX autostart 调用
#  日志: /storage/emmc_restore.log
#  成功: /storage/EMMC_RESTORE_DONE   失败: /storage/EMMC_RESTORE_FAILED
LOG=/storage/emmc_restore.log
exec >>"$LOG" 2>&1
echo "===== $(date) eMMC restore start ====="
export PATH=/usr/bin:/usr/sbin:/bin:/sbin:$PATH

S=/storage
IMG=$S/emmc_restore.img
DONE=$S/EMMC_RESTORE_DONE
FAIL=$S/EMMC_RESTORE_FAILED
EXPECT_SIZE=3959422976
# ★ 改成你自己的镜像 md5
EXPECT_MD5=ed364c9dae3585fa1d2dea6608e6bb1b

rm -f "$FAIL"
[ -f "$DONE" ] && { echo "already done"; exit 0; }
[ -f "$IMG" ] || { echo "FATAL: no $IMG"; touch "$FAIL"; exit 0; }

# 1. 定位 eMMC (按 7733248 扇区识别, 避免写错设备)
EMMC=""; TF=""
for B in /sys/block/mmcblk*; do
  N=$(basename "$B")
  case "$N" in *boot*|*rpmb*) continue;; esac
  SZ=$(cat "$B/size" 2>/dev/null)
  [ "$SZ" = "7733248" ] && EMMC=/dev/$N || { [ -z "$TF" ] && TF=/dev/$N; }
done
[ -z "$EMMC" ] && { echo "FATAL: eMMC not found"; touch "$FAIL"; exit 0; }
[ "$EMMC" = "$TF" ] && { echo "FATAL: eMMC==TF"; touch "$FAIL"; exit 0; }
echo "eMMC=$EMMC"

# 2. 卸载 eMMC 上所有挂载
for P in ${EMMC}p*; do [ -b "$P" ] && umount -f "$P" 2>/dev/null; done
sync

# 3. 校验镜像 md5
echo "verifying image md5..."
MD=$(md5sum "$IMG" | awk '{print $1}')
[ "$MD" = "$EXPECT_MD5" ] || { echo "FATAL: md5 mismatch $MD"; touch "$FAIL"; exit 0; }

# 4. 整盘写回 (4M 块, 直写 + fsync)
echo "writing $IMG -> $EMMC ..."
dd if="$IMG" of="$EMMC" bs=4M conv=fsync status=progress || { touch "$FAIL"; exit 0; }
sync

# 5. 回读校验 (抽样 1MB)
echo "verifying written data..."
dd if="$EMMC" bs=1M count=1 | md5sum > /tmp/r1
dd if="$IMG"  bs=1M count=1 | md5sum > /tmp/r2
diff -q /tmp/r1 /tmp/r2 >/dev/null || { echo "FATAL: readback mismatch"; touch "$FAIL"; exit 0; }

echo "RESTORE OK"
touch "$DONE"
sync
poweroff
EOS
chmod +x /mnt/tf/.config/autostart/00-emmc-restore.sh
umount /mnt/tf
```

**要点：**

- `EXPECT_MD5` **必须改成你自己的镜像 md5**，否则脚本会因校验不符拒刷。
- 脚本按 `7733248` 扇区识别 eMMC，**防止认错设备写成 TF 卡自己**（TF 是另一块盘）。
- 写完自动 `poweroff`，并留下 `EMMC_RESTORE_DONE`/`EMMC_RESTORE_FAILED` 标记文件。
- 抢救旧数据：如需先备份 `/data`，参考现成的 `00-emmc-install-fix11.sh`
  （内含"尽力抢救旧 userdata 日志"段落），把恢复顺序改成先备份再写。

#### 第 2 步：执行恢复

1. TF 卡插入设备
2. 开机 → AURKNIX 从 TF 启动 → autostart 自动执行恢复脚本
3. 等待刷写（4 GB 整盘，视 TF 速度约 10-20 分钟）
4. 自动关机
5. **拔掉 TF 卡**，重新开机 → 原厂固件回来了

**进度查看**（若恢复中途想确认状态）：把 TF 拔出来插电脑，看
`/storage/emmc_restore.log` 与 `EMMC_RESTORE_DONE`/`EMMC_RESTORE_FAILED` 标记。

#### 第 3 步：验证

拔卡开机后：

```bash
adb root
adb shell getprop sys.boot_completed        # 应为 1
# 核对系统分区 md5 与备份一致
adb shell 'dd if=/dev/block/by-name/super bs=4M | md5sum'
```

### 三条恢复通道优先级

| 优先级 | 通道 | 前提 |
|---|---|---|
| 1 | `adb reboot recovery` → recovery 里 `dd` | adb 可用（最方便） |
| 2 | `fastboot flash super ...` | 能进 fastbootd/bootloader |
| 3 | **TF 卡 AURKNIX 启动 + autostart 恢复脚本** | **adb/fastboot 全挂时的最后手段** |
| 4 | MaskRom 强刷（Rockchip 官方工具） | 彻底没救时的最后兜底 |

> **硬件不会砖**——`security`/`uboot`/`trust` 在独立分区且从未改写，芯片级引导永远活着。

---

## 仓库内容

```
x35s-slimdroid/
├── device/rockchip/
│   ├── rm35k/           # 设备配置（核心）：mk、sepolicy、eink_logo、zedkeys、波形
│   ├── rm35k-kernel/    # 预编译内核 Image + boot.dtb
│   └── common/          # RK 通用构建脚本 (mkimage.sh 等)
├── vendor/rockchip/
│   ├── rm35k/           # RK vendor blobs (HAL/lib/firmware) + 我们的补丁
│   ├── common/          # RK 通用 vendor (已按本机硬件裁剪)
│   └── hardware/        # RK HAL 接口定义
├── hardware/rockchip/   # audio/hwcomposer/keymaster 等 HAL
├── build-patches/
│   ├── aosp/            # 3 个改动的 AOSP 源文件 (保留原始相对路径)
│   │   ├── build/make/target/product/base_system.mk
│   │   ├── frameworks/base/data/keyboards/Generic.kl
│   │   └── frameworks/native/data/etc/handheld_core_hardware.xml
│   ├── build.sh         # 顶层构建入口 (含 NFS flock 垫片说明)
│   ├── mkimage.sh       # 镜像打包
│   ├── mkimage_ab.sh
│   └── flockshim/       # NFS flock 兼容垫片 (源码+预编译)
├── docs/evidence/       # 逐轮改动证据文档
└── README.md
```

### `vendor/rockchip/common` 裁剪说明

原树 859 MB，已按本机硬件裁到 ~450 MB，删除项均有构建条件佐证：

| 删除项 | 依据 |
|---|---|
| `wifi/` `gps/` `phone/` | `device/rockchip/rm35k/common.mk` 中 `PRODUCT_HAVE_RKWIFI/GPS/RKPHONE_FEATURES := false`，且 `device-vendor.mk:67,87,96` 用 `ifeq` 包裹对应 include |
| `gpu/` 下除 `MaliG52` 外全部 | `BoardConfig.mk:23 TARGET_BOARD_PLATFORM_GPU := mali-G52`，`device-vendor.mk` 按 GPU 型号条件 include |
| `apps/` 下未引用项 | `apps.mk` 的条件分支逐个核对，仅保留 `PRODUCT_PACKAGES` 实际会命中的 6 个 |
| `pluginsvc/` `webkit/` `samba/` `rftesttool/` | 守卫条件不匹配本平台 / 内容全注释 |

**保留**了条件会命中的 `eptz/`(39M) `vpu/`(45M) `ipp/` `nand/` `fec/` 等，虽可再省 84 MB，
但不值得冒构建风险。若你确定不用人脸/视频硬解，可自行删除对应目录并同步改
`vendor/rockchip/common/device-vendor.mk`。

---

## 刷机方法

> ⚠️ 刷机有变砖风险。操作前确认你了解回滚手段。
> 本设备有 `security`/`recovery`/`backup` 分区与独立的 DTB/rescue 卡方案可救。

### 前置条件

- 已开启 USB 调试的设备 + USB-C 数据线
- `adb`、`fastboot`（platform-tools，或直接用本仓库构建产出的 `out/host/linux-x86/bin/fastboot`）
- 镜像文件（见下）

### 关键分区表（来自 `device/rockchip/rm35k/parameter.txt`）

```
mtdparts=rk29xxnand:
  0x00002000@0x00002000(security)     0x00002000@0x00004000(uboot)
  0x00002000@0x00006000(trust)        0x00002000@0x00008000(misc)
  0x00002000@0x0000A000(dtbo)         0x00000800@0x0000C800(vbmeta)
  0x00014000@0x0000C800(boot)         0x00020000@0x00020800(recovery)
  0x00004000@0x00040800(backup)       0x00008000@0x00044800(cache)
  0x00008000@0x0004C800(metadata)     0x00000800@0x00054800(baseparameter)
  0x002A0000@0x00055000(super)        -@0x002F5000(userdata:grow)
```

本机为 **动态分区（super）** 布局：`system`/`vendor`/`odm` 都在 `super` 里。

### 方法一：只刷 super（改 system/vendor，最常用）

这是最安全、最常做的操作，**不碰 boot/recovery/uboot**。

```bash
# 1. 重启进 fastbootd (super 分区必须在 userspace fastboot 下才能写)
adb reboot fastboot
sleep 5
fastboot devices                 # 确认在线, 分区尺寸应为 0x43000000
fastboot getvar partition-size:super

# 2. 刷入
fastboot flash super super_r32.img

# 3. 回到系统
fastboot reboot
```

**校验清单**（强烈建议照做）：

```bash
# 刷之前
ls -l super_r32.img              # 大小应为 1124073472 (0x43000000)
md5sum super_r32.img             # 与预期比对

# 刷之后首次开机
adb shell getprop sys.boot_completed   # 应为 1
```

### 方法二：刷 boot / dtbo / recovery（改内核或设备树）

```bash
adb reboot bootloader            # 注意: 是 bootloader 不是 fastbootd
fastboot flash boot boot.img
fastboot flash dtbo dtbo.img
fastboot reboot
```

### 方法三：全量刷机（RKDevTool / upgrade_tool，风险最高）

需要 `update.img` 或逐个分区镜像，用 Rockchip 官方工具：
1. 设备进入 Loader/MaskRom 模式（按住恢复键插 USB）
2. 用 `RKDevTool`（Windows）或 `upgrade_tool`（Linux）加载 `parameter.txt` + 各分区镜像
3. 勾选后执行升级

**除非设备无法启动，否则不建议走这条路。**

### 刷机失败排查

| 现象 | 处理 |
|---|---|
| `fastboot` 不识别 | 确认是 fastbootd 而非 bootloader；`lsusb` 看是否有 Rockchip VID |
| 刷 super 后不开机 | 用 `super_before_r26.img` / `planB_r19b.img` 回滚 |
| 卡 logo | boot 分区与 super 不配套，需成对刷 |
| 完全无响应 | MaskRom 模式 + RKDevTool 强刷（最后手段） |

---

## Logo 自定义方法

四段启动流程各有独立图像，全部集中在 `device/rockchip/rm35k/eink_logo/`
（**目录名是原厂沿用的历史命名**，本机实为普通 LCD，该目录内容与墨水屏无关）：

```
eink_logo/
├── uboot_logo/        # U-Boot 阶段 + 充电动画
│   ├── uboot.bmp      # 16K   U-Boot 主 Logo
│   ├── battery_0.bmp  # 8K    充电 0 格
│   ├── battery_1.bmp  # 8K    充电 1 格
│   ├── battery_2.bmp  # 8K    充电 2 格
│   ├── battery_3.bmp  # 8K    充电 3 格
│   ├── battery_4.bmp  # 8K    充电 4 格
│   ├── battery_5.bmp  # 8K    充电 5 格
│   └── battery_fail.bmp   # 8K  低电告警
├── kernel_logo/
│   └── kernel.bmp     # 24K   内核阶段 Logo
├── android_logo/
│   └── bootanimation.zip  # 644K   Android 开机动画
├── standby_logo/      # 待机/充电界面
│   ├── standby.png        # 108K
│   ├── standby_lowpower.png  # 56K
│   └── standby_charge.png    # 108K
└── poweroff_logo/
    ├── poweroff.png       # 108K
    └── poweroff_nopower.png  # 108K
```

### 1. U-Boot / 内核 / 充电 Logo（BMP）

打包逻辑在 `device/rockchip/common/mkimage.sh:254-264`。**注意：该分支被
`BUILD_WITH_RK_EBOOK` 门控，而全树只有 pinenote（真正的墨水屏设备）设了这个变量，
本机未设，所以这段逻辑在本机**不会执行**，也不需要 `logo.img`：**

```bash
IS_EBOOK=$(get_build_var BUILD_WITH_RK_EBOOK)   # 本机非 true
ebook_logo_tool=rkbin/tools/bmp2gray16
$ebook_logo_tool \
    --uboot-logo   $EINK_LOGO_PATH/uboot_logo/uboot.bmp \
    --kernel-logo  $EINK_LOGO_PATH/kernel_logo/kernel.bmp \
    --charge-logo  $EINK_LOGO_PATH/uboot_logo/battery_{0..5}.bmp battery_fail.bmp \
    --output       $IMAGE_PATH/logo.img
```

**本机实际的 U-Boot/内核 Logo 路径：**

- U-Boot Logo 与充电动画：由 U-Boot 从 `resource.img` 内的 DTB 节点读取
  （`uboot.bmp`/`kernel.bmp`/`battery_*.bmp` 经 `resource.img` 打包，见
  `device/rockchip/rm35k/resource.img` 与 `mkimage.sh:95-97`）
- 修改方法：替换 `eink_logo/` 下对应 `.bmp` → 重新构建 → 得到新的 `resource.img` →
  `fastboot flash resource resource.img`（小分区，刷新快）

**步骤：**

1. 准备 **640×480 BMP**（32 位 BGRA 或 24 位均可；若走 `bmp2gray16` 才需 8-bit 灰度）
2. 直接覆盖对应 `.bmp` 文件（保持文件名不变）
3. 重新构建 → 生成新 `resource.img` → 刷 resource 分区

**注意：**
- 分辨率必须 **640×480**，否则显示偏移
- LCD 支持 24/32 位色彩，无需刻意灰度化

### 2. Android 开机动画（bootanimation）

位置：`device/rockchip/rm35k/eink_logo/android_logo/bootanimation.zip`
（实际打进系统的是 `vendor/rockchip/rm35k/media/bootanimation.zip`，见 `device.mk:204`）

**标准 Android 动画包格式：**

```
bootanimation.zip
├── part0/             # 第一段
│   ├── 0001.png
│   ├── 0002.png
│   └── ...
├── part1/             # 第二段 (可选)
│   └── ...
└── desc.txt           # 描述文件
```

`desc.txt` 格式：

```
640 480 5          # 宽 高 每秒帧数
p 1 0 part0        # part0 播放1次, 无暂停
p 0 0 part1        # part1 循环播放直到开机完成
```

**LCD 提示：**
- 帧率可达 **30 fps**（普通 LCD 无墨水屏刷新延迟），但帧数越多开机越长
- 若追求 5 秒启动目标，建议总帧数控制在 10-20 帧、单帧 < 100 KB
- 支持彩色，无需灰度化
- 播放 1 次的段（`p 1 0`）适合做静态封面

### 3. 待机 / 关机 / 低电图（PNG）

直接替换 `standby_logo/`、`poweroff_logo/` 下的 PNG，**640×480 PNG**。
这些由系统服务在对应状态读取，改完需重新构建并刷 super。

---

## 构建方法

### 环境要求

- AOSP 11 官方源码树（`android-11.0.0_r48`）
- 本仓库内容**叠加覆盖**到对应路径

### 合并到 AOSP 树

```bash
# 假设 AOSP 树在 /data/aosp
cd /data/aosp

# 覆盖设备层 (注意: 建议先备份树里原有 device/rockchip)
cp -a <本仓库>/device/rockchip/rm35k        device/rockchip/
cp -a <本仓库>/device/rockchip/rm35k-kernel device/rockchip/
cp -a <本仓库>/device/rockchip/common       device/rockchip/

cp -a <本仓库>/vendor/rockchip/rm35k         vendor/rockchip/
cp -a <本仓库>/vendor/rockchip/common        vendor/rockchip/
cp -a <本仓库>/vendor/rockchip/hardware      vendor/rockchip/

cp -a <本仓库>/hardware/rockchip             hardware/
```

### 应用 AOSP 源码补丁

3 个改动的文件在 `build-patches/aosp/` 下**保留了原始相对路径**，直接覆盖即可：

```bash
cd <本仓库>/build-patches/aosp
cp -a . /data/aosp/
```

| 文件 | 改动 |
|---|---|
| `build/make/target/product/base_system.mk` | 移除 `wificond`/`wifi.rc`（`:271-301` 有完整论证） |
| `frameworks/base/data/keyboards/Generic.kl` | 补 d-pad 映射 `key 544-547`（`:447-453`） |
| `frameworks/native/data/etc/handheld_core_hardware.xml` | 移除 WiFi 特性声明 |

> `init.rk356x.rc` 的 suspend 补丁在 `device/rockchip/rm35k/init/` 与
> `vendor/rockchip/rm35k/etc/init/hw/` 内，已随目录整体携带。

### 构建

```bash
cd /data/aosp
source build/envsetup.sh
lunch aosp_rm35k-userdebug
make installclean
make -j$(nproc)
```

产物：`out/target/product/rm35k/`（super.img / boot.img / dtbo.img 等）

### 打包成可刷写镜像

```bash
cd /data/aosp
./device/rockchip/common/mkimage.sh          # 生成 rockdev/Image-*/
```

### NFS 环境构建注意（重要）

若 `out/` 放在 NFS 上，`dex2oat` 会因 `flock(LOCK_EX)` 对只读 fd 返回 `EBADF` 而失败。
`build-patches/flockshim/` 提供垫片（C 源码 + 预编译 `.so`）：

```bash
export LD_PRELOAD=<本仓库>/build-patches/flockshim/flockshim.so
export ALLOW_NINJA_ENV=1      # soong 默认不透传 LD_PRELOAD 给 ninja, 必须开
```

**如果不满足：** `Cannot lock profiles: ... Bad file descriptor` → 就是这个原因。
本地 ext4/xfs 磁盘无需此步。

---

## 已知取舍

| 取舍 | 影响 |
|---|---|
| 只保留 `arm64` 单架构（`core_64_bit_only.mk`） | 纯 32 位 APK 无法安装（`INSTALL_FAILED_NO_MATCHING_ABIS`） |
| 无 WiFi/蓝牙 | 需要联网的场景走 USB（adb / RNDIS） |
| ART 用 release 变体 | 无法用 `dex2oatd` 调试，日常使用无影响 |
| 保留 eptz/vpu/ipp/nand | 尚可再省 ~84 MB，但需同步改 `device-vendor.mk`，风险大于收益 |

---

## 文档索引

`docs/evidence/` 下是各轮改动的完整证据链（含每条结论的实测命令与输出）：

| 文档 | 内容 |
|---|---|
| `ALL_CHANGES_STATUS.md` | **全部代码变动与状态总表（推荐先读）** |
| `R33_PEGASUS_CONFIGFILE_FIX.md` | 天马启动 RA 丢配置的根因与修复 |
| `R31_WIFICOND_REMOVAL.md` | wificond 移除的三条独立证据 |
| `R32_ZEDKEYS_ESC_AND_TFCARD.md` | 手柄按键 / TF 卡 / 退出键 |
| `R30_REPORT.md` | 当轮刷机与验证 |
| `PEGASUS_RETROARCH_REPORT.md` | 天马配置整合方案 |
| `BUILD_RECIPE.md` | 构建配方 |

---

## 许可与致谢

- Android 11 源码遵循 AOSP 许可（Apache-2.0）
- Rockchip vendor 部分来自 [aosp-rockchip](https://github.com/aosp-rockchip) 与设备厂商镜像
- RetroArch / Pegasus 前端为独立项目，本仓库仅提供其启动配置
