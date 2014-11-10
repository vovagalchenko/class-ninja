//
//  CNWelcomeStatusView.m
//  ClassNinja
//
//  Created by Vova Galchenko on 7/31/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNWelcomeStatusView.h"
#import "AppearanceConstants.h"

@interface CNWelcomeStatusView()

@property (nonatomic, readonly) UILabel *welcomeLabel;
@property (nonatomic, readonly) UIButton *addClassesButton;
@property (nonatomic, weak) id<CNWelcomeStatusViewDelegate>delegate;

@property (nonatomic) NSLayoutConstraint *actionButtonTopMarginConstraint;
@property (nonatomic) NSLayoutConstraint *separatorTopMarginConstraint;
@property (nonatomic) NSLayoutConstraint *separatorHeightConstraint;
@property (nonatomic) NSLayoutConstraint *addClassesTopMarginConstraint;
@property (nonatomic) NSLayoutConstraint *actionButtonHeightZeroingConstraint;

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
        [self addSubview:self.separatorLine];
        [self addSubview:self.actionButton];
        
        NSArray *verticalConstraints = [NSLayoutConstraint
                                        constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-%f-[_welcomeLabel]-%f-[_statusLabel]-%f-[_actionButton(0)]-%f-[_separatorLine(1.0)]-%f-[_addClassesButton]-%f-|", VERTICAL_MARGIN, INTER_ELEMENT_VERTICAL_PADDING, INTER_ELEMENT_VERTICAL_PADDING, INTER_ELEMENT_VERTICAL_PADDING*2, INTER_ELEMENT_VERTICAL_PADDING*2, 10.0]
                                        options:0
                                        metrics:nil
                                        views:NSDictionaryOfVariableBindings(_welcomeLabel, _statusLabel, _addClassesButton, _separatorLine, _actionButton)];
        self.actionButtonTopMarginConstraint = verticalConstraints[2];
        self.actionButtonHeightZeroingConstraint = verticalConstraints[3];
        self.separatorTopMarginConstraint = verticalConstraints[4];
        self.separatorHeightConstraint = verticalConstraints[5];
        self.addClassesTopMarginConstraint = verticalConstraints[6];
        [self setActionButtonType:CNWelcomeStatusViewActionStatusButtonTypeNone];

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
        NSArray *separatorLineHorizontalConstraints = [NSLayoutConstraint
                                                       constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-%f-[_separatorLine]-%f-|", HORIZONTAL_MARGIN, HORIZONTAL_MARGIN]
                                                       options:0
                                                       metrics:nil
                                                       views:NSDictionaryOfVariableBindings(_separatorLine)];
        NSArray *actionButtonHorizontalConstraints = [NSLayoutConstraint
                                                      constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-%f-[_actionButton]-%f-|", HORIZONTAL_MARGIN, HORIZONTAL_MARGIN]
                                                      options:0
                                                      metrics:nil
                                                      views:NSDictionaryOfVariableBindings(_actionButton)];
        [self addConstraints:verticalConstraints];
        [self addConstraints:welcomeHorizontalConstraints];
        [self addConstraints:statusHorizontalConstraints];
        [self addConstraints:addClassesHorizontalConstraints];
        [self addConstraints:separatorLineHorizontalConstraints];
        [self addConstraints:actionButtonHorizontalConstraints];
    }
    return self;
}

- (void)actionButtonPressed:(id)sender
{
    switch (self.actionButtonType) {
        case CNWelcomeStatusViewActionStatusButtonTypeRefreshTargets:
            [self.delegate refreshTargetsButtonPressed:sender];
            break;
        case CNWelcomeStatusViewActionStatusButtonTypePay:
            [self.delegate payToTrackMoreButtonPressed:sender];
            break;
        default:
            break;
    }
}

- (void)setActionButtonType:(CNWelcomeStatusViewActionStatusButtonType)actionButtonType
{
    switch (actionButtonType) {
        case CNWelcomeStatusViewActionStatusButtonTypeRefreshTargets:
        case CNWelcomeStatusViewActionStatusButtonTypePay:
        {
            self.actionButtonTopMarginConstraint.constant = VERTICAL_MARGIN;
            self.actionButtonHeightZeroingConstraint.priority = UILayoutPriorityDefaultLow;
            self.separatorTopMarginConstraint.constant = 2*VERTICAL_MARGIN;
            self.addClassesTopMarginConstraint.constant = 2*VERTICAL_MARGIN;
            self.separatorHeightConstraint.constant = 1.0;
            NSString *actionButtonTitle = (actionButtonType == CNWelcomeStatusViewActionStatusButtonTypeRefreshTargets)? @"Retry" : @"Get more targets";
            [self.actionButton setTitle:actionButtonTitle
                               forState:UIControlStateNormal];
            [self.actionButton setTitle:actionButtonTitle
                               forState:UIControlStateHighlighted];
            break;
        }
        default:
            [self.actionButton setTitle:@"" forState:UIControlStateNormal];
            [self.actionButton setTitle:@"" forState:UIControlStateHighlighted];
            self.actionButtonTopMarginConstraint.constant = 0;
            self.actionButtonHeightZeroingConstraint.priority = UILayoutPriorityDefaultHigh + 1; // Need to beat the content hugging priority
            self.separatorTopMarginConstraint.constant = 0;
            self.separatorHeightConstraint.constant = 0;
            self.addClassesTopMarginConstraint.constant = VERTICAL_MARGIN;
            break;
    }
    _actionButtonType = actionButtonType;
}

#pragma mark - Subviews

- (void)layoutSubviews
{
    CGFloat preferredMaxLayoutWidth = self.bounds.size.width - 2*HORIZONTAL_MARGIN;
    self.addClassesButton.titleLabel.preferredMaxLayoutWidth = preferredMaxLayoutWidth;
    self.statusLabel.preferredMaxLayoutWidth = preferredMaxLayoutWidth;
    self.welcomeLabel.preferredMaxLayoutWidth = preferredMaxLayoutWidth;
    self.actionButton.titleLabel.preferredMaxLayoutWidth = preferredMaxLayoutWidth;
    
    [super layoutSubviews];
}

@synthesize addClassesButton = _addClassesButton;
@synthesize statusLabel = _statusLabel;
@synthesize welcomeLabel = _welcomeLabel;
@synthesize actionButton = _actionButton;
@synthesize separatorLine = _separatorLine;

- (UIButton *)addClassesButton
{
    if (_addClassesButton == nil) {
        _addClassesButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _addClassesButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        _addClassesButton.titleLabel.font = [UIFont cnBoldSystemFontOfSize:12.0];
        _addClassesButton.titleLabel.numberOfLines = 1;
        NSString *buttonTitle = @"+ Track a class";
        [_addClassesButton setTitle:buttonTitle forState:UIControlStateNormal];
        [_addClassesButton setTitle:buttonTitle forState:UIControlStateHighlighted];
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
        _statusLabel.font = INSTRUCTION_LABEL_FONT;
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
        _welcomeLabel.font = [UIFont cnSystemFontOfSize:FOCAL_LABEL_TEXT_SIZE];
        _welcomeLabel.text = @"Hello";
        _welcomeLabel.textColor = [UIColor whiteColor];
        _welcomeLabel.numberOfLines = 1;
        
        _welcomeLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_welcomeLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [_welcomeLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    }
    return _welcomeLabel;
}

- (UIView *)separatorLine
{
    if (_separatorLine == nil) {
        _separatorLine = [[UIView alloc] init];
        _separatorLine.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.25];
        _separatorLine.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _separatorLine;
}

- (UIButton *)actionButton
{
    if (_actionButton == nil) {
        _actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _actionButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        _actionButton.titleLabel.font = [UIFont cnBoldSystemFontOfSize:12.0];
        _actionButton.titleLabel.numberOfLines = 1;
        [_actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_actionButton setTitleColor:[UIColor yellowColor] forState:UIControlStateHighlighted];
        [_actionButton addTarget:self
                          action:@selector(actionButtonPressed:)
                forControlEvents:UIControlEventTouchUpInside];
        
        _actionButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_actionButton setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
        [_actionButton setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
    }
    return _actionButton;
}

@end
