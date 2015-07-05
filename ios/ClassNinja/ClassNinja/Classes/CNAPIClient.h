//
//  BaseAPIClient.h
//  ClassNinja
//
//  Created by Vova Galchenko on 7/27/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CNAuthContext.h"
#import "CNModels.h"

#import "CNSalesPitch.h"

#define CN_API_CLIENT_ERROR_DOMAIN @"API_CLIENT_ERROR_DOMAIN"

typedef enum NSUInteger {
    CNAPIClientErrorPaymentRequired = 402,
    CNAPIClientErrorAuthenticationRequired = 401
} CNAPIClientErrors;

typedef enum : NSUInteger {
    CNAPIClientInAppPurchaseReceiptStatusPassed = 200,
    CNAPIClientInAppPurchaseReceiptStatusFailed = 400,
    CNAPIClientInAppPurchaseReceiptStatusNone = 0,
} CNAPIClientInAppPurchaseReceiptStatus;

typedef enum : NSUInteger {
    CNAPIClientSharedOnNone,
    CNAPIClientSharedOnFb,
    CNAPIClientSharedOnTwitter,
} CNAPIClientSharedStatus;

typedef enum : NSUInteger {
    CNFailRequestOnAuthFailure,
    CNForceAuthenticationOnAuthFailure,
} CNAuthenticationPolicy;

@interface CNAPIClient : NSObject

@property (nonatomic, readonly) CNAuthContext *authContext;

+ (instancetype)sharedInstance;

- (void)authenticateUserReferredBy:(NSString *)referredBy
                    withCompletion:(void (^)(BOOL authenticationCompleted))completionBlock;
- (void)list:(Class<CNModel>)model completion:(void (^)(NSArray *children, NSError *error))completionBlock;
- (void)listChildren:(id<CNModel>)parentModel
          completion:(void (^)(NSArray *, NSError *error))completionBlock;
- (void)list:(Class<CNModel>)model
  authPolicy:(CNAuthenticationPolicy)authPolicy
  completion:(void (^)(NSArray *children, NSError *error))completionBlock;

- (void)searchInSchool:(CNSchool *)school
          searchString:(NSString *)string
            completion:(void (^)(NSArray *departments, NSArray *courses, NSArray *departments_for_courses))completionBlock;


- (void)creditUserForSharing:(CNAPIClientSharedStatus)sharedStatus completion:(void (^)(BOOL didSucceed))completion;

- (void)verifyPurchaseOfProduct:(NSString *)productId withReceipt:(NSData *)receipt completion:(void (^)(CNAPIClientInAppPurchaseReceiptStatus receiptStatus))completion;
- (void)targetEvents:(NSArray *)events completionBlock:(void (^)(NSDictionary *userAlert, NSError *error))block;
- (void)removeEventFromTargetting:(CNEvent *)event successBlock:(void (^)(BOOL success))successBlock;

- (void)registerDeviceForPushNotifications:(NSData *)token completion:(void (^)(BOOL success))completion;

- (void)fetchSalesPitch:(void (^)(CNSalesPitch *salesPitch))completion;
- (void)fetchAuthPitch:(void (^)(NSString *authPitch))completion;

- (NSMutableURLRequest *)mutableURLRequestForAPIEndpoint:(NSString *)endpoint
                                              HTTPMethod:(NSString *)httpMethod
                                      HTTPBodyParameters:(NSDictionary *)httpBodyParams;
- (void)makeURLRequest:(NSMutableURLRequest *)request
authenticationRequired:(BOOL)authRequired
        withAuthPolicy:(CNAuthenticationPolicy)authPolicy
            completion:(void (^)(NSDictionary *response, NSError *error))completionBlock;

@end
