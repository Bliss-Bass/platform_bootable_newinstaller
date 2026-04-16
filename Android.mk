# Copyright 2009-2014, The Android-x86 Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
BUILD_TOP := $(shell pwd)

ifneq ($(filter x86%,$(TARGET_ARCH)),)
LOCAL_PATH := $(call my-dir)

ifeq ($(USE_NEWINSTALLER),)
USE_NEWINSTALLER := 1
endif

install_dir := $(LOCAL_PATH)/install
install_lib_dir := $(LOCAL_PATH)/install_lib

ifneq ($(shell test -d $(install_lib_dir) && echo exists), exists)
    $(error install_lib does not exist, have you run the download script yet ?)
endif

TARGET_INSTALL_OUT := $(PRODUCT_OUT)/install
INSTALL_RAMDISK := $(PRODUCT_OUT)/install.img
$(INSTALL_RAMDISK): $(wildcard $(LOCAL_PATH)/install/*/* $(LOCAL_PATH)/install/*/*/*/*) | $(ACP) $(HOST_OUT_EXECUTABLES)/toybox
	$(hide) rm -rf $(TARGET_INSTALL_OUT)
	mkdir -p $(addprefix $(TARGET_INSTALL_OUT)/,android apex dev proc sys tmp etc data cdrom boot source hd)
	touch $(addprefix $(TARGET_INSTALL_OUT)/,etc/fstab)
	$(ACP) -dpr $(install_dir)/* $(install_lib_dir)/* $(TARGET_INSTALL_OUT)
	cd $(TARGET_INSTALL_OUT); find . | $(HOST_OUT_EXECUTABLES)/toybox cpio -o | gzip -9 > $@; cd -

.PHONY: installimage
installimage: $(INSTALL_RAMDISK)

# Grab branch names
KRNL := $(shell cd $(BUILD_TOP)/kernel ; make kernelversion)
MSA := $(shell cd $(BUILD_TOP)/external/mesa ; git name-rev --name-only HEAD | cut -d '/' -f3)
HWC := $(shell cd $(BUILD_TOP)/external/drm_hwcomposer ; git name-rev --name-only HEAD | cut -d '/' -f3)

# Grab enabled extras
ifeq ($(USE_GMS),true)
	GMS := "_gms"
else ifeq ($(USE_EMU_GAPPS),true)
	GMS := "_emugapps"
else ifeq ($(USE_FOSS_APPS),true)
	GMS := "_foss"
else
	GMS := ""
endif

ifeq ($(USE_LIBNDK_TRANSLATION_NB),true)
	HOU := "_libndk"
else ifeq ($(USE_CROS_HOUDINI_NB),true)
	HOU := "_cros-hd"
else
	HOU := ""
endif

ifeq ($(USE_WIDEVINE),true)
WDV := "_cros-wv"
else
WDV := ""
endif

ifneq ("$(wildcard $(PRODUCT_OUT)/gearlock)","")
GLK := "_gearlock"
else
GLK := ""
endif

ifeq ($(TARGET_ARCH),x86_64)
IS_ANDROID_X86_64 := true
else ifeq ($(TARGET_ARCH),x86)
IS_ANDROID_X86_64 := false
endif

# Use vendor defined version names
ifeq ($(TARGET_PRODUCT),virtualbox)
KRNL := $(shell cd $(BUILD_TOP)/kernel ; make kernelversion)
ROM_VENDOR_VERSION := $(RELEASE_OS_TITLE)-vbox-$(shell date +%Y%m%d%H%M)
else ifeq ($(TARGET_PRODUCT),legacy_pc)
KRNL := $(shell cd $(BUILD_TOP)/kernel ; make kernelversion)
ROM_VENDOR_VERSION := $(RELEASE_OS_TITLE)-legacy_pc-$(shell date +%Y%m%d%H%M)
else
ROM_VENDOR_VERSION := $(RELEASE_OS_TITLE)-$(TARGET_ARCH)-$(shell date +%Y%m%d%H%M)
endif

BUILD_NAME_VARIANT := $(ROM_VENDOR_VERSION)
ifeq ($(BLISS_BUILD_ZIP),)
ROM_VENDOR_VERSION := $(RELEASE_OS_TITLE)$(BLISS_SPECIAL_VARIANT)-$(TARGET_ARCH)-$(shell date +%Y%m%d%H)
else
ROM_VENDOR_VERSION := $(BLISS_BUILD_ZIP)
endif

changelog: $(boot_dir) $(INSTALL_RAMDISK)
	# Generate Changelog
	bash bootable/newinstaller/tools/changelog
	$(hide) mv Changelog.txt $(PRODUCT_OUT)/Changelog-$(ROM_VENDOR_VERSION).txt

.PHONY: changelog

endif
