export ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = KaiwanLicense
KaiwanLicense_FILES = Tweak.xm
KaiwanLicense_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk