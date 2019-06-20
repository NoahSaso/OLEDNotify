#import "global.h"

@implementation NSOledNotifyManager

+ (instancetype)sharedInstance {
  static NSOledNotifyManager *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [NSOledNotifyManager new];
  });
  return sharedInstance;
}

- (id)init {
  self = [super init];
  if (self) {
    _colorCube = [CCColorCube new];
    self.isDisplayingOled = NO;
  }
  return self;
}

- (void)load {
	XLog(@"Loading manager");

  _window = [NSOledNotifyWindow new];

  UIViewController *viewController = [UIViewController new];

  UIView *view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];

  _borderLayer = [CALayer new];
  _borderLayer.frame = view.layer.bounds;
  _borderLayer.borderWidth = 0;
  _borderLayer.continuousCorners = YES;
  _borderLayer.cornerRadius = CONTINUOUS_CORNER_RADIUS;
  [view.layer addSublayer:_borderLayer];

  viewController.view = view;
  _window.rootViewController = viewController;

  XLog(@"Loaded manager");
}

- (void)show:(BBBulletin *)bulletin {
  // XLog(@"show bulletin: %@", bulletin);
  if (!bulletin || ![((SBLockScreenManager *)[%c(SBLockScreenManager) sharedInstance]).lockScreenViewController isInScreenOffMode]) {
    return;
  }

  dispatch_async(dispatch_get_main_queue(), ^{
    if (!self.isDisplayingOled) {
      [self load];
      [self addIconFromBulletin:bulletin];
      self.isDisplayingOled = YES;
      [[%c(SBBacklightController) sharedInstance] _animateBacklightToFactor:1 duration:FADE_DURATION source:kNSOLEDNotifyBacklightAdjustmentSource silently:YES completion:^{
        [self animateBorder];
        _hideTimer = [NSTimer scheduledTimerWithTimeInterval:VISIBLE_DURATION target:self selector:@selector(hide) userInfo:nil repeats:NO];
      }];
    } else {
      // if already loaded, blink and reset timer
      if (_hideTimer) {
        [_hideTimer invalidate];
      }
      [[%c(SBBacklightController) sharedInstance] _animateBacklightToFactor:0 duration:0.1 source:kNSOLEDNotifyBacklightAdjustmentSource silently:YES completion:^{
        [self addIconFromBulletin:bulletin];
        [[%c(SBBacklightController) sharedInstance] _animateBacklightToFactor:1 duration:0.1 source:kNSOLEDNotifyBacklightAdjustmentSource silently:YES completion:^{
          [self animateBorder];
          _hideTimer = [NSTimer scheduledTimerWithTimeInterval:VISIBLE_DURATION target:self selector:@selector(hide) userInfo:nil repeats:NO];
        }];
      }];
    }
  });

}

- (void)animateBorder {
  CABasicAnimation *enlargeBorder = [CABasicAnimation animationWithKeyPath:@"borderWidth"];
  enlargeBorder.fromValue = @0;
  enlargeBorder.toValue = @(BORDER_WIDTH * 2);
  enlargeBorder.duration = BORDER_ANIMATION_DURATION / 2;
  enlargeBorder.beginTime = 0;
  enlargeBorder.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
  enlargeBorder.fillMode = kCAFillModeForwards;

  CABasicAnimation *shrinkBorder = [CABasicAnimation animationWithKeyPath:@"borderWidth"];
  shrinkBorder.fromValue = @(BORDER_WIDTH * 2);
  shrinkBorder.toValue = @(BORDER_WIDTH);
  shrinkBorder.duration = BORDER_ANIMATION_DURATION / 2;
  shrinkBorder.beginTime = BORDER_ANIMATION_DURATION / 2;
  shrinkBorder.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
  shrinkBorder.fillMode = kCAFillModeForwards;

  CAAnimationGroup *group = [CAAnimationGroup new];
  group.duration = BORDER_ANIMATION_DURATION;
  group.animations = @[enlargeBorder, shrinkBorder];
  group.delegate = self;

  [_borderLayer addAnimation:group forKey:@"borderWidthBreathe"];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
  _borderLayer.borderWidth = BORDER_WIDTH;
}

- (void)addIconFromBulletin:(BBBulletin *)bulletin {
  SBApplicationIcon *icon = [((SBIconController *)[%c(SBIconController) sharedInstance]).model expectedIconForDisplayIdentifier:bulletin.sectionID];
	UIImage *image = [icon generateIconImage:2];
  UIImageView *imageView = [_window.rootViewController.view viewWithTag:IMAGE_VIEW_TAG];
  if (imageView) {
    imageView.image = image;
  } else {
    imageView = [[UIImageView alloc] initWithImage:image];
    imageView.tag = IMAGE_VIEW_TAG;
    imageView.center = _window.rootViewController.view.center;
    [_window.rootViewController.view addSubview:imageView];
  }
  CCFlags flags = (CCFlags) (CCOnlyDistinctColors | CCAvoidWhite | CCAvoidBlack);
  NSArray *imgColors = [_colorCube extractColorsFromImage:imageView.image flags:flags];
  _borderLayer.borderColor = ((UIColor *) imgColors[0]).CGColor;
}

- (void)hide {
  if (_hideTimer) {
    [_hideTimer invalidate];
    _hideTimer = nil;
  }
  if (!self.isDisplayingOled) {
    return;
  }
  [[%c(SBBacklightController) sharedInstance] _animateBacklightToFactor:0 duration:FADE_DURATION source:kNSOLEDNotifyBacklightAdjustmentSource silently:YES completion:^{
    self.isDisplayingOled = NO;
    _window.hidden = YES;
    [_window release];
  }];
}

- (void)fadeOn {
  if (_hideTimer) {
    [_hideTimer invalidate];
    _hideTimer = nil;
  }
  if (!self.isDisplayingOled) {
    return;
  }
  [[%c(SBBacklightController) sharedInstance] _animateBacklightToFactor:0 duration:FADE_DURATION * FADE_SPEED_FACTOR source:kNSOLEDNotifyBacklightAdjustmentSource silently:YES completion:^{
    self.isDisplayingOled = NO;
    _window.hidden = YES;
    [_window release];
    [[%c(SBLockScreenManager) sharedInstance] unlockUIFromSource:0x5 withOptions:@{@"SBUIUnlockOptionsStartFadeInAnimation": @YES, @"SBUIUnlockOptionsTurnOnScreenFirstKey": @YES}];
    [[%c(SBScreenWakeAnimationController) sharedInstance] _startWakeIfNecessary];
  }];
}

- (void)fadeOut:(void(^)(BOOL finished))completion {
  if (_hideTimer) {
    [_hideTimer invalidate];
    _hideTimer = nil;
  }
  if (!self.isDisplayingOled) {
    completion(NO);
    return;
  }
  self.isDisplayingOled = NO;
  [UIView animateWithDuration:FADE_DURATION * FADE_SPEED_FACTOR delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
    [_window hide];
  } completion:^(BOOL finished) {
    _window.hidden = YES;
    [_window release];
    completion(finished);
  }];
}

@end
