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
@property (nonatomic, assign) BOOL constraintsApplied;

@end

@implementation CNTargetSectionHeaderView

- (id)init
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.backgroundColor = [UIColor whiteColor];
        self.opaque = NO;
        
        self.label = [[UILabel alloc] init];
        self.label.clipsToBounds = YES;
        self.label.translatesAutoresizingMaskIntoConstraints = NO;
        self.label.backgroundColor = [UIColor whiteColor];
        self.label.font = [UIFont cnSystemFontOfSize:17.0];
        self.label.textColor = [UIColor blackColor];
        self.label.numberOfLines = -1;
        [self.label setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
        [self.label setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
        [self.label setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        [self.label setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        [self addSubview:self.label];
        
        self.constraintsApplied = NO;
        
    }
    return self;
}

- (void)updateConstraints
{
    if (!self.constraintsApplied) {
        self.constraintsApplied = YES;
        [self addConstraints:@[
                               [NSLayoutConstraint constraintWithItem:self.label
                                                            attribute:NSLayoutAttributeBottom
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:self
                                                            attribute:NSLayoutAttributeBottom
                                                           multiplier:1.0
                                                             constant:0.0],
                               [NSLayoutConstraint constraintWithItem:self.label
                                                            attribute:NSLayoutAttributeHeight
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:self
                                                            attribute:NSLayoutAttributeHeight
                                                           multiplier:1.0
                                                             constant:0.0]
                               
                               ]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-%f-[_label]|", HORIZONTAL_MARGIN]
                                                                     options:0
                                                                     metrics:0
                                                                       views:NSDictionaryOfVariableBindings(_label)]];
    }
    [super updateConstraints];
}

- (void)setText:(NSString *)text
{
   self.label.text = text;
}

@end
