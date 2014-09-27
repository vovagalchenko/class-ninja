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

#define CN_API_CLIENT_ERROR_DOMAIN @"API_CLIENT_ERROR_DOMAIN"

typedef enum NSUInteger {
    CNAPIClientErrorPaymentRequired = 402,
    CNAPIClientErrorAuthenticationRequired = 401
} CNAPIClientErrors;

typedef enum : NSUInteger {
    CNFailRequestOnAuthFailure,
    CNForceAuthenticationOnAuthFailure,
} CNAuthenticationPolicy;

@interface CNAPIClient : NSObject

@property (nonatomic, readonly) CNAuthContext *authContext;

+ (instancetype)sharedInstance;
- (void)list:(Class<CNModel>)model completion:(void (^)(NSArray *children, NSError *error))completionBlock;
- (void)listChildren:(id<CNModel>)parentModel
          completion:(void (^)(NSArray *, NSError *error))completionBlock;
- (void)list:(Class<CNModel>)model
  authPolicy:(CNAuthenticationPolicy)authPolicy
  completion:(void (^)(NSArray *children, NSError *error))completionBlock;

- (void)searchInSchool:(CNSchool *)school
          searchString:(NSString *)string
            completion:(void (^)(NSArray *departments, NSArray *courses, NSArray *departments_for_courses))completionBlock;

- (void)verify:(NSData *)receipt successBlock:(void (^)(BOOL success))successBlock;
- (void)targetEvents:(NSArray *)events completionBlock:(void (^)(NSError *error))block;
- (void)removeEventFromTargetting:(CNEvent *)event successBlock:(void (^)(BOOL success))successBlock;

- (void)registerDeviceForPushNotifications:(NSData *)token completion:(void (^)(BOOL success))completion;

- (NSMutableURLRequest *)mutableURLRequestForAPIEndpoint:(NSString *)endpoint
                                              HTTPMethod:(NSString *)httpMethod
                                      HTTPBodyParameters:(NSDictionary *)httpBodyParams;
- (void)makeURLRequest:(NSMutableURLRequest *)request
authenticationRequired:(BOOL)authRequired
        withAuthPolicy:(CNAuthenticationPolicy)authPolicy
            completion:(void (^)(NSDictionary *response, NSError *error))completionBlock;

@end
