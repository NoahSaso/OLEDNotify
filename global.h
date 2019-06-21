#import <BulletinBoard/BBBulletin.h>
#import <SpringBoard/SBBacklightController.h>
#import <SpringBoard/SBLockScreenManager.h>
#import <SpringBoard/SBLockScreenViewController.h>
#import "NSOledNotifyManager.h"
#import "NSOledNotifyWindow.h"
#import <QuartzCore/QuartzCore.h>
#import "NSObject+SafeKVC.h"
#import "CCColorCube.h"

#define kName @"OLEDNotify"
#import <Custom/defines.h>

#define kNSOLEDNotifyBacklightAdjustmentSource 673
#define kNSOLEDNotifyTappedNotification @"kOLEDNotifyTappedNotification"
#define FADE_DURATION 0.2
#define IMAGE_VIEW_TAG 673
#define VISIBLE_DURATION 3.0
#define FADE_SPEED_FACTOR 0.7
#define CONTINUOUS_CORNER_RADIUS 39.0

#define ANIMATION_KEY_BREATHE @"BREATHE"
#define ANIMATION_KEY_REVEAL @"REVEAL"

@interface BBBulletin (OLEDNotify)
- (BOOL)turnsOnDisplay;
- (void)handleWithOLEDNotify:(BBBulletin *)bulletin;
@end

@interface SBBacklightController (OLEDNotify)
- (void)_animateBacklightToFactor:(float)arg1 duration:(double)arg2 source:(long long)arg3 silently:(BOOL)arg4 completion:(/*^block*/id)arg5;
- (void)setBacklightFactor:(float)factor source:(long long)source;
@end

@interface SBLockScreenViewController (OLEDNotify)
- (BOOL)isInScreenOffMode;
@end

@interface SBApplicationIcon : NSObject
- (UIImage *)generateIconImage:(int)arg1;
@end

@interface SBIconModel : NSObject
- (SBApplicationIcon *)expectedIconForDisplayIdentifier:(id)arg1;
@end

@interface SBIconController : UIViewController
@property (nonatomic, retain) SBIconModel *model;
+ (id)sharedInstance;
@end

@interface SBUIBiometricResource : NSObject {
  BOOL _isPresenceDetectionAllowed;
}
+ (id)sharedInstance;
- (void)noteScreenWillTurnOn;
@end

@interface SBLiftToWakeManager : NSObject
@property (setter=_setLockScreenManager:, getter=_lockScreenManager, nonatomic, retain) SBLockScreenManager *lockScreenManager;
@end

@interface SBScreenWakeAnimationController : NSObject
+ (instancetype)sharedInstance;
- (void)_startWakeIfNecessary;
@end

@interface SBTapToWakeController : NSObject
+ (BOOL)isTapToWakeSupported;
@end

@interface CALayer (OLEDNotify)
@property (assign) BOOL continuousCorners;
@end
