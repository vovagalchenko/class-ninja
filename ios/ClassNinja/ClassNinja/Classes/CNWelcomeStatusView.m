//
//  CNWelcomeStatusView.m
//  ClassNinja
//
//  Created by Vova Galchenko on 7/31/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNWelcomeStatusView.h"
#import "AppearanceConstants.h"

#define INTER_ELEMENT_VERTICAL_PADDING      10.0

@interface CNWelcomeStatusView()

@property (nonatomic, readonly) UILabel *welcomeLabel;
@property (nonatomic, readonly) UIButton *addClassesButton;
@property (nonatomic, weak) id<CNWelcomeStatusViewDelegate>delegate;

@end

@implementation CNWelcomeStatusView

#pragma mark - UIView lifecycle

- (instancetype)initWithDelegate:(id<CNWelcomeStatusViewDelegate>)delegate
{
    if (self = [super init]) {
        self.delegate = delegate;
        self.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:self.welcomeLabel];
        [self addSubview:self.statusLabel];
        [self addSubview:self.addClassesButton];
        
        NSArray *verticalConstraints = [NSLayoutConstraint
                                        constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-%f-[_welcomeLabel]-%f-[_statusLabel]-%f-[_addClassesButton]-%f-|", 50.0, INTER_ELEMENT_VERTICAL_PADDING, INTER_ELEMENT_VERTICAL_PADDING, 10.0]
                                        options:0
                                        metrics:nil
                                        views:NSDictionaryOfVariableBindings(_welcomeLabel, _statusLabel, _addClassesButton)];
        NSArray *welcomeHorizontalConstraints = [NSLayoutConstraint
                                                 constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-%f-[_welcomeLabel]-%f-|", HORIZONTAL_MARGIN, HORIZONTAL_MARGIN]
                                                 options:0
                                                 metrics:nil
                                                 views:NSDictionaryOfVariableBindings(_welcomeLabel)];
        NSArray *statusHorizontalConstraints = [NSLayoutConstraint
                                                 constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-%f-[_statusLabel]-%f-|", HORIZONTAL_MARGIN, HORIZONTAL_MARGIN]
                                                 options:0
                                                 metrics:nil
                                                 views:NSDictionaryOfVariableBindings(_statusLabel)];
        NSArray *addClassesHorizontalConstraints = [NSLayoutConstraint
                                                constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-%f-[_addClassesButton]-%f-|", HORIZONTAL_MARGIN, HORIZONTAL_MARGIN]
                                                options:0
                                                metrics:nil
                                                views:NSDictionaryOfVariableBindings(_addClassesButton)];

        [self addConstraints:verticalConstraints];
        [self addConstraints:welcomeHorizontalConstraints];
        [self addConstraints:statusHorizontalConstraints];
        [self addConstraints:addClassesHorizontalConstraints];
        
        [self setNeedsLayout];
        [self layoutIfNeeded];
    }
    return self;
}

- (void)layoutSubviews
{
    CGFloat preferredMaxLayoutWidth = self.bounds.size.width - 2*HORIZONTAL_MARGIN;
    self.addClassesButton.titleLabel.preferredMaxLayoutWidth = preferredMaxLayoutWidth;
    self.statusLabel.preferredMaxLayoutWidth = preferredMaxLayoutWidth;
    self.welcomeLabel.preferredMaxLayoutWidth = preferredMaxLayoutWidth;
    
    [super layoutSubviews];
}

#pragma mark - Subviews

@synthesize addClassesButton = _addClassesButton;
@synthesize statusLabel = _statusLabel;
@synthesize welcomeLabel = _welcomeLabel;

- (UIButton *)addClassesButton
{
    if (_addClassesButton == nil) {
        _addClassesButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _addClassesButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        _addClassesButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
        _addClassesButton.titleLabel.numberOfLines = 1;
        [_addClassesButton setTitle:@"+ Add classes" forState:UIControlStateNormal];
        [_addClassesButton setTitle:@"+ Add classes" forState:UIControlStateHighlighted];
        [_addClassesButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_addClassesButton setTitleColor:[UIColor yellowColor] forState:UIControlStateHighlighted];
        [_addClassesButton addTarget:self.delegate
                              action:@selector(addClassesButtonPressed:)
                    forControlEvents:UIControlEventTouchUpInside];
        
        _addClassesButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_addClassesButton setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [_addClassesButton setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    }
    return _addClassesButton;
}

- (UILabel *)statusLabel
{
    if (_statusLabel == nil) {
        _statusLabel = [[UILabel alloc] init];
        _statusLabel.font = [UIFont systemFontOfSize:18.0];
        _statusLabel.text = @"Fetching your targets...";
        _statusLabel.textColor = [UIColor whiteColor];
        _statusLabel.numberOfLines = 0;
        _statusLabel.lineBreakMode = NSLineBreakByWordWrapping;
        
        _statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_statusLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [_statusLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    }
    return _statusLabel;
}

- (UILabel *)welcomeLabel
{
    if (_welcomeLabel == nil) {
        _welcomeLabel = [[UILabel alloc] init];
        _welcomeLabel.font = [UIFont systemFontOfSize:25.0];
        _welcomeLabel.text = @"Hello";
        _welcomeLabel.textColor = [UIColor whiteColor];
        _welcomeLabel.numberOfLines = 1;
        
        _welcomeLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_welcomeLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [_welcomeLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    }
    return _welcomeLabel;
}

@end
