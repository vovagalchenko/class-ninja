//
//  CNAuthContext.m
//  ClassNinja
//
//  Created by Vova Galchenko on 7/29/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNAuthContext.h"
#import "CNAppDelegate.h"
#import "CNAPIClient.h"

@interface CNAuthContext()

@property (nonatomic, copy) void (^authenticationCompletionBlock)(BOOL);

@end

@implementation CNAuthContext

- (instancetype)init
{
    if (self = [super init]) {
        // Clear the logged in user out of the keychain in case of a reinstall
        if (![[NSUserDefaults standardUserDefaults] objectForKey:@"FirstRun"]) {
            self.loggedInUser = nil;
            [[NSUserDefaults standardUserDefaults] setValue:@"1strun" forKey:@"FirstRun"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
    return self;
}

#pragma mark Authentication

- (void)authenticateWithCompletion:(void (^)(BOOL))completionBlock
{
    UIViewController *topController = APP_DELEGATE.window.rootViewController;
    
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    self.authenticationCompletionBlock = ^(BOOL succeeded){
        [topController dismissViewControllerAnimated:YES completion:^{
            completionBlock(succeeded);
        }];
    };
    
    CNAuthViewController *authVC = [[CNAuthViewController alloc] initWithDelegate:self];
    
    [topController presentViewController:authVC animated:YES completion:nil];
}

- (void)authViewControllerCancelledAuthentication:(CNAuthViewController *)authViewController
{
    if (self.authenticationCompletionBlock) {
        self.authenticationCompletionBlock(NO);
        self.authenticationCompletionBlock = nil;
    }
}

- (void)authViewController:(CNAuthViewController *)authViewController
   receivedUserPhoneNumber:(NSString *)phoneNumber
    doneProcessingCallback:(void (^)(BOOL))completionCallback
{
    CNAPIClient *apiClient = [CNAPIClient sharedInstance];
    NSString *deviceVendorID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    NSMutableURLRequest *request = [apiClient mutableURLRequestForAPIEndpoint:@"user"
                                                                   HTTPMethod:@"POST"
                                                           HTTPBodyParameters:@{@"phone" : phoneNumber,
                                                                                @"device_vendor_id" : deviceVendorID
                                                                                }];
    [apiClient makeURLRequest:request
       authenticationRequired:NO
               withAuthPolicy:CNFailRequestOnAuthFailure
                   completion:^(NSDictionary *response, NSError *error) {
                    completionCallback([[response objectForKey:@"status"] isEqualToString:@"SMS request sent"]);
                   }];
}

- (BOOL)isGoingThroughReferral
{
    return self.referredBy != nil;
}

- (void)authViewController:(CNAuthViewController *)authViewController
  receivedConfirmationCode:(NSString *)confirmationCode
            forPhoneNumber:(NSString *)phoneNumber
    doneProcessingCallback:(void (^)(BOOL))completionCallback
{
    CNAPIClient *apiClient = [CNAPIClient sharedInstance];
    

    NSMutableDictionary *bodyParams = [NSMutableDictionary dictionaryWithObject:confirmationCode forKey:@"confirmation_token"];
    // setValue is failsafe when self.referredBy is nil
    [bodyParams setValue:self.referredBy forKey:@"referred_by"];
    
    NSMutableURLRequest *request = [apiClient mutableURLRequestForAPIEndpoint:[@"user" stringByAppendingPathComponent:phoneNumber]
                                                                   HTTPMethod:@"POST"
                                                           HTTPBodyParameters:bodyParams];
    [apiClient makeURLRequest:request
       authenticationRequired:NO
               withAuthPolicy:CNFailRequestOnAuthFailure
                   completion:^(NSDictionary *response, NSError *error) {
                       NSString *accessToken = [response objectForKey:@"access_token"];
                       if (accessToken.length && error == nil) {
                           CNUser *user = [[CNUser alloc] init];
                           user.phoneNumber = phoneNumber;
                           user.accessToken = accessToken;
                           self.loggedInUser = user;
                           completionCallback(YES);
                           if (self.authenticationCompletionBlock) {
                               self.authenticationCompletionBlock(YES);
                           }
                           self.authenticationCompletionBlock = nil;
                       } else {
                           completionCallback(NO);
                       }
                   }];
}

#pragma mark loggedInUser Management

@synthesize loggedInUser = _loggedInUser;

- (void)logUserOut
{
    @synchronized(self) {
        _loggedInUser = nil;
        [CNUser deleteUserEntryFromKeychain];
    }
}

- (CNUser *)loggedInUser
{
    @synchronized(self) {
        if (!_loggedInUser) {
            _loggedInUser = [CNUser retrieveLoggedInUserFromKeychain];
        }
    }
    return _loggedInUser;
}

- (void)setLoggedInUser:(CNUser *)loggedInUser
{
    @synchronized(self) {
        _loggedInUser = loggedInUser;
        [CNUser writeLoggedInUserToKeychain:loggedInUser];
    }
}

- (void)setCreditsForLoggedInUser:(NSUInteger)credits
{
    @synchronized(self) {
        self.loggedInUser.credits = credits;
        [CNUser writeLoggedInUserToKeychain:self.loggedInUser];
    }
}

-(void)setDidPostOnFbForLoggedInUser:(BOOL)didPostOnFb
{
    @synchronized(self) {
        self.loggedInUser.didPostOnFb = didPostOnFb;
        [CNUser writeLoggedInUserToKeychain:self.loggedInUser];
    }
}

-(void)setDidPostOnTwitterForLoggedInUser:(BOOL)didPostOnTwitter
{
    @synchronized(self) {
        self.loggedInUser.didPostOnTwitter = didPostOnTwitter;
        [CNUser writeLoggedInUserToKeychain:self.loggedInUser];
    }
}



@end
