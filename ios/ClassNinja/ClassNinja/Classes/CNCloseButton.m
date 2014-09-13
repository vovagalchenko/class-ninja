//
//  CNCloseButton.m
//  ClassNinja
//
//  Created by Vova Galchenko on 9/13/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNCloseButton.h"

@interface CNCloseButton()

@property (nonatomic) UIColor *color;

@end

@implementation CNCloseButton

- (id)initWithColor:(UIColor *)color
{
    if ((self = [[self class] buttonWithType:UIButtonTypeCustom])) {
        self.opaque = NO;
        self.backgroundColor = [UIColor clearColor];
        self.clearsContextBeforeDrawing = YES;
        self.color = color;
    }
    return self;
}

#define TAPPABLE_AREA_SIZE      CGSizeMake(44.0, 44.0)

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    CGFloat xSpill = MAX((TAPPABLE_AREA_SIZE.width - self.bounds.size.width)/2.0, 0.0);
    CGFloat ySpill = MAX((TAPPABLE_AREA_SIZE.height - self.bounds.size.height)/2.0, 0.0);
    BOOL retVal = (point.x >= -xSpill && point.x <= self.bounds.size.width + xSpill && point.y >= -ySpill && point.y <= self.bounds.size.height + ySpill);
    return retVal;
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(11.0, 11.0);
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGContextMoveToPoint(ctx, 0, 0);
    CGContextAddLineToPoint(ctx, self.bounds.size.width, self.bounds.size.height);
    CGContextMoveToPoint(ctx, self.bounds.size.width, 0);
    CGContextAddLineToPoint(ctx, 0, self.bounds.size.height);
    
    [self.color setStroke];
    CGContextSetLineWidth(ctx, self.bounds.size.width/10.0);
    CGContextDrawPath(ctx, kCGPathStroke);
}

@end
