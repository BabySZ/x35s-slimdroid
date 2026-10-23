# aosp_rm35k — RMX35K 掌机 (rk3566_rm700k) AOSP 11 目标
$(call inherit-product, device/rockchip/rm35k/common.mk)
$(call inherit-product, device/rockchip/rm35k/device.mk)
$(call inherit-product, frameworks/native/build/tablet-10in-xhdpi-2048-dalvik-heap.mk)


PRODUCT_NAME := aosp_rm35k
PRODUCT_DEVICE := rm35k
PRODUCT_BRAND := rockchip
PRODUCT_MODEL := RMX35K
PRODUCT_MANUFACTURER := rockchip

BUILD_FINGERPRINT := "rockchip/rk3566_rm700k/rk3566_rm700k:11/RQ3A.210705.001/eng.mahaor.20240802.095610:userdebug/release-keys"

# ────────────────────────────────────────────────────────────────────────────
# R19 精简: ART 用 release 变体而非 debug 变体
#   userdebug 默认装 com.android.art.debug (~120 MB @ /system/apex), 其中含
#   dex2oatd/libartd/profmand 等调试工具。本机是生产用途, 不需要。
#   依据 art/Android.mk:296-320 —— 该变量为 false 时无论构建变体都选
#   com.android.art.release; 先例: build/make/target/product/go_defaults_common.mk:37,
#   device/google/atv/products/atv_system.mk:92。
#   注意: 这是 _product_single_value_vars (build/make/core/product.mk:294), 可被 := 覆盖。
# ────────────────────────────────────────────────────────────────────────────
PRODUCT_ART_TARGET_INCLUDE_DEBUG_BUILD := false

# ────────────────────────────────────────────────────────────────────────────
# R20 精简/提速: 本机无摄像头 (无 /dev/video*, 无 camera HAL; 见交接 §1)
#
# ⚠️ 静默失效陷阱 (2026-09-28 实测核对源码后修正):
#   交接文档 §8#3 建议「PRODUCT_SUPPORTS_CAMERA := false」。核对源码发现
#   **单独设这个变量在我们的产品上完全无效**:
#     - PRODUCT_SUPPORTS_CAMERA 的 ifeq 逻辑只存在于
#       device/google/atv/products/atv_system.mk:73-78, 而我们**没有继承** atv_system.mk。
#     - 我们的 cameraserver 来自 build/make/target/product/handheld_system.mk:36
#       的 PRODUCT_PACKAGES += cameraserver (无任何条件)。
#   因此必须直接改 handheld_system.mk (同 R19 对 base_system.mk 的做法:
#   AOSP 11 没有 PRODUCT_PACKAGES_remove)。
#
#   改动: handheld_system.mk 删 `cameraserver`, 并加
#         config.disable_cameraservice=true (ATV 的 else 分支同款,
#         让 CameraService 客户端知道不要连 cameraserver)。
#   收益: ~3 MiB 内存 + 少一个启动进程。
# ────────────────────────────────────────────────────────────────────────────
PRODUCT_PROPERTY_OVERRIDES += \
    config.disable_cameraservice=true

# ────────────────────────────────────────────────────────────────────────────
# R20 精简: 去掉 Java 调试信息 (省若干 MB, 减小镜像)
#   先例: build/make/target/product/go_defaults_common.mk:48
#   实现在 build/make/core/java.mk:226, 受 soong_config MinimizeJavaDebugInfo 控制。
#   注意: _product_single_value_vars (build/make/core/product.mk:303), 用 := 覆盖。
# ────────────────────────────────────────────────────────────────────────────
PRODUCT_MINIMIZE_JAVA_DEBUG_INFO := true

# ────────────────────────────────────────────────────────────────────────────
# R20 提速: 关掉 dalvik.vm.minidebuginfo (交接 §8#7)
#   默认在 build/make/target/product/runtime_libart.mk:92-93 被设为 true,
#   会为每个 dex 生成 mini debug info, 增加 dex2oat 时间与镜像体积。
#   本机是生产用途, 不需要调试符号。
# ────────────────────────────────────────────────────────────────────────────
PRODUCT_PROPERTY_OVERRIDES += \
    dalvik.vm.minidebuginfo=false \
    dalvik.vm.dex2oat-minidebuginfo=false

# ────────────────────────────────────────────────────────────────────────────
# R25 提速: 抑制 SystemServerTiming 的启动刷屏 (目标(1) A2)
#   背景: userdebug 下 TimingsTraceLog.DEBUG_BOOT_TIME = !Build.IS_USER
#         (frameworks/base/core/java/android/util/TimingsTraceLog.java:39) 为 true,
#         启动时 SystemServerTiming 产生 1300+ 行 I/D 级日志。
#   机制: Slog.i/d 无 Java 侧闸门 (Slog.java 直接转 Log.println_native),
#         过滤发生在 native: __android_log_buf_write ->
#         __android_log_is_loggable (system/core/liblog/logger_write.cpp:320)
#         -> __android_log_level (properties.cpp:96, log_namespace="persist.log.tag.")
#   取值 W(5) 而非 S(8): 保留 UserController.java:505 那条真实 Slog.wtf(ERROR)
#         (finishUserBoot took too long), 只压掉 I(4)/D(3) 两类刷屏。
#   ★ 实机已验证 (2026-09-29, 证据 A2_DEVICE_VERIFIED.md):
#     三态单调: 未设 I=647/D=650 -> =I I=791/D=0 -> =W I=0/D=0;
#     同名 Async tag 恒为 ~439 行 (不同 tag, 不受影响) => 特异性成立。
#   注: 用 DEFAULT 而非 PRODUCT_PROPERTY_OVERRIDES? 二者开局都生效
#       (PropertyLoadBootDefaults 在 main() 早期读入内存属性区)。
#       这里用 PRODUCT_PROPERTY_OVERRIDES 与上方 §8 保持一致;
#       选 persist.* 前缀是为了可 setprop 回退与重启后保留。
# ────────────────────────────────────────────────────────────────────────────
PRODUCT_PROPERTY_OVERRIDES += \
    persist.log.tag.SystemServerTiming=W
