//
//  CNGradientView.m
//  ClassNinja
//
//  Created by Vova Galchenko on 9/26/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNGradientView.h"

@interface CNGradientView()

@property (nonatomic) UIColor *gradientColor;

@end

@implementation CNGradientView

- (instancetype)initWithColor:(UIColor *)color
{
    if ((self = [super initWithFrame:CGRectZero])) {
        self.gradientColor = color;
        self.opaque = NO;
        self.clearsContextBeforeDrawing = YES;
        self.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    
    const void *colors[2] = {
        [self.gradientColor CGColor],
        [[self.gradientColor colorWithAlphaComponent:0.0] CGColor]
    };
    CFArrayRef colorsArray = CFArrayCreate(NULL, colors, 2, NULL);
    CGGradientRef gradient = CGGradientCreateWithColors(rgbColorSpace, colorsArray, NULL);
    CGColorSpaceRelease(rgbColorSpace);
    CFRelease(colorsArray);
    CGContextDrawLinearGradient(ctx,
                                gradient,
                                CGPointMake(self.bounds.size.width/2.0, 0),
                                CGPointMake(self.bounds.size.width/2.0, self.bounds.size.height),
                                0);
    CGGradientRelease(gradient);
}

@end
