//
//  UIColor+CNAdditions.h
//  ClassNinja
//
//  Created by Boris Suvorov on 8/16/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (CNAdditions)

+ (UIColor *)r:(NSUInteger)red g:(NSUInteger)green b:(NSUInteger)blue;
+ (UIColor *)opaqueWhiteWithIntensity:(NSUInteger)white;

@end

@interface NSData (CNAdditions)

- (NSString *)hexString;

@end

@interface UIFont (CNAdditions)

+ (UIFont *)cnSystemFontOfSize:(CGFloat)fontSize;
+ (UIFont *)cnBoldSystemFontOfSize:(CGFloat)fontSize;

@end

@interface UIButton (CNAdditions)
+ (instancetype)cnTextButton;
+ (instancetype)cnTextButtonForAutolayout;
@end

@interface UILabel (CNAdditions)
+ (instancetype)cnMessageLabelForAutoLayout;
+ (instancetype)cnMessageLabel;
@end
