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

#import <FacebookSDK/FacebookSDK.h>
#import <Social/Social.h>

#define kSpinnerRadius 36

#define kMessageOffsetX     30
#define kMessageOffsetY     90
#define KMessageMaxHeight   200

#define kSignUpOffsetX  160

#define kSharingOffsetY kSignUpOffsetY

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
@property (nonatomic) FBAppCall *call;

@property (nonatomic) UIButton *shareOnFacebook;
@property (nonatomic) UIButton *shareOnTwitter;
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

- (BOOL)isFacebookSharingEnabled
{
    CNUser *loggedInUser = [[[CNAPIClient sharedInstance] authContext] loggedInUser];
    BOOL canPresentDialogInFBApp = ([FBDialogs canPresentShareDialog] && [FBSession activeSession]);
    return [loggedInUser didPostOnFb] == NO && (canPresentDialogInFBApp || [self canPresentSystemFacebookDialog]);
}

- (BOOL)canPresentSystemFacebookDialog
{
   return [FBDialogs canPresentOSIntegratedShareDialogWithSession:[FBSession activeSession]];
}

- (BOOL)isTwitterSharingEnabled
{
    CNUser *loggedInUser = [[[CNAPIClient sharedInstance] authContext] loggedInUser];
    BOOL twitterUserIsLoggedIn =  [SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter];
    return [loggedInUser didPostOnTwitter] == NO && twitterUserIsLoggedIn;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor r:43 g:53 b:100];
    [self.view addSubview:self.cancel];
    [self.view addSubview:self.signUp];
    [self.view addSubview:self.marketingMessage];
    [self.view addSubview:self.activityIndicator];
    
    if ([self isFacebookSharingEnabled]) {
        [self.view addSubview:self.shareOnFacebook];
    }
    
    if ([self isTwitterSharingEnabled]) {
        [self.view addSubview:self.shareOnTwitter];
    }
}

- (void)changeElementsVisibilityWithActivityIndicatorVisible:(BOOL)showActivityIndicator
{
    self.activityIndicator.alpha = showActivityIndicator;
    self.cancel.alpha = !showActivityIndicator;
    self.signUp.alpha = !showActivityIndicator;
    self.marketingMessage.alpha = !showActivityIndicator;
    self.shareOnTwitter.alpha = !showActivityIndicator;
    self.shareOnFacebook.alpha = !showActivityIndicator;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self changeElementsVisibilityWithActivityIndicatorVisible:YES];
    
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
                        [self changeElementsVisibilityWithActivityIndicatorVisible:NO];
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
    [super viewWillDisappear:animated];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.marketingMessage.frame = CGRectMake(kMessageOffsetX, kMessageOffsetY, self.view.bounds.size.width - 2 * kMessageOffsetX, KMessageMaxHeight);
    
    
    CGFloat sharingYOffset = 0;
    if ([self isFacebookSharingEnabled]) {
        self.shareOnFacebook.frame = CGRectMake(kSignUpOffsetX, kSharingOffsetY, kSignupMaxWidth, kSignupMaxHeight);
        sharingYOffset += kSignupMaxHeight;
    }
    
    if ([self isTwitterSharingEnabled]) {
        self.shareOnTwitter.frame = CGRectMake(kSignUpOffsetX, kSharingOffsetY + sharingYOffset, kSignupMaxWidth, kSignupMaxHeight);
        sharingYOffset += kSignupMaxHeight;
    }
    
    self.signUp.frame = CGRectMake(kSignUpOffsetX, kSignUpOffsetY + sharingYOffset, kSignupMaxWidth, kSignupMaxHeight);
    self.cancel.frame = CGRectMake(kCancelOffsetX, kCancelOffsetY + sharingYOffset, kCancelMaxWidth, kCancelMaxHeight);
}

- (void)signUpButtonPressed
{
    logUserAction(@"purchase_intent", nil);
    self.signUp.enabled = NO;
    
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        [self changeElementsVisibilityWithActivityIndicatorVisible:YES];
    } completion:^(BOOL finished){
        [[CNInAppPurchaseManager sharedInstance] addProductToPaymentQueue:self.product];
    }];
}

- (void)creditUserForSharingWithService:(NSString *)serviceType
{
    CNAPIClientSharedStatus status = CNAPIClientSharedOnNone;
    if ([serviceType isEqualToString:SLServiceTypeFacebook]) {
        status = CNAPIClientSharedOnFb;
    } else if ([serviceType isEqualToString:SLServiceTypeTwitter]) {
        status = CNAPIClientSharedOnTwitter;
    }

    if (status != CNAPIClientSharedOnNone) {
        [self changeElementsVisibilityWithActivityIndicatorVisible:YES];
        [[CNAPIClient sharedInstance] creditUserForSharing:status
                                                completion:^(BOOL didSucceed) {
                                                    [self dismiss];
                                                }];
    }
}

#define kShareURL ([NSURL URLWithString:@"http://class-ninja.com"])
#define kShareImage ([UIImage imageNamed:@"AppIcon57x57"])
#define kShareMessage (@"Get notified when class has space to register!")

- (void)shareWithiOSDialogForService:(NSString *)serviceType
{
    SLComposeViewController *vc = [SLComposeViewController composeViewControllerForServiceType:serviceType];
    [vc addImage:kShareImage];
    [vc addURL:kShareURL];

    [vc setInitialText:kShareMessage];
    
    vc.completionHandler = ^(SLComposeViewControllerResult result) {
        if (result == SLComposeViewControllerResultDone) {
            [self creditUserForSharingWithService:serviceType];
        }
        NSString *statusString = (result == SLComposeViewControllerResultCancelled) ? @"cancelled" : @"posted";
        logUserAction(@"paywall_share", @{ @"completion_status" : statusString, @"service" : serviceType});
    };
    
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)shareOnFacebookButtonPressed
{
    if ([self canPresentSystemFacebookDialog]) {
        [self shareWithiOSDialogForService:SLServiceTypeFacebook];
    } else {
        [FBDialogs presentShareDialogWithLink:kShareURL
                                         name:nil
                                      caption:@"Never miss class spots again!"
                                  description:kShareMessage
                                      picture:nil
                                  clientState:nil
                                      handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
                                          // there is no way of actually knowing if user cancelled or posted, unless user authorizes our app
                                          // We don't want to go through this just yet for two reasons: 1) time 2) it can alienate users
                                          // Let's grant them their free targets anyways, because we're testing sharing to begin with.
                                          logUserAction(@"paywall_share", @{ @"completion_status" : @"unknown", @"service" : @"fb_app"});
                                          [self creditUserForSharingWithService:SLServiceTypeFacebook];
                                      }];
    }
}

- (void)shareOnTwitterButtonPressed
{
    [self shareWithiOSDialogForService:SLServiceTypeTwitter];
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

- (UIButton *)shareOnFacebook
{
    if (_shareOnFacebook == nil) {
        _shareOnFacebook = [UIButton buttonWithType:UIButtonTypeCustom];
        [_shareOnFacebook setTitle: @"Share on Facebook" forState:UIControlStateNormal];
        [_shareOnFacebook addTarget:self action:@selector(shareOnFacebookButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        
        _shareOnFacebook.backgroundColor = [UIColor clearColor];
        _shareOnFacebook.titleLabel.textColor = [UIColor whiteColor];
        _shareOnFacebook.titleLabel.font = kSignupButtonFont;
    }
    return _shareOnFacebook;
}

- (UIButton *)shareOnTwitter
{
    if (_shareOnTwitter == nil) {
        _shareOnTwitter = [UIButton buttonWithType:UIButtonTypeCustom];
        [_shareOnTwitter setTitle: @"Share on Twitter" forState:UIControlStateNormal];
        [_shareOnTwitter addTarget:self action:@selector(shareOnTwitterButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        
        _shareOnTwitter.backgroundColor = [UIColor clearColor];
        _shareOnTwitter.titleLabel.textColor = [UIColor whiteColor];
        _shareOnTwitter.titleLabel.font = kSignupButtonFont;
    }
    return _shareOnTwitter;
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
