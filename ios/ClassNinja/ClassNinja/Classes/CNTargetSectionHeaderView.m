//
//  CNTargetSectionHeaderView.m
//  ClassNinja
//
//  Created by Vova Galchenko on 9/13/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNTargetSectionHeaderView.h"
#import "UIFont+CNAdditions.h"
#import "AppearanceConstants.h"

@interface CNTargetSectionHeaderView()

@property (nonatomic) UILabel *label;

@end

@implementation CNTargetSectionHeaderView

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self) {
        self.contentView.backgroundColor = [UIColor whiteColor];
        self.opaque = NO;
        
        self.label = [[UILabel alloc] init];
        self.label.clipsToBounds = YES;
        self.label.font = [UIFont cnSystemFontOfSize:17.0];
        self.label.textColor = [UIColor blackColor];
        self.label.lineBreakMode = NSLineBreakByWordWrapping;
        self.label.numberOfLines = 0;
        [self addSubview:self.label];
    }
    return self;
}

- (void)layoutSubviews
{
    CGFloat labelX = HORIZONTAL_MARGIN - self.frame.origin.x;
    CGRect labelRect = [self.label.attributedText boundingRectWithSize:CGSizeMake(self.bounds.size.width - 2*labelX, self.bounds.size.height)
                                                               options:NSStringDrawingUsesLineFragmentOrigin
                                                               context:nil];
    self.label.frame = CGRectMake(labelX, (self.bounds.size.height - labelRect.size.height)/2,
                                  labelRect.size.width, labelRect.size.height);
    [super layoutSubviews];
}

- (void)setText:(NSString *)text
{
    self.label.text = text;
    [self setNeedsLayout];
}

@end
