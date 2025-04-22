@import UIKit;

#import <notify.h>
#import <Foundation/NSUserDefaults+Private.h>
#import <MediaRemote/MediaRemote+Private.h>

#define PREF_PATH "/var/mobile/Library/Preferences/com.82flex.artworkspinnerprefs.plist"
#define PREF_NOTIFY_NAME "com.82flex.artworkspinnerprefs/saved"

@interface ASMediaRemoteObserver : NSObject
- (void)registerAnimationLayer:(CALayer *)layer;
@end

static ASMediaRemoteObserver *gObserver = nil;

static BOOL kIsEnabled = YES;
static BOOL kIsEnabledInMediaControls = YES;
static BOOL kIsEnabledInCoverSheetBackground = YES;
static BOOL kIsPauseSafe = NO;
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
@end

@interface _TtC13MediaRemoteUI34CoverSheetBackgroundViewController : UIViewController
- (MRUArtworkView *)artworkView;
- (void)as_setupAnimation;
- (CABasicAnimation *)as_rotationAnimation;
@end

%hook _TtC13MediaRemoteUI34CoverSheetBackgroundViewController

- (void)viewWillAppear:(BOOL)animated {
    %log; %orig;
    if (!kIsEnabled || !kIsEnabledInCoverSheetBackground) {
        return;
    }
    [self as_setupAnimation];
}

%new
- (void)as_setupAnimation {
    MRUArtworkView *artworkView = (MRUArtworkView *)[self artworkView];
    if ([artworkView respondsToSelector:@selector(artworkImageView)]) {
        [artworkView.artworkImageView.layer removeAnimationForKey:@"as_rotationAnimation"];
        [artworkView.artworkImageView.layer addAnimation:[self as_rotationAnimation] forKey:@"as_rotationAnimation"];
        [gObserver registerAnimationLayer:artworkView.artworkImageView.layer];
    }
}

%new
- (CABasicAnimation *)as_rotationAnimation {
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
- (void)as_setupAnimation;
- (CABasicAnimation *)as_rotationAnimation;
@end

%hook MRUNowPlayingViewController

- (void)viewWillAppear:(BOOL)animated {
    %log; %orig;
    if (!kIsEnabled || !kIsEnabledInMediaControls) {
        return;
    }
    [self as_setupAnimation];
}

%new
- (void)as_setupAnimation {
    MRUArtworkView *artworkView = (MRUArtworkView *)[self artworkView];
    if ([artworkView respondsToSelector:@selector(artworkImageView)]) {
        [artworkView.artworkImageView.layer removeAnimationForKey:@"as_rotationAnimation"];
        [artworkView.artworkImageView.layer addAnimation:[self as_rotationAnimation] forKey:@"as_rotationAnimation"];
        [gObserver registerAnimationLayer:artworkView.artworkImageView.layer];
    }
}

%new
- (CABasicAnimation *)as_rotationAnimation {
    CABasicAnimation *rotation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotation.toValue = @(M_PI * 2);
    rotation.duration = 4.0;
    rotation.speed = kSpeedExponent;
    rotation.repeatCount = HUGE_VALF;
    return rotation;
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
            [self toggleLayerAnimations];
        });
    }
    return self;
}

- (void)handleSessionEvent:(NSNotification *_Nullable)aNotification {
    NSDictionary *userInfo = aNotification.userInfo;
    BOOL isPlaying = [userInfo[(__bridge NSNotificationName)kMRMediaRemoteNowPlayingApplicationIsPlayingUserInfoKey] boolValue];
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        _isNowPlaying = isPlaying;
        [self toggleLayerAnimations];
    });
}

- (void)registerAnimationLayer:(CALayer *)layer {
    if (!layer) {
        return;
    }

    NSMutableSet<ASWeakContainer *> *containersToRemove = [NSMutableSet set];
    for (ASWeakContainer *container in _weakContainers) {
        if (!container.object || container.object == layer) {
            [containersToRemove addObject:container];
        }
    }
    [_weakContainers minusSet:containersToRemove];

    ASWeakContainer *container = [[ASWeakContainer alloc] init];
    container.object = layer;
    [_weakContainers addObject:container];

    [self toggleLayerAnimation:layer];
}

- (void)toggleLayerAnimations {
    if (_isNowPlaying) {
        [self resumeLayerAnimations];
    } else {
        [self pauseLayerAnimations];
    }
}

- (void)pauseLayerAnimations {
    for (ASWeakContainer *container in _weakContainers) {
        CALayer *layer = (CALayer *)container.object;
        [self pauseLayerAnimation:layer];
    }
}

- (void)resumeLayerAnimations {
    for (ASWeakContainer *container in _weakContainers) {
        CALayer *layer = (CALayer *)container.object;
        [self resumeLayerAnimation:layer];
    }
}

- (void)toggleLayerAnimation:(CALayer *)layer {
    if (_isNowPlaying) {
        [self resumeLayerAnimation:layer];
    } else {
        [self pauseLayerAnimation:layer];
    }
}

- (void)pauseLayerAnimation:(CALayer *)layer {
    if (!layer || !kIsPauseSafe) {
        return;
    }
    CFTimeInterval pausedTime = [layer convertTime:CACurrentMediaTime() fromLayer:nil];
    layer.speed = 0.0;
    layer.timeOffset = pausedTime;
}

- (void)resumeLayerAnimation:(CALayer *)layer {
    if (!layer) {
        return;
    }
    CFTimeInterval pausedTime = [layer timeOffset];
    layer.speed = 1.0;
    layer.timeOffset = 0.0;
    layer.beginTime = 0.0;
    CFTimeInterval timeSincePause = [layer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
    layer.beginTime = timeSincePause;
}

@end

%ctor {
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    if ([bundleIdentifier isEqualToString:@"com.apple.MediaRemoteUI"]) {
        kIsPauseSafe = YES;
    }

    ReloadPrefs();
    int _gNotifyToken;
    notify_register_dispatch(PREF_NOTIFY_NAME, &_gNotifyToken, dispatch_get_main_queue(), ^(int token) {
      ReloadPrefs();
    });

    gObserver = [[ASMediaRemoteObserver alloc] init];
    (void)gObserver;
}
