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

@interface CNAppDelegate ()
@property (nonatomic)CNInAppPurchaseHelper *iap;
@end

@implementation CNAppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
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
    else
        [[[UIAlertView alloc] initWithTitle:@"Warning"
                                    message:@"The app has limited utility if you don't let us notify you of when classes become available. If you change your mind, make the appropriate change in your settings."
                                   delegate:nil
                          cancelButtonTitle:@"OK" otherButtonTitles:nil] show];

}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *knownTokensCache = [userDefaults objectForKey:PUSH_NOTIFICATION_KNOWN_TOKENS_USER_DEFAULTS_KEY];
    CNAPIClient *apiClient = [CNAPIClient sharedInstance];
    NSString *currentUserPhoneNumber = [[[apiClient authContext] loggedInUser] phoneNumber];
    NSArray *knownTokensForUser = [knownTokensCache objectForKey:currentUserPhoneNumber];
    if (![knownTokensForUser containsObject:deviceToken]) {
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
    NSLog(@"%@", error);
}


- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
