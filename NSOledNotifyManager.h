#import "global.h"
#import "NSOledNotifyWindow.h"
#import "CCColorCube.h"

@interface NSOledNotifyManager : NSObject {
  NSOledNotifyWindow *_window;
  NSTimer *_hideTimer;
  CALayer *_borderLayer;
  CCColorCube *_colorCube;
}
@property (nonatomic, assign) BOOL isDisplayingOled;
+ (instancetype)sharedInstance;
- (void)load;
- (void)show:(BBBulletin *)bulletin;
- (void)addIconFromBulletin:(BBBulletin *)bulletin;
- (void)hide;
- (void)fadeOn;
- (void)fadeOut:(void(^)(BOOL finished))completion;
- (void)animateBorder;
- (void)animateBorder:(NSString *)key;
- (CAAnimation *)animationForKey:(NSString *)key;
@end
