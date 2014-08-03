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

typedef enum : NSUInteger {
    CNAuthViewControllerStatePhoneNumberEntry,
    CNAuthViewControllerStateVerificationCodeEntry,
} CNAuthViewControllerState;

@interface CNAuthViewController ()

@property (nonatomic, readonly) UILabel *detailLabel;
@property (nonatomic, readonly) CNNumberEntryTextField *textField;
@property (nonatomic, readwrite) CNAuthViewControllerState currentState;

@end

@implementation CNAuthViewController

#pragma mark - UIViewController lifecycle

- (instancetype)init
{
    if (self = [super init]) {
        self.currentState = CNAuthViewControllerStatePhoneNumberEntry;
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
    self.detailLabel.text = [self detailLabelString];
    self.textField.groupArray = [self textFieldGroupArray];
    [self.textField becomeFirstResponder];
    [super viewWillAppear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = AUTH_BLUE_COLOR;
    [self.view addSubview:self.detailLabel];
    [self.view addSubview:self.textField];
    NSArray *horizontal = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-%f-[_detailLabel]-%f-|", HORIZONTAL_MARGIN, HORIZONTAL_MARGIN]
                                                                  options:0
                                                                  metrics:nil
                                                                    views:NSDictionaryOfVariableBindings(_detailLabel)];
    NSArray *vertical = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-%f-[_detailLabel]-%f-[_textField]", VERTICAL_MARGIN, VERTICAL_MARGIN]
                                                                options:0
                                                                metrics:nil
                                                                  views:NSDictionaryOfVariableBindings(_detailLabel, _textField)];
    NSArray *horizontalTF = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-%f-[_textField]-%f-|", HORIZONTAL_MARGIN, HORIZONTAL_MARGIN]
                                                                    options:0
                                                                    metrics:nil
                                                                      views:NSDictionaryOfVariableBindings(_textField)];
    [self.view addConstraints:horizontal];
    [self.view addConstraints:vertical];
    [self.view addConstraints:horizontalTF];
    self.detailLabel.text = [self detailLabelString];
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

#pragma mark - Subviews

@synthesize detailLabel = _detailLabel;
@synthesize textField = _textField;

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
        _textField = [[CNNumberEntryTextField alloc] init];
        _textField.bounds = CGRectMake(0, 0, 0, FOCAL_LABEL_TEXT_SIZE);
    }
    return _textField;
}

- (NSArray *)textFieldGroupArray
{
    NSArray *result = @[@(3), @(3), @(4)];
    switch (self.currentState) {
        case CNAuthViewControllerStateVerificationCodeEntry:
            result = @[@(4)];
            break;
        case CNAuthViewControllerStatePhoneNumberEntry:
            result = @[@(3), @(3), @(4)];
            break;
        default:
            NSAssert(NO, @"CNAuthViewController is in an unknown state.");
            break;
    }
    return result;
}

- (NSString *)detailLabelString
{
    NSString *result = @"UNKNOWN_STATE";
    switch (self.currentState) {
        case CNAuthViewControllerStatePhoneNumberEntry:
            result = @"We’ll send you a text message when a class you’re tracking becomes available so you can register immediately.";
            break;
        case CNAuthViewControllerStateVerificationCodeEntry:
            result = @"We’ve just sent you a text message with code to verify that this is your phone number. Please enter it.";
            break;
        default:
            NSAssert(NO, @"CNAuthViewController is in an unknown state.");
            break;
    }
    return result;
}

@end
