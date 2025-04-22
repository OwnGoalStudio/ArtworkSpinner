TARGET := iphone:clang:16.5:14.0
INSTALL_TARGET_PROCESSES := Preferences
ARCHS := arm64 arm64e

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME := ArtworkSpinnerPrefs

ArtworkSpinnerPrefs_FILES += ArtworkSpinnerRootListController.m
ArtworkSpinnerPrefs_CFLAGS += -fobjc-arc

ArtworkSpinnerPrefs_FRAMEWORKS += UIKit
ArtworkSpinnerPrefs_PRIVATE_FRAMEWORKS += Preferences
ArtworkSpinnerPrefs_INSTALL_PATH += /Library/PreferenceBundles

include $(THEOS_MAKE_PATH)/bundle.mk