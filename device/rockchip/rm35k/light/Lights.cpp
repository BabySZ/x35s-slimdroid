/*
 * Copyright (C) 2019 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "Lights.h"

#include <android-base/logging.h>
#include <log/log.h>
#include <unistd.h>
#include <errno.h>

#include <aidl/android/hardware/light/LightType.h>
#include <aidl/android/hardware/light/FlashMode.h>

// RM35K 的真实背光节点 (sysfs: /sys/class/backlight/backlight/)
//
// 注意: 本文件原先抄自 device/pine64/pinenote/light/Lights.cpp, 写的是 PineNote
// 墨水屏前光 lm3630a_warm_light / lm3630a_cold_light。RM35K 是 LCD 掌机, 没有
// lm3630a, 那两个节点**永远不存在**, 于是 write_int() 返回 -ENOENT(-2),
// err = -2 + -2 = -4, setLightState() 返回 fromServiceSpecificError(-4)。
//
// 致命后果: LightsService$LightImpl.setLightUnchecked() 只 catch
// (RemoteException | UnsupportedOperationException), 而
// ServiceSpecificException extends RuntimeException -> 异常穿透 ->
// LocalDisplayAdapter.setDisplayBrightness -> android.display 线程
// "FATAL EXCEPTION IN SYSTEM PROCESS" -> system_server 死 -> zygote 无限重启,
// 表现为"卡第二屏自动重启"。
//
// 充电灯 (黄=充电中 / 绿=满电插电 / 灭=非充电) **不经过本 HAL**: 由内核
// rk817 充电器驱动根据充电状态直接控制, 见 device.mk 中的内核二进制补丁说明。
// 因此这里只负责 LCD 背光。
// ⚠ 宏名不能叫 BACKLIGHT: 会与 LightType::BACKLIGHT 枚举冲突, 展开后
// case LightType::"/sys/..." 直接编译失败。故用 _PATH 后缀。
#define BACKLIGHT_PATH "/sys/class/backlight/backlight/brightness"

using namespace std;

namespace aidl {
namespace android {
namespace hardware {
namespace light {

static int write_int(const char* path, int value) {
    int fd;

    fd = open(path, O_RDWR);
    if (fd >= 0) {
        char buf[20];
        int bytes = snprintf(buf, sizeof(buf), "%d\n", value);
        ssize_t amt = write(fd, buf, (size_t)bytes);
        close(fd);
        return amt == -1? -errno : 0;
    } else {
        ALOGE("write_int() failed to open %s:%s\n", path, strerror(errno));
        return -errno;
    }
}

static int state2brightbess(const HwLightState& state) {
    int color = state.color;
    return ((77*((color>>16)&0x00ff))
            + (150*((color>>8)&0x00ff)) + (29*(color&0x00ff))) >> 8;
}

static int setLightFromType(LightType type, const HwLightState& state) {
    int err = 0;
    switch (type) {
        case LightType::BACKLIGHT: {
            int brightness = state2brightbess(state);
            err = write_int(BACKLIGHT_PATH, brightness);
            break;
        }
        default:
            break;
    }
    if (err != 0) {
        ALOGE("Failed to setLightState: %d", err);
    }
    return 0;  // 见下方 setLightState() 的说明: 绝不向上返回错误
}

ndk::ScopedAStatus Lights::setLightState(int id, const HwLightState& state) {
    ALOGV("Lights setting state for id=%d to color:%x", id, state.color);
    LightType type;
    int err = -1;
    std::vector<HwLight>::iterator it = _lights.begin();
    for (; it != _lights.end(); ++it) {
        if (it->id == id) {
            type = it->type;
            err = 0;
            break;
        }
    }
    if (err != 0) {
        return ndk::ScopedAStatus::fromExceptionCode(EX_UNSUPPORTED_OPERATION);
    }
    // Set lights.
    //
    // ⚠ 关键: 这里**必须**始终返回 ok(), 即使底层 sysfs 写入失败。
    // LightsService$LightImpl.setLightUnchecked() 只捕获
    // (RemoteException | UnsupportedOperationException); 一旦返回
    // fromServiceSpecificError(), 框架侧会抛出
    // ServiceSpecificException extends RuntimeException, **不被捕获**,
    // 沿 LocalDisplayAdapter.setDisplayBrightness() 冒泡到 android.display
    // 线程 -> "FATAL EXCEPTION IN SYSTEM PROCESS" -> system_server 崩溃
    // -> zygote 无限重启 ("卡第二屏重启")。背光调不了是小事, 开机起不来是大事。
    setLightFromType(type, state);
    return ndk::ScopedAStatus::ok();
}

ndk::ScopedAStatus Lights::getLights(std::vector<HwLight>* lights) {
    ALOGI("Lights reporting supported lights");
    _lights.clear();
    addLight(0, LightType::BACKLIGHT);
    for (auto i = _lights.begin(); i != _lights.end(); i++) {
        lights->push_back(*i);
    }
    return ndk::ScopedAStatus::ok();
}


void Lights::addLight(int const ordinal, LightType const type) {
    HwLight light{};
    light.id = _lights.size();
    light.ordinal = ordinal;
    light.type = type;
    _lights.emplace_back(light);
}

}  // namespace light
}  // namespace hardware
}  // namespace android
}  // namespace aidl
