ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = TikTok

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AxiomTikTok
AxiomTikTok_FILES = Tweak.xm
AxiomTikTok_CFLAGS = -fobjc-arc
AxiomTikTok_FRAMEWORKS = UIKit Foundation
AxiomTikTok_LDFLAGS = -Wl,-undefined,dynamic_lookup

include $(THEOS)/makefiles/tweak.mk
