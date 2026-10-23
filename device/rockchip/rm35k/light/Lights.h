/*
 * Copyright (C) 2020 The Android Open Source Project
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

#pragma once

#include <aidl/android/hardware/light/BnLights.h>
// 原为 "PineNoteLights" (本文件抄自 pinenote), 改名以便在 logcat 中一眼认出
// 是哪块板子的 lights HAL。务必与 Lights.cpp 的行为保持一致: 最近的改动
// (背光节点改为 /sys/class/backlight/backlight/brightness, 且 setLightState
// 永不返回 service-specific error) 是为了修 "卡第二屏重启" 的致命崩溃。
#define LOG_TAG "Rm35kLights"

namespace aidl {
namespace android {
namespace hardware {
namespace light {

// Default implementation that reports no supported lights.
class Lights : public BnLights {
    ndk::ScopedAStatus setLightState(int id, const HwLightState& state) override;
    ndk::ScopedAStatus getLights(std::vector<HwLight>* types) override;

private:
    void addLight(int const ordinal, LightType const type);
    std::vector<HwLight> _lights;
};

}  // namespace light
}  // namespace hardware
}  // namespace android
}  // namespace aidl
