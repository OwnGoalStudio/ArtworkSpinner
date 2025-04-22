@import UIKit;

#import <notify.h>
#import <Foundation/NSUserDefaults+Private.h>

#define PREF_PATH "/var/mobile/Library/Preferences/com.82flex.artworkspinnerprefs.plist"

static BOOL kIsEnabled = YES;
static BOOL kIsEnabledInMediaControls = YES;
static BOOL kIsEnabledInCoverSheetBackground = YES;
static CGFloat kSpeedExponent = 1.0;

static void ReloadPrefs() {
    static NSUserDefaults *prefs = nil;
    if (!prefs) {
        prefs = [[NSUserDefaults alloc] _initWithSuiteName:@PREF_PATH container:nil];
    }

    NSDictionary *settings = [prefs dictionaryRepresentation];

    kIsEnabled = settings[@"IsEnabled"] ? [settings[@"IsEnabled"] boolValue] : YES;
    kIsEnabledInMediaControls = settings[@"IsEnabledInMediaControls"] ? [settings[@"IsEnabledInMediaControls"] boolValue] : YES;
    kIsEnabledInCoverSheetBackground = settings[@"IsEnabledInCoverSheetBackground"] ? [settings[@"IsEnabledInCoverSheetBackground"] boolValue] : YES;
    kSpeedExponent = settings[@"SpeedExponent"] ? [settings[@"SpeedExponent"] doubleValue] : 1.0;
}

@interface _TtC13MediaRemoteUI34CoverSheetBackgroundViewController : UIViewController
- (UIView *)artworkView;
- (CABasicAnimation *)rotationAnimation;
@end

%hook _TtC13MediaRemoteUI34CoverSheetBackgroundViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    if (!kIsEnabled || !kIsEnabledInCoverSheetBackground) {
        return;
    }

    UIView *artworkView = [self artworkView];
    [artworkView.layer removeAnimationForKey:@"as_rotationAnimation"];
    [artworkView.layer addAnimation:[self rotationAnimation] forKey:@"as_rotationAnimation"];
}

%new
- (CABasicAnimation *)rotationAnimation {
    CABasicAnimation *rotation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotation.toValue = @(M_PI * 2);
    rotation.duration = 4.0;
    rotation.speed = kSpeedExponent;
    rotation.repeatCount = HUGE_VALF;
    return rotation;
}

%end

@interface MRUNowPlayingViewController : UIViewController
- (UIView *)artworkView;
- (CABasicAnimation *)rotationAnimation;
@end

%hook MRUNowPlayingViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    if (!kIsEnabled || !kIsEnabledInMediaControls) {
        return;
    }

    UIView *artworkView = (UIView *)[self artworkView];
    [artworkView.layer removeAnimationForKey:@"as_rotationAnimation"];
    [artworkView.layer addAnimation:[self rotationAnimation] forKey:@"as_rotationAnimation"];
}

%new
- (CABasicAnimation *)rotationAnimation {
    CABasicAnimation *rotation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotation.toValue = @(M_PI * 2);
    rotation.duration = 4.0;
    rotation.speed = kSpeedExponent;
    rotation.repeatCount = HUGE_VALF;
    return rotation;
}

%end

%ctor {
    ReloadPrefs();
    int _gNotifyToken;
    notify_register_dispatch("com.82flex.artworkspinnerprefs/saved", &_gNotifyToken, dispatch_get_main_queue(), ^(int token) {
      ReloadPrefs();
    });
}
