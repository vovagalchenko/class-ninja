//
//  UIColor+CNAdditions.m
//  ClassNinja
//
//  Created by Boris Suvorov on 8/16/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "UIColor+CNAdditions.h"

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
