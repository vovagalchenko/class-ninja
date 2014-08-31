//
//  BaseAPIClient.m
//  ClassNinja
//
//  Created by Vova Galchenko on 7/27/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNAPIClient.h"
#import "CNAPIResource.h"

@implementation CNAPIClient

#pragma mark Misc. Helpers

static inline NSURL *baseURL()
{
    // TODO: Get this from info plist
    return [NSURL URLWithString:@"http://vova.class-ninja.com/api"];
}

static inline NSTimeInterval urlRequestTimeoutInterval()
{
    return 10.0;
}

#pragma mark Object Lifecycle

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static CNAPIClient *sharedAPIClient = nil;
    dispatch_once(&onceToken, ^{
        sharedAPIClient = [[CNAPIClient alloc] init];
    });
    return sharedAPIClient;
}

- (id)init
{
    if (self = [super init]) {
        _authContext = [[CNAuthContext alloc] init];
    }
    return self;
}

#pragma mark API Implementation

- (void)list:(Class<CNModel>)model completion:(void (^)(NSArray *))completionBlock
{
    [self list:model authPolicy:CNFailRequestOnAuthFailure completion:completionBlock];
}

- (void)list:(Class<CNModel>)model authPolicy:(CNAuthenticationPolicy)authPolicy completion:(void (^)(NSArray *))completionBlock
{
    [self listChildrenOfAPIResource:[CNRootAPIResource rootAPIResourceForModel:model]
               authenticationPolicy:authPolicy
                         completion:completionBlock];
}

- (void)listChildren:(id<CNModel>)parentModel completion:(void (^)(NSArray *))completionBlock
{
    [self listChildren:parentModel authPolicy:CNFailRequestOnAuthFailure completion:completionBlock];
}

- (void)listChildren:(id<CNModel>)parentModel
          authPolicy:(CNAuthenticationPolicy)authPolicy
          completion:(void (^)(NSArray *))completionBlock
{
    id<CNAPIResource>apiResource = [CNAPIResourceFactory apiResourceWithModel:parentModel];
    [self listChildrenOfAPIResource:apiResource
               authenticationPolicy:authPolicy
                         completion:completionBlock];
}

- (void)listChildrenOfAPIResource:(id<CNAPIResource>)parentAPIResource
             authenticationPolicy:(CNAuthenticationPolicy)authPolicy
                       completion:(void (^)(NSArray *))completionBlock
{
    NSMutableURLRequest *request = [self mutableURLRequestForAPIEndpoint:[[parentAPIResource resourceTypeName] stringByAppendingPathComponent:[parentAPIResource resourceIdentifier]]
                                                              HTTPMethod:@"GET"
                                                      HTTPBodyParameters:nil];
    [self makeURLRequest:request
  authenticationRequired:[[parentAPIResource childResourceClass] needsAuthentication]
          withAuthPolicy:authPolicy
              completion:^(NSDictionary *jsonResult) {
                  if (jsonResult == nil) {
                      completionBlock(nil);
                  } else {
                      NSString *childrenKey = nil;
                      if ([parentAPIResource isKindOfClass:[CNRootAPIResource class]]) {
                          childrenKey = [[parentAPIResource resourceTypeName] stringByAppendingString:@"s"];
                      } else {
                          id<CNAPIResource>childAPIResourceInstance = [[(Class)[parentAPIResource childResourceClass] alloc] init];
                          childrenKey = [NSString stringWithFormat:@"%@_%@s",
                                         [parentAPIResource resourceTypeName], [childAPIResourceInstance resourceTypeName]];
                      }
                      NSArray *children = [jsonResult objectForKey:childrenKey];
                      NSAssert(children != nil, @"Unable to find the childrenKey <%@> in JSON result:\n%@", childrenKey, jsonResult);
                      NSMutableArray *childObjects = [NSMutableArray arrayWithCapacity:children.count];
                      for (NSDictionary *childDict in children) {
                          [childObjects addObject:[[parentAPIResource childResourceClass] modelWithDictionary:childDict]];
                      }
                      completionBlock(childObjects);
                  }
              }];
}

#pragma API Utilities

- (NSMutableURLRequest *)mutableURLRequestForAPIEndpoint:(NSString *)endpoint
                                              HTTPMethod:(NSString *)httpMethod
                                      HTTPBodyParameters:(NSDictionary *)httpBodyParams
{
    NSURL *url = [baseURL() URLByAppendingPathComponent:endpoint];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url
                                                              cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                          timeoutInterval:urlRequestTimeoutInterval()];
    [urlRequest setHTTPMethod:httpMethod];
    if (httpBodyParams.count) {
        NSError *err = nil;
        NSData *httpBody = [NSJSONSerialization dataWithJSONObject:httpBodyParams options:0 error:&err];
        NSAssert(err == nil, @"Unable to JSON serialize your http body parameters: %@", httpBodyParams);
        [urlRequest setHTTPBody:httpBody];
    }
    return urlRequest;
}

- (void)makeURLRequest:(NSMutableURLRequest *)request
authenticationRequired:(BOOL)authRequired
        withAuthPolicy:(CNAuthenticationPolicy)authPolicy
            completion:(void (^)(id))completionBlock
{
    NSAssert(completionBlock != nil, @"Must pass in a completion block");
    
    void (^authFailureHandler)() = nil;
    switch (authPolicy) {
        case CNForceAuthenticationOnAuthFailure:
        {
            authFailureHandler = ^{
                [self.authContext authenticateWithCompletion:^{
                    [self makeURLRequest:request
                  authenticationRequired:YES
                          withAuthPolicy:CNFailRequestOnAuthFailure
                              completion:completionBlock];
                }];
            };
            break;
        }
        case CNFailRequestOnAuthFailure:
        default:
        {
            authFailureHandler = ^{ completionBlock(nil); };
            break;
        }
    }
    
    if (authRequired && !self.authContext.loggedInUser) {
        authFailureHandler();
        return;
    } else if (self.authContext.loggedInUser) {
        [request setValue:self.authContext.loggedInUser.accessToken
       forHTTPHeaderField:@"AUTHORIZATION"];
    }
    
    UIApplication* app = [UIApplication sharedApplication];
    app.networkActivityIndicatorVisible = YES;
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue] // Callbacks executed on the main thread
                           completionHandler:^(NSURLResponse* response, NSData* data, NSError* connectionError) {
        app.networkActivityIndicatorVisible = NO;
        if (connectionError || [(NSHTTPURLResponse *)response statusCode] >= 400) {
            NSLog(@"Error attempting to execute: %@\n%@\n%@", response, connectionError, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            completionBlock(nil);
        } else {
            NSError *serializationError = nil;
            NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&serializationError];
            if (serializationError) {
                NSLog(@"Error attempting to deserialize response to: %@\nResponse: %@\nError: %@",
                      jsonDict, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding], serializationError);
                completionBlock(nil);
            } else {
                completionBlock(jsonDict);
            }
        }
    }];
}

#pragma mark targets
- (void)removeEventFromTargetting:(CNEvent *)event successBlock:(void (^)(BOOL success))successBlock
{
    NSString *targetId = event.targetId;
    if (targetId == nil) {
        return;
    }
    
    NSString *urlString = [@"target" stringByAppendingPathComponent:event.targetId];
    NSMutableURLRequest *request = [self mutableURLRequestForAPIEndpoint:urlString
                                                              HTTPMethod:@"DELETE"
                                                      HTTPBodyParameters:nil];
    
    [self makeURLRequest:request
  authenticationRequired:YES
          withAuthPolicy:CNForceAuthenticationOnAuthFailure
              completion:^(NSDictionary *response) {
                  if (successBlock) {
                      successBlock(response != nil);
                  }
              }];
    
}

- (void)verify:(NSData *)receipt successBlock:(void (^)(BOOL success))successBlock
{
    NSString *receiptString = [receipt base64EncodedStringWithOptions:0];
    NSMutableURLRequest *request = [self mutableURLRequestForAPIEndpoint:@"ios_payment"
                                                              HTTPMethod:@"POST"
                                                      HTTPBodyParameters:@{
                                                                           @"receipt_data" : receiptString,
                                                                           }];
    [self makeURLRequest:request
  authenticationRequired:YES
          withAuthPolicy:CNForceAuthenticationOnAuthFailure
              completion:^(NSDictionary *response) {
                  NSNumber *creditsLeft = [response objectForKey:@"credits"];
                  if (creditsLeft) {
                      NSLog(@"IAP receipt verification succeeded. User has %@ credits left", creditsLeft);
                      if (successBlock) {
                          successBlock(YES);
                      }
                  } else {
                      NSLog(@"IAP receipt verification failed with response %@", response);
                      if (successBlock) {
                          successBlock(NO);
                      }
                  }
              }];

}

- (void)targetEvents:(NSArray *)events successBlock:(void (^)(BOOL success))successBlock
{
    NSMutableArray *event_ids = [[NSMutableArray alloc] initWithCapacity:events.count];
    for (CNEvent *event in events) {
        [event_ids addObject:event.eventId];
    }
    
    NSMutableURLRequest *request = [self mutableURLRequestForAPIEndpoint:@"target"
                                                              HTTPMethod:@"POST"
                                                      HTTPBodyParameters:@{
                                                                           @"event_ids" : event_ids,
                                                                           }];
    [self makeURLRequest:request
       authenticationRequired:YES
               withAuthPolicy:CNForceAuthenticationOnAuthFailure
                   completion:^(NSDictionary *response) {
                       NSNumber *creditsLeft = [response objectForKey:@"credits"];
                       if (creditsLeft) {
                           NSLog(@"Targetting successful, user has %@ credits left", creditsLeft);
                           if (successBlock) {
                               successBlock(YES);
                           }
                       } else {
                           NSLog(@"Targetting failed with response %@", response);
                           if (successBlock) {
                               successBlock(NO);
                           }
                       }
                   }];

}

- (void)registerDeviceForPushNotifications:(NSData *)token completion:(void (^)(BOOL success))completion
{
    NSMutableString *tokenString = [NSMutableString stringWithCapacity:token.length*2];
    const unsigned char *bytes = token.bytes;
    for (int i = 0; i < token.length; i++) {
        [tokenString appendFormat:@"%02x", bytes[i]];
    }
    NSMutableURLRequest *req = [self mutableURLRequestForAPIEndpoint:@"notification_interface"
                                                          HTTPMethod:@"POST"
                                                  HTTPBodyParameters:@{
                                                                       @"kind" : @"iOS",
                                                                       @"notification_interface_key" : tokenString,
                                                                       @"notification_interface_name" : [[UIDevice currentDevice] name],
                                                                       }];
    [self makeURLRequest:req
  authenticationRequired:YES
          withAuthPolicy:CNForceAuthenticationOnAuthFailure
              completion:^(NSDictionary *response) {
                  completion(response != nil);
              }];
}

@end
