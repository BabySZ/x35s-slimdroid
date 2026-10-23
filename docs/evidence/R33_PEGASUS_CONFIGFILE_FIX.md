# R33 — 天马(Pegasus)启动 RetroArch 未加载用户配置：根因与修复

## 现象

| 启动方式 | 屏幕比例 | 虚拟手柄 | 方向键 | 投币/开始/ABCD |
|---|---|---|---|---|
| RA 主界面直接打开 | 1:1 | 有 | 正常 | 正常 |
| 从天马进入游戏 | 全屏 | 无 | **失效** | 正常 |

关键判据：ABCD/投币/开始 **正常**，说明 `zed_joystick` 设备注册、autoconfig
(`zed_joystick.cfg`) 全部工作。只有"方向键 + 画面比例 + 虚拟手柄"三项不同，
而这三项恰好**全部由 `retroarch.cfg` 控制**。因此问题不在手柄映射，而在
**配置文件没被加载**。

## 根因

`retroarch.cfg` 中的关键项：

- `:14  aspect_ratio_index="21"`     → 1:1 比例
- `:341 input_overlay_enable="true"` → 虚拟手柄
- `:332 input_overlay=".../neo-retropad.cfg"`

天马原始 launch 行（设备端）：

```
launch : am start -a android.intent.action.VIEW \
  -n com.retroarch.aarch64/com.retroarch.browser.retroactivity.RetroActivityFuture \
  -e ROM {file.path} \
  -e LIBRETRO /data/data/com.retroarch.aarch64/cores/fbalpha2012_cps1_libretro_android.so
```

**只传了 `ROM` 和 `LIBRETRO`，没有 `CONFIGFILE`。**
RetroArch 的 Android 端必须通过 intent extra `CONFIGFILE` 才能知道用户配置在哪；
未传时退回内置默认值，于是出现全屏 + 无虚拟手柄 + 方向键失效。

对照：RA 自身 `MainMenuActivity.startRetroActivity(...)` 会传 8 个 extra，
其中就包含 `CONFIGFILE`（dexdump 已确认）。两条路径的差异正在于此。

设备上不存在任何兜底配置：

```
/data/data/com.retroarch.aarch64/files/retroarch.cfg   → No such file
/data/data/com.retroarch.aarch64/retroarch.cfg         → No such file
/storage/emulated/0/RetroArch/retroarch.cfg            → No such file
```

即：不传 `CONFIGFILE` 时，RA **没有任何途径**读到用户配置。

## 上游佐证

Pegasus 官方 Android 文档（platform-android）给出的 RetroArch 标准 launch 行
本身就带 `CONFIGFILE`：

```
am start --user 0 -n com.retroarch.aarch64/com.retroarch.browser.retroactivity.RetroActivityFuture \
  -e ROM {file.path} \
  -e LIBRETRO /data/data/com.retroarch.aarch64/cores/fceumm_libretro_android.so \
  -e CONFIGFILE /storage/emulated/0/Android/data/com.retroarch.aarch64/files/retroarch.cfg \
  -e QUITFOCUS --activity-clear-top --activity-clear-task --activity-no-history
```

官方在线生成器 `app.js` 中的模板同样只包含 `ROM / LIBRETRO / CONFIGFILE / QUITFOCUS`。
本机当初生成 metafiles 时漏掉了 `CONFIGFILE`（以及 `QUITFOCUS` 和三个 task 标志）。

## 修复

对 21 个 `*.metadata.pegasus.txt` 的 `launch` 行**仅追加** `-e CONFIGFILE`：

```
-e CONFIGFILE /storage/emulated/0/Android/data/com.retroarch.aarch64/files/retroarch.cfg
```

改动最小化，不动原有 `ROM` / `LIBRETRO` 部分。

- 设备路径：`/sdcard/Android/data/org.pegasus_frontend.android/files/pegasus-frontend/metafiles/`
- 备份：`/data/local/tmp/mf_backup/`（设备端）、
  `/data/rmx35k_work/pegasus_metafiles_backup/orig_pristine_20261001_012223/`（宿主机）

### 校验

| 项目 | 结果 |
|---|---|
| 设备端含 `CONFIGFILE` 文件数 | 21 / 21 ✔ |
| 设备端含 `DATADIR` 文件数 | 0（未加多余参数）✔ |
| 逐文件 md5（宿主机 vs 设备） | 21 个全部一致 ✔ |
| 属主/权限 | `u0_a94:u0_a94` `0660`，与原件一致 ✔ |
| 用户配置 md5 | `d172bf8293f18115b781e30a2cfb521f` 未改动 ✔ |

## 注意事项

1. **必须重启天马**：天马在启动时读取 metafiles，需完全退出后重新打开才生效。
2. 若退出游戏行为异常，可再补上游的 `-e QUITFOCUS --activity-clear-top
   --activity-clear-task --activity-no-history`；本次遵循最小改动未加。
3. 不要修改 `/data/data/com.retroarch.aarch64/autoconfig/android/zed_joystick.cfg`
   （用户主动保存的手柄配置，与本次问题无关）。

## 走过的弯路（避免重复）

- `config_save_on_exit` 的 mtime 探针**无效**：控制组（RA 自身路径）mtime 同样不变，
  因为无 ROM 时 ESC 不会触发退出保存。该探针不能证明任何结论。
- 截图像素对比**无效**：Vulkan 画面 `screencap` 抓到的是全黑图（两张均 2335 字节，
  差异 0），不构成证据。
- 文件日志探针**无效**：开 `log_to_file` 并重定向 `log_dir` 后，带/不带 `CONFIGFILE`
  两组均无日志产出，无法区分。
- 手柄端口顺序 / `MAX_NUM_KEYBOARDS` 溢出 / `reserved_device` 均**不是**主因：
  `input_player1_device_reservation_type="0"`（No Reservation）使
  `input_player1_reserved_device` 失效，且 ABCD 正常已反证设备注册无误。
