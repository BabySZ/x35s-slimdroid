#
# RMX35K (rk3566_rm700k) BoardConfig — 基于官方 dtb/分区/内核配置
-include device/rockchip/rm35k-kernel/BoardConfigKernel.mk

# RMX35K: 从设备原厂 boot.img 提取的 LCD resource (RSCE 格式)
TARGET_PREBUILT_RESOURCE := device/rockchip/rm35k/resource.img
include device/rockchip/rm35k/BoardConfigCommon.mk # RMX35K: 引入通用 RK 配置 (动态分区尺寸/sepolicy等)
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := cortex-a55
TARGET_CPU_SMP := true

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-2a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 :=
TARGET_2ND_CPU_VARIANT := cortex-a55

TARGET_BOARD_PLATFORM_PRODUCT := tablet
TARGET_BOARD_PLATFORM := rk356x
TARGET_BOARD_PLATFORM_GPU := mali-G52
TARGET_RK_GRALLOC_VERSION := 4

BUILD_EMULATOR := false
BOARD_USE_DRM := true
TARGET_USES_64_BIT_BINDER := true

# --- RMX35K 特化: 无 wifi/bt/触摸/GPS, 640x480 竖屏? (横屏 480x640)
BOARD_HAS_WIFI := false
BOARD_HAS_BLUETOOTH := false
BOARD_HAS_GPS := false
TARGET_NO_TOUCH := true

# 屏幕
TARGET_SCREEN_WIDTH := 480
TARGET_SCREEN_HEIGHT := 640

# 内核/dtb: 官方 boot.img second 区 dtb 原样回填
BOARD_INCLUDE_DTB_IN_BOOTIMG := true
BOARD_PREBUILT_DTBIMAGE_DIR := device/rockchip/rm35k-kernel/dtb

# 分区 (与设备实测一致: system 932M 动态, eMMC 3.69G)
BOARD_AVB_ENABLE := false
# BOARD_BUILD_SYSTEM_ROOT_IMAGE 删除: 动态分区设备不允许 (system.img 挂载为 /)
BOARD_USES_RECOVERY_AS_BOOT := false

# SELinux: 厂商 permissive userdebug
SELINUX_IGNORE_NEVERALLOWS := true

# RMX35K: VINTF 检查暂关 (vendor manifest 待按设备实际 HAL 修正后开启)

# RMX35K: super 2044MiB (原厂 1532MiB + 从 backup/cache 各回收 256MiB)
# 原厂权威值 = LBA 1945600..5083135 (3137536 扇区 = 1606418432 B)
# 方案 B (激进, 2026-09-25 定稿): super 缩到 1344 MiB, 把 backup/cache 的
# 冗余空间全部让给 userdata。super 实测内容仅 1290.1 MiB (lpdump), 留 54 MiB 余量。
#   旧: super 2044 MiB / backup 128 / cache 128 / userdata @0x4D9000 (1294 MiB)
#   新: super 1344 MiB / backup   8 / cache  16 / userdata @0x2F5000 (2262 MiB)
BOARD_SUPER_PARTITION_GROUPS := rockchip_dynamic_partitions
# 设备 super 实际含 system/system_ext/vendor/product/odm 五个子分区 (lpdump 实测),
# 必须全部列出, 否则 system_ext/product 不会被打进 super, 开机 first_stage_mount 失败
# (原厂 super 里那个无人引用的 scratch 分区已正确剔除)
BOARD_ROCKCHIP_DYNAMIC_PARTITIONS_PARTITION_LIST := system system_ext vendor product odm
BOARD_SUPER_PARTITION_METADATA_DEVICE := super

# RMX35K: super 1344 MiB = 1409286144 B, 组上限 = super - 4MiB metadata
BOARD_SUPER_PARTITION_SIZE := 1409286144
BOARD_ROCKCHIP_DYNAMIC_PARTITIONS_SIZE := 1405091840

# RMX35K: 动态分区各子分区文件系统
# 注意: 这里声明的 *_FILE_SYSTEM_TYPE 决定该子分区是否真的会生成独立镜像。
# board_config.mk 的逻辑是: PRODUCT_BUILD_<X>_IMAGE 为空时, 只要
# BOARD_<X>IMAGE_FILE_SYSTEM_TYPE 有定义就置 BUILDING_<X>_IMAGE := true。
# 原厂 super 实测(lpdump)含 5 个子分区 system/system_ext/vendor/product/odm,
# 设备 fstab_rm35k.in 也在 first_stage_mount 挂载 /product 与 /system_ext,
# 因此这两个必须建独立镜像; 漏掉它们会导致 check_all_partition_sizes 读到空路径
# ("IOError: No such file or directory: ''") 而中断打包。
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_ODMIMAGE_FILE_SYSTEM_TYPE := ext4
# product / system_ext 必须是顶层目录 (TARGET_COPY_OUT_* = product/system_ext),
# 这样 system/ 下会生成指向 /product、/system_ext 的符号链接, 内容才能独立成像。
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := ext4
TARGET_COPY_OUT_PRODUCT := product
BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE := ext4
TARGET_COPY_OUT_SYSTEM_EXT := system_ext

