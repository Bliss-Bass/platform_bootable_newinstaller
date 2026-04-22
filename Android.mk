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
ifeq ($(USE_NEWINSTALLER),true)
LOCAL_PATH := $(call my-dir)


install_dir := $(LOCAL_PATH)/install
install_lib_dir := $(LOCAL_PATH)/install_lib

ifneq ($(shell test -d $(install_lib_dir) && echo exists), exists)
    $(error install_lib does not exist, have you run the download script yet ?)
endif

TARGET_INSTALL_OUT := $(PRODUCT_OUT)/install
INSTALL_RAMDISK := $(PRODUCT_OUT)/install.img
$(INSTALL_RAMDISK): $(wildcard $(LOCAL_PATH)/install/*/* $(LOCAL_PATH)/install/*/*/*/*) | $(ACP) $(HOST_OUT_EXECUTABLES)/toybox
	$(hide) rm -rf $(TARGET_INSTALL_OUT)
	mkdir -p $(addprefix $(TARGET_INSTALL_OUT)/,android apex dev proc sys tmp etc data cdrom boot source hd var/lib/os-prober/mount)
	touch $(addprefix $(TARGET_INSTALL_OUT)/,etc/fstab)
	$(ACP) -dpr $(install_dir)/. $(install_lib_dir)/. $(TARGET_INSTALL_OUT)
	cd $(TARGET_INSTALL_OUT); find . | $(HOST_OUT_EXECUTABLES)/toybox cpio -o | gzip -9 > $@; cd -

.PHONY: installimage
installimage: $(INSTALL_RAMDISK)

endif
endif
