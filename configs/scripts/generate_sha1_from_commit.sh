#!/bin/bash
#
#==============================================================================
# SYNOPSIS
#    generate_sha1_from_commit.sh args ...
#
# DESCRIPTION
#    The script generates and updates proprietary-files.txt sha1sum from a
#    vendor commit id.
#
# EXAMPLES
#    ./generate_sha1_from_commit.sh 1a2b3c4d
#
# AUTHOR
#    Chenyang Zhong
#
# HISTORY
#    2020/06/19 : Script creation
#    2020/09/29 : Updated script to handle added and deleted blobs
#
#==============================================================================
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

MY_DIR="${PWD}"

VENDOR_DIR="${MY_DIR}"/../../../../../vendor/xiaomi/beryllium
DEVICE=beryllium
DIR_PREFIX="proprietary/"

cd "${VENDOR_DIR}"

# get commit id from input
if [ "${#}" -eq 1 ]; 
then
    COMMIT="${1}"
else
    echo >&2 "Please specify a vendor commit id."
    exit 1
fi 

# display commit id and title
echo "$(git show -s --format='%h %s' ${COMMIT})"
echo "========================================================"

# iterate through changed files in the commit
git diff-tree --no-commit-id --name-status -r ${COMMIT} | while read line ;
do
    # separate status and file name
    read -ra arr_line <<< "${line}"
    status=${arr_line[0]}
    file=${arr_line[1]}

    # remove directory prefix from filename
    file_stripped=${file#"${DIR_PREFIX}"}

    # blob status is deleted
    if [[ "$status" == "D" ]]; then
        echo "deleting ${file_stripped}"
        sed -i "\%^${file_stripped}%d" "${MY_DIR}/../../proprietary-files.txt"
        continue
    fi

    # generate sha1
    r="$(sha1sum "$file")"
    r_arr=($r)
    sha1="${r_arr[0]}"

    # blob is newly added
    if [[ "$status" == "A" ]]; then
        echo "adding ${file_stripped}"
        echo "${file_stripped}|${sha1}" >> "${MY_DIR}/../../proprietary-files.txt"
        continue
    fi

    # the rest files already exist in the list and are modified
    # iterate through lines in proprietary-files.txt until the first
    # non-comment match
    for line in $(grep "$file_stripped" "${MY_DIR}/../../proprietary-files.txt")
    do
        # continue if this line starts with #
        [[ $line =~ ^#.* ]] && continue

        # check if it has a sha1sum already
        if [[ "$line" == *"|"* ]]; then
            # remove the old sha1sum and append the new one
            newline="${line:0:${#line}-40}${sha1}" 
        else
            # append the new sha1sum to it
            newline="${line}|${sha1}"
        fi

        # display which line is getting replaced
        echo "$line ---> $newline"

        # use % as delimiter because file path contains "/"
        sedstr="s%^$line\$%$newline%" 
        sed -i "$sedstr" "${MY_DIR}/../../proprietary-files.txt"

        # exit after the first replacement
        break
    done
    
done
