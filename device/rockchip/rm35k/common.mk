#
# Copyright 2014 Rockchip Limited
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# ============================================================================
# C 精简 (2026-09-27): 关掉**真正生效**的硬件开关
# ============================================================================
# 审计发现 (关键): BoardConfig.mk:31-33 里的
#     BOARD_HAS_WIFI := false / BOARD_HAS_BLUETOOTH := false / BOARD_HAS_GPS := false
# 是**完全无效**的 —— 这三个变量在整棵树里没有任何地方读它们。
#
# 真正决定 wifi/gps/phone 是否被继承的是 vendor/rockchip/common/BoardConfigVendor.mk
# 里的 (默认全为 true):
#     PRODUCT_HAVE_RKWIFI ?= true
#     PRODUCT_HAVE_GPS   ?= true
#     PRODUCT_HAVE_RKPHONE_FEATURES ?= true
# 它们被 vendor/rockchip/common/device-vendor.mk:67,87,96 消费:
#     ifeq ($(PRODUCT_HAVE_RKWIFI), true)
#       $(call inherit-product-if-exists, vendor/rockchip/common/wifi/wifi.mk)
# 蓝牙则走 **BOARD_HAVE_BLUETOOTH**, 且被 BoardConfigCommon.mk:258 用 `:=` 强制 true:
#     ifeq ($(strip $(BOARD_HAVE_BLUETOOTH)),true)   # device-vendor.mk:83
#       $(call inherit-product-if-exists, .../bluetooth/bluetooth.mk)
#
# ★ 覆盖时机: 这些变量是 `?=`, 而第 16 行才 include BoardConfigVendor.mk。
#   所以必须在 include **之前** 赋值, 才能在 `?=` 时生效。
#   (这就是为什么下面这段放在第 16 行前面)
# ============================================================================
PRODUCT_HAVE_RKWIFI          := false   # 无 WiFi 模组 (8821cs.ko 从未 insmod)
PRODUCT_HAVE_GPS             := false   # 无 GNSS 硬件
PRODUCT_HAVE_RKPHONE_FEATURES := false  # 无蜂窝模组 (phone.mk 只放 ppp/rild, 用不到)

include vendor/rockchip/common/BoardConfigVendor.mk

BOARD_VENDOR_GPU_PLATFORM := bifrost

# R20 优化: 本设备无任何 32 位应用 (第三方 0 个, 系统应用全为 arm64-v8a).
# 唯一为 32 位服务的 SecondaryZygotePreload 实测耗时 2561ms, 其唯一目的是
# 供 WebView RELRO 进程 fork 使用 -- 而本机未安装 WebView
# (WebViewUpdater: WebViewPackageMissingException: Could not find a loadable WebView package).
# 该预载在 ZygoteProcess.preloadDefault() 中持有 mLock, 与 startViaZygote()
# 争用同一把锁, 实测阻塞一次应用进程启动 465ms (Long monitor contention).
# 改用 core_64_bit_only.mk 后: ro.zygote=zygote64, 不再启动 zygote_secondary,
# 不再执行 SecondaryZygotePreload, 省下该预载并消除锁争用;
# 同时省去 zygote32 常驻内存 (实测 TOTAL PSS: 75812 kB).
# 注意: 32 位 vendor HAL (audio/rockit/omx) 由 TARGET_2ND_ARCH 构建,
# 不受本开关影响 (该开关仅被 package.mk/board_config.mk/executable_prefer_symlink.mk
# 消费, binary.mk 与 soong cc 从不读取), 故 BoardConfig.mk 的 TARGET_2ND_ARCH 保持不动.
# 代价: 纯 armeabi-v7a 单架构 APK 将无法安装 (INSTALL_FAILED_NO_MATCHING_ABIS),
#       用户已确认接受.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)

# Normal tablet, add QuickStep for normal product only.
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base.mk)
PRODUCT_PACKAGES += Launcher3QuickStep

# ============================================================================
# A 精简 (2026-09-27, 第15轮): 语言只保留 简体中文 / 英文
# ============================================================================
# 链路 (已逐级证实):
#   PRODUCT_LOCALES -> build/make/core/product_config.mk:225  PRODUCT_AAPT_CONFIG
#                   -> product_config.mk:229 空格转逗号
#                   -> package_internal.mk:518 PRIVATE_PRODUCT_AAPT_CONFIG
#                   -> definitions.mk:1964  $(addprefix -c ,...)
#                   -> aapt2 link 的资源过滤器
#
# full_base.mk:55 会继承 languages_full.mk (89 种语言)。此赋值放在上面
# inherit **之后**, 用 `:=` 覆盖, 只有这 4 个 locale 进入各 APK 的 resources.arsc。
# 实测 (aapt2 optimize 等价测量): 34 个含资源 APK 由 232.3 MiB 降到 117.2 MiB。
#
# 保留: en_US(默认, 不可去) + zh_CN(简体) + zh_TW/zh_HK(繁体, 少量, 一并留着稳妥)
# 注意: 资源过滤**不动 classes.dex**, 预置 odex/vdex 仍然有效, 无需重编 oat。
# ============================================================================
PRODUCT_LOCALES := en_US zh_CN zh_TW zh_HK

PRODUCT_AAPT_CONFIG ?= normal large xlarge hdpi xhdpi xxhdpi
PRODUCT_AAPT_PREF_CONFIG ?= xhdpi



########################################################
# Kernel
########################################################

#SDK Version
PRODUCT_PROPERTY_OVERRIDES += \
    ro.rksdk.version=RK30_ANDROID$(PLATFORM_VERSION)-SDK-v1.00.00

# Filesystem management tools
PRODUCT_PACKAGES += \
    fsck.f2fs \
    mkfs.f2fs \
    fsck_f2fs

PRODUCT_PACKAGES += \
    vndservicemanager

# omx
PRODUCT_PACKAGES += \
    libomxvpu_enc \
    libomxvpu_dec \
    libRkOMX_Resourcemanager \
    libOMX_Core \

# For screen hwrotation
ifneq ($(filter 90 180 270, $(strip $(SF_PRIMARY_DISPLAY_ORIENTATION))), )
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
	ro.surface_flinger.primary_display_orientation=ORIENTATION_$(SF_PRIMARY_DISPLAY_ORIENTATION)
endif

PRODUCT_DEX_PREOPT_GENERATE_DM_FILES := true
PRODUCT_DEX_PREOPT_DEFAULT_COMPILER_FILTER := verify
# Configure jemalloc for low memory 
MALLOC_SVELTE := true

# ⚠️ 2026-09-26 关键修复: init rc 必须用 vendor/rockchip/rm35k 下的版本, 不能用
#    device/rockchip/rm35k/init/ 下的版本!
#    证据: 逐个 md5 比对原厂 /vendor/etc/init/hw/*.rc, 原厂与 vendor/ 版本**完全一致**,
#    而 device/ 版本是 pinenote 派生(ebook)分支的, 三个文件内容不同:
#      init.rockchip.rc  : device 版把 `setprop sys.usb.config adb` 从 `on charger`
#                          挪到了 `on boot` -> 充电模式(ro.boot.charger.emmc=0)下
#                          不会配置 USB -> 该模式下 adb 永远起不来
#      init.rk30board.rc : device 版少 106 行 (cpu governor/hdmi/backlight 权限等)
#      init.mount_all.rc : device 版 (init.mount_all_early.rc) 缺 `on early-fs / start vold`
#                          和 `exec_start wait_for_keymaster`
#    另外 device/ 版 init.rockchip.rc 第 2 行 import 的
#    init.rk30board.environment.rc 在镜像里根本不存在 (原厂有, 内容 export EXTERNAL_STORAGE)。
PRODUCT_COPY_FILES += \
    vendor/rockchip/rm35k/etc/init/hw/init.rockchip.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.rockchip.rc \
    vendor/rockchip/rm35k/etc/init/hw/init.mount_all.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.mount_all.rc \
    vendor/rockchip/rm35k/etc/init/hw/init.rk30board.environment.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.rk30board.environment.rc \
    $(LOCAL_PATH)/init/init.connectivity.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.connectivity.rc \
    $(LOCAL_PATH)/init/init.insmod.cfg:$(TARGET_COPY_OUT_VENDOR)/etc/init.insmod.cfg \
    $(LOCAL_PATH)/init/init.insmod.sh:$(TARGET_COPY_OUT_VENDOR)/bin/init.insmod.sh \
    vendor/rockchip/rm35k/etc/init/hw/init.rk30board.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.rk30board.rc \
    $(LOCAL_PATH)/init/init.rk356x.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.rk356x.rc \
    $(LOCAL_PATH)/init/init.rk30board.usb.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.rk30board.usb.rc \
    $(LOCAL_PATH)/init/ueventd.rockchip.rc:$(TARGET_COPY_OUT_VENDOR)/ueventd.rc \
    $(LOCAL_PATH)/configs/alarm_filter.xml:system/etc/alarm_filter.xml \

PRODUCT_COPY_FILES += \
    hardware/rockchip/libgraphicpolicy/graphic_profiles.conf:$(TARGET_COPY_OUT_VENDOR)/etc/graphic/graphic_profiles.conf

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/wpa_config.txt:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/wpa_config.txt \
    hardware/broadcom/wlan/bcmdhd/config/wpa_supplicant_overlay.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/wpa_supplicant_overlay.conf \
    hardware/broadcom/wlan/bcmdhd/config/p2p_supplicant_overlay.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/p2p_supplicant_overlay.conf \
    hardware/realtek/wlan/supplicant_overlay_config/wpa_supplicant_overlay.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/wpa_supplicant_rtk.conf \
    hardware/realtek/wlan/supplicant_overlay_config/p2p_supplicant_overlay.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/p2p_supplicant_rtk.conf

#for ssv6051
PRODUCT_COPY_FILES += \
    vendor/rockchip/common/wifi/ssv6xxx/p2p_supplicant.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/p2p_supplicant_ssv.conf \

# RMX35K 精简: 本机无 WiFi/蓝牙硬件, 以下 WiFi 组件已裁除
# (wificond/wifilogd/wpa_supplicant/hostapd/wifi@1.0-service-lazy 等)
# 如需恢复, 参照 /data/rmx35k_work/common.mk.orig

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_configuration.xml \
    $(LOCAL_PATH)/configs/audio_policy_volumes_drc.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_volumes_drc.xml \
    frameworks/av/services/audiopolicy/config/default_volume_tables.xml:$(TARGET_COPY_OUT_VENDOR)/etc/default_volume_tables.xml \
    frameworks/av/services/audiopolicy/config/a2dp_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/a2dp_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/r_submix_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/r_submix_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/usb_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/usb_audio_policy_configuration.xml \
    frameworks/av/media/libeffects/data/audio_effects.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_effects.xml

# For audio-recoard 
PRODUCT_PACKAGES += \
    libsrec_jni

# For tts test
PRODUCT_PACKAGES += \
    libwebrtc_audio_coding

#audio
$(call inherit-product-if-exists, hardware/rockchip/audio/tinyalsa_hal/codec_config/rk_audio.mk)

# SDCardFS deprecate
# https://source.android.google.cn/devices/storage/sdcardfs-deprecate
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)

# ============================================================================
# C 精简 (2026-09-27): 移除本机**不存在**的硬件 feature 声明
# ============================================================================
# 原理 (实测确认): SystemServer 里这些服务都是 **feature-guarded** 的:
#     BluetoothService          : SystemServer.java:1212
#         else if (!pm.hasSystemFeature(FEATURE_BLUETOOTH)) -> "No Bluetooth Service"
#     WifiService/WifiScanning  : SystemServer.java:1493  if (hasSystemFeature(FEATURE_WIFI))
#     WifiAware                 : :1513  FEATURE_WIFI_AWARE
#     WifiP2P                   : :1521  FEATURE_WIFI_DIRECT
#     PrintManagerService       : :1877  FEATURE_PRINTING
#     CompanionDeviceManager    : :1883  FEATURE_COMPANION_DEVICE_SETUP
#   => **删掉 feature XML 即可让服务不启动**, 不必改 Java (比删 SystemServer 代码更安全)。
#
# 之前 BOARD_HAS_WIFI/BLUETOOTH/GPS := false (BoardConfig.mk:30-33) 是**无效**的:
#   这些变量在 AOSP 里不 gate 任何东西, feature 完全由下面这些 PRODUCT_COPY_FILES 决定。
#   实测 `pm list features` 确实仍报告 wifi/bluetooth/camera -> 服务真的被启动了。
#
# 本机硬件事实: 无 WiFi 模组使能 (8821cs.ko 在 init.insmod.cfg 里没被 insmod),
#               无蓝牙, 无 GPS/GNSS, 无摄像头 -> 全部移除。
#
# 【已移除】bluetooth / bluetooth_le / wifi.direct / wifi.passpoint /
#           camera / camera.front / camera.external / ipsec_tunnels
# 【保留】  faketouch (无害, 部分 app 会探测)、usb.host / usb.accessory
#           (游戏手柄与外设需要)
#
# ----------------------------------------------------------------------------
# ★★ R16 回归事故 (2026-09-27, 实机复现并已修复) ★★
# ----------------------------------------------------------------------------
# 曾把 android.hardware.wifi.xml 也一起删掉 -> 实机 SystemUI **无限崩溃重启**:
#     FEATURE_WIFI 缺失
#       -> SystemServer.java:1493 `if (hasSystemFeature(FEATURE_WIFI))` 为假
#       -> WifiService 从不启动, WifiManager 从未注册
#       -> SystemUI Dagger 的 @Provides **非** @Nullable:
#            SystemServicesModule.java:321-323
#              provideWifiManager(Context c){ return c.getSystemService(WifiManager.class); }
#          injected by dagger.internal.Preconditions.checkNotNull
#       -> java.lang.NullPointerException: Cannot return null from a
#          non-@Nullable @Provides method
#       -> SystemUI 每 ~1.5s 重启一次 (FATAL 320 次), 无状态栏/无导航栏/无锁屏
#          但 sys.boot_completed=1, 表面"已开机" -> 极易误判为 GPT 切分问题
#       -> 另有 system_server 侧 NPE (见下)
#
# 【R20 已修复该契约, 故本次可删】2026-09-29:
#   (1) frameworks/base/packages/SystemUI/.../dagger/SystemServicesModule.java:327-332
#       provideWifiManager 已加 @Nullable -> Dagger 不再插入 checkNotNull
#       实机验证: dexdump 显示旧镜像 ProvideWifiManagerFactory 里
#         invoke-static ... Preconditions.checkNotNull 计数 = 1;
#       新构建 = 0 (双对照: provideWindowManager 两版都为 1, 说明计数方法有效)。
#   (2) Rockchip 供应商代码 WifiSleepController 在 ACTION_SCREEN_OFF 无条件解引用
#       mWifiManager.isScanAlwaysAvailable() => 实机 NPE 打死 system_server
#       (WifiSleepController.java:98, system_server PID 356->3381, 161 次 FATAL)。
#       已在本轮全部判空 (:107, :111, :202) 并留档:
#         /data/rmx35k_work/WIFI_FEATURE_REMOVAL_AB_TEST.md
#   (3) 其余框架侧 WifiManager 解引用点已逐一处以判空 (StatsPullAtomService,
#       SettingsLib WifiTracker/WifiSavedConfigUtils, DevicePolicyManagerService,
#       NetworkPolicyManagerService/ShellCommand, AdbDebuggingManager,
#       NetworkMonitor, DeviceDiscoveryService, SystemUI WifiDebugging*Activity)。
#
# 因此 wifi.xml 现在**不再是框架契约**: 本机无 WiFi 模组 (8821cs.ko 未 insmod),
# 删除后 WifiService/WifiScanningService 不启动, 省下 StartWifi 主线程窗口。
# ----------------------------------------------------------------------------

# USB HOST
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.usb.host.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.host.xml

# WIFI — R20 起已移除 (R16 事故的框架契约已通过 @Nullable + 判空修复)
# 原条目: frameworks/native/data/etc/android.hardware.wifi.xml -> vendor/etc/permissions/
# 注意: 移除本行后 `pm list features` 不再报告 android.hardware.wifi,
#       SystemServer.java:1493 的 `if (hasSystemFeature(FEATURE_WIFI))` 为假,
#       WifiService/WifiScanningService/WifiAwareService/WifiP2pService 均不启动。

# USB ACCESSORY
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.usb.accessory.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.accessory.xml

PRODUCT_PROPERTY_OVERRIDES += \
    ro.boot.vr=0

# Sensor HAL —— R18 已整机摘除 (假传感器)
# 证据见 /data/rmx35k_work/ACCELEROMETER_FAKE_FINDING.md:
#   HAL 只广告 1 个 Accelerometer, registerListener() 返回 false;
#   /dev/mma8452_daemon 不存在, GSENSOR_IOCTL_APP_SET_RATE 一律 -1 (Bad file descriptor)。
#   机制: nusensors.cpp:114 无条件 new MmaSensor(); SensorBase::open_device() 失败只 LOGD,
#   MmaSensor 构造函数忽略返回值 -> 广告一个永远无数据的传感器。
#   摘除必须三处同时做, 只删二进制会**挂住开机** (hwservicemanager 等惰性 HAL 直到超时):
#     (1) device/rockchip/rm35k/manifest.xml 去掉 sensors <hal> 块
#     (2) 本处去掉 HAL 服务/impl
#     (3) PRODUCT_COPY_FILES 去掉 sensors.rk30board.so
#   只杀运行中的 HAL 会 abort system_server (SensorDevice.cpp:1204 handleHidlDeath)。
# 注意: android.frameworks.sensorservice@1.0 (compatibility_matrix.xml:11-17, ISensorManager)
#   是 platform 侧的 sensorservice, 与本 HAL 无关, **必须保留**。
# (历史) sensors.rk30board.so 在本树中无构建模块, 原为 prebuilt 经 PRODUCT_COPY_FILES
# 安装; R18 已连同其服务/impl/COPY 条目一并删除, 不要再加回来。

# Power AIDL
PRODUCT_PACKAGES += \
    android.hardware.power \
    android.hardware.power-service.rm35k

# Camera omx-plugin vpu akmd libion_rockchip_ext
# NOTE: libstagefrighthw.so is a prebuilt installed via PRODUCT_COPY_FILES below;
# adding it here collides with hardware/qcom/sdm845/media/libstagefrighthw.
PRODUCT_PACKAGES += \
    libvpu \
    libgralloc_priv_omx \
    akmd \
    libion_ext


# Light AIDL
PRODUCT_PACKAGES += \
    android.hardware.lights \
    android.hardware.lights-service.rm35k

# Fastbootd HAL
# TODO: develop a hal for GMS...
PRODUCT_PACKAGES += \
    android.hardware.fastboot@1.0-impl-rockchip \
    fastbootd

PRODUCT_PROPERTY_OVERRIDES += \
    ro.vendor.mpp_buf_type=1
# Gralloc HAL
PRODUCT_PACKAGES += \
    arm.graphics-V1-ndk_platform.so \
    android.hardware.graphics.allocator@4.0-impl-$(BOARD_VENDOR_GPU_PLATFORM) \
    android.hardware.graphics.mapper@4.0-impl-$(BOARD_VENDOR_GPU_PLATFORM) \
    android.hardware.graphics.allocator@4.0-service

DEVICE_MANIFEST_FILE += \
    device/rockchip/rm35k/manifests/android.hardware.graphics.mapper@4.0.xml \
    device/rockchip/rm35k/manifests/android.hardware.graphics.allocator@4.0.xml

PRODUCT_PACKAGES += \
    rkhelper

# For EGL
# ⚠️ 不能写 ${TARGET_BOARD_HARDWARE_EGL}: 该变量在 BoardConfigCommon.mk 里定义,
#    而 common.mk 是通过 aosp_rm35k.mk 的 inherit-product 先被解析的, 此时
#    TARGET_BOARD_HARDWARE_EGL 尚未定义 -> 展开成空串 ->
#        ro.hardware.egl=      (实测产物确实为空)
#    原厂是 ro.hardware.egl=mali。该属性决定 EGL/GLES 加载哪个后端,
#    为空会让 hw_get_module(EGL) 找不到实现, 图形栈行为未定义。
#    这里直接写字面量 mali, 与原厂一致, 不依赖解析顺序。
PRODUCT_PROPERTY_OVERRIDES += \
    ro.hardware.egl=mali

# HW Composer
# ⚠️ 下面是「卡第二屏重启」的根因修复点 (2026-09-25):
#   hwcomposer.rk30board 这个名字原来虽然写在这里, 但**没有任何模块定义**
#   (唯一规则在 hardware/rockchip/hwcomposer/einkhwc/Android.mk, 被
#    ifeq ($(BUILD_WITH_RK_EBOOK),true) 包住, 而全树只有 pinenote 设了它)。
#   PRODUCT_PACKAGES 里放了不存在的模块名, 构建系统**不报错**, 于是
#   /vendor/lib64/hw/hwcomposer.rk30board.so 根本没进镜像 =>
#   composer service 的 HwLoader::loadModule() hw_get_module(HWC) 失败 =>
#   SurfaceFlinger 拿不到 composer HAL => 卡第二屏后被 init watchdog 重启。
#   libstagefrighthw / libsync_vendor / libbaseparameter 同理也是静默缺失。
#
# 修法: 这些 .so 在 vendor/rockchip/rm35k/{lib,lib64}/ 下本来就有, 且与
#   运行中的原厂文件逐字节一致 (md5 已核对)。但**不能**用
#   cc_prebuilt_library_shared 补声明: libhwjpeg 已被
#   hardware/rockchip/libhwjpeg/Android.bp 的源码模块占用, libstagefrighthw
#   被 hardware/qcom/sdm845/... 占用, 两者会争同一 out 目标, kati 直接报
#       error: overriding commands for target '.../libhwjpeg.so'
#   (已实测)。因此这里改用 PRODUCT_COPY_FILES 直接拷贝, 绕开模块名与
#   输出路径冲突 —— 这也是本树既有 vendor blob 的安装方式。
#   libbaseparameter / libteec 无冲突, 仍走 Android.bp 的模块声明。
#
# 关键区分 (2026-09-25 二次踩坑后厘清): 这 7 个库里有两类, 处理方式**必须不同**。
#
#  A) 树里**已有真源码模块**, 且其安装路径就是 vendor/lib[64]/xxx.so:
#        libsync_vendor  <- system/core/libsync/Android.bp (vendor_available,
#                           变体 libsync_vendor.vendor -> vendor/lib[64])
#        libhwjpeg       <- hardware/rockchip/libhwjpeg/Android.bp (vendor: true)
#        libbaseparameter<- vendor/rockchip/rm35k/Android.bp (本仓声明)
#     这类**只能写进 PRODUCT_PACKAGES 让构建系统去装**。若再用
#     PRODUCT_COPY_FILES 拷到同一目标, ckati 立刻报:
#        error: overriding commands for target '.../vendor/lib/libsync_vendor.so'
#     (实测: 第一次只报了 libsync_vendor 就中止, 后面还排着同类的队)。
#
#  B) 树里**没有任何模块**产出该文件:
#        hwcomposer.rk30board / hw_output.default / sensors.rk30board
#            (唯一规则在 einkhwc/Android.mk, 被 BUILD_WITH_RK_EBOOK 门控,
#             本产品未开 -> 模块根本不存在)
#        libstagefrighthw
#            (hardware/qcom/sdm845/media/... 的模块在本产品 Makefile 遍历中
#             未被 include, 实测 soong 产物里 0 条)
#     这类才用 PRODUCT_COPY_FILES 直接拷。
#
#  两个额外坑 (本轮实测):
#   1) libsync_vendor 是 vendor_available, PRODUCT_PACKAGES += libsync_vendor
#      装的是 **system 变体** -> 落到 /system/lib64/libsync_vendor.so,
#      而原厂在 /vendor/lib64/libsync_vendor.so。必须写 libsync_vendor.vendor
#      才会选 vendor 变体 (本树已有 libstdc++.vendor 先例)。
#   2) android.hardware.graphics.composer@2.1-impl **不是模块名**:
#      实测 grep -c 'LOCAL_MODULE := ...-impl$' out/soong/Android-*.mk 为 0,
#      原厂 /vendor/lib64/hw/ 下也没有该文件 (只有 hwcomposer.rk30board.so),
#      HAL 靠 HwcLoader 的 hw_get_module(HWC_HARDWARE_MODULE_ID) 直取
#      hwcomposer.rk30board.so, 不经 impl 层。写在这里同样是静默 no-op, 已删。
#
# 判据: grep -c 'LOCAL_MODULE := <名字>$' out/soong/Android-aosp_rm35k.mk
#   非 0 => 走 A 类 (PRODUCT_PACKAGES); 为 0 => 走 B 类 (PRODUCT_COPY_FILES)。
PRODUCT_PACKAGES += \
    libbaseparameter \
    libteec \
    libhwjpeg \
    libsync_vendor.vendor \
    android.hardware.graphics.composer@2.1-service

# B 类: 无模块, 只能直接拷贝 (32+64 位, 与原厂布局一致)
PRODUCT_COPY_FILES += \
    vendor/rockchip/rm35k/lib/hw/hwcomposer.rk30board.so:$(TARGET_COPY_OUT_VENDOR)/lib/hw/hwcomposer.rk30board.so \
    vendor/rockchip/rm35k/lib64/hw/hwcomposer.rk30board.so:$(TARGET_COPY_OUT_VENDOR)/lib64/hw/hwcomposer.rk30board.so \
    vendor/rockchip/rm35k/lib/hw/hw_output.default.so:$(TARGET_COPY_OUT_VENDOR)/lib/hw/hw_output.default.so \
    vendor/rockchip/rm35k/lib64/hw/hw_output.default.so:$(TARGET_COPY_OUT_VENDOR)/lib64/hw/hw_output.default.so \
    vendor/rockchip/rm35k/lib/libstagefrighthw.so:$(TARGET_COPY_OUT_VENDOR)/lib/libstagefrighthw.so \
    vendor/rockchip/rm35k/lib64/libstagefrighthw.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libstagefrighthw.so

# ────────────────────────────────────────────────────────────────────────────
# 回归护栏 (regression guard)
# 当初「卡第二屏」的失效模式是: PRODUCT_PACKAGES 里放一个**没有模块定义**的
# 名字, 构建系统不报错, 文件静默缺失。PRODUCT_COPY_FILES 的源文件不存在时
# 同样不报错 (只会少拷)。因此这里做两道存在性断言, 缺失即 $(error) 中止。
#
#  A) A 类源码模块用到的 prebuilt 源文件 (Android.bp/内置模块的输入)
#  B) B 类直接拷贝的 prebuilt 源文件
# 注意: 护栏只断言「源文件存在」。A 类是否真的被装进镜像, 由
#       verify_image_contents.sh 在打包后按**产物路径**复核 (见该脚本 [1] 节)。
# ────────────────────────────────────────────────────────────────────────────
# A 类: 源码模块的 prebuilt 输入 (libsync_vendor/libhwjpeg 是源码, 无 prebuilt)
REQUIRED_MODULE_PREBUILTS := \
    vendor/rockchip/rm35k/lib/libbaseparameter.so \
    vendor/rockchip/rm35k/lib64/libbaseparameter.so

# B 类: 直接拷贝的源文件 (必须与上面 PRODUCT_COPY_FILES 一一对应)
REQUIRED_COPY_SRCS := \
    vendor/rockchip/rm35k/lib/hw/hwcomposer.rk30board.so \
    vendor/rockchip/rm35k/lib64/hw/hwcomposer.rk30board.so \
    vendor/rockchip/rm35k/lib/hw/hw_output.default.so \
    vendor/rockchip/rm35k/lib64/hw/hw_output.default.so \
    vendor/rockchip/rm35k/lib/libstagefrighthw.so \
    vendor/rockchip/rm35k/lib64/libstagefrighthw.so

$(foreach _lib,$(REQUIRED_MODULE_PREBUILTS) $(REQUIRED_COPY_SRCS),\
  $(if $(wildcard $(LOCAL_PATH)/../../../$(_lib)),,\
    $(error [rm35k] 必需 vendor 库源文件缺失, 拒绝构建: $(_lib))))

# 交叉断言: A/B 两类不得同时出现同名目标, 否则 ckati 会报
# "overriding commands for target" (本轮实测踩中 libsync_vendor)。
_VENDOR_A_DESTS := $(TARGET_COPY_OUT_VENDOR)/lib64/libbaseparameter.so \
                   $(TARGET_COPY_OUT_VENDOR)/lib64/libsync_vendor.so \
                   $(TARGET_COPY_OUT_VENDOR)/lib64/libhwjpeg.so
_VENDOR_B_DESTS := $(TARGET_COPY_OUT_VENDOR)/lib64/hw/hwcomposer.rk30board.so \
                   $(TARGET_COPY_OUT_VENDOR)/lib64/hw/hw_output.default.so \
                   $(TARGET_COPY_OUT_VENDOR)/lib64/libstagefrighthw.so
ifneq ($(filter $(_VENDOR_A_DESTS),$(_VENDOR_B_DESTS)),)
$(error [rm35k] A/B 两类 vendor 库目标重叠, 会导致 kati overriding commands)
endif

# iep
BUILD_IEP := true
PRODUCT_PACKAGES += \
    libiep

# charge
PRODUCT_PACKAGES += \
    charger \
    charger_res_images

# Allows healthd to boot directly from charger mode rather than initiating a reboot.
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    ro.enable_boot_charger_mode=0

# Add board.platform default property to parsing related rc
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    ro.board.platform=$(strip $(TARGET_BOARD_PLATFORM)) \
    ro.target.product=$(strip $(TARGET_BOARD_PLATFORM_PRODUCT))

PRODUCT_CHARACTERISTICS := tablet

# audio lib
PRODUCT_PACKAGES += \
    audio_policy.rk30board \
    audio.primary.rk30board \
    audio.alsa_usb.rk30board \
    audio.a2dp.default\
    audio.r_submix.default\
    libaudioroute\
    audio.usb.default

PRODUCT_PACKAGES += \
    android.hardware.audio@2.0-service \
    android.hardware.audio@6.0-impl \
    android.hardware.audio.effect@6.0-impl

PRODUCT_PACKAGES += \
    libclearkeycasplugin

PRODUCT_PACKAGES += \
    android.hardware.cas@1.2-service-lazy \
    android.hardware.drm@1.3-service-lazy.clearkey

PRODUCT_PACKAGES += \
    rockchip.hardware.rockit.hw@1.0-service \
    librockit_hw_client@1.0

#Health hardware
PRODUCT_PACKAGES += \
    android.hardware.health@2.1-service \
    android.hardware.health@2.1-impl

# for swiftshader, vulkan v1.1 test.
PRODUCT_PACKAGES += \
  vulkan.rk30board

PRODUCT_PROPERTY_OVERRIDES += \
  ro.cpuvulkan.version=4198400

PRODUCT_COPY_FILES += \
  frameworks/native/data/etc/android.hardware.vulkan.version-1_1.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.version-1_1.xml \
  frameworks/native/data/etc/android.hardware.vulkan.level-0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.level-0.xml \
  frameworks/native/data/etc/android.hardware.vulkan.compute-0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.compute-0.xml \
  frameworks/native/data/etc/android.software.vulkan.deqp.level-2020-03-01.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.vulkan.deqp.level.xml

# Filesystem management tools
# EXT3/4 support
PRODUCT_PACKAGES += \
    mke2fs \
    e2fsck \
    tune2fs \
    resize2fs

# audio lib
PRODUCT_PACKAGES += \
    libasound \
    alsa.default \
    acoustics.default \
    libtinyalsa \
    tinymix \
    tinyplay \
    tinycap \
    tinypcminfo

PRODUCT_PACKAGES += \
	alsa.audio.primary.rk30board\
	alsa.audio_policy.rk30board

$(call inherit-product-if-exists, external/alsa-lib/copy.mk)
$(call inherit-product-if-exists, external/alsa-utils/copy.mk)


PRODUCT_PROPERTY_OVERRIDES += \
    persist.sys.strictmode.visual=false 

PRODUCT_PROPERTY_OVERRIDES += ro.rk.bt_enable=true

ifeq ($(strip $(MT6622_BT_SUPPORT)),true)
    PRODUCT_PROPERTY_OVERRIDES += ro.rk.btchip=mt6622
endif

# RMX35K: 本机确认有 HDMI 口, 故此处不再设 ro.rk.hdmi_enable=false。
# 原先此处与下方 "ro.rk.hdmi_enable=true" 冲突, 而 PRODUCT_PROPERTY_OVERRIDES
# 对同一属性保留首个取值, 导致生效值被静默置为 false (HDMI 被关)。
# 现统一由下方 hwui 属性块设为 true。
PRODUCT_PROPERTY_OVERRIDES += ro.rk.flash_enable=false

ifeq ($(strip $(MT7601U_WIFI_SUPPORT)),true)
    PRODUCT_PROPERTY_OVERRIDES += ro.rk.wifichip=mt7601u
endif

PRODUCT_TAGS += dalvik.gc.type-precise

PRODUCT_PROPERTY_OVERRIDES +=       \
    ro.factory.hasUMS=false         \
    testing.mediascanner.skiplist = /mnt/shell/emulated/Android/

PRODUCT_PACKAGES += rockchip.drmservice

# RMX35K: 手柄无 Back 键, 用 VOL+ / VOL- 组合键注入 BACK 以退出游戏
PRODUCT_PACKAGES += zedkeys

PRODUCT_PROPERTY_OVERRIDES += \
    ro.factory.hasGPS=false

PRODUCT_PROPERTY_OVERRIDES += \
    ro.factory.storage_suppntfs=false

PRODUCT_PROPERTY_OVERRIDES += \
    ro.factory.without_battery=false
 
PRODUCT_PACKAGES += \
    com.android.future.usb.accessory

# C 精简 (2026-09-27): 移除 Bluetooth HAL 相关包
#   本机无蓝牙硬件 (8821cs.ko 未 insmod), 且 feature XML 已删 ->
#   BluetoothService 不会启动 -> 这些 HAL 永远没人用。
#   保留 libbt-vendor 的静态库定义, 只是不再打进镜像。
#   (如需恢复: /data/rmx35k_work/upstream_orig/ 有原始文件)
# PRODUCT_PACKAGES += \
#     libbt-vendor \
#     android.hardware.bluetooth@1.0-impl \
#     android.hardware.bluetooth@1.0-service \
#     android.hardware.bluetooth@1.0-service.rc

PRODUCT_PROPERTY_OVERRIDES += \
    ro.rk.screenoff_time=60000

# C 精简 (2026-09-27): 关掉 CameraServiceProxy
#   SystemServer.java:1044 读这个属性:
#       boolean disableCameraService = SystemProperties.getBoolean(
#               "config.disable_cameraservice", false);
#   :2061  if (!disableCameraService) { startService(CameraServiceProxy.class); }
#   本机无摄像头 (vendor/bin/hw 里无 camera HAL, VINTF 无对应项),
#   设为 true 即可彻底不启动该服务 —— **零 Java 改动**, 是收益/风险比最高的一项。
#   (审计报告 §4 特别推荐)
PRODUCT_PROPERTY_OVERRIDES += \
    config.disable_cameraservice=true

# Flash Lock Status reporting,
# GTS: com.google.android.gts.persistentdata.
# PersistentDataHostTest#testTestGetFlashLockState
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    ro.oem_unlock_supported=1

PRODUCT_PACKAGES += \
    move_widevine_data.sh

PRODUCT_PACKAGES += \
    android.hardware.drm@1.3-service-lazy.widevine

$(call inherit-product-if-exists, vendor/rockchip/common/device-vendor.mk)

########################################################
# this product has support remotecontrol or not
########################################################
PRODUCT_PROPERTY_OVERRIDES += \
    ro.config.enable.remotecontrol=false

PRODUCT_PACKAGES += \
	abc

PRODUCT_PROPERTY_OVERRIDES += \
	ro.vendor.udisk.visible=true

#if disable safe mode to speed up booting time
PRODUCT_PROPERTY_OVERRIDES += \
    ro.safemode.disabled=true

#add for hwui property
PRODUCT_PROPERTY_OVERRIDES += \
    ro.rk.screenshot_enable=true   \
    ro.rk.hdmi_enable=true   \
    sys.status.hidebar_enable=false

PRODUCT_FULL_TREBLE_OVERRIDE := true
#PRODUCT_COMPATIBILITY_MATRIX_LEVEL_OVERRIDE := 27

# Add runtime resource overlay for framework-res
PRODUCT_ENFORCE_RRO_TARGETS := \
    framework-res

#The module which belong to vndk-sp is defined by google
PRODUCT_PACKAGES += \
    android.hardware.renderscript@1.0.vndk-sp\
    android.hardware.graphics.allocator@2.0.vndk-sp\
    android.hardware.graphics.mapper@2.0.vndk-sp\
    android.hardware.graphics.common@1.0.vndk-sp\
    libhwbinder.vndk-sp\
    libbase.vndk-sp\
    libcutils.vndk-sp\
    libhardware.vndk-sp\
    libhidlbase.vndk-sp\
    libhidltransport.vndk-sp\
    libutils.vndk-sp\
    libc++.vndk-sp\
    libRS_internal.vndk-sp\
    libRSDriver.vndk-sp\
    libRSCpuRef.vndk-sp\
    libbcinfo.vndk-sp\
    libblas.vndk-sp\
    libft2.vndk-sp\
    libpng.vndk-sp\
    libcompiler_rt.vndk-sp\
    libbacktrace.vndk-sp\
    libunwind.vndk-sp\
    liblzma.vndk-sp

#######for target product ########
PRODUCT_PROPERTY_OVERRIDES += \
    ro.target.product=tablet

# By default, enable zram; experiment can toggle the flag,
# which takes effect on boot
PRODUCT_PROPERTY_OVERRIDES += \
    persist.sys.zram_enabled=1

### fix adb-device cannot be identified  ###
### in AOSP-system image (user firmware) ###
ifneq (,$(filter userdebug eng,$(TARGET_BUILD_VARIANT)))
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    ro.logd.kernel=1
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/bin/rz:$(TARGET_COPY_OUT_VENDOR)/bin/rz \
    $(LOCAL_PATH)/bin/sz:$(TARGET_COPY_OUT_VENDOR)/bin/sz \
    $(LOCAL_PATH)/bin/picocom:$(TARGET_COPY_OUT_VENDOR)/bin/picocom
PRODUCT_PACKAGES += io
endif

USE_XML_AUDIO_POLICY_CONF := 1

PRODUCT_PROPERTY_OVERRIDES += \
       ro.usb.default_mtp=true

PRODUCT_PACKAGES += libstdc++.vendor

#TWRP
BOARD_TWRP_ENABLE ?= false

# add AudioSetting
PRODUCT_PACKAGES += \
    rockchip.hardware.rkaudiosetting@1.0-service \
    rockchip.hardware.rkaudiosetting@1.0-impl \
    rockchip.hardware.rkaudiosetting@1.0

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/rt_audio_config.xml:/system/etc/rt_audio_config.xml

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/rt_video_config.xml:/system/etc/rt_video_config.xml

#FLASH_IMG
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    ro.flash_img.enable=false

# Vendor seccomp policy files for media components:
PRODUCT_COPY_FILES += \
    device/rockchip/rm35k/seccomp_policy/mediacodec.policy:$(TARGET_COPY_OUT_VENDOR)/etc/seccomp_policy/mediacodec.policy

#bt config for ap bt
PRODUCT_COPY_FILES += \
    $(TARGET_DEVICE_DIR)/bluetooth/bt_vendor.conf:/vendor/etc/bluetooth/bt_vendor.conf

# Rockchip HALs
$(call inherit-product, device/rockchip/rm35k/manifests/frameworks/vintf.mk)
#for disable optee support
PRODUCT_PACKAGES += \
    android.hardware.keymaster@4.0-service \
    android.hardware.gatekeeper@1.0-service.software

DEVICE_MANIFEST_FILE += device/rockchip/rm35k/manifests/android.hardware.keymaster@4.0-service.xml

# RMX35K: VINTF manifest 检查关闭 (HAL 清单后续再补)
#
# ★ 严重副作用 (2026-09-26 定位): build/make/core/config.mk:705-713 会把
#   PRODUCT_ENFORCE_VINTF_MANIFEST 列为 PRODUCT_FULL_TREBLE 的 requirement 之一,
#   只要它的 *_OVERRIDE 是 false, PRODUCT_FULL_TREBLE 就会被强制降级为 false
#   —— 连上面第 515 行的 PRODUCT_FULL_TREBLE_OVERRIDE := true 也救不回来。
#   随之而来的连锁反应 (曾导致卡第二屏/黑屏重启, 排查了很久):
#     main.mk:202  -> /system/build.prop 写入 ro.treble.enabled=false
#     system/linkerconfig/modules/environment.cc:26 IsLegacyDevice() 判为 true
#     system/linkerconfig/main.cc:204 -> CreateLegacyConfiguration()
#     -> /linkerconfig/ld.config.txt 只有 [legacy]/[postinstall], 没有 [vendor]/[system]
#     -> vendor 的 AIDL HAL 在 legacy namespace 下找不到 VNDK APEX 里的
#        android.hardware.{power,light}-V1-ndk_platform.so
#     -> "CANNOT LINK EXECUTABLE ... not found" -> HAL 反复 exited with status 1
#     -> PowerManagerService.nativeInit() 阻塞 -> Watchdog 60s 杀 system_server
#
#   所以这里**不能**用 *_OVERRIDE := false 来关 VINTF 检查。
#   改为用 PRODUCT_ENFORCE_VINTF_MANIFEST 无关的方式关闭, 见下面两行。
#   (原实现保留在注释里以免后人再踩)
# PRODUCT_ENFORCE_VINTF_MANIFEST_OVERRIDE := false

# 保持 Treble 完整语义 (PRODUCT_FULL_TREBLE_OVERRIDE 已在第 515 行设为 true);
# VINTF 清单的实际校验由下面这条关掉, 它不参与 PRODUCT_FULL_TREBLE 的 requirement 计算。
# === A 修复 (2026-09-27): 恢复 VINTF manifest 校验 ===
#
# 【结论修正】上面那条 `PRODUCT_ENFORCE_VINTF_MANIFEST := false` 是**死代码**,
# 从来没生效过, 而且它描述的现象另有一个真正的解释:
#
#   build/make/core/config.mk:701-713 的 requirements 循环会**无条件改写**这个变量:
#       PRODUCT_ENFORCE_VINTF_MANIFEST := $(PRODUCT_FULL_TREBLE)   # OVERRIDE 为空时
#   而 PRODUCT_FULL_TREBLE_OVERRIDE 已是 true (第 515 行) -> FULL_TREBLE=true
#   -> enforce 被改写回 true。所以源码里写 false 也压不住它。
#
# 【真正的根因: 陈旧 .so】用 strings 对 libhidlbase.so 做了决定性验证
#   ('Potential race detected' 只出现在 !kEnforceVintfManifest 分支里,
#    若 enforce==true 常量折叠会**消除**该字符串):
#       fix9/system.img (实际刷进去的)  libhidlbase.so  mtime=09-25 01:24  race=1
#       刚重新编译的                     libhidlbase.so  mtime=09-27 00:27  race=0
#   即: 镜像里那份是 **treble=false 时代**编出来的陈旧产物, 一直没被重建。
#   这是增量构建的 stale artifact, 不是配置错误。
#
# 【为什么 enforce=true 是启动提速的关键】system/libhidl/transport/ServiceManagement.cpp:
#       if (!kEnforceVintfManifest) { ALOGE("Potential race detected…"); sleep(1); }
#   实测 'Potential race detected' 出现 **82 次**, 分布在 21 个进程
#   (surfaceflinger 独占 6 次, 且它在 4.9s 启动、zygote 8.6s 才开始 -> 直接推迟整条链)。
#   另外 enforce=false 会让找不到的 HAL 走 legacy 重试路径 (每次约 1 秒):
#       Thermal 试 2.0/1.1/1.0 = 3008ms, Location 试 gnss 2.1/2.0/1.1/1.0 = 4015ms
#   enforce=true 后: 缺失的 HAL **立即失败、不重试、不 sleep** -> 两条线一起消失。
#
# 所以这里**不再写任何 false**, 保持 config.mk 推导出的 true。
# (留此行仅为可读性; 与 config.mk 的推导结果一致, 不产生覆盖)
PRODUCT_ENFORCE_VINTF_MANIFEST := true

# RMX35K: VNDK / product VNDK 版本 —— 【已确认必须删除, 否则 soong 崩溃】
#
# 2026-09-26 22:28 实测: 打开这条会把 soong 直接打挂:
#   panic: duplicate module name:
#     android_product.30_arm64_armv8-a_cortex-a55  (external/minijail/Android.bp:104)
#   两个同名的 cc_genrule(libminijail_gen_constants) 在 product.30 变体下撞名,
#   blueprint.moduleSorter.Less 里 panic -> "soong bootstrap failed" -> 构建零产出。
#   (该产品的 Android.bp 用了 arch_variant, product VNDK 一变就复制出第二份变体)
#
# 而且它本来就是多余的:
#   * main.mk:239-243 它只写 ro.product.vndk.version, 与 ro.treble.enabled 无关
#     (ro.treble.enabled 来自 main.mk:202 的 PRODUCT_FULL_TREBLE, 已由 515 行保证)
#   * fix8/fix9 镜像都是在没有这条的情况下编出来的, 实机验证:
#       ro.treble.enabled=true
#       /linkerconfig/ld.config.txt = [system][vendor][product][unrestricted][postinstall]
#       vendor.light-rockchip / vendor.power-aidl-rockchip 都是 running
#       CANNOT LINK EXECUTABLE 计数 = 0
#   说明 linkerconfig 在没有 ro.product.vndk.version 时照样生成 product 命名空间。
#
# PRODUCT_PRODUCT_VNDK_VERSION := 30

# RMX35K: 动态分区 (super 3.26GB)
PRODUCT_USE_DYNAMIC_PARTITIONS := true
