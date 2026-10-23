# RMX35K device 主清单
PRODUCT_CHARACTERISTICS := tablet

# vendor blobs (从设备提取, 位于 vendor/rockchip/rm35k)
$(call inherit-product-if-exists, vendor/rockchip/rm35k/device-vendor.mk)

# --- 音量键修复: 无需补丁 ---------------------------------------------
# 原厂固件在 PhoneWindowManager 里打了 "volume keycode" hack 吞掉 KEYCODE 24/25。
# 本 AOSP 树是干净源码, 不存在该 hack, 音量键走标准路径 -> 天然正常。
# (2026-09-25 已 grep 确认 frameworks/base 无 'volume keycode' 字符串)

# --- LED 指示灯修复: 直接二进制修补原厂内核, 无任何外挂模块 ----------------
# 目标: 非充电=全灭 / 充电中=黄(橙) / 满电插电=只绿 / 红灯永不使用
#
# 出厂内核的反逻辑 (由 arm64 反汇编确认, 见 rk817_charger.c 与 my_work_func):
#   插电 & 满电  -> red=0 green=1 yellow=1   绿+黄   (应: 只绿)
#   未插电 & >=20% -> red=0 green=1 yellow=0 常亮绿  (应: 全灭)
#   未插电 & <20%  -> 红闪 (my_work_func 1s 翻转)     (应: 全灭)
#
# 修复方式: 对 device/rockchip/rm35k-kernel/kernel (arm64 Image, 加载基址
#   0xffffff8008080000 == _text, 文件偏移 = 虚拟地址 - 基址) 就地打 4 处
#   指令补丁, 见 /data/rmx35k_work/kpatch/apply_led_patch.py:
#     0x09ce150  usb_get_property 满电分支   yellow=1 -> yellow=0
#     0x09ce1ec  usb_get_property 未插电分支 green=1  -> green=0
#     0x09cdd2c  charge_probe     未插电分支 green=1  -> green=0
#     0x09cdf68  my_work_func     cbz -> b (永久跳过红闪循环; 红灯保持工厂
#                                 已置的 0, 因而不亮)
#
# 为什么用二进制补丁而不是重编内核:
#   * 重编 x55 内核树会得到 vermagic "4.19.219+" (多了 '+' 号, 来自 .git),
#     mali_kbase.ko / 8821cs.ko 会 refuse to load -> 卡第二屏;
#   * x55 树缺本机 DTB 需要的触摸屏 compatible (GSL,GSL3676) 与
#     LT9211/MIR3DA/SW_2001 等配置, 无法直接替换;
#   * 就地补丁只改 15 字节, vermagic / 版本串 / 符号表全部不变, 风险最低。
#
# 已废弃的旧"外挂模块"方案 (rk817_lsm.ko + load_led_lsm.sh + led_lsm.rc):
#   * 依赖厂商内核私有符号 redled_work/led_*_store 的运行时地址;
#   * 需要 300ms 定时器对抗 rk817_battery_work 每 ~5.1s 直接写 GPIO 黄=1,
#     结果仍有约 800ms 的橙色闪灯窗口 (实测 90 次采样中 5 次错误);
#   * 属补丁摞补丁, 已彻底弃用。相关源文件保留在 vendor/rockchip/rm35k/
#     仅供追溯, **不会**被打进镜像。
# 因此这里不拷贝任何 .ko / .sh / .rc, 也不存在 /system/etc/init/led_lsm.rc。

# --- 掌机按键布局 (十字键 + MODE 退出键) --------------------------------
# 设备实测 Generic.kl = vendor 定制版 (453 行, md5 47001b5a...);
# AOSP 原版只有 445 行, 缺 BTN_DPAD_* (key 544-547) 映射 -> 十字键会失灵。
#
# ⚠️ 静默覆盖陷阱 (2026-09-25 实测踩中):
#   frameworks/base/data/keyboards/keyboards.mk 里有
#       framework_keylayouts := $(wildcard $(LOCAL_PATH)/*.kl)
#       PRODUCT_COPY_FILES := $(foreach f,$(framework_keylayouts),f:system/usr/keylayout/$(notdir f))
#   它会把自己目录下 **所有** *.kl 都装到 system/usr/keylayout/, 其中就包含一个
#   Generic.kl —— 目标路径与本文件下面这行完全相同。两个 PRODUCT_COPY_FILES
#   指向同一目标时, build 系统只保留一个, 而 keyboards.mk 经由
#   handheld_system.mk 继承, 实际胜出的是 AOSP 那版 445 行文件,
#   我们的 453 行被静默丢弃 (构建日志无任何警告, staging 里就是 445 行)。
#   这正是"编译成功但内容不对且不报错"的典型。
# 因此除了下面这行, 还必须把定制版同步覆盖到框架源文件本身:
#   frameworks/base/data/keyboards/Generic.kl   (已覆盖, md5 47001b5a...)
# 两处内容一致 => 无论谁胜出结果都正确。改动框架源文件是必需的, 因为
# keyboards.mk 用的是 wildcard, 无法从 device 侧排除单个文件。
PRODUCT_COPY_FILES += \
    vendor/rockchip/rm35k/Generic.kl:$(TARGET_COPY_OUT_SYSTEM)/usr/keylayout/Generic.kl

# 音量键 daemon workaround —— **不启用**
# framework 已是标准音量逻辑, 再跑 voldaemon 会一键跳两格 (历史已踩坑)。
# 若确需, 取消下面注释即可。
# PRODUCT_COPY_FILES += \
#    vendor/rockchip/rm35k/voldaemon.sh:$(TARGET_COPY_OUT_SYSTEM)/bin/voldaemon.sh \
#    vendor/rockchip/rm35k/voldaemon.rc:$(TARGET_COPY_OUT_SYSTEM)/etc/init/voldaemon.rc

# 预编译内核 (原厂内核 4.19.219 #126 + 官方 dtb)
# ⚠️ 注意: 该 kernel 已由 /data/rmx35k_work/kpatch/apply_led_patch.py 就地打过
#   LED 逻辑补丁, md5 应为 4f8f358d57e9a04c497ae733cb395412 (原厂为
#   968740b0e666d376d866a804ea80a5bf)。构建前请用
#   /data/rmx35k_work/build_boot_patched.sh 重建, 该脚本带 md5 守卫,
#   内核既非原厂也非补丁版时会直接失败, 避免"编译成功但产物不对"。
TARGET_PREBUILT_KERNEL := device/rockchip/rm35k-kernel/kernel
BOARD_PREBUILT_DTB := device/rockchip/rm35k-kernel/dtb/boot.dtb
PRODUCT_COPY_FILES += \
    device/rockchip/rm35k-kernel/kernel:kernel

# --- boot ramdisk 里的 fstab.rk30board (首阶段挂载必需) ------------------
# 陷阱 (2026-09-25 实测): 之前刷进去的 boot.img 卡在第一屏, 除了内核错树,
# 还有一个**独立**缺陷 —— boot ramdisk 里没有 fstab.rk30board。
#
# 原因链:
#   RebuildFstab.mk 整个文件被 `ifdef PRODUCT_FSTAB_TEMPLATE` 包住;
#   本产品从未定义该变量 => 文件体被完全跳过 =>
#   INSTALLED_RK_RAMDISK_FSTAB 规则不存在 => $(PRODUCT_OUT)/ramdisk/ 下
#   永远不会出现 fstab.rk30board (实测只有 debug_ramdisk/ dev/ init mnt/ proc/ sys/)。
#   (整个树里只有 device/pine64/pinenote 定义了 PRODUCT_FSTAB_TEMPLATE)
#
# 为什么必须放在 ramdisk 根:
#   GetFstabPath() (system/core/fs_mgr/fs_mgr_fstab.cpp:408) 按
#     /odm/etc/fstab.<suffix> -> /vendor/etc/fstab.<suffix> -> /fstab.<suffix>
#   顺序查找, suffix 取自 androidboot.hardware=rk30board。
#   first_stage_mount 发生在 /vendor 挂载**之前**, 此时只有 ramdisk 可见,
#   因此 vendor/etc/fstab.rk30board 救不了首阶段 —— 必须 ramdisk 根有一份。
#
# 这里用 PRODUCT_COPY_FILES 直接落到 $(TARGET_COPY_OUT_RAMDISK) (= ramdisk),
# 会被 Makefile:1134 的 INTERNAL_RAMDISK_FILES := $(filter $(TARGET_RAMDISK_OUT)/%,...)
# 自动收进 ramdisk.img, 绕开 RebuildFstab.mk。
#
# 内容与验证过的原厂 fstab.rk30board 逐字节一致 (md5 b6d2e43dbcfffa6b492abb11a19ffdf3):
# system/vendor/odm/product/system_ext 用 wait,logical,first_stage_mount
# (logical 对应 super 动态分区, 与原厂相同) + metadata 首阶段 + data/cache。
PRODUCT_COPY_FILES += \
    vendor/rockchip/rm35k/etc/fstab.rk30board:$(TARGET_COPY_OUT_RAMDISK)/fstab.rk30board

# --- recovery ramdisk: 恢复 USB 逃生通道 (2026-09-26 实测踩中) ---------------
# 症状: 自建方案B 的 recovery 刷进去之后 **USB 完全不枚举**
#       (既没有 18d1:d001 recovery adb, 也没有 fastboot), 设备变砖后
#       只能拆机/上 TF 卡整盘刷, 没有任何设备端通道可以救援。
#
# 根因 (两处, 都是 PRODUCT_COPY_FILES 缺失, 构建系统**不报错**):
#   1) recovery ramdisk 的 init.rc 第一行是
#          import /init.recovery.${ro.hardware}.rc
#      本机 ro.hardware=rk30board, 因此它需要 /init.recovery.rk30board.rc,
#      而该文件正是设置 USB controller 的地方:
#          setprop sys.usb.controller "fcc00000.dwc3"
#          setprop sys.usb.configfs 1
#      没有它 -> sys.usb.controller 为空 ->
#      init.usb.configfs.rc 里 `write .../UDC ${sys.usb.controller}` 写空值 ->
#      UDC 从未绑定 -> adbd 起来了但 USB gadget 不工作 -> 电脑侧什么都看不到。
#   2) recovery 的 fstab 也缺失。Makefile:2075 只在定义了 TARGET_RECOVERY_FSTAB
#      时才用, 否则 wildcard $(TARGET_DEVICE_DIR)/recovery.fstab —— 而我们的
#      recovery.fstab 放在 init/ 子目录, 不在设备根目录, wildcard 落空 ->
#      recovery 认不出任何分区 (super/metadata/userdata 全不可见)。
#
# 对照: device/pine64/pinenote/device.mk:44 有这一行, 我们当初漏了。
# 修复: 显式把这两个文件装进 recovery/root。
# 自检: 构建后 recovery/root/init.recovery.rk30board.rc 与
#       recovery/root/system/etc/recovery.fstab 必须存在, 且前者含
#       sys.usb.controller —— 见 /data/rmx35k_work/check_recovery_ramdisk.sh
PRODUCT_COPY_FILES += \
    device/rockchip/rm35k/init/init.recovery.rk30board.rc:recovery/root/init.recovery.rk30board.rc \
    device/rockchip/rm35k/init/recovery.fstab:recovery/root/system/etc/recovery.fstab

# --- vendor 图形/显示属性: 补齐原厂有而我们缺的 (2026-09-26) ----------------
# 实测对比: 原厂 vendor/build.prop 里有下列属性, 自建方案B **一个都没有**。
# 它们都由 pinenote 的 device.mk 显式设置, 而 rm35k 当初从 pinenote 派生时
# 整段漏掉了 —— 属于"没写就没写, 构建系统不报错"的静默缺失。
#
# 最可疑的是 vendor.hwc.compose_policy 与 ro.opengles.version:
#   * hwcomposer.rk30board.so 读 vendor.hwc.compose_policy 决定合成策略
#     (0/1/2 走不同路径), 缺失时取默认值, 与原厂行为不一致;
#   * ro.opengles.version 缺失会让 hwui/EGL 初始化时拿不到 GLES 版本,
#     可能在 SurfaceFlinger 起来之后、应用绘制第一帧时卡住 ——
#     症状恰好是"卡第二屏、不重启"。
# 其余为显示密度/旋转/帧率锁等, 与原厂保持一致以消除变量。
#
# 值逐条取自原厂 vendor/build.prop (已确认存在), 不是我编的。
PRODUCT_PROPERTY_OVERRIDES += \
    ro.opengles.version=196610 \
    vendor.hwc.compose_policy=1 \
    ro.sf.lcd_density=160 \
    ro.sf.fakerotation=false \
    sys.resolution.changed=false \
    ro.vendor.frameratelock=true \
    sf.power.control=2073600 \
    vendor.gralloc.disable_afbc=0 \
    debug.hwui.use_partial_updates=false \
    ro.vendor.sdkversion=rk356x_ANDROID10.0_MID_V1.0 \
    ro.product.first_api_level=30

# --- 开机动画: 黑底 + 版本指纹 + 走秒计数 (用户要求, 便于判断卡在哪一步) -------
# 背景: 原厂的开机动画在 /odm/media/bootanimation.zip, debloat 时被删掉,
#       自建方案B **完全没有** bootanimation.zip ->
#       SurfaceFlinger 起来后 bootanimation 找不到 zip 就退回 AOSP 默认
#       "android" 文字动画, 无法区分是哪一版镜像、卡在哪个阶段。
#
# 查找顺序 (frameworks/base/cmds/bootanimation/BootAnimation.cpp:543-546):
#   /apex/com.android.bootanimation/etc/bootanimation.zip
#   /product/media/bootanimation.zip        <- 优先级高于 system
#   /oem/media/bootanimation.zip
#   /system/media/bootanimation.zip
#
# ★ 2026-09-26 v5 改动: 从 product 改放 **system**, 原因:
#   1) product 分区只剩 140 KB (Free blocks=35 x 4096), 而带"走秒计数"的
#      诊断动画是 151 KB, 塞不进; system 尚有 2.7 MB。
#   2) 旧的静态版动画在 v2/v3/v4 里**完全相同**, 画面上分不出跑的是哪一版,
#      也无法判断"系统还在启动"还是"已经卡死" —— 这正是"卡第二屏"这个
#      描述长期含糊的根源。新版 part0 打出版本/两条根因修复状态/内核 md5,
#      part1 是**会走秒的数字**: 数字在动=还在启动; 数字冻住=卡死在这一阶段。
#   ==> 因此 **product 里那份必须删掉**, 否则它优先级更高会把新版盖住。
#
# 打包要求: desc.txt 在 zip 根, 且必须 **STORED 不压缩**,
#           否则 loadAnimation 读不到 -> 生成脚本已保证。
# 生成脚本: /data/rmx35k_work/bootanim/make_bootanim_v3_clock.py
# 校验: unzip -l 应见 desc.txt 在根; 且 zip 内 method=0 (stored)
#
# ★ 2026-09-27 v3 改动: 黑白风格 + **实时时钟**
#   part0 = 版本指纹 (enforce on/off、services trimmed、kernel md5)
#   part1 = 极简表盘 (60 帧走秒装饰) + desc.txt 叠加**真实时间** HH:MM
#   时钟来自 RTC (/dev/rtc0, 内核 hctosys), 不是预渲染。
#   desc.txt 末行: `p 0 0 part1 #000000 c -100`
#     c    = 水平居中
#     -100 = 距顶部 100 px   (parsePosition/drawText 的负值语义)
#   字形取自 core/res/assets/images/clock_font.png (640x576 => 40x48/字符,
#   只含数字与冒号, 正好够 "HH:MM")。该文件已打进 zip 根 (clock_font.png)。
#   布局核算: 时钟 100..148, 表盘 195..405, 底部文字 435..480, 互不重叠。
PRODUCT_COPY_FILES += \
    vendor/rockchip/rm35k/media/bootanimation.zip:$(TARGET_COPY_OUT_SYSTEM)/media/bootanimation.zip
