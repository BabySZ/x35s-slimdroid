# RMX35K 内核编译配置: 使用 AOSP 树内 kernel (4.19.219 rk356x)
TARGET_KERNEL_SOURCE := kernel
TARGET_KERNEL_CONFIG := rockchip_defconfig
# dtb 用官方提取版 (rk3566_rm700k 无上游源 dts), 由 device dtb 目录直供
TARGET_KERNEL_ADDITIONAL_CONFIG := 
TARGET_KERNEL_ARCH := arm64
TARGET_KERNEL_CROSS_COMPILE_PREFIX := aarch64-linux-gnu-
