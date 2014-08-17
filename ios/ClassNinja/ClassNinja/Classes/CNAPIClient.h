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

typedef enum : NSUInteger {
    CNFailRequestOnAuthFailure,
    CNForceAuthenticationOnAuthFailure,
} CNAuthenticationPolicy;

@interface CNAPIClient : NSObject

@property (nonatomic, readonly) CNAuthContext *authContext;

+ (instancetype)sharedInstance;
- (void)list:(Class<CNModel>)model completion:(void (^)(NSArray *))completionBlock;
- (void)list:(Class<CNModel>)model
  authPolicy:(CNAuthenticationPolicy)authPolicy
  completion:(void (^)(NSArray *))completionBlock;
- (void)listChildren:(id<CNModel>)parentModel completion:(void (^)(NSArray *))completionBlock;
- (void)listChildren:(id<CNModel>)parentModel
          authPolicy:(CNAuthenticationPolicy)authPolicy
          completion:(void (^)(NSArray *))completionBlock;


- (void)targetEvents:(NSArray *)events successBlock:(void (^)(BOOL success))successBlock;

- (NSMutableURLRequest *)mutableURLRequestForAPIEndpoint:(NSString *)endpoint
                                              HTTPMethod:(NSString *)httpMethod
                                      HTTPBodyParameters:(NSDictionary *)httpBodyParams;
- (void)makeURLRequest:(NSMutableURLRequest *)request
authenticationRequired:(BOOL)authRequired
        withAuthPolicy:(CNAuthenticationPolicy)authPolicy
            completion:(void (^)(id))completionBlock;

@end
