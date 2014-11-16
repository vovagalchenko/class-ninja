//
//  UIColor+CNAdditions.m
//  ClassNinja
//
//  Created by Boris Suvorov on 8/16/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNCategories.h"

@implementation UIColor (CNAdditions)

+ (UIColor *)opaqueWhiteWithIntensity:(NSUInteger)white
{
    return [UIColor colorWithWhite:white/255.0 alpha:1];
}

+ (UIColor *)r:(NSUInteger)red g:(NSUInteger)green b:(NSUInteger)blue
{
    return ([UIColor colorWithRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:1]);
}

@end

@implementation NSData (CNAdditions)

- (NSString *)hexString
{
    NSMutableString *tokenString = [NSMutableString stringWithCapacity:self.length*2];
    const unsigned char *bytes = self.bytes;
    for (int i = 0; i < self.length; i++) {
        [tokenString appendFormat:@"%02x", bytes[i]];
    }
    return [NSString stringWithString:tokenString];
}

@end

@implementation UIFont (CNAdditions)

+ (UIFont *)cnSystemFontOfSize:(CGFloat)fontSize
{
    return [UIFont fontWithName:@"HelveticaNeue-Light" size:fontSize];
}

+ (UIFont *)cnBoldSystemFontOfSize:(CGFloat)fontSize
{
    return [UIFont fontWithName:@"HelveticaNeue-Bold" size:fontSize];
}

@end

@implementation UIButton (CNAdditions)
+ (instancetype)cnTextButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = [UIColor clearColor];
    button.titleLabel.textColor = [UIColor whiteColor];
    button.titleLabel.font = BUTTON_FONT;
    return button;
}

+ (instancetype)cnTextButtonForAutolayout
{
    UIButton *button = [self cnTextButton];
    
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [button setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [button setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    
    return button;
}
@end


@implementation UILabel (CNAdditions)

+ (instancetype)cnMessageLabelForAutoLayout
{
    UILabel *label = [self cnMessageLabel];
    setDefaultAutoLayoutSettings(label);
    return label;
}

+ (instancetype)cnMessageLabel
{
    UILabel *label = [[UILabel alloc] init];
    
    label.numberOfLines = 0;
    label.textColor = [UIColor whiteColor];
    label.font = DESCRIPTION_FONT;

    return label;
}

@end
