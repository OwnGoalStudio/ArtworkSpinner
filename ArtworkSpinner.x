@import UIKit;

@interface _TtC13MediaRemoteUI34CoverSheetBackgroundViewController : UIViewController
- (UIView *)artworkView;
- (CABasicAnimation *)rotationAnimation;
@end

%hook _TtC13MediaRemoteUI34CoverSheetBackgroundViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;

    UIView *artworkView = [self artworkView];
    [artworkView.layer addAnimation:[self rotationAnimation] forKey:@"rotationAnimation"];
}

%new
- (CABasicAnimation *)rotationAnimation {
    CABasicAnimation *rotation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotation.toValue = @(M_PI * 2);
    rotation.duration = 2.0;
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

    UIView *artworkView = (UIView *)[self artworkView];
    [artworkView.layer addAnimation:[self rotationAnimation] forKey:@"rotationAnimation"];
}

%new
- (CABasicAnimation *)rotationAnimation {
    CABasicAnimation *rotation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotation.toValue = @(M_PI * 2);
    rotation.duration = 2.0;
    rotation.repeatCount = HUGE_VALF;
    return rotation;
}

%end

%ctor {

}
