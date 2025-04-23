export PACKAGE_VERSION := 1.4
export TARGET := iphone:clang:16.5:14.0

INSTALL_TARGET_PROCESSES += MediaRemoteUI
INSTALL_TARGET_PROCESSES += SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME += ArtworkSpinner

ArtworkSpinner_FILES += ArtworkSpinner.x
ArtworkSpinner_CFLAGS += -fobjc-arc
ArtworkSpinner_CFLAGS += -Iheaders

ArtworkSpinner_PRIVATE_FRAMEWORKS += MediaRemote

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += ArtworkSpinnerPrefs

include $(THEOS_MAKE_PATH)/aggregate.mk
