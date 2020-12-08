#! /vendor/bin/sh

# Copyright (c) 2012-2018, The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
#       copyright notice, this list of conditions and the following
#       disclaimer in the documentation and/or other materials provided
#       with the distribution.
#     * Neither the name of The Linux Foundation nor the names of its
#       contributors may be used to endorse or promote products derived
#      from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT
# ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
# IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#

#
# Check ESOC for external modem
#
# Note: currently only a single MDM/SDX is supported
#
esoc_name=`cat /sys/bus/esoc/devices/esoc0/esoc_name 2> /dev/null`

# Clear vendor USB config because it is only needed for debugging
setprop persist.vendor.usb.config ""

# Check configfs is mounted or not
if [ -d /config/usb_gadget ]; then
    # ADB requires valid iSerialNumber; if ro.serialno is missing, use dummy
    serialnumber=`cat /config/usb_gadget/g1/strings/0x409/serialnumber` 2> /dev/null
    if [ "$serialnumber" == "" ]; then
        serialno=1234567
        echo $serialno > /config/usb_gadget/g1/strings/0x409/serialnumber
    fi
    setprop vendor.usb.configfs 1
fi

#
# Initialize RNDIS Diag option. If unset, set it to 'none'.
#
diag_extra=`getprop persist.vendor.usb.config.extra`
if [ "$diag_extra" == "" ]; then
    setprop persist.vendor.usb.config.extra none
fi

#
# Initialize UVC configuration.
#
if [ -d /config/usb_gadget/g1/functions/uvc.0 ]; then
    cd /config/usb_gadget/g1/functions/uvc.0

    echo 3072 > streaming_maxpacket
    echo 10 > streaming_maxburst
    mkdir control/header/h
    ln -s control/header/h control/class/fs/
    ln -s control/header/h control/class/ss

    mkdir -p streaming/uncompressed/u/360p
    echo "666666\n1000000\n5000000\n" > streaming/uncompressed/u/360p/dwFrameInterval

    mkdir -p streaming/uncompressed/u/720p
    echo 1280 > streaming/uncompressed/u/720p/wWidth
    echo 720 > streaming/uncompressed/u/720p/wHeight
    echo 29491200 > streaming/uncompressed/u/720p/dwMinBitRate
    echo 29491200 > streaming/uncompressed/u/720p/dwMaxBitRate
    echo 1843200 > streaming/uncompressed/u/720p/dwMaxVideoFrameBufferSize
    echo 5000000 > streaming/uncompressed/u/720p/dwDefaultFrameInterval
    echo "5000000\n" > streaming/uncompressed/u/720p/dwFrameInterval

    #mkdir -p streaming/mjpeg/m/360p
    #echo "666666\n1000000\n5000000\n" > streaming/mjpeg/m/360p/dwFrameInterval
    mkdir -p streaming/mjpeg/m/360p
    echo 640 > streaming/mjpeg/m/360p/wWidth
    echo 360 > streaming/mjpeg/m/360p/wHeight
    echo 460800   > streaming/mjpeg/m/360p/dwMaxVideoFrameBufferSize
    echo 18432000  > streaming/mjpeg/m/360p/dwMinBitRate
    echo 55296000 > streaming/mjpeg/m/360p/dwMaxBitRate
    echo "333333\n666666\n1000000\n5000000\n" > streaming/mjpeg/m/360p/dwFrameInterval
    echo 333333 > streaming/mjpeg/m/360p/dwDefaultFrameInterval

    mkdir -p streaming/mjpeg/m/720p
    echo 1280 > streaming/mjpeg/m/720p/wWidth
    echo 720 > streaming/mjpeg/m/720p/wHeight
    echo 29491200 > streaming/mjpeg/m/720p/dwMinBitRate
    echo 29491200 > streaming/mjpeg/m/720p/dwMaxBitRate
    echo 1843200 > streaming/mjpeg/m/720p/dwMaxVideoFrameBufferSize
    echo 333333 > streaming/mjpeg/m/720p/dwDefaultFrameInterval
    echo "333333\n666666\n1000000\n5000000\n" > streaming/mjpeg/m/720p/dwFrameInterval
    #echo 5000000 > streaming/mjpeg/m/720p/dwDefaultFrameInterval
    #echo "5000000\n" > streaming/mjpeg/m/720p/dwFrameInterval

    mkdir -p streaming/mjpeg/m/1080p
    echo 1920 > streaming/mjpeg/m/1080p/wWidth
    echo 1080 > streaming/mjpeg/m/1080p/wHeight
    echo 66355200 > streaming/mjpeg/m/1080p/dwMinBitRate
    echo 995328000 > streaming/mjpeg/m/1080p/dwMaxBitRate
    echo 4147200 > streaming/mjpeg/m/1080p/dwMaxVideoFrameBufferSize
    echo 333333 > streaming/mjpeg/m/1080p/dwDefaultFrameInterval
    echo "333333\n666666\n1000000\n5000000\n" > streaming/mjpeg/m/1080p/dwFrameInterval

    mkdir -p streaming/mjpeg/m/2160p
    echo 3840 > streaming/mjpeg/m/2160p/wWidth
    echo 2160 > streaming/mjpeg/m/2160p/wHeight
    echo 265420800 > streaming/mjpeg/m/2160p/dwMinBitRate
    echo 3981312000 > streaming/mjpeg/m/2160p/dwMaxBitRate
    echo 16588800 > streaming/mjpeg/m/2160p/dwMaxVideoFrameBufferSize
    echo 333333 > streaming/mjpeg/m/2160p/dwDefaultFrameInterval
    echo "333333\n666666\n1000000\n5000000\n" > streaming/mjpeg/m/2160p/dwFrameInterval

    echo 0x04 > /config/usb_gadget/g1/functions/uvc.0/streaming/mjpeg/m/bmaControls

    mkdir -p streaming/h264/h/960p
    echo 1920 > streaming/h264/h/960p/wWidth
    echo 960 > streaming/h264/h/960p/wHeight
    echo 40 > streaming/h264/h/960p/bLevelIDC
    echo "333667\n" > streaming/h264/h/960p/dwFrameInterval

    mkdir -p streaming/h264/h/1920p
    echo "333667\n" > streaming/h264/h/1920p/dwFrameInterval

    mkdir streaming/header/h
    ln -s streaming/uncompressed/u streaming/header/h
    ln -s streaming/mjpeg/m streaming/header/h
    ln -s streaming/h264/h streaming/header/h
    ln -s streaming/header/h streaming/class/fs/
    ln -s streaming/header/h streaming/class/hs/
    ln -s streaming/header/h streaming/class/ss/
fi
