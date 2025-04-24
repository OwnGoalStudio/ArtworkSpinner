#import "UIColor+.h"

@implementation UIColor (ArtworkSpinner)

+ (instancetype)as_colorWithExternalRepresentation:(NSString *)externalRepresentation {
    NSScanner *scanner = [NSScanner scannerWithString:externalRepresentation];

    UIColor *color = nil;
    if ([externalRepresentation hasPrefix:@"#"]) {
        [scanner setScanLocation:1];

        unsigned int hexValue;
        if (![scanner scanHexInt:&hexValue]) {
            return nil;
        }

        CGFloat red = ((hexValue & 0xFF0000) >> 16) / 255.0;
        CGFloat green = ((hexValue & 0x00FF00) >> 8) / 255.0;
        CGFloat blue = (hexValue & 0x0000FF) / 255.0;
        color = [UIColor colorWithRed:red green:green blue:blue alpha:1];
    } else if ([externalRepresentation hasPrefix:@"rgba("]) {
        [scanner setScanLocation:5];

        CGFloat red, green, blue, alpha;
        if (![scanner scanDouble:&red] || ![scanner scanString:@"," intoString:nil] || ![scanner scanDouble:&green] ||
            ![scanner scanString:@"," intoString:nil] || ![scanner scanDouble:&blue] ||
            ![scanner scanString:@"," intoString:nil] || ![scanner scanDouble:&alpha] ||
            ![scanner scanString:@")" intoString:nil]) {
            return nil;
        }

        color = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
    }

    return color;
}

- (NSString *)as_externalRepresentation {
    CGFloat red, green, blue, alpha;
    if (![self getRed:&red green:&green blue:&blue alpha:&alpha]) {
        return nil;
    }

    return [NSString stringWithFormat:@"rgba(%f, %f, %f, %f)", red, green, blue, alpha];
}

- (BOOL)as_isDarkColor {
    CGFloat red, green, blue, alpha;
    if (![self getRed:&red green:&green blue:&blue alpha:&alpha]) {
        return NO;
    }

    CGFloat luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue;
    return luminance < 0.5;
}

@end