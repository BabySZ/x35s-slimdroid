# R31 —— 移除 wificond/wifi.rc (目标 2 收尾) 验证报告

日期: 2026-09-30
设备: RMX35K (rk3566_rm700k), AOSP 11, 序列号 7b264ab2a454303
本轮性质: **目标(2)"激进移除无硬件功能"的收尾补漏** —— 前 30 轮已移除 WiFi/蓝牙/电话
的功能声明与服务, 但漏掉一个**仍在运行的守护进程 `wificond`**。

---

## 0. 结论先行

| 项 | 结果 |
|---|---|
| `wificond` 进程 | **已消失** (原 VmRSS 5268 kB, 2 线程) |
| `/system/bin/wificond` | **已消失** |
| `/system/etc/init/wifi.rc` | **已消失** |
| `/system/etc/init/wificond.rc` | **已消失** |
| binder 服务 `wifinl80211` | **已消失** |
| 启动时间 (同 TF 卡条件 A/B) | **−129.7 ms**, 区间不重叠 |
| 稳定性 | FATAL=0, am_crash=0, pid 全稳定 |
| 两条红线 | WiFi 特性=0 ✔, GPU `g2p0-01eac0-x-8@0` ✔ |

**方法学要点**: 本轮做了一次**同条件 A/B**(TF 卡都在位), 因为发现 r30 的历史
基线全是**无 TF 卡**测的, 直接比会得出错误结论(见 §5)。

---

## 1. 为什么这是个真漏项 (不是重复劳动)

前 30 轮的目标(2)确实做了大量工作 —— `FEATURE_WIFI`/`FEATURE_BLUETOOTH`/
`FEATURE_TELEPHONY` 声明已删, `StartWifi` 已从 354 ms 变 0, SystemUI 的
`@Nullable` 契约已修。**但 `wificond` 是个独立的守护进程**, 它由
`wificond.rc` 里 `class main` 启动, **不受 FEATURE_WIFI 影响**:

```
$ adb shell 'getprop init.svc.wificond'
running                        <- 前 30 轮一直是这个状态
$ adb shell 'ps -A | grep wificond'
308  1  5268  wificond         <- 5 MB RSS 常驻
$ adb shell 'service list | grep wifinl80211'
157  wifinl80211: [android.net.wifi.nl80211.IWificond]   <- 还注册了 binder 服务
```

而设备上**没有 WiFi 硬件**:
```
$ adb shell 'cat /sys/class/net/*/ 2>/dev/null'   # 只有 dummy0/lo/ip6tnl0 等虚拟接口
$ adb shell 'cat /sys/class/rfkill/*/name'
bt_default                                         # 无 wlan
$ dmesg | grep -c 'fe2c0000.*sdio'                 # SDIO WiFi 控制器已被 disable (G1)
0
```

---

## 2. 根因: `wificond` 来自 `base_system.mk`, 不在产品 mk 里

这是本轮**最关键的发现**, 也是前 30 轮漏掉它的原因:

```
$ grep -rn "wificond" build/make/
build/make/target/product/base_system.mk:271:    wificond \
build/make/target/product/emulator.mk:34:	wificond \
```

`wificond` **不在** `device/rockchip/rm35k/*.mk` 里。历史上裁 WiFi 时改的是
`common.mk`(那里有 `wificond`/`wifilogd`/`wpa_supplicant`/`hostapd` 的副本),
但那些是**多余副本** —— 真正把它装进 system 镜像的是 `base_system.mk:271`。

### 2.1 为什么只能就地改 `base_system.mk`

```
$ grep -n "PRODUCT_PACKAGES_remove" build/make/core/product.mk build/make/core/*.mk
(0 命中)
```

AOSP 11 **没有** `PRODUCT_PACKAGES_remove` 机制。这与 R20 处理 `cameraserver`
时完全同型 —— 当时的结论就写在 `aosp_rm35k.mk:36`:
> 「必须直接改 handheld_system.mk (同 R19 对 base_system.mk 的做法:
>  AOSP 11 没有 PRODUCT_PACKAGES_remove)」

### 2.2 继承链 (为什么 base_system.mk 会生效)

```
aosp_rm35k.mk:2  device/rockchip/rm35k/common.mk
common.mk:64     $(SRC_TARGET_DIR)/product/full_base.mk
full_base.mk:58  generic_no_telephony.mk
generic_no_telephony.mk:23  handheld_system.mk
handheld_system.mk:21       media_system.mk
media_system.mk:21          base_system.mk        <- wificond 在这
```

---

## 3. 安全性论证: 三条独立证据 (回答"会不会重演 r16 NPE")

r16 事故的机制是: 删 feature 声明 → WifiService 不启动 → `WifiManager` 未注册
→ SystemUI Dagger `@Provides` 非 `@Nullable` → `checkNotNull` NPE → SystemUI
无限重启。**本轮删的是进程, 不是类**, 契约完全不同, 但必须逐条证明:

### 证据 1: `WifiService` 从未启动
```
$ adb shell 'service check wifi'
Service wifi: not found
$ adb shell 'service list | grep -ic wifi'
0
```
原因: `SystemServer.java:1493` `if (pm.hasSystemFeature(FEATURE_WIFI))` 为假
(FEATURE_WIFI 已被前 30 轮移除)。

### 证据 2: 唯一消费者链已被切断 (决定性)
```
$ grep -rn "new WifiInjector" --include=*.java frameworks/opt/net/wifi/
frameworks/opt/net/wifi/service/java/com/android/server/wifi/WifiService.java:48:
        WifiInjector injector = new WifiInjector(mWifiContext);      <- 唯一构造点

$ grep -n "getSystemService" frameworks/opt/net/wifi/service/java/.../WifiInjector.java
233:  mWifiCondManager = (WifiNl80211Manager) mContext.getSystemService(
234:            Context.WIFI_NL80211_SERVICE);                            <- 唯一非测试调用点
```
`WifiInjector` 只被 `WifiService` 构造, 而只有 `WifiInjector` 会去取
`WIFI_NL80211_SERVICE`。`WifiService` 不启动 ⇒ **`wificond` 零客户端**。

设备侧佐证 —— `wificond` 是**纯空转**:
```
$ cat /proc/308/stat | awk '{print "utime="$14" stime="$15}'
utime=2 stime=1                    <- 几乎没用过 CPU
$ ls -l /proc/*/fd | grep -c wificond
0                                  <- 无任何进程持有它的 fd
```

### 证据 3: 无 VINTF 契约
```
$ adb shell 'grep -c wifi /vendor/etc/vintf/manifest.xml'
0
```
VINTF 里没有 wifi HAL 声明, 移除不会触发 `checkvintf` 失败。

### 3.1 刻意保留 `com.android.wifi` apex (反面边界)
`base_system.mk:68` 与 `:336` 的 `com.android.wifi` **未动**。它提供
`framework-wifi.jar` 里的 `WifiManager`/`WifiNl80211Manager` 等**类**,
SystemUI 与 Settings 静态链接这些类 —— 删 apex 会 `NoClassDefFoundError`,
那就真会重演 r16。**本轮只删"无硬件的守护进程与其 init 脚本", 不删类库。**

---

## 4. 改动内容 (可复核的精确 diff)

文件: `build/make/target/product/base_system.mk`
备份: `/data/rmx35k_work/src_backup_r31_base_system.mk` (md5 `ed2e8877…`)

```diff
     watchdogd \
-    wificond \
-    wifi.rc \
     wm \
```
外加一段 26 行的注释说明(含上述论证与备份路径)。

### 4.1 Makefile 陷阱: 注释不能插进续行块 (本轮自曝并规避)
最初我把注释直接写在 `wificond \` 与 `wifi.rc \` 之间, **这会让 make 报错**。
实测验证 (GNU make 语义):
```
$ cat _t.mk
X = a \
# comment
b
all:
	@echo "[$(X)]"
$ make -f _t.mk
_t.mk:3: *** 缺失分隔符。 停止。
```
已改为: 把两行删净, 注释**放在整个 `PRODUCT_PACKAGES` 块结束之后**。

### 4.2 改动的双向对照 (make 实际求值, 非肉眼)
抽出第 18–272 行的 `PRODUCT_PACKAGES` 块, 让 make 求值:

| 文件 | `wificond` | `wifi.rc` | 包总数 |
|---|---|---|---|
| 改动后 | **0** | **0** | 253 |
| 备份(负对照) | **1** | **1** | 254 |

→ 恰好 -2 项, 且 Makefile 语法合法。

---

## 5. 启动时间: 同条件 A/B (本轮方法学修正)

### 5.1 发现的混杂因素
r31 首次测量时设备**插着 TF 卡**(`mmcblk3`, acer 58.2 GiB), 而**所有历史基线
都是无卡测的**:
```
$ for d in bootcap_r20base bootcap_r26 bootcap_r30b bootcap_r31; do
    echo "$d: $(grep -l mmcblk3 $d/boot*/dmesg.txt 2>/dev/null|wc -l)/3 个 boot 有卡"; done
bootcap_r20base: 0/3
bootcap_r26:     0/3
bootcap_r30b:    0/3
bootcap_r31:     3/3      <- 只有 r31 有卡
```
直接拿 r31(有卡) 比 r30b(无卡) 是**错误的**, 会低估收益。

### 5.2 于是做了严格 A/B: 把 r30 刷回去, **保持 TF 卡在位**再测 3 次

| 版本 | 三轮 (ms) | 均值 | 屏幕状态 |
|---|---|---|---|
| r30 (有卡, 负对照) | 11864 / 11897 / 11935 | 11898.7 | Awake \| ON |
| **r31 (有卡)** | **11749 / 11765 / 11793** | **11769.0** | Awake \| ON |
| 差 | | **−129.7 ms** | |

- **区间不重叠**: r31 max = 11793 < r30 min = 11864 ✔
- r31 极差 44 ms, r30 极差 71 ms, 测量稳定
- 证据: `bootcap_r31_20260930_214051/`、`bootcap_r30card_20260930_214927/`

### 5.3 诚实说明: 收益机制不是"wificond 阻塞了开机"
`wificond` 是 `class main`(见 `wificond.rc:2` 与 `init.rc:945` `on nonencrypted
-> class_start main`), 与其它 main 级服务**并行**启动, 本就不在关键路径上
(这一点 TODO_2026-09-28.md:1073 早有记载)。所以这 −130 ms **不能**归因为
"少等 wificond"; 更可能是:
1. 少一个进程的 fork/exec/权限设置/内存分配调度开销;
2. 少加载一个 391 KB ELF + 其 `libwificond*` 依赖;
3. 开机期 lmkd/内存压力略降(951 MB 内存机器上, 5 MB 不是零)。

**确定收益是内存与攻击面**: 常驻 5268 kB、2 个线程、1 个 binder 服务
(且该服务对外暴露 `IWificond` 接口却无人使用)。启动时间的 −130 ms 是
A/B 实测值, 归因保持保守。

---

## 6. 双向负对照汇总 (方法学要求)

### 6.1 镜像级 (debugfs, 改动前 vs 改动后)
`system.img` 内逐路径存在性检查:

| 路径 | 新镜像 r31 | 设备原 r30 (对照) |
|---|---|---|
| `/bin/wificond` | **缺失** | 存在 |
| `/etc/init/wifi.rc` | **缺失** | 存在 |
| `/etc/init/wificond.rc` | **缺失** | 存在 |
| `/bin/sh` (方法有效性证明) | 存在 | 存在 |

`/bin/sh` 在两版**都**存在 ⇒ 说明测的确实是"文件在不在", 不是"debugfs 打不开"。
(注: 首次做这个对照时我抓了 64 MB 头部, debugfs 报
`Can't read a block bitmap` → 对照无效; 改为抓完整 838860800 B 后才有上述有效结果。)

### 6.2 设备级 (刷机后)
| 检查 | r31 实测 | 同批负对照 |
|---|---|---|
| `/system/bin/wificond` | 缺失 | `netd` init.svc=running ✔ |
| `/system/etc/init/wifi.rc` | 缺失 | `vold` init.svc=running ✔ |
| `/system/etc/init/wificond.rc` | 缺失 | `statsd` init.svc=running ✔ |
| `init.svc.wificond` | 空(不存在) | |
| `ps -A \| grep -c wificond` | **0** | |
| `service list \| grep -c wifinl80211` | **0** | |

### 6.3 刷机完整性
```
写入源 super_r31.img md5 = 4dc89f759d3d4d0c7e7e299405250bb2
设备回读      super md5 = 4dc89f759d3d4d0c7e7e299405250bb2   <- 逐字节一致 ✔
几何: device_size=1124073472, 5 分区尺寸与 r20 逐字段相同 ✔
lpunpack 往返: 5 分区前缀 md5 全一致 + 尾零填充 ✔
回滚镜像: super_r30.img (md5 e9fff4b0…, 即刷前状态) ✔
```

---

## 7. 稳定性 (r16 NPE 教训: 必须实机枚举, 不能只静态审计)

### 7.1 浸泡测试 (主动触碰所有 wifi 表面)
```
5 轮 熄屏/亮屏 切换
+ am start -a android.settings.WIFI_SETTINGS
+ am start -a android.settings.SETTINGS
+ am start -n com.android.settings/.Settings
```
结果:
```
FATAL(主)      = 0
am_crash       = 0
SystemUI pid   = 458     (前后不变)
system_server  = 350     (前后不变)
Settings pid   = 607
boot_completed = 1
```

### 7.2 wifi 入口优雅降级 (不崩, 只是报告服务不存在)
```
$ dumpsys wifi
Can't find service: wifi
$ cmd wifi status
cmd: Can't find service: wifi
```
两者都正常返回、**无异常抛出** —— 这是"服务不存在"的正常路径, 与 r16 的
`NullPointerException` 性质完全不同。

### 7.3 内核无因删除产生的报错
```
$ dmesg | grep -iE "wificond|cannot exec|failed to start"
(与删除无关的既有 3 条: /metadata、/avb、/factory/factory.prop —— 属正常缺失)
```

---

## 8. postflash 两个 FAIL 的归因 (不是隐患)

| FAIL | 真相 |
|---|---|
| `super 回读 md5 != e9fff4b0…` | **脚本断言没更新**: `e9fff4b0…` 是 r30 的 md5。回读值 `4dc89f75…` **恰好等于**写入源 `super_r31.img` ⇒ 逐字节正确。 |
| `overlay 残留 5 项` | `/cache/overlay/{system,system_ext,vendor,product,odm}` 5 个目录。**日期全是 09-29, 非本轮引入**; 且 `system/upper` **为空**(0 条目), `vendor/upper` 仅 3 个**空目录**、无文件 ⇒ **不遮蔽**新刷内容。已用 `ls /system/bin/wificond` → `No such file` 独立确认 overlay 没有掩盖删除。 |

---

## 9. 复现命令

```bash
# 构建
cd /data/rmx35k_work && bash build.sh systemimage
# 验证镜像内确实没有
debugfs -R "stat /bin/wificond" out/target/product/rm35k/system.img   # -> File not found
# 打包 super (复用 r20 几何)
bash build_super_r31.sh
# 刷写 (含尺寸/md5/liblp magic 自检 + 回读)
bash flash_r31_super.sh --yes

# 设备侧验收
adb shell 'getprop init.svc.wificond; ls /system/bin/wificond'   # 空 + No such file
adb shell 'ps -A | grep -c wificond; service list | grep -c wifinl80211'   # 0 0
adb shell 'logcat -d | grep -c "FATAL EXCEPTION"'                # 0
```

---

## 10. 文件清单

| 文件 | 说明 |
|---|---|
| `/data/aosp/build/make/target/product/base_system.mk` | 改动点(删 2 行 + 注释) |
| `/data/rmx35k_work/src_backup_r31_base_system.mk` | 改动前备份 (md5 ed2e8877…) |
| `/data/rmx35k_work/build_super_r31.sh` | super 重组脚本 |
| `/data/rmx35k_work/flash_r31_super.sh` | 刷写脚本 |
| `/data/rmx35k_work/postflash_r31.sh` | 刷后验证脚本 |
| `/data/rmx35k_work/build_r31_wificond.log` | 构建日志 (01:35, rc=0) |
| `/data/rmx35k_work/bootcap_r31_20260930_214051/` | r31 三轮启动测量 |
| `/data/rmx35k_work/bootcap_r30card_20260930_214927/` | r30 有卡负对照三轮 |
| `/data/rmx35k_work/r31_flash_evidence/` | 刷写+刷后日志 |
| NFS: `/mnt/nfs/srv/share/Ubuntu/rmx35k/super_r31.img` | 成品 (md5 4dc89f75…) |
