# RMX35K 全部代码变动与当前状态汇总

> 生成时间：2026-10-01
> 设备：RMX35K (`rk3566_rm700k`, `aosp_rm35k-userdebug`)，AOSP 11，内核 4.19.219，640x480 LCD (MIPI DSI)，adb 序列号 `7b264ab2a454303`
> 当前已刷入版本：**r32**（`super_r32.img`，md5 `feb0c5f17f1bf3868ed46992d10dcc4b`）
> 本文所有结论均为**本轮实测复核**，非凭记忆。构建树 `/data/aosp` 不是 git 仓库，故逐文件用 md5 比对。

---

## 一、AOSP 构建树改动（需重新构建才生效）

构建树根目录：`/data/aosp`。以下 5 处为实际落盘的文件改动。

### 1. `Generic.kl` — 手柄十字键映射

| 项目 | 内容 |
|---|---|
| 路径 | `frameworks/base/data/keyboards/Generic.kl`<br>`vendor/rockchip/rm35k/Generic.kl` |
| md5（两者相同） | `47001b5a46382d3cff48d38da5330779` |
| 行数 | 453 |
| 设备端已生效 | `/system/usr/keylayout/Generic.kl` md5 **一致** ✔ |

新增内容（`:447-453`，追加在文件末尾）：

```
# --- handheld gamepad additions (zed_joystick) ---
key 544   DPAD_UP
key 545   DPAD_DOWN
key 546   DPAD_LEFT
key 547   DPAD_RIGHT
# MODE: dedicated quit/back key (emulator quit dialog)
```

对应内核键码 `BTN_DPAD_UP=0x220`(544) … `BTN_DPAD_RIGHT=0x223`(547)。
`zed_joystick` 通过 `/proc/bus/input/devices` 确认上报这 4 个键，映射后 Android 侧得到
`AKEYCODE_DPAD_*`(19/20/21/22)。

### 2. `init.rk356x.rc` — 允许深度睡眠

| 项目 | 内容 |
|---|---|
| 路径 | `vendor/rockchip/rm35k/etc/init/hw/init.rk356x.rc`<br>`device/rockchip/rm35k/init/init.rk356x.rc` |
| md5（两者相同） | `e8962d844ea56e37b0836712cc88f24d` |
| 设备端已生效 | `/vendor/etc/init/hw/init.rk356x.rc` md5 **一致** ✔ |

`:27-28` 内容：

```
	# [RMX35K power] noSuspend removed to allow deep sleep; restore by uncommenting next line
	# write /sys/power/wake_lock "PowerManagerService.noSuspend"
```

即注释掉 `noSuspend` 唤醒锁，设备可正常休眠。
运行期验证：`/sys/power/wake_lock` 为空（无锁）。

### 3. `fstab.rk30board` — vold 可采纳存储

| 项目 | 内容 |
|---|---|
| 路径 | `vendor/rockchip/rm35k/etc/fstab.rk30board` |
| md5 | `81ec1ced934d5d3ec40a1330fe982d57` |
| 设备端已生效 | `/vendor/etc/fstab.rk30board` md5 **一致** ✔ |

含 6 个 FUSE/vfat 挂载点（usb / sata / pcie / dwmmc ×2），
`voldmanaged=sdcard1:auto,encryptable=userdata`，`vold.has_adoptable=1`。

### 4. `base_system.mk` — 移除 wificond / wifi.rc

| 项目 | 内容 |
|---|---|
| 路径 | `build/make/target/product/base_system.mk` |
| md5（当前） | `4cb454c3bddef35003aa7497e0d44acf` |
| 备份原件 | `/data/rmx35k_work/src_backup_r31_base_system.mk` |
| 设备端验证 | `/vendor/bin/wificond` **不存在** ✔，无 wificond 进程 ✔ |

实际差异（`diff 备份 当前`）：

```diff
271,272d270
<     wificond \
<     wifi.rc \
```

并在原位置插入大段说明注释（`:272-301`），论证三点：
1. 无 WiFi 硬件 ⇒ `FEATURE_WIFI` 已移除 ⇒ `SystemServer.java:1493` 的 if 为假，WifiService 从不启动（设备实测 `service check wifi` → not found）。
2. `WifiInjector` 仅由 `WifiService.java:48` 构造 ⇒ 无客户端使用 wificond（实测 utime=2/stime=1 空转，0 个外部进程持有其 fd）。
3. `/vendor/etc/vintf/manifest.xml` 中 "wifi" 计数 = 0 ⇒ 无 VINTF 契约，移除不触发校验失败。

**★ 保留 `com.android.wifi` apex**（`:68` 与 `:336`）——它提供
`framework-wifi.jar` 中的 `WifiManager` 等**类**，SystemUI/Settings 静态链接，
删除会导致 `NoClassDefFoundError`。本次只删"无硬件的守护进程及其 init 脚本"。

> 补充：`init_rc: ["wificond.rc"]` 定义在 `system/connectivity/wificond/Android.bp`，
> 随模块一并移除；`wifi.rc` 是独立 `prebuilt_etc`。故设备上不留任何 wifi init 脚本。

### 5. WIFI 硬件特性声明

| 项目 | 内容 |
|---|---|
| 路径 | `frameworks/native/data/etc/handheld_core_hardware.xml` |
| md5 | `e52c7955c1c2f47b50459e12f2ff5d47` |

`:78` 仅存注释（特性声明已移除）：

```xml
    <!-- devices with WiFi must also include android.hardware.wifi.xml -->
```

---

## 二、设备端改动（已生效，非构建产物）

### 6. 天马（Pegasus）metafiles — 补 `CONFIGFILE`

**这是本轮新修复的核心问题**（详见 `R33_PEGASUS_CONFIGFILE_FIX.md`）。

| 项目 | 内容 |
|---|---|
| 设备路径 | `/sdcard/Android/data/org.pegasus_frontend.android/files/pegasus-frontend/metafiles/` |
| 文件数 | 21 个 `*.metadata.pegasus.txt` |
| 属主/权限 | `u0_a94:u0_a94` `0660`（与原件一致）✔ |
| 含 `CONFIGFILE` | **21 / 21** ✔ |
| 含多余 `DATADIR` | 0 ✔ |
| md5 逐个比对宿主机 | 21 个全部一致 ✔ |

改动：`launch` 行**追加**一句（其余部分未动）：

```
-e CONFIGFILE /storage/emulated/0/Android/data/com.retroarch.aarch64/files/retroarch.cfg
```

修复后 cps1 的完整 launch 行：

```
launch : am start -a android.intent.action.VIEW -n com.retroarch.aarch64/com.retroarch.browser.retroactivity.RetroActivityFuture -e ROM {file.path} -e LIBRETRO /data/data/com.retroarch.aarch64/cores/fbalpha2012_cps1_libretro_android.so -e CONFIGFILE /storage/emulated/0/Android/data/com.retroarch.aarch64/files/retroarch.cfg
```

**根因**：天马原始 launch 行只传 `ROM` + `LIBRETRO`。RetroArch Android 端
必须靠 intent extra `CONFIGFILE` 才能定位用户配置；未传时退回内置默认值，
表现为**全屏（非 1:1）+ 无虚拟手柄 + 机身方向键失效**，而 ABCD/投币/开始仍正常
（因为 autoconfig `zed_joystick.cfg` 独立于 `retroarch.cfg`）——极易误判为手柄故障。

设备上**不存在任何兜底配置**（`/data/data/com.retroarch.aarch64/files/retroarch.cfg`、
`/data/data/com.retroarch.aarch64/retroarch.cfg`、`/storage/emulated/0/RetroArch/retroarch.cfg`
均不存在），故不传 `CONFIGFILE` 时 RA 完全读不到用户设置。

**上游佐证**：Pegasus 官方文档 *platform-android* 给出的 RetroArch 标准启动命令
本身就含 `-e CONFIGFILE`（另有 `-e QUITFOCUS` 及三个 activity 标志）。

### 7. `es2pegasus.py` — 生成器同步修正

| 项目 | 内容 |
|---|---|
| 路径 | `/data/rmx35k_work/es2pegasus.py` |
| 状态 | 已修改，语法校验通过 ✔ |

原 `:166-169` 生成的 launch 行**缺少** `CONFIGFILE`，正是问题来源。
已在 `:162-172` 追加该参数并加注释说明，防止将来重新生成 metafiles 时复发。
生成格式与已推送设备的内容**逐字一致**。

### 8. RetroArch 用户配置（未改动，仅确认）

| 项目 | 值 |
|---|---|
| 路径 | `/storage/emulated/0/Android/data/com.retroarch.aarch64/files/retroarch.cfg` |
| md5 | `d172bf8293f18115b781e30a2cfb521f`（用户设定状态，**本轮全程未改动**）✔ |
| 关键项 | `:14 aspect_ratio_index="21"`（1:1）<br>`:341 input_overlay_enable="true"`（虚拟手柄）<br>`:332 input_overlay=".../neo-retropad.cfg"`<br>`:100 config_save_on_exit="true"` |

> `:100` 表示 RA 正常退出时会重写此文件，编辑配置前需注意。

### 9. RetroArch 手柄 autoconfig（保留，勿动）

| 项目 | 内容 |
|---|---|
| 路径 | `/data/data/com.retroarch.aarch64/autoconfig/android/zed_joystick.cfg` |
| 大小 | 612 B |
| 说明 | **用户主动保存**的手柄映射，与本次问题无关，**不要修改** |

方向键绑定 `input_up_btn="19"` / `down_btn="20"` / `left_btn="21"` / `right_btn="22"`，
与 `Generic.kl` 映射结果一致。

---

## 三、构建与镜像

### 构建入口

```bash
cd /data/rmx35k_work && bash build.sh <targets>
```

产物 `out/` 软链至 `/mnt/nfs/srv/share/Ubuntu/rmx35k/out`。

`build.sh` 关键点：
- `TMPDIR=/data/tmp`（避免打爆只有 4.6G 的 `/`）
- **NFS flock 垫片**（必需）：`out/` 位于 NFSv4.2，内核强制 `local_lock=none`，
  flock 退化为 POSIX 记录锁，对 `O_RDONLY` fd 加排他锁返回 `EBADF(9)`，
  导致 ART `dex2oat` 的 `LoadProfile()` 必然失败。垫片 `flockshim.so` 在该
  排他锁因 EBADF 失败时降级为共享锁重试（profile 构建期只读，语义充分）。
  受影响 3 个文件：`out/soong/rm35k/dex_bootjars/boot.prof` 及两个
  `dexpreopt/profile.prof`。
- 需 `ALLOW_NINJA_ENV=1`：soong 默认只透传白名单环境变量
  （`build/soong/ui/build/ninja.go:100`），`LD_PRELOAD` 不在名单内，
  否则 ninja 派生的 `dex2oatd64` 拿不到垫片。

### 镜像产物

| 镜像 | 大小 | md5 | 状态 |
|---|---|---|---|
| `super_r30.img` | 1124073472 | `e9fff4b044ef34294b2fceedb778d5c5` | 历史版本 |
| `super_r31.img` | 1124073472 | `4dc89f759d3d4d0c7e7e299405250bb2` | 历史版本 |
| **`super_r32.img`** | 1124073472 | **`feb0c5f17f1bf3868ed46992d10dcc4b`** | **已刷入** ✔ |

刷写证据：`/data/rmx35k_work/r32_flash_evidence/flash_r32_20260930_223933.log`
（PASS=8 FAIL=0；分区尺寸 `0x43000000` 校验通过；liblp 双 magic 正确）。

> 注：U-Boot fastboot 不支持 `fetch`，故无法在 fastbootd 内回读校验，
> 依靠"本地写入源 + 设备尺寸交叉确认"。

---

## 四、设备当前状态（本轮实测）

| 检查项 | 结果 |
|---|---|
| `sys.boot_completed` | `1` ✔ |
| `/system/usr/keylayout/Generic.kl` md5 | `47001b5a46382d3cff48d38da5330779`（= 构建树）✔ |
| `/vendor/etc/fstab.rk30board` md5 | `81ec1ced934d5d3ec40a1330fe982d57`（= 构建树）✔ |
| `/vendor/etc/init/hw/init.rk356x.rc` md5 | `e8962d844ea56e37b0836712cc88f24d`（= 构建树）✔ |
| `/vendor/bin/wificond` | 不存在 ✔ |
| wificond 进程 | 0 个 ✔ |
| `/sys/power/wake_lock` | 空（无锁，可休眠）✔ |
| TF 卡挂载 | `/storage/06B3-D7DD` 存在，6 个挂载点 ✔ |
| 天马 metafiles | 21 个全部含 `CONFIGFILE` ✔ |
| RA `retroarch.cfg` | md5 `d172bf8293f18115b781e30a2cfb521f` 未变 ✔ |

---

## 五、待办 / 注意事项

1. **天马必须完全重启**才会重新读取 metafiles（它仅在启动时读取）。
   改完 metafiles 后需退出天马再打开，然后进游戏验证：方向键可用、画面 1:1、有虚拟手柄。
2. `es2pegasus.py` 已同步修正，重新生成 metafiles 不会再丢 `CONFIGFILE`。
3. **不要修改** `/data/data/com.retroarch.aarch64/autoconfig/android/zed_joystick.cfg`。
4. 若游戏退出行为异常，可按上游补 `-e QUITFOCUS --activity-clear-top
   --activity-clear-task --activity-no-history`（本次遵循最小改动未加）。
5. `debug_ramdisk/fstab.rk30board` 仍为原厂版本（无 `TARGET_COPY_OUT_DEBUG_RAMDISK`
   拷贝规则）；运行期查找已由 `/vendor/etc/fstab.rk30board` 满足，无影响。
6. 若需回滚 super，可用既有备份镜像（`super_before_r26.img` / `planB_r19b.img`）。

---

## 六、本轮走过的弯路（方法论教训，避免重复）

| 探针 | 为何无效 |
|---|---|
| `config_save_on_exit` 的 mtime 变化 | **无效**。控制组（RA 自身 `MainMenuActivity` 路径）mtime 同样不变——无 ROM 时 ESC 不触发退出保存。该探针不能证明任何结论，据此得出的"配置未加载"结论已**撤回**，后由官方文档独立证实。 |
| 截图像素对比 | **无效**。Vulkan 画面 `screencap` 抓到全黑图（两张均 2335 字节，差异 0）。 |
| 文件日志探针 | **无效**。开 `log_to_file` 并重定向 `log_dir` 后，带/不带 `CONFIGFILE` 两组均无日志产出。 |
| 手柄端口顺序 / `MAX_NUM_KEYBOARDS` 溢出 / `reserved_device` | **非主因**。`input_player1_device_reservation_type="0"`（No Reservation）使 `reserved_device` 失效；且 ABCD 正常已反证设备注册无误。 |
| 逆向 RA `.so` 逻辑 | 方向错误。查阅 Pegasus 官方文档即可一锤定音，无需逆向。 |

**教训**：优先查上游官方文档，其次找能真正区分两种状态的观测量；
不要用"看起来相关"的指标充当证据（须先做双向负对照验证该指标确实可区分）。
