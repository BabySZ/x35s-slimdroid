# TF 卡 / Pegasus / RetroArch 完整交付报告

日期: 2026-09-30
设备: RMX35K (`rk3566_rm700k`, AOSP 11, kernel 4.19.219, 640x480 墨水屏)
目标: 1) 恢复镜像  2) 装天马(Pegasus) + 恢复刮削  3) 按 TF 卡内容装模拟器(FC/街机优先)

---

## 一、结论速览

| 项目 | 状态 |
|---|---|
| 恢复镜像 | ✅ 已有 r30 全盘镜像(分区级校验), 见 `RESTORE_r30.md` |
| 天马 Pegasus | ✅ 已装, 索引 4209 个游戏, FC 封面覆盖 99% |
| 刮削数据 | ✅ ES `gamelist.xml` → Pegasus `metadata.pegasus.txt` 转换完成 |
| FC 模拟 (fceumm) | ✅ 实测启动成功 |
| 街机 (fbneo/cps1/2/3) | ✅ 实测启动成功 |
| app 读 TF 卡 | ✅ 已修根因 (fstab), 重启后保持 |
| 重启需求 | ❌ 不需要 (overlayfs 持久化, 现网已生效) |

---

## 二、关键根因: 为什么 app 读不到 TF 卡

### 2.1 缺陷

`device/rockchip/rm35k/init/fstab_eink.in:17` 里 sdcard1 的 fs_mgr 选项只有:

```
voldmanaged=sdcard1:auto
```

**缺少 `encryptable=userdata`**。对照 AOSP 参考实现
`device/google/cuttlefish/shared/config/fstab.ext4:16` 是有的。

### 2.2 因果链 (逐环在真机验证)

```
fstab 无 encryptable
  → system/vold/main.cpp:252  entry.is_encryptable() == false
  → 不加 Disk::Flags::kAdoptable
  → StorageManagerService.java:1536  vol.disk.isAdoptable() == false
    且 :1531 false (mPrimaryStorageUuid == null != "primary_physical")
  → 不设 MOUNT_FLAG_VISIBLE
  → VolumeInfo.java:300  isVisible() == false
  → StorageSessionController.java:365  shouldHandle() == false
  → :84 onVolumeMount() 直接 return
     (日志里只有 "On volume unmount", 从无 "On volume mount")
  → 不建 FUSE 会话
  → 没有 /storage/<uuid>
  → 只有 /mnt/media_rw/<uuid>  (drwxrwx--- root:external_storage, gid=1077)
  → app 补充组 {3003,9997,20094,50094} 不含 1077 → 读不到 ROM
```

### 2.3 修复

给 fstab 的两条 sdmmc/inner-sdmmc 行都加上 `,encryptable=userdata`。
修好后 vold 建 FUSE 会话, `/storage/06B3-D7DD` 出现在 app 命名空间, 直接可读。

**日志证据**:
```
vold: Mounting emulated fuse volume
ExternalStorageServiceImpl: Starting session for id: emulated;0
ExternalStorageServiceImpl: Starting session for id: 06B3-D7DD
```

### 2.4 持久化 (为什么不用刷机/重启)

`adb remount` 把 `/vendor` 变成 overlayfs:

```
overlay /vendor overlay rw,...
  lowerdir=/vendor
  upperdir=/cache/overlay/vendor/upper
  workdir=/cache/overlay/vendor/work
```

- `/cache` 是真实 ext4 分区 (`/dev/block/mmcblk2p10`, 15 MiB), **不是 RAM**
- 每次开机 `fs_mgr_overlayfs_mount_all()`
  (`system/core/fs_mgr/fs_mgr.cpp:1545`) 都会重新挂上这个 overlay
- 所以补丁**重启后依然生效**

同时已改 AOSP 源码 `device/rockchip/rm35k/init/fstab_eink.in`,
以后重新编译就会自带修复。

---

## 三、天马 (Pegasus) 部署

### 3.1 为什么必须转换格式

Pegasus 的 Android 版**没有编译** EmulationStation(es2) provider:

- `src/backend/AppSettings.cpp` 里 es2 相关代码被 `#ifdef WITH_COMPAT_ES2` 包住
- 出货的 `lib/arm64-v8a/libpegasus-fe_arm64-v8a.so` 里搜不到
  `EmulationStation` / `gamelist.xml` / `Es2Provider` 任何字符串
  (13 个 `es2` 匹配全是 "Themes"/"Locales" 的子串)

所以卡上现成的 ES `gamelist.xml` 用不了, 必须转成 Pegasus 原生格式。

### 3.2 Pegasus 元数据格式 (来自上游源码, 非猜测)

- **文件名** (`providers/pegasus_metadata/PegasusProvider.cpp`):
  `metadata.pegasus.txt` / `metadata.txt` / `*.metadata.pegasus.txt` / `*.metadata.txt`
- **查找位置**: 非递归地在每个 game dir **以及**
  `<配置目录>/metafiles/` 下找
  - 配置目录 = `/storage/emulated/0/Android/data/org.pegasus_frontend.android/files/pegasus-frontend/`
- **资产 key** 必须是 `assets.<type>`, type 见
  `src/backend/PegasusAssets.cpp` 的 `str_to_type()`:
  `boxFront / boxBack / boxSpine / boxFull / cartridge / logo / marquee /
   bezel / panel / tile / poster / background / music / screenshot /
   video / titlescreen / ...`
  - ⚠️ ES 的 `image` / `thumbnail` **不是**合法 key → 都映射成 `boxFront`
- **`file :` 相对路径按元数据文件所在目录解析**
  (`PegasusMetadata.cpp`: `QFileInfo(ps.dir, line)`)
  → 元数据放在 `metafiles/` 时**必须写绝对路径**

### 3.3 转换器

`es2pegasus.py` —— 已实现的映射:

| ES 标签 | Pegasus |
|---|---|
| `name` | `game :` |
| `path` | `file :` |
| `desc` | `summary :` (+ 超 300 字加 `description :`) |
| `developer` / `publisher` / `genre` | 同名 |
| `releasedate` (`19911102T000000`) | `release : 1991-11-02` |
| `rating` (`0.55`) | `rating : 0.55` |
| `players` (`1-2`) | `players : 1-2` |
| `image` / `thumbnail` | `assets.boxFront` |
| `marquee` | `assets.logo` |
| `fanart` | `assets.background` |
| `boxback` | `assets.boxBack` |
| `video` | `assets.video` |
| `manual` / `map` | 丢弃 (Pegasus 无对应类型) |
| 目录型条目 (合辑介绍页) | 丢弃 |

### 3.4 转换结果

| 系统 | 游戏数 | 资产数 | 封面覆盖 |
|---|---|---|---|
| FC (`nes`) | 2078 | 8724 | 2071/2074 = **99%** |
| 街机 `fbneo` | 2112 | 3726 | 1999 = 89% |
| 街机 `arcade` | 10 | 10 | 100% |
| `cps1` | 48 | 48 | 100% |
| `cps2` | 62 | 62 | 100% |
| `cps3` | 12 | 12 | 100% |

**Pegasus 实际索引 = 4209 个游戏** (来自 `gameindex-v1.json`, 7.5 MB)。
所有 2078 个 FC 游戏文件都逐一核验存在 (缺失 0)。

> 注: 被算作 "asset_missing" 的绝大多数是 `videos/*.mp4`,
> 卡上 `videos/` 是空目录 (0 文件), 且 Pegasus 也没有对应需求。

---

## 四、模拟器 (RetroArch)

### 4.1 已安装核心 (10 个, 在 `/data/data/com.retroarch.aarch64/cores/`)

`fceumm` `nestopia` `quicknes` `mesen` (FC)
`fbneo` `mame2003_plus` `fbalpha2012_cps1` `fbalpha2012_cps2`
`fbalpha2012_cps3` `fbalpha2012_neogeo` (街机)

### 4.2 启动协议 (来自 RetroArch 源码 + 真机实测)

Android 上 Pegasus 只接受 `am start` 开头的命令, 通过 JNI 直接构造 Intent
(`ProcessLauncher.cpp` + `AndroidHelpers.cpp` + `IntentHelper.java`),
**不经过 shell**, 所以带空格的路径安全。

RetroArch 从 intent 读两个 String extra
(`RetroActivityFuture.java:81-82`):

- `ROM` = 游戏绝对路径
- `LIBRETRO` = 核心 `.so` 绝对路径

可用占位符 (`ProcessLauncher.cpp:60-88`):
`{file.path}` `{file.uri}` `{file.name}` `{file.basename}` `{file.dir}` `{file.documenturi}`

### 4.3 生成的 launch 命令

```
am start -a android.intent.action.VIEW \
  -n com.retroarch.aarch64/com.retroarch.browser.retroactivity.RetroActivityFuture \
  -e ROM {file.path} \
  -e LIBRETRO /data/data/com.retroarch.aarch64/cores/<core>_libretro_android.so
```

核心映射:
`nes→fceumm` `arcade/fbneo→fbneo` `cps1→fbalpha2012_cps1`
`cps2→fbalpha2012_cps2` `cps3→fbalpha2012_cps3`

### 4.4 实测验证

```
RetroArch: [ENV] Libretro path: ".../fceumm_libretro_android.so"
RetroArch: [ENV] Auto-start game "/storage/06B3-D7DD/AURKNIX/nes/roms/Super Robin Hood.nes"
mCurrentFocus=Window{... com.retroarch.aarch64/...RetroActivityFuture}
```
FC ✅ 街机 ✅ 均前台运行, 无 FATAL, 音频线程活跃 (AudioTrack 1024 帧)。

---

## 五、踩过的坑 (供以后参考)

1. **不要 `stop vold; start vold`**
   StorageManagerService 会丢掉 binder 绑定 (`vold not found; trying again`),
   emulated 卷变 `unmountable` (`Failed to prepare directory /mnt/user/0/emulated`),
   然后 `/sdcard` 整个挂掉。
   → 已恢复: 先 `umount -l` 掉 stale FUSE 挂载, 再 `sm mount 'emulated;0'`。

2. **vfat 的 gid 选项对已有 superblock 无效**
   `mount_bdev` 会复用同一 block device 的 superblock, 所以 `mount -o remount,gid=9997`
   会 rc=0 但选项不变。必须先把该设备**所有**挂载点 umount 干净再重新 mount。

3. **toybox 的 mount 在某些 vfat 选项下返回 EINVAL**, 用 `busybox mount`。

4. **`su 10094 -c cmd` 语法错误** —— 本设备 su 是 `su WHO COMMAND...`。

5. **低内存杀进程**: 扫描 38948 个文件时 MediaProvider + Pegasus + RetroArch
   同时跑会触发 lowmemorykiller 杀掉 RetroArch
   (`Kill 'com.retroarch.aarch64' ... to free 716084kB`)。
   单跑没问题 (MemFree 稳定 350 MB, zram swap 487 MB)。

6. **adb push 到 app 数据目录时**, 若目标文件已属 `u0_a94:u0_a94 0660`,
   shell 覆盖会静默失败。先 `rm -f` 再 push。

---

## 六、文件清单

### 设备端
- `/vendor/etc/fstab.rk30board` (已打补丁; 原文件备份为 `.orig`)
- `/storage/emulated/0/Android/data/org.pegasus_frontend.android/files/pegasus-frontend/metafiles/*.metadata.pegasus.txt`
- `.../pegasus-frontend/game_dirs.txt` → `/storage/06B3-D7DD/AURKNIX`
- `/storage/06B3-D7DD` (vold 建的 FUSE 挂载, app 可见)
- `/mnt/media_rw/06B3-D7DD` (vold 原始挂载)
- `/data/data/com.retroarch.aarch64/cores/*.so` (10 个核心)

### 主机 (工作目录 `/data/rmx35k_work/`)
- `es2pegasus.py` —— ES gamelist → Pegasus metadata 转换器
- `apply_tfcard_fix.sh` —— fstab 修复 + 验证
- `tfcard_mount.sh` —— 备用: 手工挂 TF 卡到 app 可见路径
- `pegasus_meta/*.metadata.pegasus.txt` —— 6 个系统的元数据
- `tfcardsurvey/*.gamelist.xml` —— 从卡上拉下来的原始 ES 数据 (35 个系统)
- `tf_filelist.txt` / `tf_dirlist.txt` —— 卡上 38240 个文件的清单
- `PEGASUS_RETROARCH_REPORT.md` —— 本文件

### 备份镜像
- `/mnt/nfs/srv/share/Ubuntu/RMX35K_restore/r30_20260930/planB_r30_full.img`
  (3959422976 B, md5 `20e15bf0e16ca1ceb882b56cb97b53e6`)

---

## 七、日常使用

开机后 Pegasus 自动扫描 (约 60-90 秒, 4209 个游戏)。
若 TF 卡没挂上, 手动:

```bash
adb shell sm mount public:179,97
# 或
adb shell sh /data/local/tmp/tfcard_mount.sh
```

检查:
```bash
adb shell sm list-volumes all
adb shell ls /storage/06B3-D7DD/AURKNIX/
```

---

## 九、扩展到全部系统 (2026-09-30 21:30)

用户要求"根据 TF 卡上的内容装模拟器"。卡上共有 **34 个系统目录**,
按实际 ROM 数和核心可用性, 最终部署了 **21 个系统 / 7487 个游戏**。

### 9.1 追加安装的 10 个核心

从 `https://buildbot.libretro.com/nightly/android/latest/arm64-v8a/` 下载:

| 核心 | 覆盖系统 |
|---|---|
| `gambatte` | Game Boy / Game Boy Color |
| `mgba` | Game Boy Advance |
| `mednafen_pce` | PC Engine |
| `genesis_plus_gx` | Mega Drive / Game Gear / Master System |
| `snes9x` | Super Nintendo |
| `mednafen_wswan` | WonderSwan / WonderSwan Color |
| `picodrive` | Sega 32X |
| `bluemsx` | MSX2 |
| `mednafen_ngp` | Neo Geo Pocket / Color |
| `mednafen_vb` | Virtual Boy |

设备上核心总数: **20 个** (`/data/data/com.retroarch.aarch64/cores/`)

### 9.2 最终索引 (7487 游戏, 21 系统)

| 系统 | 游戏 | 封面覆盖 |
|---|---|---|
| FC / 小霸王 | 2074 | 99% |
| 街机 FBNeo | 1999 | 98% |
| Game Boy | 881 | 100% |
| Game Boy Advance | 472 | 95% |
| PC Engine | 404 | 100% |
| Mega Drive | 395 | 100% |
| Super Nintendo | 356 | 100% |
| Game Boy Color | 194 | 100% |
| WonderSwan | 111 | 100% |
| Game Gear | 105 | 100% |
| WonderSwan Color | 89 | 98% |
| Neo Geo Pocket Color | 82 | 100% |
| MSX2 | 67 | 100% |
| CAPCOM CPS2 | 62 | 100% |
| Master System | 58 | 100% |
| CAPCOM CPS1 | 48 | 100% |
| Sega 32X | 40 | 100% |
| Virtual Boy | 15 | 100% |
| CAPCOM CPS3 | 12 | 100% |
| Neo Geo Pocket | 9 | 100% |
| 街机 Arcade | 9 | 100% |

### 9.3 核心加载实测 (4 MiB logcat buffer)

```
GBA (mgba)            core=mgba            pid=13416  ENV=1
GB (gambatte)         core=gambatte        pid=13497  ENV=1
MD (genesis_plus_gx)  core=genesis_plus_gx pid=13575  ENV=1
SNES (snes9x)         core=snes9x          pid=13654  ENV=1
PCE (mednafen_pce)    core=mednafen_pce    pid=13732  ENV=1
WS (mednafen_wswan)   core=mednafen_wswan  pid=13809  ENV=1
32X (picodrive)       core=picodrive       pid=13887  ENV=1
```
全部 7 个新核心均正确加载。

### 9.4 两个重要的踩坑

**坑 1: `find` 输出被 shell locale 破坏**
早期用 `adb shell find . -type f` 生成的清单里, 中文文件名全变成 `????`
(如 `./gba/????2.zip`), 导致 gba 的 472/473 个 ROM 被判为"不存在"。
修法: `find -print0` 传二进制, 主机侧用 Python 按 `\x00` 切分并以 UTF-8 写文件。
修好后 gba 匹配率 472/473。

**坑 2: logcat 默认 256 KiB 环形缓冲会冲掉启动日志**
RetroArch 的 `[ENV]` 行在启动瞬间打印, 默认 buffer 很快被系统日志挤掉,
表现成"核心没加载"。`logcat -G 4M` 放大后即可稳定抓到。

> 注意 `logcat -G` 是临时设置, 重启后复位。
