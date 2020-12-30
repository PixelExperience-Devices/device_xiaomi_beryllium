/*
 * Copyright (C) 2018-2020 The LineageOS Project
 * Copyright (C) 2020 The PixelExperience Project
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

#define LOG_TAG "LightsService"

#include "Light.h"

#include <android-base/logging.h>
#include <android-base/stringprintf.h>
#include <fstream>

namespace android {
namespace hardware {
namespace light {
namespace V2_0 {
namespace implementation {

/*
 * Write value to path and close file.
 */
template <typename T>
static void set(const std::string& path, const T& value) {
    std::ofstream file(path);
    file << value;
}

static constexpr uint32_t kBrightnessNoBlink = 5;

Light::Light() {
    mLights.emplace(Type::ATTENTION, std::bind(&Light::handleNotification, this, std::placeholders::_1, 0));
    mLights.emplace(Type::NOTIFICATIONS, std::bind(&Light::handleNotification, this, std::placeholders::_1, 1));
    mLights.emplace(Type::BATTERY, std::bind(&Light::handleNotification, this, std::placeholders::_1, 2));
}

void Light::handleBattery(const LightState& state) {
    uint32_t whiteBrightness = getBrightness(state);

    uint32_t onMs = state.flashMode == Flash::TIMED ? state.flashOnMs : 0;
    uint32_t offMs = state.flashMode == Flash::TIMED ? state.flashOffMs : 0;

    auto getScaledDutyPercent = [](int brightness) -> std::string {
        std::string output;
        for (int i = 0; i <= kRampSteps; i++) {
            if (i != 0) {
                output += ",";
            }
            if (i <= kRampSteps / 2) {
                output += "0";
            } else {
                output += std::to_string((i - kRampSteps / 2) * 100 * brightness /
                                         (kDefaultMaxBrightness * (kRampSteps/2)));
            }
        }
        return output;
    };

    // Disable blinking to start
    set("/sys/class/leds/white/blink", 0);

    if (onMs > 0 && offMs > 0) {
        uint32_t pauseLo, pauseHi, stepDuration;
        stepDuration = 10;
        if (stepDuration * kRampSteps > onMs) {
            pauseHi = 0;
        } else {
            pauseHi = onMs - kRampSteps * stepDuration;
            pauseLo = offMs - kRampSteps * stepDuration;
        }

        set("/sys/class/leds/white/start_idx", 0);
        set("/sys/class/leds/white/duty_pcts", getScaledDutyPercent(whiteBrightness));
        set("/sys/class/leds/white/pause_lo", pauseLo);
        set("/sys/class/leds/white/pause_hi", pauseHi);
        set("/sys/class/leds/white/ramp_step_ms", stepDuration);

        // Start blinking
        set("/sys/class/leds/white/blink", 1);
    } else {
        set("/sys/class/leds/white/brightness", whiteBrightness);
    }
}

void Light::handleNotification(const LightState& state, size_t index) {
    mLightStates.at(index) = state;

    uint32_t whiteBrightness = 0;
    LightState stateToUse = mLightStates.front();
    for (const auto& lightState : mLightStates) {
        if (lightState.color & 0xffffff) {
            stateToUse = lightState;
            whiteBrightness = kBrightnessNoBlink;
            break;
        }
    }

    uint32_t onMs = stateToUse.flashMode == Flash::TIMED ? stateToUse.flashOnMs : 0;
    uint32_t offMs = stateToUse.flashMode == Flash::TIMED ? stateToUse.flashOffMs : 0;

    // Disable blinking to start
    set("/sys/class/leds/white/blink", 0);

    if (onMs > 0 && offMs > 0) {
        // Start blinking
        set("/sys/class/leds/white/blink", 1);
    } else {
        set("/sys/class/leds/white/brightness", whiteBrightness);
    }
}

Return<Status> Light::setLight(Type type, const LightState& state) {
    auto it = mLights.find(type);

    if (it == mLights.end()) {
        return Status::LIGHT_NOT_SUPPORTED;
    }

    // Lock global mutex until light state is updated.
    std::lock_guard<std::mutex> lock(mLock);

    it->second(state);

    return Status::SUCCESS;
}

Return<void> Light::getSupportedTypes(getSupportedTypes_cb _hidl_cb) {
    std::vector<Type> types;

    for (auto const& light : mLights) {
        types.push_back(light.first);
    }

    _hidl_cb(types);

    return Void();
}

}  // namespace implementation
}  // namespace V2_0
}  // namespace light
}  // namespace hardware
}  // namespace android
