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
@property (nonatomic) UIColor *highlightedColor;

@end

@implementation CNCloseButton

- (id)initWithColor:(UIColor *)color
{
    if ((self = [[self class] buttonWithType:UIButtonTypeCustom])) {
        self.opaque = NO;
        self.backgroundColor = [UIColor clearColor];
        self.clearsContextBeforeDrawing = YES;
        self.color = color;
        self.highlightedColor = [color colorWithAlphaComponent:.75];
        [self setTitleColor:color forState:UIControlStateNormal];
        [self setTitleColor:self.highlightedColor forState:UIControlStateHighlighted];
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
    return CGSizeMake(CLOSE_BUTTON_DIMENSION, CLOSE_BUTTON_DIMENSION);
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    [self setNeedsDisplay];
}

#define MAX_X_MARGIN        25.0

- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGFloat xDrawingDimension = MIN(CLOSE_BUTTON_DIMENSION, MIN(self.bounds.size.width, self.bounds.size.height));
    CGFloat yMargin = (self.bounds.size.height - xDrawingDimension)/2;
    CGFloat xMargin = MIN(self.bounds.size.width - xDrawingDimension, MAX_X_MARGIN);
    CGContextMoveToPoint(ctx, xMargin, yMargin);
    CGContextAddLineToPoint(ctx, xDrawingDimension + xMargin, self.bounds.size.height - yMargin);
    CGContextMoveToPoint(ctx, xDrawingDimension + xMargin, yMargin);
    CGContextAddLineToPoint(ctx, xMargin, self.bounds.size.height - yMargin);
    
    UIColor *xColor = self.color;
    if (self.highlighted)
        xColor = self.highlightedColor;
    [xColor setStroke];
    CGContextSetLineWidth(ctx, 2.0);
    CGContextDrawPath(ctx, kCGPathStroke);
}

@end
