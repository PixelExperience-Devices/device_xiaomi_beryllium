/*
 * Copyright (C) 2019 The LineageOS Project
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

#define LOG_TAG "lineage.livedisplay@2.0-service.xiaomi_sdm845"

#include <android-base/logging.h>
#include <binder/ProcessState.h>
#include <hidl/HidlTransportSupport.h>

#include "SunlightEnhancement.h"

using android::OK;
using android::sp;
using android::status_t;
using android::hardware::configureRpcThreadpool;
using android::hardware::joinRpcThreadpool;

using ::vendor::lineage::livedisplay::V2_0::ISunlightEnhancement;
using ::vendor::lineage::livedisplay::V2_0::implementation::SunlightEnhancement;

int main() {
    sp<SunlightEnhancement> sunlightEnhancement;
    status_t status;

    LOG(INFO) << "LiveDisplay HAL custom service is starting.";

    sunlightEnhancement = new SunlightEnhancement();
    if (sunlightEnhancement == nullptr) {
        LOG(ERROR) << "Can not create an instance of LiveDisplay HAL SunlightEnhancement Iface,"
                   << "exiting.";
        goto shutdown;
    }

    if (!sunlightEnhancement->isSupported()) {
        LOG(ERROR) << "SunlightEnhancement Iface is not supported, gracefully bailing out.";
        return 1;
    }

    configureRpcThreadpool(1, true /*callerWillJoin*/);

    status = sunlightEnhancement->registerAsService();
    if (status != OK) {
        LOG(ERROR) << "Could not register service for LiveDisplay HAL SunlightEnhancement Iface ("
                   << status << ")";
        goto shutdown;
    }

    LOG(INFO) << "LiveDisplay HAL custom service is ready.";
    joinRpcThreadpool();
    // Should not pass this line

shutdown:
    // In normal operation, we don't expect the thread pool to shutdown
    LOG(ERROR) << "LiveDisplay HAL custom service is shutting down.";
    return 1;
}
