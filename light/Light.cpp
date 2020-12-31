/*
 * Copyright (C) 2018-2020 The LineageOS Project
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

static constexpr int kDefaultMaxBrightness = 255;
static constexpr int kRampSteps = 8;
static constexpr int kRampMaxStepDurationMs = 50;

static uint32_t getBrightness(const LightState& state) {
    uint32_t alpha, red, green, blue;

    // Extract brightness from AARRGGBB
    alpha = (state.color >> 24) & 0xff;

    // Retrieve each of the RGB colors
    red = (state.color >> 16) & 0xff;
    green = (state.color >> 8) & 0xff;
    blue = state.color & 0xff;

    // Scale RGB colors if a brightness has been applied by the user
    if (alpha != 0xff) {
        red = red * alpha / 0xff;
        green = green * alpha / 0xff;
        blue = blue * alpha / 0xff;
    }

    return (77 * red + 150 * green + 29 * blue) >> 8;
}

Light::Light() {
    mLights.emplace(Type::ATTENTION, std::bind(&Light::handleWhiteLed, this, std::placeholders::_1, 0));
    mLights.emplace(Type::BATTERY, std::bind(&Light::handleWhiteLed, this, std::placeholders::_1, 1));
    mLights.emplace(Type::NOTIFICATIONS, std::bind(&Light::handleWhiteLed, this, std::placeholders::_1, 2));
}

void Light::handleWhiteLed(const LightState& state, size_t index) {
    mLightStates.at(index) = state;

    LightState stateToUse = mLightStates.front();
    for (const auto& lightState : mLightStates) {
        if (lightState.color & 0xffffff) {
            stateToUse = lightState;
            break;
        }
    }

    uint32_t whiteBrightness = getBrightness(stateToUse);

    auto getScaledDutyPercent = [](int brightness) -> std::string {
        std::string output;
        for (int i = 0; i <= kRampSteps; i++) {
            if (i != 0) {
                output += ",";
            }
            output += std::to_string(i * 100 * brightness / (kDefaultMaxBrightness * kRampSteps));
        }
        return output;
    };

    // Disable blinking to start
    set("/sys/class/leds/white/blink", 0);

    if (stateToUse.flashMode == Flash::TIMED) {
        // If the flashOnMs duration is not long enough to fit ramping up and down
        // at the default step duration, step duration is modified to fit.
        int32_t stepDuration = kRampMaxStepDurationMs;
        int32_t pauseHi = stateToUse.flashOnMs - (stepDuration * kRampSteps * 2);
        int32_t pauseLo = stateToUse.flashOffMs;

        if (pauseHi < 0) {
            stepDuration = stateToUse.flashOnMs / (kRampSteps * 2);
            pauseHi = 0;
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
