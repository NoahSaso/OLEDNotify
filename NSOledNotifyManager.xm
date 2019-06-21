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
  _borderLayer.borderWidth = 0; // ANIMATION_KEY_BREATHE
  // _borderLayer.borderWidth = _borderLayer.bounds.size.height / 2; // ANIMATION_KEY_REVEAL
  _borderLayer.continuousCorners = YES;
  _borderLayer.cornerRadius = CONTINUOUS_CORNER_RADIUS;
  [view.layer addSublayer:_borderLayer];

  viewController.view = view;
  _window.rootViewController = viewController;

  XLog(@"Loaded manager");
}

- (void)show:(BBBulletin *)bulletin {
  // XLog(@"show bulletin: %@", bulletin);
  XLog(@"Trying to show bulletin: %@", bulletin.sectionID);
  if (!bulletin || ![((SBLockScreenManager *)[%c(SBLockScreenManager) sharedInstance]).lockScreenViewController isInScreenOffMode]) {
    return;
  }

  dispatch_async(dispatch_get_main_queue(), ^{
    XLog(@"Showing: %@", bulletin.sectionID);
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
  [self animateBorder:ANIMATION_KEY_BREATHE];
}

- (void)animateBorder:(NSString *)key {
  XLog(@"Animating key: %@", key);
  CAAnimation *anim = [self animationForKey:key];
  if (anim) [_borderLayer addAnimation:anim forKey:@"layerAnimation"];
}

- (void)addIconFromBulletin:(BBBulletin *)bulletin {
  XLog(@"Adding icon: %@", bulletin.sectionID);
  SBApplicationIcon *icon = [((SBIconController *)[%c(SBIconController) sharedInstance]).model expectedIconForDisplayIdentifier:bulletin.sectionID];
	UIImage *image = [icon generateIconImage:2];
  XLog(@"Icon image: %@", image);
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

- (CAAnimation *)animationForKey:(NSString *)key {

  if (Xeq(key, ANIMATION_KEY_BREATHE)) {
    const CGFloat END_BORDER_WIDTH = 3.0;
    const CGFloat MAX_BORDER_WIDTH = END_BORDER_WIDTH * 2;
    const CGFloat BREATHE_DELAY = 0.35;
    const CGFloat BORDER_ANIMATION_DURATION = 2.0;

    CABasicAnimation *breatheUp = [CABasicAnimation animationWithKeyPath:@"borderWidth"];
    breatheUp.fromValue = @0;
    breatheUp.toValue = @(MAX_BORDER_WIDTH);
    breatheUp.duration = BORDER_ANIMATION_DURATION * 1 / 2.0;
    breatheUp.beginTime = 0;
    breatheUp.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    breatheUp.fillMode = kCAFillModeForwards;

    CABasicAnimation *breatheDown = [CABasicAnimation animationWithKeyPath:@"borderWidth"];
    breatheDown.fromValue = @(MAX_BORDER_WIDTH);
    breatheDown.toValue = @(END_BORDER_WIDTH);
    breatheDown.duration = BORDER_ANIMATION_DURATION - breatheUp.duration;
    breatheDown.beginTime = breatheUp.duration + BREATHE_DELAY;
    breatheDown.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];

    CAAnimationGroup *group = [CAAnimationGroup new];
    group.animations = @[breatheUp, breatheDown];
    group.duration = breatheDown.beginTime + breatheDown.duration;
    group.fillMode = kCAFillModeForwards;
    group.removedOnCompletion = NO;
    group.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

    return group;
  }

  else if (Xeq(key, ANIMATION_KEY_REVEAL)) {
    const CGFloat END_BORDER_WIDTH = 3.0;
    const CGFloat BORDER_ANIMATION_DURATION = 0.8;

    CABasicAnimation *reveal = [CABasicAnimation animationWithKeyPath:@"borderWidth"];
    reveal.fromValue = @(_borderLayer.bounds.size.height / 2);
    reveal.toValue = @(END_BORDER_WIDTH);
    reveal.duration = BORDER_ANIMATION_DURATION;
    reveal.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    reveal.fillMode = kCAFillModeForwards;
    reveal.removedOnCompletion = NO;

    return reveal;
  }

  return nil;

}

@end
