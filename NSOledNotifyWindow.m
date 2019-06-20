#import "global.h"

@implementation NSOledNotifyWindow

- (id)init {
  self = [super init];
  if (self) {
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:1];
    self.hidden = NO;
    self.windowLevel = UIWindowLevelAlert + 1;
  }
  return self;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
  if (self.rootViewController.view.alpha > 0) {
    [[NSOledNotifyManager sharedInstance] fadeOn];
    return NO;
  }
  // for (UIView *view in self.subviews) {
  //   if ([view.nextResponder isKindOfClass:[ABVolumeHUDContainerViewController class]] && [view pointInside:[self convertPoint:point toView:view] withEvent:event]) return YES;
  // }
  return NO;
}

- (BOOL)_shouldCreateContextAsSecure {
  return YES;
}

- (void)hide {
  self.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
}

@end
