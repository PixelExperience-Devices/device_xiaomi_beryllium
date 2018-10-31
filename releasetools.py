# Copyright (C) 2009 The Android Open Source Project
# Copyright (c) 2011, The Linux Foundation. All rights reserved.
# Copyright (C) 2017-2018 The LineageOS Project
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

import hashlib
import common
import re

def FullOTA_Assertions(info):
  AddModemAssertion(info, info.input_zip)
  AddVendorAssertion(info, info.input_zip)
  return

def IncrementalOTA_Assertions(info):
  AddModemAssertion(info, info.target_zip)
  AddVendorAssertion(info, info.target_zip)
  return

def AddModemAssertion(info, input_zip):
  android_info = info.input_zip.read("OTA/android-info.txt")
  m = re.search(r'require\s+version-modem\s*=\s*(.+)', android_info)
  miui_version = re.search(r'require\s+version-miui\s*=\s*(.+)', android_info)
  if m and miui_version:
    timestamp = m.group(1).rstrip()
    firmware_version = miui_version.group(1).rstrip()
    if ((len(timestamp) and '*' not in timestamp) and \
        (len(firmware_version) and '*' not in firmware_version)):
      cmd = 'assert(xiaomi.verify_modem("{}") == "1" || abort("ERROR: This package requires firmware from MIUI {} developer build or newer. Please upgrade firmware and retry!"););'
      info.script.AppendExtra(cmd.format(timestamp, firmware_version))
  return

def AddVendorAssertion(info, input_zip):
  android_info = info.input_zip.read("OTA/android-info.txt")
  v = re.search(r'require\s+version-vendor\s*=\s*(.+)', android_info)
  miui_version = re.search(r'require\s+version-miui\s*=\s*(.+)', android_info)
  if v and miui_version:
    build_date_utc, vndk_version = v.group(1).rstrip().split(',')
    firmware_version = miui_version.group(1).rstrip()
    cmd = 'assert(xiaomi.verify_vendor("{}", "{}") == "1" || abort("ERROR: This package requires vendor from MIUI {} developer build or newer. Please upgrade vendor image along with matching firmware and retry!"););'
    info.script.AppendExtra(cmd.format(build_date_utc, vndk_version, firmware_version))
  return
