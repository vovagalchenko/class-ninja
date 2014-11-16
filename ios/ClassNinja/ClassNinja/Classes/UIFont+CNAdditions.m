//
//  NSFont+CNAdditions.m
//  ClassNinja
//
//  Created by Boris Suvorov on 8/9/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "UIFont+CNAdditions.h"

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
