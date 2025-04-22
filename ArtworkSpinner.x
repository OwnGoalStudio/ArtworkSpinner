@import UIKit;

#import <notify.h>
#import <Foundation/NSUserDefaults+Private.h>
#import <MediaRemote/MediaRemote+Private.h>

#define PREF_PATH "/var/mobile/Library/Preferences/com.82flex.artworkspinnerprefs.plist"
#define PREF_NOTIFY_NAME "com.82flex.artworkspinnerprefs/saved"

@class MRUArtworkView;

@interface ASMediaRemoteObserver : NSObject
- (void)registerArtworkView:(MRUArtworkView *)view;
@end

static ASMediaRemoteObserver *gObserver = nil;

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

@interface MRUArtworkView : UIView
@property (nonatomic, strong) UIImageView *artworkImageView;
@property (nonatomic, strong) UIViewPropertyAnimator *as_propertyAnimator;
- (void)as_rotate;
- (void)as_beginRotation;
- (void)as_endRotation;
@end

%hook MRUArtworkView

%property (nonatomic, strong) UIViewPropertyAnimator *as_propertyAnimator;

%new
- (void)as_rotate {
    __weak __typeof(self) weakSelf = self;
    int repeatTimes = 10;
    UIViewPropertyAnimator *animator = [[UIViewPropertyAnimator alloc] initWithDuration:4.0 * repeatTimes / kSpeedExponent curve:UIViewAnimationCurveLinear animations:^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.artworkImageView.transform = CGAffineTransformRotate(strongSelf.artworkImageView.transform, M_PI);
    }];
    while (--repeatTimes) {
        [animator addAnimations:^{
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.artworkImageView.transform = CGAffineTransformRotate(strongSelf.artworkImageView.transform, M_PI);
        }];
    }
    [animator addCompletion:^(UIViewAnimatingPosition finalPosition) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf as_rotate];
    }];
    [animator startAnimation];
    self.as_propertyAnimator = animator;
}

%new
- (void)as_beginRotation {
    if (!self.as_propertyAnimator) {
        [self as_rotate];
    } else {
        [self.as_propertyAnimator startAnimation];
    }
}

%new
- (void)as_endRotation {
    [self.as_propertyAnimator pauseAnimation];
}

%end

@interface _TtC13MediaRemoteUI34CoverSheetBackgroundViewController : UIViewController
- (MRUArtworkView *)artworkView;
@end

%hook _TtC13MediaRemoteUI34CoverSheetBackgroundViewController

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    if (!kIsEnabled || !kIsEnabledInCoverSheetBackground) {
        return;
    }
    [gObserver registerArtworkView:self.artworkView];
}

%end

@interface MRUNowPlayingViewController : UIViewController
- (MRUArtworkView *)artworkView;
@end

%hook MRUNowPlayingViewController

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    if (!kIsEnabled || !kIsEnabledInMediaControls) {
        return;
    }
    [gObserver registerArtworkView:self.artworkView];
}

%end

@interface ASWeakContainer : NSObject
@property (nonatomic, weak) NSObject *object;
@end

@implementation ASWeakContainer
@end

@implementation ASMediaRemoteObserver {
    BOOL _isNowPlaying;
    NSMutableSet<ASWeakContainer *> *_weakContainers;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _isNowPlaying = NO;
        _weakContainers = [[NSMutableSet alloc] init];

        [[NSNotificationCenter defaultCenter]
            addObserver:self
               selector:@selector(handleSessionEvent:)
                   name:(__bridge NSNotificationName)kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification
                 object:nil];

        MRMediaRemoteSetWantsNowPlayingNotifications(true);
        MRMediaRemoteGetNowPlayingApplicationIsPlaying(dispatch_get_main_queue(), ^(Boolean isPlaying) {
            _isNowPlaying = isPlaying;
            [self toggleArtworkAnimations];
        });
    }
    return self;
}

- (void)handleSessionEvent:(NSNotification *_Nullable)aNotification {
    NSDictionary *userInfo = aNotification.userInfo;
    BOOL isPlaying = [userInfo[(__bridge NSNotificationName)kMRMediaRemoteNowPlayingApplicationIsPlayingUserInfoKey] boolValue];
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        _isNowPlaying = isPlaying;
        [self toggleArtworkAnimations];
    });
}

- (void)registerArtworkView:(MRUArtworkView *)view {
    if (!view) {
        return;
    }

    NSMutableSet<ASWeakContainer *> *containersToRemove = [NSMutableSet set];
    for (ASWeakContainer *container in _weakContainers) {
        if (!container.object || container.object == view) {
            [containersToRemove addObject:container];
        }
    }
    [_weakContainers minusSet:containersToRemove];

    ASWeakContainer *container = [[ASWeakContainer alloc] init];
    container.object = view;
    [_weakContainers addObject:container];

    [self toggleArtworkAnimation:view];
}

- (void)toggleArtworkAnimations {
    if (_isNowPlaying) {
        [self resumeArtworkAnimations];
    } else {
        [self pauseArtworkAnimations];
    }
}

- (void)pauseArtworkAnimations {
    for (ASWeakContainer *container in _weakContainers) {
        MRUArtworkView *view = (MRUArtworkView *)container.object;
        [self pauseArtworkAnimation:view];
    }
}

- (void)resumeArtworkAnimations {
    for (ASWeakContainer *container in _weakContainers) {
        MRUArtworkView *view = (MRUArtworkView *)container.object;
        [self resumeArtworkAnimation:view];
    }
}

- (void)toggleArtworkAnimation:(MRUArtworkView *)view {
    if (_isNowPlaying) {
        [self resumeArtworkAnimation:view];
    } else {
        [self pauseArtworkAnimation:view];
    }
}

- (void)pauseArtworkAnimation:(MRUArtworkView *)view {
    if (!view) {
        return;
    }
    [view as_endRotation];
}

- (void)resumeArtworkAnimation:(MRUArtworkView *)view {
    if (!view) {
        return;
    }
    [view as_beginRotation];
}

@end

%ctor {
    ReloadPrefs();
    int _gNotifyToken;
    notify_register_dispatch(PREF_NOTIFY_NAME, &_gNotifyToken, dispatch_get_main_queue(), ^(int token) {
      ReloadPrefs();
    });

    gObserver = [[ASMediaRemoteObserver alloc] init];
    (void)gObserver;
}
