//
//  CNAuthViewController.m
//  ClassNinja
//
//  Created by Vova Galchenko on 8/2/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNAuthViewController.h"
#import "AppearanceConstants.h"
#import "CNNumberEntryTextField.h"
#import "CNActivityIndicator.h"
#import "CNCloseButton.h"

typedef enum : NSUInteger {
    CNAuthViewControllerStatePhoneNumberEntry,
    CNAuthViewControllerStateWait,
    CNAuthViewControllerStateVerificationCodeEntry,
} CNAuthViewControllerState;

@interface CNAuthViewController ()

@property (nonatomic, readonly) UILabel *detailLabel;
@property (nonatomic, readonly) CNCloseButton *cancelButton;
@property (nonatomic, readonly) CNNumberEntryTextField *textField;
@property (nonatomic, readonly) UIButton *confirmationButton;
@property (nonatomic, readonly) CNActivityIndicator *activityIndicator;
@property (nonatomic, readwrite) CNAuthViewControllerState currentState;
@property (nonatomic, weak) id<CNAuthViewControllerDelegate>delegate;
@property (nonatomic, readwrite) NSString *phoneNumber;
@property (nonatomic, readonly) NSMutableArray *statesChain;

@end

@implementation CNAuthViewController

#pragma mark - UIViewController lifecycle

- (instancetype)initWithDelegate:(id<CNAuthViewControllerDelegate>)delegate
{
    if (self = [super init]) {
        self.currentState = CNAuthViewControllerStatePhoneNumberEntry;
        self.delegate = delegate;
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // TODO: implement this
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [self changeState:self.currentState animated:NO];
    [super viewWillAppear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view addSubview:self.detailLabel];
    [self.view addSubview:self.textField];
    [self.view addSubview:self.confirmationButton];
    [self.view addSubview:self.activityIndicator];
    [self.view addSubview:self.cancelButton];
    
    NSArray *horizontal = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-%f-[_detailLabel]-%f-|", HORIZONTAL_MARGIN, HORIZONTAL_MARGIN]
                                                                  options:0
                                                                  metrics:nil
                                                                    views:NSDictionaryOfVariableBindings(_detailLabel)];
    NSArray *horizontalTF = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-%f-[_textField]-%f-|", HORIZONTAL_MARGIN, HORIZONTAL_MARGIN]
                                                                    options:0
                                                                    metrics:nil
                                                                      views:NSDictionaryOfVariableBindings(_textField)];
    NSArray *horizontalButton = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-(>=%f)-[_confirmationButton(>=%f)]-%f-|", HORIZONTAL_MARGIN, TAPPABLE_AREA_DIMENSION, HORIZONTAL_MARGIN]
                                                                        options:0
                                                                        metrics:nil
                                                                          views:NSDictionaryOfVariableBindings(_confirmationButton)];
    NSLayoutConstraint *activityIndicatorHorizontal = [NSLayoutConstraint constraintWithItem:self.activityIndicator
                                                                                   attribute:NSLayoutAttributeCenterX
                                                                                   relatedBy:NSLayoutRelationEqual
                                                                                      toItem:self.view
                                                                                   attribute:NSLayoutAttributeCenterX multiplier:1.0
                                                                                    constant:0.0];
    NSLayoutConstraint *activityIndicatorVertical = [NSLayoutConstraint constraintWithItem:self.activityIndicator
                                                                                 attribute:NSLayoutAttributeCenterY
                                                                                 relatedBy:NSLayoutRelationEqual
                                                                                    toItem:self.view
                                                                                 attribute:NSLayoutAttributeCenterY multiplier:1.0
                                                                                  constant:0.0];
    NSLayoutConstraint *activityIndicatorWidth = [NSLayoutConstraint constraintWithItem:self.activityIndicator
                                                                                 attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
                                                                                    toItem:nil
                                                                                 attribute:NSLayoutAttributeNotAnAttribute multiplier:0.0
                                                                                    constant:TAPPABLE_AREA_DIMENSION];
    NSLayoutConstraint *activityIndicatorHeight = [NSLayoutConstraint constraintWithItem:self.activityIndicator
                                                                              attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual
                                                                                 toItem:nil
                                                                              attribute:NSLayoutAttributeNotAnAttribute multiplier:0.0
                                                                               constant:TAPPABLE_AREA_DIMENSION];
    NSArray *horizontalCancelConstraints = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-%f-[_cancelButton]", HORIZONTAL_MARGIN]
                                                                                   options:0
                                                                                   metrics:nil
                                                                                     views:NSDictionaryOfVariableBindings(_cancelButton)];
    NSArray *vertical = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-%f-[_cancelButton(%f)]-(>=8)-[_detailLabel]-(>=8)-[_textField]-[_confirmationButton]", X_BUTTON_VERTICAL_MARGIN, CLOSE_BUTTON_DIMENSION]
                                                                options:0
                                                                metrics:nil
                                                                  views:NSDictionaryOfVariableBindings(_cancelButton, _detailLabel, _textField, _confirmationButton)];
    NSLayoutConstraint *detailLabelCenter = [NSLayoutConstraint constraintWithItem:self.detailLabel
                                                                         attribute:NSLayoutAttributeCenterY
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.view
                                                                         attribute:NSLayoutAttributeBottom
                                                                        multiplier:0.20
                                                                          constant:0.0];
    NSLayoutConstraint *tfCentering = [NSLayoutConstraint constraintWithItem:self.textField
                                                                   attribute:NSLayoutAttributeCenterY
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.view
                                                                   attribute:NSLayoutAttributeCenterY
                                                                  multiplier:0.75
                                                                    constant:0.0];

    [self.view addConstraints:horizontal];
    [self.view addConstraints:vertical];
    [self.view addConstraints:horizontalTF];
    [self.view addConstraints:horizontalButton];
    [self.view addConstraints:@[activityIndicatorHorizontal, activityIndicatorVertical, activityIndicatorWidth, activityIndicatorHeight]];
    [self.view addConstraints:horizontalCancelConstraints];
    [self.view addConstraints:@[tfCentering, detailLabelCenter]];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setNeedsStatusBarAppearanceUpdate];
}

#pragma mark - Read-Only Properties

@synthesize detailLabel = _detailLabel;
@synthesize textField = _textField;
@synthesize confirmationButton = _confirmationButton;
@synthesize activityIndicator = _activityIndicator;
@synthesize cancelButton = _cancelButton;
@synthesize statesChain = _statesChain;

- (CNActivityIndicator *)activityIndicator
{
    if (!_activityIndicator) {
        _activityIndicator = [[CNActivityIndicator alloc] initWithFrame:CGRectZero presentedOnLightBackground:NO];
        _activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _activityIndicator;
}

- (UIButton *)cancelButton
{
    if (!_cancelButton) {
        _cancelButton = [[CNCloseButton alloc] initWithColor:[UIColor whiteColor]];
        [_cancelButton addTarget:self action:@selector(closeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        _cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _cancelButton;
}

- (UIButton *)confirmationButton
{
    if (!_confirmationButton) {
        _confirmationButton = [[UIButton alloc] init];
        [_confirmationButton setTitle:@"OK" forState:UIControlStateNormal];
        _confirmationButton.titleLabel.numberOfLines = 1;
        _confirmationButton.titleLabel.backgroundColor = [UIColor clearColor];
        _confirmationButton.backgroundColor = [UIColor clearColor];
        _confirmationButton.titleLabel.textColor = [UIColor whiteColor];
        _confirmationButton.alpha = 0.0;
        [_confirmationButton setTitleColor:DISABLED_GRAY_COLOR forState:UIControlStateHighlighted];
        [_confirmationButton addTarget:self
                                action:@selector(confirmationButtonWasPressed:)
                      forControlEvents:UIControlEventTouchUpInside];
        
        _confirmationButton.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _confirmationButton;
}

- (UILabel *)detailLabel
{
    if (!_detailLabel) {
        _detailLabel = [[UILabel alloc] init];
        _detailLabel.backgroundColor = [UIColor clearColor];
        _detailLabel.textColor = [UIColor whiteColor];
        _detailLabel.font = INSTRUCTION_LABEL_FONT;
        _detailLabel.numberOfLines = 0;
        
        _detailLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_detailLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [_detailLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    }
    return _detailLabel;
}

- (CNNumberEntryTextField *)textField
{
    if (!_textField) {
        _textField = [[CNNumberEntryTextField alloc] initWithDelegate:self];
        _textField.bounds = CGRectMake(0, 0, 0, FOCAL_LABEL_TEXT_SIZE);
    }
    return _textField;
}

- (NSMutableArray *)statesChain
{
    if (!_statesChain) {
        _statesChain = [NSMutableArray array];
    }
    return _statesChain;
}

static inline NSArray *textFieldGroupArray(CNAuthViewControllerState state)
{
    NSArray *result = nil;
    switch (state) {
        case CNAuthViewControllerStateVerificationCodeEntry:
            result = @[@(6)];
            break;
        case CNAuthViewControllerStatePhoneNumberEntry:
            result = @[@(3), @(3), @(4)];
            break;
        case CNAuthViewControllerStateWait:
            result = nil;
            break;
        default:
            NSCAssert(NO, @"CNAuthViewController is in an unknown state.");
            break;
    }
    return result;
}

static inline NSString *detailLabelStringForState(CNAuthViewControllerState state)
{
    NSString *result = @"UNKNOWN_STATE";
    switch (state) {
        case CNAuthViewControllerStatePhoneNumberEntry:
            result = @"We’ll send you a text message when a class you’re tracking becomes available so you can register immediately.";
            break;
        case CNAuthViewControllerStateVerificationCodeEntry:
            result = @"We’ve just sent you a text message with code to verify that this is your phone number. Please enter it.";
            break;
        case CNAuthViewControllerStateWait:
            result = @"";
            break;
        default:
            NSCAssert(NO, @"CNAuthViewController is in an unknown state.");
            break;
    }
    return result;
}

#pragma mark - Number Entry Text Field Handling

- (void)numberEntryTextFieldDidChangeText:(CNNumberEntryTextField *)tf
{
    CGFloat targetButtonAlpha = 0.0;
    if (tf.numberOfDigitsEntered == tf.digitsNeeded) {
        targetButtonAlpha = 1.0;
    }
    
    if (targetButtonAlpha != self.confirmationButton.alpha) {
        [UIView animateWithDuration:ANIMATION_DURATION animations:^{
            self.confirmationButton.alpha = targetButtonAlpha;
        }];
    }
}

#pragma mark - State Machine

- (void)confirmationButtonWasPressed:(id)sender
{
    switch (self.currentState) {
        case CNAuthViewControllerStatePhoneNumberEntry:
        {
            self.phoneNumber = self.textField.text;
            [self changeState:CNAuthViewControllerStateWait animated:YES];
            [self.delegate authViewController:self
                      receivedUserPhoneNumber:self.phoneNumber
                       doneProcessingCallback:^(BOOL processingSucceeded){
                           if (!processingSucceeded) {
                               [self changeState:CNAuthViewControllerStatePhoneNumberEntry animated:YES];
                               [[[UIAlertView alloc] initWithTitle:@"Error"
                                                           message:@"Unable to send the phone number to Class Ninja"
                                                          delegate:nil
                                                 cancelButtonTitle:@"OK"
                                                 otherButtonTitles:nil] show];
                           } else {
                               [self changeState:CNAuthViewControllerStateVerificationCodeEntry animated:YES];
                           }
                       }];
            break;
        }
        case CNAuthViewControllerStateVerificationCodeEntry:
        {
            [self changeState:CNAuthViewControllerStateWait animated:YES];
            [self.delegate authViewController:self
                     receivedConfirmationCode:self.textField.text
                               forPhoneNumber:self.phoneNumber
                       doneProcessingCallback:^(BOOL success) {
                        if (!success) {
                            self.phoneNumber = nil;
                            [self changeState:CNAuthViewControllerStatePhoneNumberEntry animated:YES];
                            [[[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"Unable to confirm your phone number with Class Ninja"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil] show];
                        }
                    }];
            break;
        }
        default:
        {
            CNAssertFail(@"auth_view_conf_button_state", @"Confirmation button pressed in unexpected state: %d", (int)self.currentState);
            break;
        }
    }
}

- (void)changeState:(CNAuthViewControllerState)newState animated:(BOOL)animated
{
    [self.view.layer removeAllAnimations];
    [self.detailLabel.layer removeAllAnimations];
    [self.textField.layer removeAllAnimations];
    [self.confirmationButton.layer removeAllAnimations];
    void (^switchUIToNewState)(CNAuthViewControllerState) = ^(CNAuthViewControllerState state){
        self.detailLabel.text = detailLabelStringForState(state);
        NSArray *groups = textFieldGroupArray(state);
        if (groups) {
            self.textField.groupArray = groups;
        }
        self.textField.text = @"";
        NSString *stateNameForAnalytics = @"unknown";
        
        switch (state) {
            case CNAuthViewControllerStatePhoneNumberEntry:
                self.detailLabel.alpha = 1.0;
                self.textField.alpha = 1.0;
                self.activityIndicator.alpha = 0.0;
                self.view.backgroundColor = AUTH_BLUE_COLOR;
                [self.textField becomeFirstResponder];
                stateNameForAnalytics = @"phone_number_entry";
                break;
            case CNAuthViewControllerStateVerificationCodeEntry:
                self.detailLabel.alpha = 1.0;
                self.textField.alpha = 1.0;
                self.activityIndicator.alpha = 0.0;
                self.view.backgroundColor = CONFIRMATION_COLOR;
                [self.textField becomeFirstResponder];
                stateNameForAnalytics = @"verification_code_entry";
                break;
            case CNAuthViewControllerStateWait:
                self.detailLabel.alpha = 0.0;
                self.textField.alpha = 0.0;
                self.activityIndicator.alpha = 1.0;
                [self.textField resignFirstResponder];
                stateNameForAnalytics = @"wait";
                break;
            default:
                CNAssertFail(@"auth_view_switch_to_state", @"Unknown state: %d", (int)state);
                break;
        }
        self.currentState = state;
        
        logUserAction(@"auth_view_state_switch", @{ @"state" : stateNameForAnalytics });
        [self.statesChain addObject:stateNameForAnalytics];
    };
    
    if (animated) {
        [UIView animateWithDuration:ANIMATION_DURATION animations:^{
            self.detailLabel.alpha = 0.0;
            self.textField.alpha = 0.0;
            self.confirmationButton.alpha = 0.0;
            self.activityIndicator.alpha = 0.0;
        } completion:^(BOOL finished) {
            if (finished) {
                [UIView animateWithDuration:ANIMATION_DURATION animations:^{
                    switchUIToNewState(newState);
                }];
            }
        }];
    } else {
        switchUIToNewState(newState);
    }
}

- (void)closeButtonTapped:(id)sender
{
    logUserAction(@"auth_view_cancel", @{ @"state_chain" : self.statesChain });
    [self.delegate authViewControllerCancelledAuthentication:self];
}

@end
