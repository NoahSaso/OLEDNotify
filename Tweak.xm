#import "global.h"

%hook BBServer

%new
- (void)handleWithOLEDNotify:(BBBulletin *)bulletin {
	// Check if notification within last 5 seconds so we don't send uncleared notifications every respring
	NSDate *fiveSecondsAgo = [[NSDate date] dateByAddingTimeInterval:-5];
	if (bulletin.date && [bulletin.date compare:fiveSecondsAgo] == NSOrderedAscending) {
		return;
	}
	[[NSOledNotifyManager sharedInstance] show:bulletin];
}

// iOS 10 & 11
- (void)publishBulletin:(BBBulletin *)bulletin destinations:(unsigned long long)arg2 alwaysToLockScreen:(BOOL)arg3 {
	if (!bulletin.turnsOnDisplay) return %orig;
	bulletin.turnsOnDisplay = NO;
	%orig(bulletin, arg2, arg3);
	[self handleWithOLEDNotify:bulletin];
}

// iOS 12
- (void)publishBulletin:(BBBulletin *)bulletin destinations:(unsigned long long)arg2 {
	if (!bulletin.turnsOnDisplay) return %orig;
	bulletin.turnsOnDisplay = NO;
	%orig(bulletin, arg2);
	[self handleWithOLEDNotify:bulletin];
}

%end

%hook SBUIBiometricResource

- (void)noteScreenWillTurnOn {
	if ([NSOledNotifyManager sharedInstance].isDisplayingOled) {
		// If we're in OLED mode, disable Face ID detecting faces
		[self safelySetValue:@NO forKey:@"_isPresenceDetectionAllowed"];
		return;
	}
	%orig;
}

%end

%hook SBBacklightController

- (BOOL)screenIsOn {
    // If we're in OLED mode, trick system into thinking the screen is off
    if ([NSOledNotifyManager sharedInstance].isDisplayingOled) return NO;
    return %orig;
}

- (void)_animateBacklightToFactor:(float)factor duration:(double)duration source:(long long)source silently:(BOOL)silently completion:(/*^block*/id)completion {
	if ([NSOledNotifyManager sharedInstance].isDisplayingOled && source != kNSOLEDNotifyBacklightAdjustmentSource) {
		// Hacky solution to fix animations not working because SpringBoard ignores this wake
		// Basically, when we wake for OLED mode, we do it with silently set to YES. The rest of SpringBoard isn't notified.
		// But when we actually want to wake up the phone for real, it isn't sent because the factor is already 1.
		// Here we adjust the factor by a tiny bit so that the events get sent throughout SpringBoard.
		[[%c(SBBacklightController) sharedInstance] _animateBacklightToFactor:factor-0.0001 duration:0 source:kNSOLEDNotifyBacklightAdjustmentSource silently:YES completion:nil];
	}
	%orig;
	if (![NSOledNotifyManager sharedInstance].isDisplayingOled || source == kNSOLEDNotifyBacklightAdjustmentSource) return;
	// Animate the OLED mode curtain away if we're animating backlight
	[[NSOledNotifyManager sharedInstance] fadeOut:^(BOOL finished) {
		if (finished) {
			[[%c(SBUIBiometricResource) sharedInstance] noteScreenWillTurnOn];
		}
	}];
}

- (void)setBacklightFactor:(float)factor source:(long long)source {
	if ([NSOledNotifyManager sharedInstance].isDisplayingOled && factor <= 0 && source != kNSOLEDNotifyBacklightAdjustmentSource) return;
	%orig;
}

%end

%hook SBLiftToWakeManager

// iOS 11
- (void)liftToWakeController:(id)arg1 didObserveTransition:(long long)transition {
	if ([NSOledNotifyManager sharedInstance].isDisplayingOled && transition == 2) {
		// Restore lift to wake while in OLED mode
		[[NSOledNotifyManager sharedInstance] fadeOn];
		return;
	}
	%orig;
}

// iOS 12
- (void)liftToWakeController:(id)arg1 didObserveTransition:(long long)transition deviceOrientation:(long long)deviceOrientation {
	if ([NSOledNotifyManager sharedInstance].isDisplayingOled && transition == 2) {
		// Restore lift to wake while in OLED mode
		[[NSOledNotifyManager sharedInstance] fadeOn];
		return;
	}
	%orig;
}

%end

%ctor {
	// CFPreferencesSynchronize(PUSHER_APP_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	// CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)pusherPrefsChanged, PUSHER_PREFS_NOTIFICATION, NULL, CFNotificationSuspensionBehaviorCoalesce);
	// pusherPrefsChanged();
	// %init;
	// [NSPTestPush load];
}
