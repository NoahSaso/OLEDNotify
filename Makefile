ARCMS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = OLEDNotify
OLEDNotify_FILES = Tweak.xm NSOledNotifyManager.xm NSOledNotifyWindow.m NSObject+SafeKVC.m CCLocalMaximum.m CCColorCube.m
OLEDNotify_FRAMEWORKS = UIKit QuartzCore

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
