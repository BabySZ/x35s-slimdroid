#
# Copyright 2014 The Android Open-Source Project
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
#binder protocol(8)
TARGET_USES_64_BIT_BINDER := true
TARGET_BOARD_HARDWARE := rk30board
# value: tablet,box,phone
# It indicates whether to be tablet platform or not

# Export this prop for Mainline Modules.
ROCKCHIP_LUNCHING_API_LEVEL := $(PRODUCT_SHIPPING_API_LEVEL)

TARGET_BOARD_PLATFORM_PRODUCT ?= tablet

BOARD_PLATFORM_VERSION := 11.0

# Enable android verified boot 2.0
BOARD_AVB_ENABLE ?= false
BOARD_BOOT_HEADER_VERSION ?= 2
BOARD_MKBOOTIMG_ARGS :=
BOARD_PREBUILT_DTBOIMAGE ?= $(TARGET_DEVICE_DIR)/dtbo.img
BOARD_ROCKCHIP_VIRTUAL_AB_ENABLE ?= false
BOARD_SELINUX_ENFORCING ?= false

PRODUCT_PARAMETER_TEMPLATE ?= device/rockchip/common/scripts/parameter_tools/parameter.in
TARGET_BOARD_HARDWARE_EGL ?= mali

ifeq ($(TARGET_BUILD_VARIANT), user)
PRODUCT_KERNEL_CONFIG += non_debuggable.config
endif

ifeq ($(BOARD_AVB_ENABLE), true)
BOARD_KERNEL_CMDLINE := androidboot.hardware=rk30board androidboot.console=ttyFIQ0 firmware_class.path=/vendor/etc/firmware init=/init rootwait ro init=/init
else # BOARD_AVB_ENABLE is false
BOARD_KERNEL_CMDLINE := console=ttyFIQ0 androidboot.veritymode=enforcing androidboot.hardware=rk30board androidboot.console=ttyFIQ0 android.wificountrycode=CN androidboot.verifiedbootstate=orange firmware_class.path=/vendor/etc/firmware init=/init rootwait ro
endif # BOARD_AVB_ENABLE

BOARD_KERNEL_CMDLINE += loop.max_part=7
ROCKCHIP_RECOVERYIMAGE_CMDLINE_ARGS ?= console=ttyFIQ0 androidboot.baseband=N/A androidboot.selinux=permissive androidboot.wificountrycode=CN androidboot.veritymode=enforcing androidboot.hardware=rk30board androidboot.console=ttyFIQ0 firmware_class.path=/vendor/etc/firmware init=/init root=PARTUUID=af01642c-9b84-11e8-9b2a-234eb5e198a0

ifneq ($(BOARD_SELINUX_ENFORCING), true)
BOARD_KERNEL_CMDLINE += androidboot.selinux=permissive
endif

# For Header V2, set resource.img as second.
BOARD_MKBOOTIMG_ARGS += --second $(TARGET_PREBUILT_RESOURCE)
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)

BOARD_RECOVERY_MKBOOTIMG_ARGS ?= --second $(TARGET_PREBUILT_RESOURCE) --header_version 2
ifeq ($(BOARD_AVB_ENABLE), true)
BOARD_AVB_RECOVERY_KEY_PATH ?= external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_RECOVERY_ALGORITHM ?= SHA256_RSA4096
BOARD_AVB_RECOVERY_ROLLBACK_INDEX ?= $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_RECOVERY_ROLLBACK_INDEX_LOCATION ?= 2
endif

BOARD_INCLUDE_RECOVERY_DTBO ?= true
BOARD_INCLUDE_DTB_IN_BOOTIMG ?= true

# Add standalone metadata partition
BOARD_USES_METADATA_PARTITION ?= true

# Add standalone odm partition configrations
TARGET_COPY_OUT_ODM := odm
BOARD_ODMIMAGE_FILE_SYSTEM_TYPE ?= ext4

# Add standalone vendor partition configrations
TARGET_COPY_OUT_VENDOR := vendor
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE ?= ext4

# default.prop & build.prop split
BOARD_PROPERTY_OVERRIDES_SPLIT_ENABLED ?= true

# ⚠️ 2026-09-26 修复: 原来这里是 `:=`, 但 BoardConfig*.mk 的解析时机**晚于**
#    产品 makefile (common.mk)。于是 common.mk 里那三条
#        DEVICE_MANIFEST_FILE += graphics.mapper@4.0 / graphics.allocator@4.0 / keymaster
#    全被这里的 `:=` 覆盖丢弃 -> 最终 vendor manifest 只剩 manifest.xml 一个输入,
#    /vendor/etc/vintf/manifest.xml 里**没有** graphics.allocator 和 graphics.mapper
#    (原厂有)。改用 `+=` 追加, 这样 4 个输入都会进入合并。
DEVICE_MANIFEST_FILE += device/rockchip/rm35k/manifest.xml
DEVICE_MATRIX_FILE   += device/rockchip/rm35k/compatibility_matrix.xml

#Calculate partition size from parameter.txt
USE_DEFAULT_PARAMETER := $(shell test -f $(TARGET_DEVICE_DIR)/parameter.txt && echo true)
ifeq ($(strip $(USE_DEFAULT_PARAMETER)), true)
  ifeq ($(PRODUCT_USE_DYNAMIC_PARTITIONS), true)
    BOARD_SUPER_PARTITION_SIZE := $(shell python device/rockchip/common/get_partition_size.py $(TARGET_DEVICE_DIR)/parameter.txt super)
    BOARD_ROCKCHIP_DYNAMIC_PARTITIONS_SIZE := $(shell expr $(BOARD_SUPER_PARTITION_SIZE) - 4194304)
  else
    BOARD_SYSTEMIMAGE_PARTITION_SIZE := $(shell python device/rockchip/common/get_partition_size.py $(TARGET_DEVICE_DIR)/parameter.txt system)
    BOARD_VENDORIMAGE_PARTITION_SIZE := $(shell python device/rockchip/common/get_partition_size.py $(TARGET_DEVICE_DIR)/parameter.txt vendor)
    BOARD_ODMIMAGE_PARTITION_SIZE := $(shell python device/rockchip/common/get_partition_size.py $(TARGET_DEVICE_DIR)/parameter.txt odm)
  endif
  BOARD_CACHEIMAGE_PARTITION_SIZE := $(shell python device/rockchip/common/get_partition_size.py $(TARGET_DEVICE_DIR)/parameter.txt cache)
  BOARD_BOOTIMAGE_PARTITION_SIZE := $(shell python device/rockchip/common/get_partition_size.py $(TARGET_DEVICE_DIR)/parameter.txt boot)
  BOARD_DTBOIMG_PARTITION_SIZE := $(shell python device/rockchip/common/get_partition_size.py $(TARGET_DEVICE_DIR)/parameter.txt dtbo)
  BOARD_RECOVERYIMAGE_PARTITION_SIZE := $(shell python device/rockchip/common/get_partition_size.py $(TARGET_DEVICE_DIR)/parameter.txt recovery)
  # Header V3, add vendor_boot
  ifeq (1,$(strip $(shell expr $(BOARD_BOOT_HEADER_VERSION) \>= 3)))
    BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := $(shell python device/rockchip/common/get_partition_size.py $(TARGET_DEVICE_DIR)/parameter.txt vendor_boot)
  endif
  #$(info Calculated BOARD_SYSTEMIMAGE_PARTITION_SIZE=$(BOARD_SYSTEMIMAGE_PARTITION_SIZE) use $(TARGET_DEVICE_DIR)/parameter.txt)
else
  ifeq ($(PRODUCT_USE_DYNAMIC_PARTITIONS), true)
    ifeq ($(BUILD_WITH_GO_OPT), true)
      BOARD_SUPER_PARTITION_SIZE ?= 2516582400
    else
      BOARD_SUPER_PARTITION_SIZE ?=  3263168512
    endif
    BOARD_ROCKCHIP_DYNAMIC_PARTITIONS_SIZE ?= $(shell expr $(BOARD_SUPER_PARTITION_SIZE) - 4194304)
  else
    BOARD_SYSTEMIMAGE_PARTITION_SIZE ?= 2726297600
    BOARD_VENDORIMAGE_PARTITION_SIZE ?= 402653184
    BOARD_ODMIMAGE_PARTITION_SIZE ?= 134217728
  endif
  BOARD_CACHEIMAGE_PARTITION_SIZE ?= 402653184
  BOARD_BOOTIMAGE_PARTITION_SIZE ?= 33554432
  BOARD_RECOVERYIMAGE_PARTITION_SIZE ?= 100663296
  BOARD_DTBOIMG_PARTITION_SIZE ?= 4194304
  # Header V3, add vendor_boot
  ifeq (1,$(strip $(shell expr $(BOARD_BOOT_HEADER_VERSION) \>= 3)))
    BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE ?= 41943040
  endif
  ifneq ($(strip $(TARGET_DEVICE_DIR)),)
    #$(info $(TARGET_DEVICE_DIR)/parameter.txt not found! Use default BOARD_SYSTEMIMAGE_PARTITION_SIZE=$(BOARD_SYSTEMIMAGE_PARTITION_SIZE))
  endif
endif

# GPU configration
GRAPHIC_MEMORY_PROVIDER ?= ump
USE_OPENGL_RENDERER ?= true
TARGET_DISABLE_TRIPLE_BUFFERING ?= false
TARGET_RUNNING_WITHOUT_SYNC_FRAMEWORK ?= false

DEVICE_HAVE_LIBRKVPU ?= true

#rotate screen to 0, 90, 180, 270
#0:   ROTATION_NONE      ORIENTATION_0  : 0
#90:  ROTATION_RIGHT     ORIENTATION_90 : 90
#180: ROTATION_DOWN    ORIENTATION_180: 180
#270: ROTATION_LEFT    ORIENTATION_270: 270
# For Recovery Rotation
TARGET_RECOVERY_DEFAULT_ROTATION ?= ROTATION_NONE

#Screen to Double, Single
#YES: Screen to Double
#NO: Screen to single
DOUBLE_SCREEN ?= NO

VENDOR_SECURITY_PATCH := $(PLATFORM_SECURITY_PATCH)

TARGET_BOOTLOADER_BOARD_NAME ?= rk30sdk
TARGET_NO_BOOTLOADER ?= true

TARGET_RELEASETOOLS_EXTENSIONS := device/rockchip/common

//MAX-SIZE=512M, for generate out/.../system.img
BOARD_FLASH_BLOCK_SIZE := 131072

# Sepolicy
PRODUCT_SEPOLICY_SPLIT := true
BOARD_SEPOLICY_DIRS := \
    device/rockchip/rm35k/sepolicy/vendor
BOARD_PLAT_PRIVATE_SEPOLICY_DIR ?= \
    device/rockchip/rm35k/private \
    device/rockchip/rm35k/sepolicy

# ⚠ 注意: 下面三行指向 device/rockchip/rk356x/..., 该目录在**本树中不存在**。
#    这是从 device/pine64/pinenote/BoardConfigCommon.mk:174-176 继承来的上游
#    Rockchip 原始缺陷（pinenote 自己也一样，同样指向不存在的路径）。
#
#    后果: device/rockchip/rm35k/sepolicy_ebook{,_public,_system} 这三个目录
#    **从未被编译**，其内容（eink_service / sysfs_vendor_sleep / rk_bluetooth_file
#    / vendor_ebook_prop 等）从未生效。
#
#    已实测证实 factory 当年也没编译它们:
#      factory 的 system_ext_sepolicy.cil = 17459 B, 但 grep 这些类型**全部为 0**;
#      其内容实际来自 device/rockchip/common/sepolicy/private/ (本树亦不存在,
#      说明 factory 是用另一份树构建的, 无法在本树复现)。
#
#    曾经试图把路径改回真实的 device/rockchip/rm35k/... 来"修好"它, 结果立即
#    编译失败:
#      sepolicy/vendor/file.te:29:ERROR 'Duplicate declaration of type'
#      type rk_bluetooth_file, sysfs_type, fs_type, mlstrustedobject;
#    —— sepolicy_ebook_public/file.te:2 与 sepolicy/vendor/file.te:28 重复声明,
#    正因为这些文件从未被编译过, 这个冲突才被掩盖至今。
#
#    结论: **保持与 factory 完全一致的原始配置**, 不做改动。
#    空 system_ext_sepolicy.cil 是既有偏差, 但**不是**「卡第二屏」的原因
#    (bisectA 用 v5 的 system_ext 照样跑到第三屏), 故不动它。
BOARD_PLAT_PUBLIC_SEPOLICY_DIR := device/rockchip/rk356x/sepolicy_ebook_public
BOARD_PLAT_PRIVATE_SEPOLICY_DIR += device/rockchip/rk356x/sepolicy_ebook_system
BOARD_SEPOLICY_DIRS += device/rockchip/rk356x/sepolicy_ebook

# Enable VNDK Check for Android P (MUST after P)
BOARD_VNDK_VERSION := current

# Recovery
#TARGET_NO_RECOVERY ?= false
TARGET_ROCHCHIP_RECOVERY ?= true

# to flip screen in recovery
BOARD_HAS_FLIPPED_SCREEN ?= false

# Auto update package from USB
RECOVERY_AUTO_USB_UPDATE ?= false

# To use bmp as kernel logo, uncomment the line below to use bgra 8888 in recovery
TARGET_RECOVERY_PIXEL_FORMAT := "RGBX_8888"
TARGET_ROCKCHIP_PCBATEST ?= false
#TARGET_RECOVERY_UI_LIB ?= librecovery_ui_$(TARGET_PRODUCT)
TARGET_USERIMAGES_USE_EXT4 ?= true
TARGET_USERIMAGES_USE_F2FS ?= false
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE ?= ext4
RECOVERY_UPDATEIMG_RSA_CHECK ?= false

# use ext4 cache for OTA
BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE ?= ext4

TARGET_USES_MKE2FS ?= true

# for drmservice
BUILD_WITH_DRMSERVICE :=true

# Audio
BOARD_USES_GENERIC_AUDIO ?= true

# Wifi&Bluetooth
BOARD_HAVE_BLUETOOTH ?= true
BLUETOOTH_USE_BPLUS ?= false
BOARD_HAVE_BLUETOOTH_BCM ?= false
BOARD_BLUETOOTH_BDROID_BUILDCFG_INCLUDE_DIR := device/rockchip/rm35k/bluetooth

BOARD_WPA_SUPPLICANT_DRIVER := NL80211
WPA_SUPPLICANT_VERSION      := VER_0_8_X
BOARD_WPA_SUPPLICANT_PRIVATE_LIB := lib_driver_cmd_bcmdhd
BOARD_HOSTAPD_DRIVER        := NL80211
BOARD_HOSTAPD_PRIVATE_LIB   := lib_driver_cmd_bcmdhd
BOARD_WLAN_DEVICE           := bcmdhd
WIFI_DRIVER_FW_PATH_PARAM   := "/sys/module/bcmdhd/parameters/firmware_path"
WIFI_DRIVER_FW_PATH_STA     := "/vendor/etc/firmware/fw_bcm4329.bin"
WIFI_DRIVER_FW_PATH_P2P     := "/vendor/etc/firmware/fw_bcm4329_p2p.bin"
WIFI_DRIVER_FW_PATH_AP      := "/vendor/etc/firmware/fw_bcm4329_apsta.bin"

# C 精简 (2026-09-27): 本机无蓝牙硬件。
#   消费者: vendor/rockchip/common/device-vendor.mk:83
#       ifeq ($(strip $(BOARD_HAVE_BLUETOOTH)),true)
#         $(call inherit-product-if-exists, .../bluetooth/bluetooth.mk)
#   之前这里是 `:= true`, 会无条件把 bluetooth.mk 拉进来 (HAL + 固件 + conf)。
#   而 device/rockchip/rm35k/BoardConfig.mk:31-33 里写的 BOARD_HAS_BLUETOOTH := false
#   是**无效变量** (全树无人读取), 从未起作用 —— 这就是"声明了无蓝牙却仍在编译"的原因。
BOARD_HAVE_BLUETOOTH := false
BOARD_HAVE_BLUETOOTH_BCM := false

# gralloc 4.0
include device/rockchip/rm35k/gralloc.device.mk

# face lock
BUILD_WITH_FACELOCK ?= false

BOARD_BP_AUTO ?= true

# phone pad codec list
BOARD_CODEC_WM8994 ?= false
BOARD_CODEC_RT5625_SPK_FROM_SPKOUT ?= false
BOARD_CODEC_RT5625_SPK_FROM_HPOUT ?= false
BOARD_CODEC_RT3261 ?= false
BOARD_CODEC_RT3224 ?= true
BOARD_CODEC_RT5631 ?= false
BOARD_CODEC_RK616 ?= false

# multi usb partitions
BUILD_WITH_MULTI_USB_PARTITIONS ?= false

# pppoe for cts, you should set this true during pass CTS and which will disable  pppoe function.
BOARD_PPPOE_PASS_CTS ?= false

BOARD_CHARGER_ENABLE_SUSPEND ?= true
CHARGER_ENABLE_SUSPEND ?= true
CHARGER_DISABLE_INIT_BLANK ?= true
BOARD_CHARGER_DISABLE_INIT_BLANK ?= true

#for WV keybox provision
ENABLE_KEYBOX_PROVISION ?= false

# product has follow sensors or not,if had override it in product's BoardConfig
BOARD_GSENSOR_MXC6655XA_SUPPORT ?= false
BOARD_BLUETOOTH_SUPPORT ?= true
BOARD_BLUETOOTH_LE_SUPPORT ?= true
BOARD_WIFI_SUPPORT ?= true

#Use HWC2
TARGET_USES_HWC2 ?= true

HIGH_RELIABLE_RECOVERY_OTA := false
BOARD_USES_FULL_RECOVERY_IMAGE := false
BOARD_DEFAULT_CAMERA_HAL_VERSION ?=3.3
