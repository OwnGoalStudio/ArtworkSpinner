@import UIKit;

#import <notify.h>
#import <Foundation/NSUserDefaults+Private.h>
#import <MediaRemote/MediaRemote+Private.h>

#import "UIColor+.h"

#define PREF_PATH "/var/mobile/Library/Preferences/com.82flex.artworkspinnerprefs.plist"
#define PREF_NOTIFY_NAME "com.82flex.artworkspinnerprefs/saved"

@protocol ASRotator <NSObject>
- (void)as_rotate;
- (void)as_beginRotation;
- (void)as_endRotation;
@end

@class ASMediaProgressView;

@interface ASMediaRemoteObserver : NSObject
- (void)registerRotator:(id<ASRotator>)rotator;
- (void)registerProgressView:(ASMediaProgressView *)progressView;
@end

static ASMediaRemoteObserver *gObserver = nil;

static BOOL kIsEnabled = YES;
static BOOL kIsEnabledInMediaControls = YES;
static BOOL kIsEnabledInCoverSheetBackground = YES;
static BOOL kIsEnabledInDynamicIsland = YES;
static CGFloat kSpeedExponent = 1.0;

static BOOL kIsMediaProgressEnabled = YES;
static UIColor *kMediaProgressForegroundColor = nil;

static UIColor *asColorWithHexString(NSString *hexString) {
    if (!hexString) {
        return nil;
    }
    return [UIColor as_colorWithExternalRepresentation:hexString];
}

static void ReloadPrefs() {
    static NSUserDefaults *prefs = nil;
    if (!prefs) {
        prefs = [[NSUserDefaults alloc] _initWithSuiteName:@PREF_PATH container:nil];
    }

    NSDictionary *settings = [prefs dictionaryRepresentation];

    kIsEnabled = settings[@"IsEnabled"] ? [settings[@"IsEnabled"] boolValue] : YES;
    kIsEnabledInMediaControls = settings[@"IsEnabledInMediaControls"] ? [settings[@"IsEnabledInMediaControls"] boolValue] : YES;
    kIsEnabledInCoverSheetBackground = settings[@"IsEnabledInCoverSheetBackground"] ? [settings[@"IsEnabledInCoverSheetBackground"] boolValue] : YES;
    kIsEnabledInDynamicIsland = settings[@"IsEnabledInDynamicIsland"] ? [settings[@"IsEnabledInDynamicIsland"] boolValue] : YES;
    kSpeedExponent = settings[@"SpeedExponent"] ? [settings[@"SpeedExponent"] doubleValue] : 1.0;

    kIsMediaProgressEnabled = settings[@"IsMediaProgressEnabled"] ? [settings[@"IsMediaProgressEnabled"] boolValue] : YES;

    NSString *lightFgColorStr = settings[@"ForegroundColorLight"] ? settings[@"ForegroundColorLight"] : @"#32c759";
    NSString *darkFgColorStr = settings[@"ForegroundColorDark"] ? settings[@"ForegroundColorDark"] : @"#2cd057";

    UIColor *lightFgColor = asColorWithHexString(lightFgColorStr);
    UIColor *darkFgColor = asColorWithHexString(darkFgColorStr);

    UIColor *mixedColor = [[UIColor alloc] initWithDynamicProvider:^UIColor *(UITraitCollection *traitCollection) {
        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            return darkFgColor;
        } else {
            return lightFgColor;
        }
    }];

    kMediaProgressForegroundColor = mixedColor;
}

@interface MRUArtworkView : UIView <ASRotator>
@property (nonatomic, strong) UIView *packageView;  // <- MRUActivityArtworkView?
@property (nonatomic, strong) UIImageView *artworkImageView;
@property (nonatomic, strong) UIViewPropertyAnimator *as_propertyAnimator;
@end

@interface _TtC13MediaRemoteUI34CoverSheetBackgroundViewController : UIViewController
- (MRUArtworkView *)artworkView;
@end

@interface MRUNowPlayingViewController : UIViewController
- (MRUArtworkView *)artworkView;
@end

@interface MRUActivityNowPlayingView : UIView <ASRotator>
@property (nonatomic, strong) NSArray<MRUArtworkView *> *artworkViews;
@end

%group ArtworkSpinner

%hook MRUArtworkView

%property (nonatomic, strong) UIViewPropertyAnimator *as_propertyAnimator;

- (void)dealloc {
    if (self.as_propertyAnimator) {
        [self.as_propertyAnimator stopAnimation:YES];
        self.as_propertyAnimator = nil;
    }
    %orig;
}

%new
- (void)as_rotate {
    UIView *targetView = nil;
    if ([self respondsToSelector:@selector(packageView)]) {
        targetView = self.packageView;
    } else if ([self respondsToSelector:@selector(artworkImageView)]) {
        targetView = self.artworkImageView;
    } else {
        return;
    }
    if (!targetView) {
        return;
    }
    int repeatTimes = 10;
    UIViewPropertyAnimator *animator = [[UIViewPropertyAnimator alloc] initWithDuration:4.0 * repeatTimes / kSpeedExponent curve:UIViewAnimationCurveLinear animations:^{
        targetView.transform = CGAffineTransformRotate(targetView.transform, M_PI);
    }];
    while (--repeatTimes) {
        [animator addAnimations:^{
            targetView.transform = CGAffineTransformRotate(targetView.transform, M_PI);
        }];
    }
    __weak __typeof(self) weakSelf = self;
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

%hook _TtC13MediaRemoteUI34CoverSheetBackgroundViewController

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    if (!kIsEnabled || !kIsEnabledInCoverSheetBackground ||
        ![self respondsToSelector:@selector(artworkView)] ||
        ![self.artworkView respondsToSelector:@selector(artworkImageView)]
    ) {
        return;
    }
    [gObserver registerRotator:self.artworkView];
}

%end

%hook MRUNowPlayingViewController

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    if (!kIsEnabled || !kIsEnabledInMediaControls ||
        ![self respondsToSelector:@selector(artworkView)] ||
        ![self.artworkView respondsToSelector:@selector(artworkImageView)]
    ) {
        return;
    }
    [gObserver registerRotator:self.artworkView];
}

%end

%hook MRUActivityNowPlayingView

- (instancetype)initWithWaveformView:(id)arg1 {
    id ret = %orig;
    if (!kIsEnabled || !kIsEnabledInDynamicIsland ||
        ![self respondsToSelector:@selector(artworkViews)]
    ) {
        return ret;
    }
    for (MRUArtworkView *artworkView in self.artworkViews) {
        if (![artworkView respondsToSelector:@selector(packageView)]) {
            continue;
        }
        [gObserver registerRotator:artworkView];
    }
    return ret;
}

%end

%end // ArtworkSpinner

@interface ASMediaProgressView : UIView
- (void)setPlaying:(BOOL)isPlaying;
- (void)setCurrentTime:(NSTimeInterval)currentTime duration:(NSTimeInterval)duration playbackRate:(NSTimeInterval)playbackRate;
@end

@implementation ASMediaProgressView {
    BOOL _isStable;
    BOOL _isPlaying;
    NSTimeInterval _currentTime;
    NSTimeInterval _duration;
    NSTimeInterval _playbackRate;
    NSTimeInterval _reportTime;
    CADisplayLink *_displayLink;
    UIColor *_foregroundColor;
    CGFloat _backgroundAlpha;
    UIColor *_backgroundColor;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self enterUnstableState];
}

- (void)enterUnstableState {
    _isStable = NO;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(leaveUnstableState) object:nil];
    [self performSelector:@selector(leaveUnstableState) withObject:nil afterDelay:3.0];
    [self reloadVisibility];
}

- (void)leaveUnstableState {
    _isStable = YES;
    [self reloadVisibility];
}

- (void)setPlaying:(BOOL)isPlaying {
    _isPlaying = isPlaying;
    [self reloadVisibility];

    if (_isPlaying && !_displayLink) {
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateProgress)];
        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    } else if (!_isPlaying && _displayLink) {
        [_displayLink invalidate];
        _displayLink = nil;
    }
}

- (void)setCurrentTime:(NSTimeInterval)currentTime duration:(NSTimeInterval)duration playbackRate:(NSTimeInterval)playbackRate {
    _currentTime = currentTime;
    _duration = duration;
    _playbackRate = playbackRate;
    _reportTime = CACurrentMediaTime();
    [self reloadVisibility];
}

- (void)reloadVisibility {
    _foregroundColor = [kMediaProgressForegroundColor resolvedColorWithTraitCollection:self.traitCollection];
    UIView *decorLine = nil;
    NSArray<UIView *> *decorViews = self.superview.subviews.firstObject.subviews;
    if (decorViews.count > 1) {
        decorLine = decorViews[1];
        _backgroundAlpha = decorLine.alpha;
        _backgroundColor = decorLine.backgroundColor;
    }
    [self setNeedsDisplay];
    if (self.bounds.size.height < 48 && _isStable && _isPlaying && _duration > 1) {
        if (self.alpha < 1e-3) {
            [UIView animateWithDuration:0.25 animations:^{
                self.alpha = 1;
            } completion:nil];
            [UIView transitionWithView:self.superview duration:0.25 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                decorLine.hidden = YES;
            } completion:nil];
        }
    } else {
        decorLine.hidden = NO;
        self.alpha = 0;
    }
}

- (void)updateProgress {
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    // Don't draw anything if duration is too short
    if (!_isPlaying || _duration < 1) {
        return;
    }

    // Calculate current progress
    NSTimeInterval elapsedTime = _currentTime + (CACurrentMediaTime() - _reportTime) * _playbackRate;
    CGFloat progress = MIN(MAX(elapsedTime / _duration, 0.0), 1.0);

    // Get view dimensions
    CGFloat width = CGRectGetWidth(rect);
    CGFloat height = CGRectGetHeight(rect);

    // Drawing constants
    CGFloat lineWidth = 2.0;
    CGFloat cornerRadius = height / 2;  // For capsule shape (stadium shape)
    CGFloat drawRadius = cornerRadius - lineWidth / 2;  // Actual drawing radius accounting for line width

    // Set up graphics context
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);

    // Create the track path (full capsule shape)
    CGRect insetRect = CGRectInset(rect, lineWidth / 2, lineWidth / 2);
    UIBezierPath *trackPath = [UIBezierPath bezierPathWithRoundedRect:insetRect
                                                         cornerRadius:cornerRadius];

    // Draw background track
    if (_backgroundColor && _backgroundAlpha > 1e-2) {
        [[_backgroundColor colorWithAlphaComponent:_backgroundAlpha] setStroke];
    } else {
        [[UIColor colorWithWhite:0.7 alpha:0.35] setStroke];
    }
    trackPath.lineWidth = lineWidth;
    [trackPath stroke];

    // Skip progress drawing if no progress
    if (progress <= 0) {
        CGContextRestoreGState(context);
        return;
    }

    // Define key points for the path
    CGPoint startPoint = CGPointMake(width / 2, lineWidth / 2);  // Top center (12 o'clock position)
    CGPoint topRightCorner = CGPointMake(width - cornerRadius, lineWidth / 2);
    CGPoint rightArcCenter = CGPointMake(width - cornerRadius, cornerRadius);
    CGPoint bottomRightCorner = CGPointMake(width - cornerRadius, height - lineWidth / 2);
    CGPoint bottomLeftCorner = CGPointMake(cornerRadius, height - lineWidth / 2);
    CGPoint leftArcCenter = CGPointMake(cornerRadius, cornerRadius);

    // Calculate lengths of different segments
    CGFloat rightHalfTopLength = width / 2 - cornerRadius;  // From top center to start of right arc
    CGFloat rightArcLength = M_PI * drawRadius;  // Half circle (180°) arc length
    CGFloat bottomLength = width - 2 * cornerRadius;  // Straight bottom section
    CGFloat leftArcLength = M_PI * drawRadius;  // Half circle (180°) arc length
    CGFloat leftHalfTopLength = width / 2 - cornerRadius;  // From end of left arc to top center

    // Accumulated segment lengths for progress comparison
    CGFloat len1 = rightHalfTopLength;
    CGFloat len2 = len1 + rightArcLength;
    CGFloat len3 = len2 + bottomLength;
    CGFloat len4 = len3 + leftArcLength;
    CGFloat totalLength = len4 + leftHalfTopLength;

    // Calculate absolute progress length
    CGFloat progressLength = totalLength * progress;

    // Create progress path
    UIBezierPath *progressPath = [UIBezierPath bezierPath];
    [progressPath moveToPoint:startPoint];

    // Draw segments based on progress
    if (progressLength <= rightHalfTopLength) {
        // Only draw part of the top-right straight section
        [progressPath addLineToPoint:CGPointMake(width / 2 + progressLength, lineWidth / 2)];
    }
    else if (progressLength <= len2) {
        // Draw full top-right straight section and part of right arc
        [progressPath addLineToPoint:topRightCorner];

        // Calculate angle for partial right arc
        CGFloat arcProgress = progressLength - rightHalfTopLength;
        CGFloat angle = arcProgress / drawRadius;

        // Draw partial right arc - starting from top (-π/2) going clockwise
        [progressPath addArcWithCenter:rightArcCenter
                                radius:drawRadius
                            startAngle:-M_PI / 2  // Top (12 o'clock)
                              endAngle:-M_PI / 2 + angle
                             clockwise:YES];
    }
    else if (progressLength <= len3) {
        // Draw full top-right section, complete right arc, and part of bottom
        [progressPath addLineToPoint:topRightCorner];

        // Draw complete right arc - half circle from top to bottom
        [progressPath addArcWithCenter:rightArcCenter
                                radius:drawRadius
                            startAngle:-M_PI / 2  // Top (12 o'clock)
                              endAngle:M_PI / 2   // Bottom (6 o'clock)
                             clockwise:YES];

        // Calculate distance along bottom edge
        CGFloat bottomProgress = progressLength - len2;

        // Draw partial bottom line from right to left
        [progressPath addLineToPoint:CGPointMake(bottomRightCorner.x - bottomProgress,
                                                bottomRightCorner.y)];
    }
    else if (progressLength <= len4) {
        // Draw full top-right section, right arc, bottom line, and part of left arc
        [progressPath addLineToPoint:topRightCorner];

        // Draw complete right arc
        [progressPath addArcWithCenter:rightArcCenter
                                radius:drawRadius
                            startAngle:-M_PI / 2  // Top (12 o'clock)
                              endAngle:M_PI / 2   // Bottom (6 o'clock)
                             clockwise:YES];

        // Draw complete bottom line
        [progressPath addLineToPoint:bottomLeftCorner];

        // Calculate partial left arc
        CGFloat leftArcProgress = progressLength - len3;
        CGFloat angle = leftArcProgress / drawRadius;

        // Draw partial left arc - starting from bottom going counterclockwise
        [progressPath addArcWithCenter:leftArcCenter
                                radius:drawRadius
                            startAngle:M_PI / 2    // Bottom (6 o'clock)
                              endAngle:M_PI / 2 + angle
                             clockwise:YES];
    }
    else {
        // Draw full path except maybe part of top-left section
        [progressPath addLineToPoint:topRightCorner];

        // Draw complete right arc
        [progressPath addArcWithCenter:rightArcCenter
                                radius:drawRadius
                            startAngle:-M_PI / 2  // Top (12 o'clock)
                              endAngle:M_PI / 2   // Bottom (6 o'clock)
                             clockwise:YES];

        // Draw complete bottom line
        [progressPath addLineToPoint:bottomLeftCorner];

        // Draw complete left arc
        [progressPath addArcWithCenter:leftArcCenter
                                radius:drawRadius
                            startAngle:M_PI / 2   // Bottom (6 o'clock)
                              endAngle:-M_PI / 2  // Top (12 o'clock)
                             clockwise:YES];

        // Draw partial top-left line back to start point if needed
        CGFloat topLeftProgress = progressLength - len4;
        if (topLeftProgress > 0) {
            // Calculate endpoint on top edge
            CGPoint endPoint = CGPointMake(cornerRadius + topLeftProgress, lineWidth / 2);
            [progressPath addLineToPoint:endPoint];
        }
    }

    // Draw the progress line
    [(_foregroundColor ?: [UIColor systemBlueColor]) setStroke];
    progressPath.lineWidth = lineWidth;
    [progressPath stroke];

    CGContextRestoreGState(context);
}

@end

%group MediaProgress

%hook SBSystemApertureViewController

// UIView *_containerSubBackgroundParent;
// UIView *_containerBackgroundParent;

- (void)viewDidLoad {
    %orig;
    if (!kIsEnabled || !kIsMediaProgressEnabled) {
        return;
    }

    UIView *subBackgroundParent = MSHookIvar<UIView *>(self, "_containerSubBackgroundParent");
    UIView *realSubBgView = [[subBackgroundParent subviews] lastObject];

    ASMediaProgressView *mediaProgressView = [[ASMediaProgressView alloc] initWithFrame:realSubBgView.bounds];
    mediaProgressView.alpha = 0.0;
    mediaProgressView.backgroundColor = [UIColor clearColor];
    mediaProgressView.translatesAutoresizingMaskIntoConstraints = NO;
    [subBackgroundParent addSubview:mediaProgressView];

    [NSLayoutConstraint activateConstraints:@[
        [mediaProgressView.leadingAnchor constraintEqualToAnchor:realSubBgView.leadingAnchor constant:-4],
        [mediaProgressView.trailingAnchor constraintEqualToAnchor:realSubBgView.trailingAnchor constant:4],
        [mediaProgressView.topAnchor constraintEqualToAnchor:realSubBgView.topAnchor constant:-4],
        [mediaProgressView.bottomAnchor constraintEqualToAnchor:realSubBgView.bottomAnchor constant:4],
    ]];

    [gObserver registerProgressView:mediaProgressView];
}

%end

%end // MediaProgress

@interface ASWeakContainer : NSObject
@property (nonatomic, weak) NSObject *object;
@end

@implementation ASWeakContainer
@end

@interface ASMediaRemoteObserver ()
@property (nonatomic, weak) ASMediaProgressView *progressView;
@end

@implementation ASMediaRemoteObserver {
    BOOL _isNowPlaying;
    NSTimeInterval _currentTime;
    NSTimeInterval _duration;
    NSTimeInterval _playbackRate;
    NSMutableSet<ASWeakContainer *> *_weakContainers;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _isNowPlaying = NO;
        _weakContainers = [[NSMutableSet alloc] init];

        [[NSNotificationCenter defaultCenter]
            addObserver:self
               selector:@selector(handleIsPlayingDidChangeNotification:)
                   name:(__bridge NSNotificationName)kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification
                 object:nil];

        [[NSNotificationCenter defaultCenter]
            addObserver:self
               selector:@selector(handleNowPlayingInfoDidChangeNotification:)
                   name:(__bridge NSNotificationName)kMRMediaRemoteNowPlayingInfoDidChangeNotification
                 object:nil];

        MRMediaRemoteSetWantsNowPlayingNotifications(true);
        MRMediaRemoteGetNowPlayingApplicationIsPlaying(dispatch_get_main_queue(), ^(Boolean isPlaying) {
            [self handleIsPlayingDidChange:isPlaying];
        });
        MRMediaRemoteGetNowPlayingInfo(dispatch_get_main_queue(), ^(CFDictionaryRef userInfo) {
            [self handleNowPlayingInfoDidChange:(__bridge NSDictionary *)userInfo];
        });
    }
    return self;
}

- (void)handleIsPlayingDidChangeNotification:(NSNotification *)noti {
    NSDictionary *userInfo = noti.userInfo;
    BOOL isPlaying = [userInfo[(__bridge NSString *)kMRMediaRemoteNowPlayingApplicationIsPlayingUserInfoKey] boolValue];
    [self handleIsPlayingDidChange:isPlaying];
}

- (void)handleIsPlayingDidChange:(BOOL)isPlaying {
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        _isNowPlaying = isPlaying;
        [self toggleArtworkAnimations];
        [self updateIsPlaying];
    });
}

- (void)handleNowPlayingInfoDidChangeNotification:(NSNotification *)noti {
    MRMediaRemoteGetNowPlayingInfo(dispatch_get_main_queue(), ^(CFDictionaryRef userInfo) {
        [self handleNowPlayingInfoDidChange:(__bridge NSDictionary *)userInfo];
    });
}

- (void)handleNowPlayingInfoDidChange:(NSDictionary *)userInfo {
    _currentTime = [userInfo[(__bridge NSString *)kMRMediaRemoteNowPlayingInfoElapsedTime] doubleValue];
    _duration = [userInfo[(__bridge NSString *)kMRMediaRemoteNowPlayingInfoDuration] doubleValue];
    _playbackRate = [userInfo[(__bridge NSString *)kMRMediaRemoteNowPlayingInfoPlaybackRate] doubleValue];
    if (_playbackRate < 1e-3) {
        _playbackRate = 1.0;
    }
    [self updateNowPlayingInfo];
}

- (void)registerRotator:(id<ASRotator>)rotator {
    if (!rotator) {
        return;
    }

    NSMutableSet<ASWeakContainer *> *containersToRemove = [NSMutableSet set];
    for (ASWeakContainer *container in _weakContainers) {
        if (!container.object || container.object == rotator) {
            [containersToRemove addObject:container];
        }
    }
    [_weakContainers minusSet:containersToRemove];

    ASWeakContainer *container = [[ASWeakContainer alloc] init];
    container.object = rotator;
    [_weakContainers addObject:container];

    [self toggleArtworkAnimation:rotator];
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
        id<ASRotator> rotator = (id<ASRotator>)container.object;
        [self pauseArtworkAnimation:rotator];
    }
}

- (void)resumeArtworkAnimations {
    for (ASWeakContainer *container in _weakContainers) {
        id<ASRotator> rotator = (id<ASRotator>)container.object;
        [self resumeArtworkAnimation:rotator];
    }
}

- (void)toggleArtworkAnimation:(id<ASRotator>)rotator {
    if (_isNowPlaying) {
        [self resumeArtworkAnimation:rotator];
    } else {
        [self pauseArtworkAnimation:rotator];
    }
}

- (void)pauseArtworkAnimation:(id<ASRotator>)rotator {
    if (!rotator) {
        return;
    }
    [rotator as_endRotation];
}

- (void)resumeArtworkAnimation:(id<ASRotator>)rotator {
    if (!rotator) {
        return;
    }
    [rotator as_beginRotation];
}

- (void)registerProgressView:(ASMediaProgressView *)progressView {
    self.progressView = progressView;
    [self updateIsPlaying];
    [self updateNowPlayingInfo];
}

- (void)updateIsPlaying {
    [self.progressView setPlaying:_isNowPlaying];
}

- (void)updateNowPlayingInfo {
    [self.progressView setCurrentTime:_currentTime duration:_duration playbackRate:_playbackRate];
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

    %init(ArtworkSpinner);
    %init(MediaProgress);
}
