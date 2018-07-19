LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE := power.qcom
LOCAL_MODULE_RELATIVE_PATH := hw
LOCAL_MODULE_TAGS := optional

LOCAL_SRC_FILES := \
    hint-data.c \
    list.c \
    metadata-parser.c \
    power-845.c \
    power.c \
    powerhintparser.c \
    utils.c

LOCAL_C_INCLUDES := external/libxml2/include \
                    external/icu/icu4c/source/common

LOCAL_SHARED_LIBRARIES := liblog libcutils libdl libxml2

LOCAL_CFLAGS += -Werror -Wall -Wno-unused-parameter
LOCAL_CFLAGS += -DINTERACTION_BOOST

include $(BUILD_SHARED_LIBRARY)
