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

@property (nonatomic, readwrite) CNUser *loggedInUser;
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
    NSMutableURLRequest *request = [apiClient mutableURLRequestForAPIEndpoint:@"user" HTTPMethod:@"POST" HTTPBodyParameters:@{
                                                                                                                              @"phone" : phoneNumber,
                                                                                                                              @"device_vendor_id" : [[[UIDevice currentDevice] identifierForVendor] UUIDString]
                                                                                                                              }];
    [apiClient makeURLRequest:request
       authenticationRequired:NO
               withAuthPolicy:CNFailRequestOnAuthFailure
                   completion:^(NSDictionary *response) {
                    // Ewww
                    completionCallback([[response objectForKey:@"status"] isEqualToString:@"SMS request sent"]);
                   }];
}

- (void)authViewController:(CNAuthViewController *)authViewController
  receivedConfirmationCode:(NSString *)confirmationCode
            forPhoneNumber:(NSString *)phoneNumber
    doneProcessingCallback:(void (^)(BOOL))completionCallback
{
    CNAPIClient *apiClient = [CNAPIClient sharedInstance];
    NSMutableURLRequest *request = [apiClient mutableURLRequestForAPIEndpoint:[@"user" stringByAppendingPathComponent:phoneNumber]
                                                                   HTTPMethod:@"POST"
                                                           HTTPBodyParameters:@{
                                                                                @"confirmation_token" : confirmationCode,
                                                                                }];
    [apiClient makeURLRequest:request
       authenticationRequired:NO
               withAuthPolicy:CNFailRequestOnAuthFailure
                   completion:^(NSDictionary *response) {
                       NSString *accessToken = [response objectForKey:@"access_token"];
                       if (accessToken.length) {
                           CNUser *user = [[CNUser alloc] init];
                           user.phoneNumber = phoneNumber;
                           user.accessToken = accessToken;
                           self.loggedInUser = user;
                           completionCallback(YES);
                           if (self.authenticationCompletionBlock)
                               self.authenticationCompletionBlock(YES);
                           self.authenticationCompletionBlock = nil;
                       } else {
                           if (self.authenticationCompletionBlock)
                               self.authenticationCompletionBlock(NO);
                           completionCallback(NO);
                       }
                   }];
}

#pragma mark loggedInUser Management

@synthesize loggedInUser = _loggedInUser;

- (CNUser *)loggedInUser
{
    // Assert main thread so we don't have to worry about synchronizing this.
    NSAssert([NSThread isMainThread], @"loggedInUser is assumed to be called on the main thread.");
    if (!_loggedInUser) {
        _loggedInUser = [self retrieveLoggedInUserFromKeychain];
        [_loggedInUser addObserver:self forKeyPath:@"credits" options:NSKeyValueObservingOptionNew context:nil];
    }
    return _loggedInUser;
}

- (void)setLoggedInUser:(CNUser *)loggedInUser
{
    // Assert main thread so we don't have to worry about synchronizing this.
    NSAssert([NSThread isMainThread], @"setLoggedInUser is assumed to be called on the main thread.");
    _loggedInUser = loggedInUser;
    [self writeLoggedInUserToKeychain:loggedInUser];
    [_loggedInUser addObserver:self forKeyPath:@"credits" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.loggedInUser) {
        [self writeLoggedInUserToKeychain:object];
    }
}

static inline NSMutableDictionary *keychainSearchDictionaryForLoggedInUser()
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:(__bridge_transfer id)kSecClassGenericPassword forKey:(__bridge_transfer id)kSecClass];
    [dict setObject:[@"logged_in_user" dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge_transfer id)kSecAttrGeneric];
    return dict;
}

- (CNUser *)retrieveLoggedInUserFromKeychain
{
    CFTypeRef loggedInUser = nil;
    NSMutableDictionary *searchDict = keychainSearchDictionaryForLoggedInUser();
    [searchDict setObject:(__bridge_transfer id)kCFBooleanTrue forKey:(__bridge_transfer id)kSecReturnData];
    [searchDict setObject:(__bridge_transfer id)kSecMatchLimitOne forKey:(__bridge_transfer id)kSecMatchLimit];
    SecItemCopyMatching((__bridge CFDictionaryRef)searchDict, &loggedInUser);
    NSData *data = (__bridge_transfer NSData *)loggedInUser;
    return (data == nil)? nil : [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

- (void)writeLoggedInUserToKeychain:(CNUser *)newLoggedInUser
{
    NSMutableDictionary *keychainSearchDict = keychainSearchDictionaryForLoggedInUser();
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:newLoggedInUser];
    [keychainSearchDict setObject:data forKey:(__bridge_transfer id)kSecValueData];
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)keychainSearchDict, NULL);
    if (status == errSecDuplicateItem) {
        status = SecItemUpdate((__bridge CFDictionaryRef)keychainSearchDict,
                               (__bridge CFDictionaryRef)[NSDictionary dictionaryWithObject:data forKey:(__bridge_transfer id)kSecValueData]);
    }
    NSAssert(status == errSecSuccess, @"Error writing to keychain.");
}

- (void)dealloc
{
    [_loggedInUser removeObserver:self forKeyPath:@"credits"];
}

@end
