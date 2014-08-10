//
//  CNActivityIndicator.m
//  ClassNinja
//
//  Created by Vova Galchenko on 8/9/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNActivityIndicator.h"

@interface CNActivityIndicator()
{
    unsigned short *_bitmapData;
}

@property (nonatomic, readwrite) CGSize previouslyRenderedGradientImageSize;
@property (nonatomic, readwrite) UIImageView *gradientImageView;

@end

@implementation CNActivityIndicator

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
        self.clearsContextBeforeDrawing = YES;
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.gradientImageView = [[UIImageView alloc] init];
        self.gradientImageView.translatesAutoresizingMaskIntoConstraints = NO;
        self.previouslyRenderedGradientImageSize = CGSizeMake(0, 0);
        [self addSubview:self.gradientImageView];
        NSArray *vertical = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_gradientImageView]|" options:0 metrics:0 views:NSDictionaryOfVariableBindings(_gradientImageView)];
        NSArray *horizontal = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_gradientImageView]|" options:0 metrics:0 views:NSDictionaryOfVariableBindings(_gradientImageView)];
        [self addConstraints:vertical];
        [self addConstraints:horizontal];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (!CGSizeEqualToSize(self.gradientImageView.bounds.size, self.previouslyRenderedGradientImageSize)) {
        self.gradientImageView.image = createGradientImage(self.gradientImageView.bounds.size, _bitmapData);
        self.previouslyRenderedGradientImageSize = self.gradientImageView.bounds.size;
        
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        UIBezierPath *roundedPath = [UIBezierPath bezierPathWithOvalInRect:self.bounds];
        maskLayer.fillColor = [[UIColor whiteColor] CGColor];
        maskLayer.backgroundColor = [[UIColor clearColor] CGColor];
        maskLayer.path = [roundedPath CGPath];
        maskLayer.frame = self.gradientImageView.bounds;
        self.gradientImageView.layer.mask = maskLayer;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.gradientImageView.layer removeAllAnimations];
            [self spin];
        });
    }
}

- (void)spin
{
    [UIView animateWithDuration:0.5
                          delay:0.0f
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         self.gradientImageView.transform = CGAffineTransformRotate(self.gradientImageView.transform, M_PI / 2);
                     }
                     completion:^(BOOL finished) {
                         [self spin];
                     }];
}

void releaseCallback(void *info, const void *data, size_t size)
{
    free((void *)data);
}

static inline UIImage *createGradientImage(CGSize sizeInPts, unsigned short *bitmapData)
{
    CGFloat scale = [[UIScreen mainScreen] scale];
    unsigned short bitsPerComponent = 8;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    unsigned short bitsPerPixel = bitsPerComponent * (CGColorSpaceGetNumberOfComponents(colorSpace) + 1);
    unsigned int numPixels = sizeInPts.width * sizeInPts.height * scale * scale;
    
    size_t sizeOfBitmapData = numPixels * sizeof(unsigned short);
    free(bitmapData);
    bitmapData = malloc(sizeOfBitmapData);
    memset(bitmapData, 0, sizeOfBitmapData);
    CGFloat portionOfCircleForGradientTail = 0.65;
    for (int i = 0; i < numPixels; i++) {
        CGFloat y = (int)i/(int)(sizeInPts.width * scale) - sizeInPts.height;
        CGFloat x = i % (int)(sizeInPts.width * scale) - sizeInPts.width;
        CGFloat theta = atan2(y, x)  + M_PI;
        CGFloat alphaMultiple = 1 - MIN(theta/(portionOfCircleForGradientTail*M_PI*2), 1);
        unsigned char alpha = (unsigned char)(0xFF*alphaMultiple);
        bitmapData[i] = (alpha << 8) + 0xFF;
    }
    
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, bitmapData, numPixels, releaseCallback);
    
    CGImageRef imageRef = CGImageCreate(
                                   sizeInPts.width * scale,
                                   sizeInPts.height * scale,
                                   bitsPerComponent,
                                   bitsPerPixel,
                                   (bitsPerPixel/8) * sizeInPts.width * scale,
                                   colorSpace,
                                   kCGBitmapByteOrderDefault | kCGImageAlphaLast,
                                   dataProvider,
                                   NULL,
                                   NO,
                                   kCGRenderingIntentDefault
                                   );
    
    
    CGColorSpaceRelease(colorSpace);
    CGDataProviderRelease(dataProvider);
    UIImage *image = [UIImage imageWithCGImage:imageRef scale:scale orientation:UIImageOrientationUpMirrored];
    CGImageRelease(imageRef);
    return image;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    unsigned short numCircles = 4;
    CGFloat innermostCircleAlpha = .75;
    CGFloat outermostCircleAlpha = .1;
    CGFloat innermostCircleProportion = .05;
    CGFloat outermostCircleProportion = 1.0;
    CGFloat strokeWidth = 2.0;
    CGContextSetLineWidth(ctx, strokeWidth);
    for (int i = 0; i < numCircles; i++) {
        [[[UIColor whiteColor] colorWithAlphaComponent:outermostCircleAlpha + i*((innermostCircleAlpha - outermostCircleAlpha)/numCircles)] setStroke];
        CGFloat circleProportion = outermostCircleProportion - i*((outermostCircleProportion - innermostCircleProportion)/numCircles);
        CGContextStrokeEllipseInRect(ctx, CGRectMake(
            (self.bounds.size.width - self.bounds.size.width*circleProportion)/2 + strokeWidth/2,
            (self.bounds.size.height - self.bounds.size.height*circleProportion)/2 + strokeWidth/2,
            self.bounds.size.width*circleProportion - strokeWidth,
            self.bounds.size.height*circleProportion - strokeWidth
        ));
    }
}

@end
