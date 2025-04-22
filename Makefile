TARGET := iphone:clang:latest:14.0

INSTALL_TARGET_PROCESSES += MediaRemoteUI

include $(THEOS)/makefiles/common.mk

TWEAK_NAME += ArtworkSpinner

ArtworkSpinner_FILES += ArtworkSpinner.x
ArtworkSpinner_CFLAGS += -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += ArtworkSpinnerPrefs

include $(THEOS_MAKE_PATH)/aggregate.mk
