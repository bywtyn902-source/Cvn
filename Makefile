include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AxiomDeltaRoblox
AxiomDeltaRoblox_FILES = Tweak.xm
AxiomDeltaRoblox_FRAMEWORKS = UIKit Foundation QuartzCore
AxiomDeltaRoblox_LIBRARIES = substrate

include $(THEOS)/makefiles/tweak.mk
