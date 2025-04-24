#import <UIKit/UIKit.h>

@interface UIColor (ArtworkSpinner)

+ (nullable instancetype)as_colorWithExternalRepresentation:(NSString *_Nonnull)externalRepresentation;
- (NSString *_Nonnull)as_externalRepresentation;
- (BOOL)as_isDarkColor;

@end