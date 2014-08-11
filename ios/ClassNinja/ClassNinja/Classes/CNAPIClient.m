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
    return [NSURL URLWithString:@"http://boris.class-ninja.com/api"];
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
    NSURL *urlWithResourceType = [baseURL() URLByAppendingPathComponent:[parentAPIResource resourceTypeName] isDirectory:YES];
    
    NSURL *finishedURL = [urlWithResourceType URLByAppendingPathComponent:[parentAPIResource resourceIdentifier]];
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:finishedURL
                            cachePolicy:NSURLRequestReloadIgnoringCacheData
                        timeoutInterval:urlRequestTimeoutInterval()];
    
    [self makeURLRequest:urlRequest
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
    
    if (authRequired) {
        if (!self.authContext.loggedInUser) {
            authFailureHandler();
            return;
        } else {
            [request setValue:self.authContext.loggedInUser.accessToken
           forHTTPHeaderField:@"AUTHORIZATION"];
        }
    }
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue] // Callbacks executed on the main thread
                           completionHandler:^(NSURLResponse* response, NSData* data, NSError* connectionError) {
        if (connectionError || [(NSHTTPURLResponse *)response statusCode] >= 400) {
            NSLog(@"Error attempting to execute: %@\n%@", response, connectionError);
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

#pragma mark Auth

@end
