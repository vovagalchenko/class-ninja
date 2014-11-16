//
//  CNAppDelegate.m
//  ClassNinja
//
//  Created by Boris Suvorov on 7/5/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNAppDelegate.h"
#import "CNAPIClient.h"
#import "CNDashboardViewController.h"
#import "CNInAppPurchaseManager.h"
#import "NSData+CNAdditions.h"
#import "CNPaywallViewController.h"
#import <FacebookSDK/FacebookSDK.h>

@implementation CNAppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[Analytics sharedInstance] setDelegate:self];
    logAppLifecycleEvent(@"launch", nil);
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    configureStaticAppearance();
    
    CNDashboardViewController *dashboardVC = [[CNDashboardViewController alloc] init];
    self.window.rootViewController = dashboardVC;
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    for (NSString *notificationName in @[TRANSACTION_DEFERRED_NOTIFICATION_NAME,
                                         TRANSACTION_FAILED_NOTIFICATION_NAME]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(transactionStateChanged:) name:notificationName object:nil];
    }
    
    [[CNInAppPurchaseManager sharedInstance] ensurePaymentQueueObserving];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    logAppLifecycleEvent(@"resign_active", nil);
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    logAppLifecycleEvent(@"enter_background", nil);
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    logAppLifecycleEvent(@"enter_foreground", nil);
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    logAppLifecycleEvent(@"become_active", nil);
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    logAppLifecycleEvent(@"terminate", nil);
}

#pragma mark - Push Notifications

- (void)registerForPushNotifications
{
    UIApplication *app = [UIApplication sharedApplication];
    if ([app respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound
                                                                                             categories:nil];
        [app registerUserNotificationSettings:notificationSettings];
    } else {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound];
    }
}

#define PUSH_NOTIFICATION_KNOWN_TOKENS_USER_DEFAULTS_KEY    @"known_tokens"

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    if (notificationSettings.types != UIRemoteNotificationTypeNone)
        [application registerForRemoteNotifications];
    else {
        logUserAction(@"pns_rejected", nil);
        [[[UIAlertView alloc] initWithTitle:@"Warning"
                                    message:@"The app has limited utility if you don't let us notify you of when classes become available. If you change your mind, make the appropriate change in your settings."
                                   delegate:nil
                          cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
    
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    return [FBSession.activeSession handleOpenURL:url];
}


- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *knownTokensCache = [userDefaults objectForKey:PUSH_NOTIFICATION_KNOWN_TOKENS_USER_DEFAULTS_KEY];
    CNAPIClient *apiClient = [CNAPIClient sharedInstance];
    NSString *currentUserPhoneNumber = [[[apiClient authContext] loggedInUser] phoneNumber];
    NSArray *knownTokensForUser = [knownTokensCache objectForKey:currentUserPhoneNumber];
    if (![knownTokensForUser containsObject:deviceToken]) {
        logUserAction(@"pns_received_new_token",
                      @{
                        @"token" : [deviceToken hexString]
                        });
        [apiClient registerDeviceForPushNotifications:deviceToken completion:^(BOOL success) {
            if (success) {
                NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:knownTokensCache ?: @{}];
                [dict setObject:[knownTokensForUser ?: @[] arrayByAddingObject:deviceToken] forKey:currentUserPhoneNumber];
                [userDefaults setObject:dict forKey:PUSH_NOTIFICATION_KNOWN_TOKENS_USER_DEFAULTS_KEY];
                [userDefaults synchronize];
            }
        }];
    }
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    logIssue(@"pns_registration_error",
             @{
               @"error_code" : @(error.code),
               @"error_msg" : error.description,
               @"error_domain" : error.domain
               });
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    [[[UIAlertView alloc] initWithTitle:@"Class Alert"
                                message:userInfo[@"aps"][@"alert"][@"body"]
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

#pragma mark - Transaction State Notifications

- (void)transactionStateChanged:(NSNotification *)notification
{
    // The notifications aren't guaranteed to be sent out on the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        SKPaymentTransaction *transaction = ((SKPaymentTransaction *)notification.object);
        if ([notification.name isEqualToString:TRANSACTION_FAILED_NOTIFICATION_NAME] &&
            transaction.error.code != SKErrorPaymentCancelled) {
            // If the user didn't straight up cancel the transaction, let's let them know something went wrong.
            [[[UIAlertView alloc] initWithTitle:@":("
                                        message:[NSString stringWithFormat:@"Apple says: %@", transaction.error.localizedDescription]
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
        } else if ([notification.name isEqualToString:TRANSACTION_DEFERRED_NOTIFICATION_NAME]) {
            [[[UIAlertView alloc] initWithTitle:@"Purchase Pending"
                                        message:@"Your purchase is pending approval from the responsible party."
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
        }

        if (transaction.error) {
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        }
    });
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - AnalyticsDelegate

- (NSDictionary *)supplementalData
{
    NSDictionary *data = nil;
    CNUser *loggedInUser = [[[CNAPIClient sharedInstance] authContext] loggedInUser];
    if (loggedInUser) {
        data = @{
            @"logged_in_user" : loggedInUser.phoneNumber
        };
    }
    return data;
}

@end
