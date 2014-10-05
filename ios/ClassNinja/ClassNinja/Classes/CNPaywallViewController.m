//
//  CNPaywallViewController.m
//  ClassNinja
//
//  Created by Boris Suvorov on 9/13/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNPaywallViewController.h"
#import "CNInAppPurchaseManager.h"
#import "CNActivityIndicator.h"
#import "CNAPIClient.h"

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

#define kCancelButtonFont           [UIFont cnSystemFontOfSize:16]
#define kSignupButtonFont           [UIFont cnBoldSystemFontOfSize:16]


@interface CNPaywallViewController ()
@property (nonatomic) UIButton *cancel;
@property (nonatomic) UIButton *signUp;
@property (nonatomic) UILabel *marketingMessage;
@property (nonatomic) CNActivityIndicator *activityIndicator;
@property (nonatomic) SKProduct *product;
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
    [self.view addSubview:self.activityIndicator];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.activityIndicator.alpha = 1.0;
    self.cancel.alpha = 0;
    self.signUp.alpha = 0;
    self.marketingMessage.alpha = 0;
    
    // Whenever a transaction is either finished, deferred or failed, just dismiss ourselves
    for (NSString *notificationName in @[TRANSACTION_FINISHED_NOTIFICATION_NAME,
                                         TRANSACTION_DEFERRED_NOTIFICATION_NAME,
                                         TRANSACTION_FAILED_NOTIFICATION_NAME])
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismiss) name:notificationName object:nil];
    
    __block NSString *salesPitchTemplate = nil;
    __block SKProduct *tenCreditsProduct = nil;
    NSDate *beforeTime = [NSDate date];
    void (^presentSalesPitch)(NSString *, SKProduct *) = ^(NSString *salesPitch, SKProduct *product)
    {
        if ((!salesPitch && !product)) {
            logIssue(@"sales_pitch_present_fail", nil);
            [self dismiss];
        } else {
            @synchronized(self) {
                if (salesPitch) {
                    salesPitchTemplate = salesPitch;
                }
                if (product) {
                    tenCreditsProduct = product;
                }
                
                if (salesPitchTemplate && tenCreditsProduct) {
                    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
                    numberFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
                    numberFormatter.locale = tenCreditsProduct.priceLocale;
                    NSString *localizedPrice = [numberFormatter stringFromNumber:tenCreditsProduct.price];
                    NSString *salesPitchText = [NSString stringWithFormat:salesPitchTemplate, localizedPrice];
                    self.marketingMessage.text = salesPitchText;
                    self.product = tenCreditsProduct;
                    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
                        self.activityIndicator.alpha = 0.0;
                        self.cancel.alpha = 1.0;
                        self.signUp.alpha = 1.0;
                        self.marketingMessage.alpha = 1.0;
                    }];
                    
                    logUserAction(@"sales_pitch_present", @
                    {
                        @"sales_pitch" : salesPitchText,
                        @"load_time" : @([[NSDate date] timeIntervalSinceDate:beforeTime])
                    });
                }
                
            }
        }
    };
    
    [[CNAPIClient sharedInstance] fetchSalesPitch:^(NSString *salesPitch) {
        if (!salesPitch) {
            salesPitch = @"For just %@, you will be able to track ten more classes.";
        }
        presentSalesPitch(salesPitch, nil);
    }];
    
    [[CNInAppPurchaseManager sharedInstance] fetchProductForProductId:@"10_Classes" completion:^(SKProduct *product) {
        presentSalesPitch(nil, product);
    }];
            
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    logUserAction(@"purchase_intent", nil);
    self.signUp.enabled = NO;
    
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        self.marketingMessage.alpha = 0;
        self.cancel.alpha = 0;
        self.signUp.alpha = 0;
        self.activityIndicator.alpha = 1;
    } completion:^(BOOL finished){
        [[CNInAppPurchaseManager sharedInstance] addProductToPaymentQueue:self.product];
    }];
}

- (void)dismiss
{
    // The notifications aren't guaranteed to be sent out on the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:YES completion:nil];
    });
}

- (void)cancelButtonPressed
{
    logUserAction(@"purchase_cancelled", nil);
    [self dismiss];
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
        _marketingMessage.numberOfLines = 0;
        _marketingMessage.textColor = [UIColor whiteColor];
        _marketingMessage.font = [UIFont systemFontOfSize:20];
    }
    return _marketingMessage;
}

@end
