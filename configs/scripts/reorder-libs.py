#!/usr/bin/env python
#
# Copyright (C) 2021 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

from functools import cmp_to_key
from locale import LC_ALL, setlocale, strcoll
from pathlib import Path

FILES = [Path(file) for file in [
    "../proprietary-files.txt",
]]

setlocale(LC_ALL, "C")

def strcoll_extract_utils(string1: str, string2: str) -> int:
    # Skip logic if one of the string if empty
    if not string1 or not string2:
        return strcoll(string1, string2)

    # Remove '-' from strings if there,
    # it is used to indicate a build target
    string1 = string1.removeprefix('-')
    string2 = string2.removeprefix('-')

    # If no directories, compare normally
    if not "/" in string1 and not "/" in string2:
        return strcoll(string1, string2)

    string1_dir = string1.rsplit("/", 1)[0] + "/"
    string2_dir = string2.rsplit("/", 1)[0] + "/"
    if string1_dir == string2_dir:
        # Same directory, compare normally
        return strcoll(string1, string2)

    if string1_dir.startswith(string2_dir):
        # First string dir is a subdirectory of the second one,
        # return string1 > string2
        return -1

    if string2_dir.startswith(string1_dir):
        # Second string dir is a subdirectory of the first one,
        # return string2 > string1
        return 1

    # Compare normally
    return strcoll(string1, string2)

for file in FILES:
    if not file.is_file():
        print(f"File {str(file)} not found")
        continue

    with open(file, 'r') as f:
        sections = f.read().split("\n\n")

    ordered_sections = []
    for section in sections:
        section_list = [line.strip() for line in section.splitlines()]
        section_list.sort(key=cmp_to_key(strcoll_extract_utils))
        ordered_sections.append("\n".join(section_list))

    with open(file, 'w') as f:
        f.write("\n\n".join(ordered_sections).strip() + "\n")
