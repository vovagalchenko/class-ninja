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
#import "CNCloseButton.h"
#import "CNSiongsTernaryViewController.h"

#import <FacebookSDK/FacebookSDK.h>
#import <Social/Social.h>

#define kSpinnerRadius 36

@interface CNPaywallViewController ()
@property (nonatomic) CNSalesPitch *salesPitch;

@property (nonatomic) UIButton *shareOnFacebook;
@property (nonatomic) UIButton *shareOnTwitter;
@property (nonatomic) UIButton *cancel;
@property (nonatomic) UIButton *signUp;

@property (nonatomic) UILabel *reminderOfFreeTargetsForSignupLabel;
@property (nonatomic) UILabel *marketingMessageForPurchaseLabel;
@property (nonatomic) UILabel *sharingPitchLabel;

@property (nonatomic) UIView *reminderSharingSeparator;
@property (nonatomic) UIView *sharingUpgradeSeparator;

@property (nonatomic) UIView *spacer;

@property (nonatomic) CNActivityIndicator *activityIndicator;
@property (nonatomic) SKProduct *product;
@end


@implementation CNPaywallViewController

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (BOOL)doesShowSharing
{
    return [self isFacebookSharingEnabled] || [self isTwitterSharingEnabled];
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
    [self.view addSubview:self.marketingMessageForPurchaseLabel];
    [self.view addSubview:self.activityIndicator];
    [self.view addSubview:self.spacer];

    if ([self doesShowSharing]) {
        [self.view addSubview:self.reminderOfFreeTargetsForSignupLabel];
        [self.view addSubview:self.sharingPitchLabel];
        
        if ([self isFacebookSharingEnabled]) {
            [self.view addSubview:self.shareOnFacebook];
        }
        
        if ([self isTwitterSharingEnabled]) {
            [self.view addSubview:self.shareOnTwitter];
        }
        
        [self.view addSubview:self.sharingUpgradeSeparator];
        [self.view addSubview:self.reminderSharingSeparator];
    }

    [self setupViewConstraints];
}

- (void)setupViewConstraints
{
    NSString *format = nil;
    NSDictionary *buttonsDict = nil;
    NSDictionary *viewsDict = nil;
    
    // s0 -> special spacer view to help autolayot at the bottom of layout
    // this essnetially adds padding at the bottom of the view and it ensures that autolayout
    // layous things similarly on all screen sizes. Without s0 spacer view, top level view would get stretched vertically
    // to take all of the available space, because all other views would have fixed size
    NSString *bottomFormat = @"[marketingMessageForPurchaseLabel]-30-[signUp]-[s0]|";
    
    if ([self doesShowSharing]) {
        format = @"V:|-60-[reminderOfFreeTargetsForSignupLabel]-40-[reminderSharingSeparator(==0.5)]-15-[sharingPitchLabel]";
        if ([self isFacebookSharingEnabled]) {
            format = [format stringByAppendingString:@"-30-[shareOnFacebook]"];
        }
        
        if ([self isTwitterSharingEnabled]) {
            format = [format stringByAppendingString:@"-30-[shareOnTwitter]"];
        }
        
        format = [format stringByAppendingString:@"-40-[sharingUpgradeSeparator(==0.5)]-"];
        format = [format stringByAppendingString:bottomFormat];
        
        buttonsDict = @{@"shareOnFacebook" : self.shareOnFacebook,
                        @"shareOnTwitter" : self.shareOnTwitter,
                        @"signUp" : self.signUp};
        
        viewsDict = @{@"s0" : self.spacer,
                      @"reminderOfFreeTargetsForSignupLabel" : self.reminderOfFreeTargetsForSignupLabel,
                      @"reminderSharingSeparator" : self.reminderSharingSeparator,
                      @"sharingPitchLabel" : self.sharingPitchLabel,
                      @"sharingUpgradeSeparator" : self.sharingUpgradeSeparator,
                      @"marketingMessageForPurchaseLabel" : self.marketingMessageForPurchaseLabel};
    } else {
        format = [@"V:|-60-" stringByAppendingString:bottomFormat];
        buttonsDict = @{@"signUp" : self.signUp};
        viewsDict = @{@"s0" : self.spacer,
                      @"marketingMessageForPurchaseLabel" : self.marketingMessageForPurchaseLabel};
    }

    NSMutableDictionary *combined = [NSMutableDictionary dictionaryWithDictionary:buttonsDict];
    [combined addEntriesFromDictionary:viewsDict];
    
    NSArray *vConstraints = [NSLayoutConstraint constraintsWithVisualFormat:format
                                                                    options:(NSLayoutFormatAlignAllRight)
                                                                    metrics:nil
                                                                      views:combined];
    [self.view addConstraints:vConstraints];
    
    [viewsDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString *format = [NSString stringWithFormat:@"H:|-30-[%@]-30-|", key];
        NSArray *hConstraint = [NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:nil views:@{key:obj}];
        [self.view addConstraints:hConstraint];
    }];

}

- (void)changeElementsVisibilityWithActivityIndicatorVisible:(BOOL)showActivityIndicator
{
    self.activityIndicator.alpha = showActivityIndicator;

    self.reminderOfFreeTargetsForSignupLabel.alpha = (!showActivityIndicator) * 0.9;
    self.sharingPitchLabel.alpha = (!showActivityIndicator) * 0.9;
    self.marketingMessageForPurchaseLabel.alpha = (!showActivityIndicator) * 0.9;
    
    self.signUp.alpha = !showActivityIndicator;
    self.shareOnTwitter.alpha = !showActivityIndicator;
    self.shareOnFacebook.alpha = !showActivityIndicator;
    
    self.reminderSharingSeparator.alpha = (!showActivityIndicator) * 0.3;
    self.sharingUpgradeSeparator.alpha = (!showActivityIndicator) * 0.3;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self changeElementsVisibilityWithActivityIndicatorVisible:YES];
    
    // Whenever a transaction is either finished, deferred or failed, just dismiss ourselves
    for (NSString *notificationName in @[TRANSACTION_FINISHED_NOTIFICATION_NAME,
                                         TRANSACTION_DEFERRED_NOTIFICATION_NAME,
                                         TRANSACTION_FAILED_NOTIFICATION_NAME]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(iapTransactionNotificationHandler:) name:notificationName object:nil];
    }
    
    __block NSString *salesPitchTemplate = nil;
    __block SKProduct *tenCreditsProduct = nil;
    NSDate *beforeTime = [NSDate date];
    void (^presentSalesPitch)(CNSalesPitch *, SKProduct *) = ^(CNSalesPitch *salesPitch, SKProduct *product)
    {
        if ((!salesPitch && !product)) {
            logIssue(@"sales_pitch_present_fail", nil);
            [self dismiss];
        } else {
            @synchronized(self) {
                if (salesPitch) {
                    salesPitchTemplate =  [self doesShowSharing] ? salesPitch.shortMarketingMessage : salesPitch.longMarketingMessage;
                    self.reminderOfFreeTargetsForSignupLabel.text = [NSString stringWithFormat:salesPitch.signup_reminder, salesPitch.freeClassesForSignup];
                    self.sharingPitchLabel.text = [NSString stringWithFormat:salesPitch.sharing_pitch, salesPitch.freeClassesForSharing];
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
                    self.marketingMessageForPurchaseLabel.text = salesPitchText;
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
    
    [[CNAPIClient sharedInstance] fetchSalesPitch:^(CNSalesPitch *salesPitch) {
        if (!salesPitch) {
            self.salesPitch = [CNSalesPitch defaultPitch];
        } else {
            self.salesPitch = salesPitch;
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
    self.cancel.frame = CGRectMake(CLOSE_BUTTON_OFFSET_X, CLOSE_BUTTON_OFFSET_Y, CLOSE_BUTTON_DIMENSION, CLOSE_BUTTON_DIMENSION);
}

-(BOOL)prefersStatusBarHidden
{
    return YES;
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


    void (^completion)(BOOL didSucceed) = ^void(BOOL didSucceed) {
        if (didSucceed) {            
            NSString *description = [NSString stringWithFormat:@"You will be able to track an extra %@ classes.", self.salesPitch.freeClassesForSharing];
            [self presentConfirmationVCWithDescription:description];
        } else {
            [[[UIAlertView alloc] initWithTitle:@"Ooops"
                                        message:@"Please try again! Something went wrong when we tried to credit you for sharing."
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
        }
    };
    
    if (status != CNAPIClientSharedOnNone) {
        [self changeElementsVisibilityWithActivityIndicatorVisible:YES];
        [[CNAPIClient sharedInstance] creditUserForSharing:status
                                                completion:completion];
    }
}

#define kShareImage ([UIImage imageNamed:@"AppIcon57x57"])
- (void)shareWithiOSDialogForService:(NSString *)serviceType
{
    SLComposeViewController *vc = [SLComposeViewController composeViewControllerForServiceType:serviceType];

    NSURL *shareURL = [NSURL URLWithString:self.salesPitch.sharingLinkString];
    [vc addURL:shareURL];
    [vc setInitialText:self.salesPitch.sharingMessagePlaceholder];

    [vc addImage:kShareImage];
    
    vc.completionHandler = ^(SLComposeViewControllerResult result) {
        if (result == SLComposeViewControllerResultDone) {
            [self creditUserForSharingWithService:serviceType];
        }
        
        NSString *statusString = (result == SLComposeViewControllerResultCancelled) ? @"cancelled" : @"posted";
        logUserAction(@"paywall_share", @{ @"completion_status" : statusString,
                                           @"service" : serviceType,
                                           @"free_targets_offered" : self.salesPitch.freeClassesForSharing});
    };
    
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)shareOnFacebookButtonPressed
{
    if ([self canPresentSystemFacebookDialog]) {
        [self shareWithiOSDialogForService:SLServiceTypeFacebook];
    } else {
        NSURL *shareURL = [NSURL URLWithString:self.salesPitch.sharingLinkString];
        [FBDialogs presentShareDialogWithLink:shareURL
                                         name:nil
                                      caption:self.salesPitch.fbCaption
                                  description:self.salesPitch.sharingMessagePlaceholder
                                      picture:nil
                                  clientState:nil
                                      handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
                                          // there is no way of actually knowing if user cancelled or posted, unless user authorizes our app
                                          // We don't want to go through this just yet for two reasons: 1) time 2) it can alienate users
                                          // Let's grant them their free targets anyways, because we're testing sharing to begin with.
                                          logUserAction(@"paywall_share", @{ @"completion_status" : @"unknown",
                                                                             @"service" : @"fb_app",
                                                                             @"free_targets_offered" : self.salesPitch.freeClassesForSharing});
                                          [self creditUserForSharingWithService:SLServiceTypeFacebook];
                                      }];
    }
}

- (void)shareOnTwitterButtonPressed
{
    [self shareWithiOSDialogForService:SLServiceTypeTwitter];
}

- (void)presentConfirmationVCWithDescription:(NSString *)descriptionString
{
    CNConfirmationViewController *vc = [[CNConfirmationViewController alloc] init];
    vc.titleLabel.text = @"Thanks!";
    vc.descriptionLabel.text = descriptionString;
    vc.completionBlock = ^{
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    };
    
    vc.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)iapTransactionNotificationHandler:(NSNotification *)notification
{
    // The notifications aren't guaranteed to be sent out on the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        if([notification.name isEqualToString:TRANSACTION_FINISHED_NOTIFICATION_NAME]) {
            NSString *description = [NSString stringWithFormat:@"You will be able to track an extra %@ classes.", self.salesPitch.classesForPurchase];
            [self presentConfirmationVCWithDescription:description];
        } else {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    });
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
        _cancel = [[CNCloseButton alloc] initWithColor:[UIColor whiteColor]];
        [_cancel addTarget:self action:@selector(cancelButtonPressed) forControlEvents:UIControlEventTouchUpInside];
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
        _shareOnFacebook = [UIButton cnTextButtonForAutolayout];
        [_shareOnFacebook setTitle: @"Share on Facebook" forState:UIControlStateNormal];
        [_shareOnFacebook addTarget:self action:@selector(shareOnFacebookButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    return _shareOnFacebook;
}

- (UIButton *)shareOnTwitter
{
    if (_shareOnTwitter == nil) {
        _shareOnTwitter = [UIButton cnTextButtonForAutolayout];
        [_shareOnTwitter setTitle: @"Share on Twitter" forState:UIControlStateNormal];
        [_shareOnTwitter addTarget:self action:@selector(shareOnTwitterButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    return _shareOnTwitter;
}

- (UIButton *)signUp
{
    if (_signUp == nil) {
        _signUp = [UIButton cnTextButtonForAutolayout];
        [_signUp setTitle: @"Sure, sign me up!" forState:UIControlStateNormal];
        [_signUp addTarget:self action:@selector(signUpButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    return _signUp;
}

- (UILabel *)marketingMessageForPurchaseLabel
{
    if (_marketingMessageForPurchaseLabel == nil) {
        _marketingMessageForPurchaseLabel = [UILabel cnMessageLabelForAutoLayout];
        
        setDefaultAutoLayoutSettings(_marketingMessageForPurchaseLabel);
    }
    return _marketingMessageForPurchaseLabel;
}

- (UILabel *)reminderOfFreeTargetsForSignupLabel
{
    if (_reminderOfFreeTargetsForSignupLabel == nil) {
        _reminderOfFreeTargetsForSignupLabel = [UILabel cnMessageLabelForAutoLayout];
       
        setDefaultAutoLayoutSettings(_reminderOfFreeTargetsForSignupLabel);
    }
    return _reminderOfFreeTargetsForSignupLabel;
}

- (UILabel *)sharingPitchLabel
{
    if (_sharingPitchLabel == nil) {
        _sharingPitchLabel = [UILabel cnMessageLabelForAutoLayout];
    }
    return _sharingPitchLabel;
}

- (UIView *)reminderSharingSeparator
{
    if (_reminderSharingSeparator == nil) {
        _reminderSharingSeparator = [[UIView alloc] init];
        _reminderSharingSeparator.backgroundColor = [UIColor whiteColor];
        _reminderSharingSeparator.translatesAutoresizingMaskIntoConstraints = NO;
    }
    
    return _reminderSharingSeparator;
}

- (UIView *)spacer
{
    if (_spacer == nil) {
        _spacer = [[UIView alloc] init];
        _spacer.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _spacer;
}

- (UIView *)sharingUpgradeSeparator
{
    if (_sharingUpgradeSeparator == nil) {
        _sharingUpgradeSeparator = [[UIView alloc] init];
        _sharingUpgradeSeparator.backgroundColor = [UIColor whiteColor];
        _sharingUpgradeSeparator.translatesAutoresizingMaskIntoConstraints = NO;
    }
    
    return _sharingUpgradeSeparator;
}

@end
