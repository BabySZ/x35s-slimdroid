# RMX35K r30 交付报告 (2026-09-30)

## 一、本轮结论 (一句话)
**r30 已刷入并通过全部验证: 13/13 Settings 页面零崩溃, 启动比 r20 基线快 714 ms (−5.78%),
比 r26 快 152 ms, 三轮测量区间互不重叠; WiFi 特性=0 与 GPU 驱动两条红线均保持。**

---

## 二、启动速度 (目标 1、2 的最终数字)

测量口径: `boot_progress_enable_screen` (events buffer), 每次均记录屏幕状态。

| 版本 | 三轮 (ms) | 均值 | 屏幕状态 |
|---|---|---|---|
| r20 基线 | 12335 / 12352 / 12384 | 12357.0 | Awake \| ON (三次全部记录) |
| r26 (WiFi 移除首版) | 11748 / 11755 / 11881 | 11794.7 | Awake \| ON |
| **r30 (本轮)** | **11592 / 11644 / 11693** | **11643.0** | Awake \| ON |

- r30 vs r20: **−714 ms (−5.78%)**, 区间不重叠 (max r30 = 11693 < min r20 = 12335)
- r30 vs r26: **−152 ms (−1.29%)**, 区间不重叠 (max r30 = 11693 < min r26 = 11748)
- 极差 101 ms, 测量稳定
- 证据: `bootcap_r30b_20260930_030725/` (boot1..3 各有 line.txt / screen.txt / events.txt / logcat_all.txt / dmesg.txt)

> **作废声明**: `bootcap_r30_20260930_025020/` 三次测量**无效** (设备当时处于充电模式,
> start=/enable_screen= 全空, 那些 0 是"读不到设备"的默认值)。已写入 `INVALID.md`。

### StartWifi 系列 (单项收益, 目标 1)
| 项 | 基线 | r30 |
|---|---|---|
| `StartWifi` | 354 ms | **0 (服务不再启动)** |
| `StartWifiScanning` | — | 0 |
| `StartWifiAware` | 死代码 | 0 |
| `StartWifiP2P` | 死代码 | 0 |

---

## 三、崩溃修复 (目标 2 的核心: "不得重演 r16 NPE")

### 本轮 (r30) 新增修复 — 第 5 个实机崩溃点
`BaseWifiTracker` 家族 (WifiTrackerLib), 由 `WIFI_SETTINGS2` / `PICK_WIFI_NETWORK` /
`WIFI_ADD_NETWORKS` 触发:
- `BaseWifiTracker.java` ctor `:262` (`isVerboseLoggingEnabled`) — 前面轮次已修
- `onStart()` 入口判空早退 (**本轮**), `onStop()` 对称早退 (**本轮**)
- `getWifiState()` 判空 (**本轮**)
- receiver / Scanner 局部不变量守卫 (**本轮**)
- `NetworkDetailsTracker.createNetworkDetailsTracker()` 工厂判空返回 null (**本轮**)
- Settings 侧 `ConfigureWifiEntryFragment` / `WifiNetworkDetailsFragment2` 兜底 (**本轮**)

### 全页面扫描结果 (实机枚举, 非静态审计)
```
== 汇总: PASS=19 FAIL=0 ==
  === 全部页面无崩溃 ===
```
13 个页面全部 FATAL=0 且 pid 不变; 6 项负对照全部通过。

### 为什么静态审计不够 (方法论教训)
静态审计了 `packages/apps/Settings` 38 个文件后, **实机扫描又抓出 3 个真实崩溃**,
分别在 **SettingsLib** / **WifiTrackerLib** / **Settings** 三个不同代码树。
**结论: 判据必须是实机枚举, 且扫描脚本本身必须带双向负对照** —— 否则脚本自身的
假阳性/假阴性会同时骗过人和审计。

### 扫描脚本自身修掉的 4 类缺陷 (每类都有负对照)
1. `am force-stop` 与 `am start` 竞争 → 假 FAIL。改为扫描前杀一次并轮询等进程消失。
2. `^android\.` 判 action 是错的 (`com.android.settings.WIFI_TETHER_SETTINGS` 也是 action)
   → 静默不启动 → 假 FAIL。改为"含 `/` 才是 component"。
3. 期望串写 Fragment 名 → 8 个假 FAIL。改为写 manifest 里真实的 `Settings$XxxActivity`。
4. 自结束页 (设计上立刻 `finish()`) 被误判 → 引入 `selffinish` 模式,
   并用 `cmd package resolve-activity`(PackageManager, 确定性) 作权威依据。
   - 反面对照: 假 action / 假 component 均解析不到 Activity;
     真实 action 解析到预期类。
   - **曾试过但否决的依据**: logcat 的 `ActivityTaskManager: START` 行 ——
     实测它对假 action/假 component **同样打印**, 无区分力。
   - `am start -W` 的 `Status: ok` 也不稳 (自结束页常报 `timeout`)。

---

## 四、目标 3: §8 低风险项
- `config.disable_cameraservice=true` (aosp_rm35k.mk:45) + handheld_system.mk 移除 cameraserver
  - 实机: `pidof cameraserver` = **0** ✔
- `PRODUCT_MINIMIZE_JAVA_DEBUG_INFO := true` (aosp_rm35k.mk:53) ✔

---

## 五、六项优化复核 (实机, r30)
| 项 | 期望 | 实测 | 结论 |
|---|---|---|---|
| G1 mmc1 (`mmc_send_io_op_cond err`) | 0 | 0 | ✔ |
| G1 `allocated mmc-pwrseq` | 0 | 0 | ✔ |
| G2 `ftl_init` | 0 | 0 | ✔ |
| G3 `init.insmod.cfg` 活跃 insmod 行 | 0 | **0** (17 行全为注释, 904 B) | ✔ |
| G5 `preloaded-classes` | 10187 行 | 10187 | ✔ |
| A2 主线程 `SystemServerTiming:` | 0 | **0** | ✔ |

> A2 的严谨说明: 日志里有 431 行 `SystemServerTimingAsync:`, 它是**另一个 tag**且
> 运行在**工作线程** (tid 376/405/411/398/374), 不是主线程。用
> `grep -E " [A-Z] SystemServerTiming:"` (带冒号) 精确匹配主线程 tag → **0 行**。
> 原先的粗略 grep 会把 Async 也算进去, 属统计口径错误, 已修正。

## 六、两条红线 (用户永久约束)
| 红线 | 实测 | 结论 |
|---|---|---|
| WiFi 特性 | `pm list features \| grep -c android.hardware.wifi` = **0** | ✔ 已移除 |
| Vulkan/GPU | `sys.gmali.version` = **g2p0-01eac0-x-8@0** | ✔ 未触碰 |
| 附带 | `ls /cache/overlay` = 0 (无 overlay 层层遮蔽) | ✔ |

## 七、稳定性
- 连续 10 次屏幕开关 + 4 页面切换后: Settings/system_server/SystemUI **pid 全部不变**,
  FATAL(主)=0, `am_crash`(events)=0。
- 刷机后 `postflash_r30.sh`: **PASS=12 FAIL=0**
  - super 全量回读 md5 = `e9fff4b044ef34294b2fceedb778d5c5` (**逐字节等于写入源**)
  - 设备 `Settings.apk` md5 与本地构建产物一致 (`e0080a69c93325f10f91582aec3101eb`)
  - 设备 `Telecom.apk` md5 一致 (`d4a05d34c1eddf68205f9e9bb0ecda3e`)
  - 从**设备侧 dex** 反查: 22 项正守卫 + 6 项负对照全部通过

---

## 八、"是不是走弯路 / 有没有作业可抄" (用户提问, 见 PRIOR_ART_ANSWER.md)
**不是走弯路, 但确实是 Google 从未测试过的配置, 所以没有现成作业可抄。**
- `build/make/target/product/mainline_system.mk:82` 强制包含 `android.hardware.wifi@1.0`
  —— 所有 AOSP 产品的公共祖先都要求 WiFi; Google 官方 ATV / 车机同样要求。
- AOSP 11 **没有** `config.disable_wifi` 这类开关 (对比: `config.disable_cameraservice`
  **有**, `SystemServer.java:1044`) —— 这正解释了为什么摄像头那项一次就过。
- `Context.java:3592-3594` 官方承认 `WIFI_SERVICE` **可能返回 null**;
  但 Settings 全树 `getSystemService(WifiManager.class)` 出现 **41 次, 判空 0 次** ——
  在"WiFi 必然存在"前提下这是合理的省略。我们人为打破前提, 于是每处都成潜在 NPE。
- 市面上无 WiFi 的安卓设备通常**保留 FEATURE_WIFI**、只是不焊天线/不加载驱动 (零补丁)。
  要拿到 `StartWifi=0` 就必须打破契约, 代价就是逐点补 null 且只能实机枚举。

---

## 九、刷机与镜像
- `super_r30.img` md5 = `e9fff4b044ef34294b2fceedb778d5c5`, 大小 1124073472 (几何与 r20 逐字段一致)
- 刷写日志: `r30_flash_evidence/flash_r30_20260930_014548.log` (PASS=8 FAIL=0)
- 回滚镜像: `super_before_r26.img`, `planB_r19b.img` (均在 NFS)

### r29 → r30 逐文件差异归因 (`R30_DIFF_ANALYSIS.md`)
共 15 个文件不同, **全部已归因, 无需担心**:
- `librga.so` / `libOMX_*` / `libRkOMX_Resourcemanager.so` (system+vendor): 内嵌构建时间戳,
  图形/OMX 红线族, **不要"修"**
- `Telecom.apk/.odex/.vdex`: Telecom **静态链接 WifiTrackerLib**
  (`SettingsLib/Android.bp:13` → `SettingsLibDefaults` → `Telecomm/Android.bp:36`),
  故继承了本轮新守卫。指令级已证: r29 `onStart` 无判空, r30 有
  `iget-object; if-nez; return-void`。
- `product` / `system_ext` / `odm`: **逐文件 md5 完全一致**

---

## 十、本机环境清理 (用户要求"挂载太乱套")
- 挂载表从 **~95 条** 降到 **8 条** (仅剩 NFS×4 + TF 卡镜像×3 + 根/数据盘)
- 卸载 35 个 `/data/*.img` 分析挂载 (其中 20 个底层文件早已删除, 是纯垃圾)
- 卸载并释放孤儿 loop (loop33/34 源已删; loop39/40 指向回滚镜像)
- **安全提醒**: `/media/user/*` 曾把回滚镜像 `planB_r21.img` **以 rw 挂载**,
  我的 `udisksctl unmount` 测试触发了 ext4 回写 (mtime 变为 01:42)。已全部卸载。
  建议后续不要把回滚镜像做可写挂载。
- 删除 88 个残留挂载点空目录
- 磁盘: `/` 1.5G→13G 可用; `/data` 29G→40G 可用
  - 删除了 `/tmp` 里 2 个 3.78GB 全盘镜像 (经全盘扫描确认**只有两处非零**:
    offset 0 的 444 B 与尾部 435 B), 已把这两个 GPT 区域提取到
    `RMX35K_restore/gpt_snapshots/` 保存, md5 与原值一致。
