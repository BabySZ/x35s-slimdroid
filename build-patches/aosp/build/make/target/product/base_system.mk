#
# Copyright (C) 2018 The Android Open Source Project
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

# Base modules and settings for the system partition.
PRODUCT_PACKAGES += \
    adbd_system_api \
    am \
    android.hidl.allocator@1.0-service \
    android.hidl.base-V1.0-java \
    android.hidl.manager-V1.0-java \
    android.hidl.memory@1.0-impl \
    android.hidl.memory@1.0-impl.vendor \
    android.system.suspend@1.0-service \
    android.test.base \
    android.test.mock \
    android.test.runner \
    apexd \
    appops \
    app_process \
    appwidget \
    atrace \
    audioserver \
    BackupRestoreConfirmation \
    bcc \
    blank_screen \
    blkid \
    service-blobstore \
    bmgr \
    bootanimation \
    bootstat \
    boringssl_self_test \
    bpfloader \
    bu \
    bugreport \
    bugreportz \
    cgroups.json \
    charger \
    cmd \
    com.android.adbd \
    com.android.conscrypt \
    com.android.extservices \
    com.android.i18n \
    com.android.ipsec \
    com.android.location.provider \
    com.android.media \
    com.android.media.swcodec \
    com.android.mediaprovider \
    com.android.os.statsd \
    com.android.permission \
    com.android.resolv \
    com.android.neuralnetworks \
    com.android.sdkext \
    com.android.tethering \
    com.android.tzdata \
    com.android.wifi \
    ContactsProvider \
    content \
    crash_dump \
    CtsShimPrebuilt \
    CtsShimPrivPrebuilt \
    debuggerd\
    device_config \
    dmctl \
    dnsmasq \
    DownloadProvider \
    dpm \
    dumpstate \
    dumpsys \
    DynamicSystemInstallationService \
    e2fsck \
    ExtShared \
    flags_health_check \
    framework-minus-apex \
    framework-res \
    framework-sysconfig.xml \
    fsck_msdos \
    fsverity-release-cert-der \
    fs_config_files_system \
    fs_config_dirs_system \
    group_system \
    gsid \
    gsi_tool \
    heapprofd \
    heapprofd_client \
    gatekeeperd \
    gpuservice \
    hid \
    hwservicemanager \
    idmap2 \
    idmap2d \
    ime \
    ims-common \
    incident \
    incidentd \
    incident_helper \
    incident-helper-cmd \
    init.environ.rc \
    init_system \
    input \
    installd \
    ip \
    iptables \
    ip-up-vpn \
    javax.obex \
    service-jobscheduler \
    keystore \
    credstore \
    ld.mc \
    libaaudio \
    libamidi \
    libandroid \
    libandroidfw \
    libandroid_runtime \
    libandroid_servers \
    libartpalette-system \
    libaudioeffect_jni \
    libbinder \
    libbinder_ndk \
    libc.bootstrap \
    libcamera2ndk \
    libcutils \
    libdl.bootstrap \
    libdl_android.bootstrap \
    libdrmframework \
    libdrmframework_jni \
    libEGL \
    libETC1 \
    libfdtrack \
    libFFTEm \
    libfilterfw \
    libgatekeeper \
    libGLESv1_CM \
    libGLESv2 \
    libGLESv3 \
    libgui \
    libhardware \
    libhardware_legacy \
    libinput \
    libinputflinger \
    libiprouteutil \
    libjnigraphics \
    libjpeg \
    liblog \
    libm.bootstrap \
    libmdnssd \
    libmedia \
    libmedia_jni \
    libmediandk \
    libmtp \
    libnetd_client \
    libnetlink \
    libnetutils \
    libneuralnetworks_packageinfo \
    libOpenMAXAL \
    libOpenSLES \
    libpdfium \
    libpower \
    libpowermanager \
    libradio_metadata \
    librtp_jni \
    libsensorservice \
    libsfplugin_ccodec \
    libskia \
    libsonic \
    libsonivox \
    libsoundpool \
    libspeexresampler \
    libsqlite \
    libstagefright \
    libstagefright_foundation \
    libstagefright_omx \
    libstdc++ \
    libsurfaceflinger \
    libsysutils \
    libui \
    libusbhost \
    libutils \
    libvulkan \
    libwilhelm \
    linker \
    linkerconfig \
    lmkd \
    LocalTransport \
    locksettings \
    logcat \
    logd \
    lpdump \
    lshal \
    mdnsd \
    mediacodec.policy \
    mediaextractor \
    mediametrics \
    media_profiles_V1_0.dtd \
    MediaProviderLegacy \
    mediaserver \
    mke2fs \
    monkey \
    mtpd \
    ndc \
    netd \
    NetworkStack \
    org.apache.http.legacy \
    otacerts \
    PackageInstaller \
    passwd_system \
    perfetto \
    ping \
    ping6 \
    platform.xml \
    pm \
    pppd \
    preinstalled-packages-platform.xml \
    privapp-permissions-platform.xml \
    racoon \
    recovery-persist \
    resize2fs \
    rss_hwm_reset \
    run-as \
    sanitizer.libraries.txt \
    schedtest \
    screencap \
    sdcard \
    secdiscard \
    selinux_policy_system \
    sensorservice \
    service \
    servicemanager \
    services \
    settings \
    SettingsProvider \
    sgdisk \
    Shell \
    shell_and_utilities_system \
    sm \
    snapshotctl \
    SoundPicker \
    storaged \
    surfaceflinger \
    svc \
    task_profiles.json \
    tc \
    telecom \
    telephony-common \
    tombstoned \
    traced \
    traced_probes \
    tune2fs \
    tzdatacheck \
    uiautomator \
    uncrypt \
    usbd \
    vdc \
    viewcompiler \
    voip-common \
    vold \
    WallpaperBackup \
    watchdogd \
    wm \

# ────────────────────────────────────────────────────────────────────────────
# R31 精简 (RMX35K): 删除 wificond / wifi.rc —— 本机无 WiFi 硬件
#   原先上面的清单里含 `wificond` 与 `wifi.rc` 两行 (现仅存于
#   /data/rmx35k_work/src_backup_r31_base_system.mk 备份中)。
#
#   为什么必须改这里: AOSP 11 **没有** PRODUCT_PACKAGES_remove
#   (已 grep build/make/core/product.mk, 0 命中), 且 wificond 在整个
#   build/make 里只出现在本文件与 emulator.mk:34, 故只能就地删。
#
#   安全性论证 —— 三条独立证据 (详见 /data/rmx35k_work/R31_WIFICOND_REMOVAL.md):
#     1) WifiService 从未启动: FEATURE_WIFI 已移除, SystemServer.java:1493
#        的 if 为假。设备实测 `service check wifi` -> "not found"。
#     2) 唯一消费者链已被切断: WifiInjector 仅由 WifiService.java:48 构造,
#        而 WifiInjector.java:233 是唯一非测试的
#        getSystemService(WIFI_NL80211_SERVICE) 调用点。
#        => WifiService 不启动 => wificond 无任何客户端。
#        设备实测: wificond 的 utime=2/stime=1 (纯空转), 0 个外部进程持有其 fd。
#     3) 无 VINTF 契约: /vendor/etc/vintf/manifest.xml 中 "wifi" 计数 = 0,
#        移除不会造成 VINTF 校验失败。
#
#   ★ 保留 com.android.wifi apex (:68 与 :336) 不动 —— 见下方说明。
#     它提供 framework-wifi.jar 里的 WifiManager / WifiNl80211Manager 等**类**,
#     SystemUI 与 Settings 静态链接这些类; 删 apex 会 NoClassDefFoundError。
#     本次只删"无对应硬件的守护进程 + 其 init 脚本", 不删类库。
#
#   注: `init_rc: ["wificond.rc"]` 定义在 system/connectivity/wificond/Android.bp,
#   即 wificond.rc 随 wificond 模块一并安装/移除; wifi.rc 则是独立 prebuilt_etc。
#   两者都已从上方清单移除, 故设备上将不留任何 wifi init 脚本。
# ────────────────────────────────────────────────────────────────────────────

# VINTF data for system image
PRODUCT_PACKAGES += \
    system_manifest.xml \
    system_compatibility_matrix.xml \

# Host tools to install
PRODUCT_HOST_PACKAGES += \
    BugReport \
    adb \
    art-tools \
    atest \
    bcc \
    bit \
    e2fsck \
    fastboot \
    flags_health_check \
    icu-data_host_i18n_apex \
    icu_tzdata.dat_host_tzdata_apex \
    idmap2 \
    incident_report \
    ld.mc \
    lpdump \
    mdnsd \
    minigzip \
    mke2fs \
    resize2fs \
    sgdisk \
    sqlite3 \
    tinyplay \
    tune2fs \
    tzdatacheck \
    unwind_info \
    unwind_reg_info \
    unwind_symbols \
    viewcompiler \
    tzdata_host \
    tzdata_host_tzdata_apex \
    tzlookup.xml_host_tzdata_apex \
    tz_version_host \
    tz_version_host_tzdata_apex \

ifeq ($(ART_APEX_JARS),)
$(error ART_APEX_JARS is empty; cannot initialize PRODUCT_BOOT_JARS variable)
endif

# The order matters for runtime class lookup performance.
PRODUCT_BOOT_JARS := \
    $(ART_APEX_JARS) \
    framework-minus-apex \
    ext \
    telephony-common \
    voip-common \
    ims-common

PRODUCT_UPDATABLE_BOOT_JARS := \
    com.android.conscrypt:conscrypt \
    com.android.media:updatable-media \
    com.android.mediaprovider:framework-mediaprovider \
    com.android.os.statsd:framework-statsd \
    com.android.permission:framework-permission \
    com.android.sdkext:framework-sdkextensions \
    com.android.wifi:framework-wifi \
    com.android.tethering:framework-tethering

PRODUCT_COPY_FILES += \
    system/core/rootdir/init.usb.rc:system/etc/init/hw/init.usb.rc \
    system/core/rootdir/init.usb.configfs.rc:system/etc/init/hw/init.usb.configfs.rc \
    system/core/rootdir/etc/hosts:system/etc/hosts

# Add the compatibility library that is needed when android.test.base
# is removed from the bootclasspath.
# Default to excluding android.test.base from the bootclasspath.
ifneq ($(REMOVE_ATB_FROM_BCP),false)
PRODUCT_PACKAGES += framework-atb-backward-compatibility
PRODUCT_BOOT_JARS += framework-atb-backward-compatibility
else
PRODUCT_BOOT_JARS += android.test.base
endif

PRODUCT_COPY_FILES += system/core/rootdir/init.zygote32.rc:system/etc/init/hw/init.zygote32.rc
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += ro.zygote=zygote32

PRODUCT_SYSTEM_DEFAULT_PROPERTIES += debug.atrace.tags.enableflags=0
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += persist.traced.enable=1

# Packages included only for eng or userdebug builds, previously debug tagged
PRODUCT_PACKAGES_DEBUG := \
    adb_keys \
    arping \
    idlcli \
    init-debug.rc \
    iotop \
    iperf3 \
    iw \
    logpersist.start \
    logtagd.rc \
    procrank \
    remount \
    showmap \
    sqlite3 \
    ss \
    start_with_lockagent \
    su \
    sanitizer-status \
    tracepath \
    tracepath6 \
    traceroute6 \
    unwind_info \
    unwind_reg_info \
    unwind_symbols \

# The set of packages whose code can be loaded by the system server.
PRODUCT_SYSTEM_SERVER_APPS += \
    SettingsProvider \
    WallpaperBackup

# Packages included only for eng/userdebug builds, when building with SANITIZE_TARGET=address
PRODUCT_PACKAGES_DEBUG_ASAN := \
    fuzz \
    honggfuzz

PRODUCT_PACKAGES_DEBUG_JAVA_COVERAGE := \
    libdumpcoverage

PRODUCT_COPY_FILES += $(call add-to-product-copy-files-if-exists,\
    frameworks/base/config/preloaded-classes:system/etc/preloaded-classes)

# Note: it is acceptable to not have a dirty-image-objects file. In that case, the special bin
#       for known dirty objects in the image will be empty.
PRODUCT_COPY_FILES += $(call add-to-product-copy-files-if-exists,\
    frameworks/base/config/dirty-image-objects:system/etc/dirty-image-objects)

$(call inherit-product, $(SRC_TARGET_DIR)/product/runtime_libart.mk)
