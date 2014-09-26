//
//  CNPaywallViewController.m
//  ClassNinja
//
//  Created by Boris Suvorov on 9/13/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNPaywallViewController.h"
#import "CNInAppPurchaseHelper.h"
#import "CNActivityIndicator.h"

#define kSpinnerRadius 36

#define kMessageOffsetX     30
#define kMessageOffsetY     90
#define KMessageMaxHeight   200

#define kSignUpOffsetX  160
#define kSignUpOffsetY  385
#define kSignupMaxWidth 160
#define kSignupMaxHeight 44

#define kCancelOffsetX  245
#define kCancelOffsetY  430
#define kCancelMaxWidth 60
#define kCancelMaxHeight 44

#define kCancelButtonFont [UIFont cnSystemFontOfSize:16]
#define kSignupButtonFont [UIFont cnBoldSystemFontOfSize:16]


@interface CNPaywallViewController ()
@property (nonatomic) UIButton *cancel;
@property (nonatomic) UIButton *signUp;
@property (nonatomic) UILabel *marketingMessage;
@property (nonatomic) CNActivityIndicator *activityIndicator;
@end


@implementation CNPaywallViewController

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor r:43 g:53 b:100];
    [self.view addSubview:self.cancel];
    [self.view addSubview:self.signUp];
    [self.view addSubview:self.marketingMessage];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.marketingMessage.frame = CGRectMake(kMessageOffsetX, kMessageOffsetY, self.view.bounds.size.width - 2 * kMessageOffsetX, KMessageMaxHeight);
    self.signUp.frame = CGRectMake(kSignUpOffsetX, kSignUpOffsetY, kSignupMaxWidth, kSignupMaxHeight);
    self.cancel.frame = CGRectMake(kCancelOffsetX, kCancelOffsetY, kCancelMaxWidth, kCancelMaxHeight);
}

- (void)signUpButtonPressed
{
    self.signUp.enabled = NO;
    [self.view addSubview:self.activityIndicator];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.marketingMessage.alpha = 0;
        self.cancel.alpha = 0;
        self.signUp.alpha = 0;
        self.activityIndicator.alpha = 1;
    } completion:nil];
    
    [[CNInAppPurchaseHelper sharedInstance] purchase:@"UQ_9_99" withCompletionBlock:^{
        [self dismiss];
    }] ;
}

- (void)dealloc
{
    NSLog(@"Dealloc called!");
}

- (void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (UIButton *)cancel
{
    if (_cancel == nil) {
        _cancel = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cancel setTitle:@"Cancel" forState:UIControlStateNormal];
        _cancel.backgroundColor = [UIColor clearColor];
        _cancel.titleLabel.textColor = [UIColor r:141 g:149 b:177];
        _cancel.titleLabel.font = kCancelButtonFont;
        [_cancel addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancel;
}

- (CNActivityIndicator *)activityIndicator
{
    if (_activityIndicator == nil) {
        CGRect frame = CGRectMake(self.view.bounds.size.width / 2 - kSpinnerRadius,
                                  self.view.bounds.size.height / 2 - kSpinnerRadius,
                                  kSpinnerRadius*2, kSpinnerRadius*2);
        
        _activityIndicator = [[CNActivityIndicator alloc] initWithFrame:frame
                                             presentedOnLightBackground:NO];
        _activityIndicator.alpha = 0;
    }
    return _activityIndicator;
}

- (UIButton *)signUp
{
    if (_signUp == nil) {
        _signUp = [UIButton buttonWithType:UIButtonTypeCustom];
        [_signUp setTitle: @"Sure, sign me up!" forState:UIControlStateNormal];
        [_signUp addTarget:self action:@selector(signUpButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        
        _signUp.backgroundColor = [UIColor clearColor];
        _signUp.titleLabel.textColor = [UIColor whiteColor];
        _signUp.titleLabel.font = kSignupButtonFont;
    }
    return _signUp;
}

- (UILabel *)marketingMessage
{
    if (_marketingMessage == nil) {
        _marketingMessage = [[UILabel alloc] init];
        
        NSString *message =@"The first 2 classes of the semester that you want to track are free.\n\n"
                            "For just $0.99, you will be able to track an unlimited number of classes for this semester";
        _marketingMessage.numberOfLines = 0;
        _marketingMessage.text = message;
        _marketingMessage.textColor = [UIColor whiteColor];
        _marketingMessage.font = [UIFont systemFontOfSize:20];
    }
    return _marketingMessage;
}

@end
