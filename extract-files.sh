#!/bin/bash
#
# Copyright (C) 2018-2019 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Sourced by the common device repo when extracting device-specific blobs
function blob_fixup() {
    case "${1}" in
    vendor/etc/qdcm_calib_data_ebbg_fhd_video_dsi_panel.xml)
        sed -i "s/\"hdr\"/\"sdr\"/" "${2}"
        ;;
    vendor/etc/qdcm_calib_data_tianma_fhd_video_dsi_panel.xml)
        sed -i "s/\"hdr\"/\"sdr\"/" "${2}"
        ;;
    esac
}

# If we're being sourced by the common script that we called,
# stop right here. No need to go down the rabbit hole.
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
    return
fi

set -e

# Required!
export DEVICE=beryllium
export DEVICE_COMMON=sdm845-common
export VENDOR=xiaomi

export DEVICE_BRINGUP_YEAR=2018

"./../../${VENDOR}/${DEVICE_COMMON}/extract-files.sh" "$@"
