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
