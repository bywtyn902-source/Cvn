TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AxiomDeltaRoblox

AxiomDeltaRoblox_FILES = Tweak.xm
AxiomDeltaRoblox_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKEFILE_PATH)/tweak.mk
