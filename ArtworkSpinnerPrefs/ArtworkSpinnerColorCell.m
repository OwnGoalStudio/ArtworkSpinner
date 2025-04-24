#import <Preferences/PSSpecifier.h>
#import <UIKit/UIKit.h>

#import "UIColor+.h"
#import "ArtworkSpinnerColorCell.h"

@interface PSTableCell (Private)
- (void)setValue:(id)value;
@end

@implementation ArtworkSpinnerColorCell {
    UIColorWell *_colorWell;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier
                    specifier:(PSSpecifier *)specifier {

    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier specifier:specifier];

    if (self) {
        _colorWell = [[UIColorWell alloc] initWithFrame:CGRectZero];

        [_colorWell setSupportsAlpha:YES];
        [_colorWell addTarget:self action:@selector(colorChanged:) forControlEvents:UIControlEventValueChanged];

        [self addSubview:_colorWell];
    }

    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _colorWell.frame = CGRectMake(CGRectGetWidth(self.frame) - 52, CGRectGetHeight(self.frame) / 2 - 16, 32, 32);
}

- (void)colorChanged:(UIColorWell *)sender {
    [self.specifier performSetterWithValue:[sender.selectedColor as_externalRepresentation]];
}

- (void)setValue:(id)value {
    [super setValue:value];

    NSString *hexString = value;
    if (![value isKindOfClass:[NSString class]]) {
        return;
    }

    [_colorWell setSelectedColor:[UIColor as_colorWithExternalRepresentation:hexString]];
}

@end