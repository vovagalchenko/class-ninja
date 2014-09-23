//
//  CNAppDelegate.m
//  ClassNinja
//
//  Created by Boris Suvorov on 7/5/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNAppDelegate.h"
#import "CNAPIClient.h"
#import "CNInAppPurchaseHelper.h"
#import "CNWelcomeViewController.h"
#import "NSData+CNAdditions.h"

@interface CNAppDelegate ()
@property (nonatomic)CNInAppPurchaseHelper *iap;
@end

@implementation CNAppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    logAppLifecycleEvent(@"launch", nil);
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    configureStaticAppearance();
    
    CNWelcomeViewController *welcomeVC = [[CNWelcomeViewController alloc] init];
    self.window.rootViewController = welcomeVC;
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];

    return YES;
}

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

@end
