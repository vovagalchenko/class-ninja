//
//  BaseAPIClient.m
//  ClassNinja
//
//  Created by Vova Galchenko on 7/27/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNAPIClient.h"
#import "CNAPIResource.h"
#import "NSData+CNAdditions.h"

@interface CNAPIClient()

@property (nonatomic, assign) NSUInteger numOngoingRequests;

@end

@implementation CNAPIClient

#pragma mark Misc. Helpers

static inline NSString *baseURLString()
{
    // TODO: Get this from info plist
    return @"http://vova.class-ninja.com/api";
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

- (void)list:(Class<CNModel>)model completion:(void (^)(NSArray *children, NSError *error))completionBlock
{
    [self list:model authPolicy:CNFailRequestOnAuthFailure completion:completionBlock];
}

- (void)list:(Class<CNModel>)model
  authPolicy:(CNAuthenticationPolicy)authPolicy
  completion:(void (^)(NSArray *children, NSError *error))completionBlock
{
    [self listChildrenOfAPIResource:[CNRootAPIResource rootAPIResourceForModel:model]
               authenticationPolicy:authPolicy
                         completion:completionBlock];
}

- (void)listChildren:(id<CNModel>)parentModel completion:(void (^)(NSArray *, NSError *error))completionBlock
{
    [self listChildren:parentModel authPolicy:CNFailRequestOnAuthFailure completion:completionBlock];
}

- (void)listChildren:(id<CNModel>)parentModel
          authPolicy:(CNAuthenticationPolicy)authPolicy
          completion:(void (^)(NSArray *, NSError *error))completionBlock
{
    id<CNAPIResource>apiResource = [CNAPIResourceFactory apiResourceWithModel:parentModel];
    [self listChildrenOfAPIResource:apiResource
               authenticationPolicy:authPolicy
                         completion:completionBlock];
}

- (void)listChildrenOfAPIResource:(id<CNAPIResource>)parentAPIResource
             authenticationPolicy:(CNAuthenticationPolicy)authPolicy
                       completion:(void (^)(NSArray *children, NSError *error))completionBlock
{
    NSMutableURLRequest *request = [self mutableURLRequestForAPIEndpoint:[[parentAPIResource resourceTypeName] stringByAppendingPathComponent:[parentAPIResource resourceIdentifier]]
                                                              HTTPMethod:@"GET"
                                                      HTTPBodyParameters:nil];
    [self makeURLRequest:request
  authenticationRequired:[[parentAPIResource childResourceClass] needsAuthentication]
          withAuthPolicy:authPolicy
              completion:^(NSDictionary *jsonResult, NSError *error) {
                  if (jsonResult == nil || error != nil) {
                      completionBlock(nil, error);
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
                      CNAssert(children != nil, @"api_children", @"Unable to find the childrenKey <%@> in JSON result:\n%@", childrenKey, jsonResult);
                      NSMutableArray *childObjects = [NSMutableArray arrayWithCapacity:children.count];
                      for (NSDictionary *childDict in children) {
                          [childObjects addObject:[[parentAPIResource childResourceClass] modelWithDictionary:childDict]];
                      }
                      completionBlock(childObjects, nil);
                  }
              }];
}

- (void)searchInSchool:(CNSchool *)school
          searchString:(NSString *)searchString
            completion:(void (^)(NSArray *departments, NSArray *courses, NSArray *departments_for_courses))completionBlock
{

    NSString *endpoint = [[CNRootAPIResource rootAPIResourceForModel:[school class]] resourceTypeName];
   
    NSString *escapedSearchQuery = [searchString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    NSString *requestString = [endpoint stringByAppendingPathComponent:school.schoolId];
    requestString = [requestString stringByAppendingFormat:@"?query=%@",escapedSearchQuery];
    
    NSMutableURLRequest *request = [self mutableURLRequestForAPIEndpoint:requestString
                                                              HTTPMethod:@"GET"
                                                      HTTPBodyParameters:nil];

    [self makeURLRequest:request
  authenticationRequired:NO
          withAuthPolicy:CNFailRequestOnAuthFailure
              completion:^(NSDictionary *jsonResult, NSError *error) {
                  if (jsonResult == nil || error != nil) {
                      if (completionBlock) {
                          completionBlock(nil, nil, nil);
                      }
                  } else {
                      NSArray *courses_dicts = [jsonResult objectForKey:@"searched_courses"];
                      NSArray *departments_dicts = [jsonResult objectForKey:@"searched_departments"];
                      NSArray *departments_for_courses_dicts = [jsonResult objectForKeyedSubscript:@"searched_courses_departments"];
                      
                      NSMutableArray *courses = [[NSMutableArray alloc] init];
                      for (NSDictionary *course_dict in courses_dicts) {
                          [courses addObject:[CNCourseAPIResource modelWithDictionary:course_dict]];
                      }

                      NSMutableArray *departments = [[NSMutableArray alloc] init];
                      for (NSDictionary *departments_dict in departments_dicts) {
                          [departments addObject:[CNDepartmentAPIResource modelWithDictionary:departments_dict]];
                      }
                      
                      NSMutableArray *departments_for_courses = [[NSMutableArray alloc] init];
                      for (NSDictionary *departments_dict in departments_for_courses_dicts) {
                          [departments_for_courses addObject:[CNDepartmentAPIResource modelWithDictionary:departments_dict]];
                      }
                      
                      if (completionBlock) {
                          completionBlock(departments, courses, departments_for_courses);
                      }
                  }
              }];

}

#pragma API Utilities

- (NSMutableURLRequest *)mutableURLRequestForAPIEndpoint:(NSString *)endpoint
                                              HTTPMethod:(NSString *)httpMethod
                                      HTTPBodyParameters:(NSDictionary *)httpBodyParams
{
    NSString *urlString = [baseURLString() stringByAppendingPathComponent:endpoint];
    NSURL *url = [NSURL URLWithString:urlString];

    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url
                                                              cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                          timeoutInterval:urlRequestTimeoutInterval()];
    [urlRequest setHTTPMethod:httpMethod];
    if (httpBodyParams.count) {
        NSError *err = nil;
        NSData *httpBody = [NSJSONSerialization dataWithJSONObject:httpBodyParams options:0 error:&err];
        CNAssert(err == nil, @"request_body_serialization", @"Unable to JSON serialize your http body parameters: %@", httpBodyParams);
        [urlRequest setHTTPBody:httpBody];
    }
    return urlRequest;
}

- (void)makeURLRequest:(NSMutableURLRequest *)request
authenticationRequired:(BOOL)authRequired
        withAuthPolicy:(CNAuthenticationPolicy)authPolicy
            completion:(void (^)(NSDictionary *response, NSError *error))completionBlock
{
    CNAssert(completionBlock != nil, @"api_call_completion", @"Must pass in a completion block");
    
    void (^authFailureHandler)() = nil;
    switch (authPolicy) {
        case CNForceAuthenticationOnAuthFailure:
        {
            authFailureHandler = ^{
                [self.authContext authenticateWithCompletion:^(BOOL authenticationCompleted){
                    if (authenticationCompleted) {
                        [self makeURLRequest:request
                      authenticationRequired:YES
                              withAuthPolicy:CNFailRequestOnAuthFailure
                                  completion:completionBlock];
                    } else {
                        completionBlock(nil, [NSError errorWithDomain:CN_API_CLIENT_ERROR_DOMAIN
                                                                 code:CNAPIClientErrorAuthenticationRequired
                                                             userInfo:nil]);
                    }
                }];
            };
            break;
        }
        case CNFailRequestOnAuthFailure:
        default:
        {
            authFailureHandler = ^{
                if (completionBlock) {
                    completionBlock(nil, [NSError errorWithDomain:CN_API_CLIENT_ERROR_DOMAIN
                                                             code:CNAPIClientErrorAuthenticationRequired
                                                         userInfo:nil]);
                }
            };
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
    self.numOngoingRequests++;
    
    logNetworkEvent(@"request_send",
  @{
    @"http_method" : request.HTTPMethod,
    @"request_url" : [request.URL absoluteString],
    @"request_headers" : [request allHTTPHeaderFields],
    @"request_http_body_length" : @([[request HTTPBody] length]),
    });
    NSDate *beforeSendDate = [NSDate date];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue] // Callbacks executed on the main thread
                           completionHandler:^(NSURLResponse* response, NSData* data, NSError* connectionError)
    {
        NSTimeInterval elapsedTime = [[NSDate date] timeIntervalSinceDate:beforeSendDate];
        logNetworkEvent(@"response_receipt",
        @{
          @"http_method" : request.HTTPMethod,
          @"request_url" : [request.URL absoluteString],
          @"request_headers" : [request allHTTPHeaderFields],
          @"request_http_body_length" : @([[request HTTPBody] length]),
          @"response_code" : @([(NSHTTPURLResponse *)response statusCode]),
          @"response_http_body_length" : @([data length]),
          @"connection_error" : connectionError.debugDescription ?: [NSNull null],
          @"elapsed_time" : @(elapsedTime)
        });
        self.numOngoingRequests--;
        app.networkActivityIndicatorVisible = self.numOngoingRequests > 0;
        NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
        if (connectionError || statusCode >= 400) {
            NSLog(@"Error attempting to execute: %@\n%@\n%@", response, connectionError, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        }

        NSDictionary *jsonDict = nil;
        NSError *completionError = connectionError;
        if (connectionError == nil) {
            jsonDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&completionError];
            if (completionError) {
                NSLog(@"Error attempting to deserialize response to: %@\nResponse: %@\nError: %@",
                      jsonDict, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding], completionError);
                logWarning(@"malformed_http_response",
                                @{
                                  @"http_method" : request.HTTPMethod,
                                  @"request_url" : [request.URL absoluteString],
                                  @"request_headers" : [request allHTTPHeaderFields],
                                  @"request_http_body_length" : @([[request HTTPBody] length]),
                                  @"response_code" : @([(NSHTTPURLResponse *)response statusCode]),
                                  @"response_http_body_length" : @([data length]),
                                  @"response_http_body_except" : [[[NSString alloc] initWithBytes:data.bytes length:data.length encoding:NSUTF8StringEncoding] substringToIndex:100],
                                  @"serialization_error" : completionError.debugDescription,
                                  
                                  });
            } else {
                NSNumber *credits = [jsonDict objectForKey:@"credits"];
                if (credits && self.authContext.loggedInUser) {
                    self.authContext.loggedInUser.credits = [credits unsignedIntegerValue];
                }

                if (statusCode >= 400) {
                    completionError = [[NSError alloc] initWithDomain:CN_API_CLIENT_ERROR_DOMAIN code:statusCode userInfo:nil];
                }
            }
        }
        
        
        completionBlock(jsonDict, completionError);
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
              completion:^(NSDictionary *response, NSError *error) {
                  if (successBlock) {
                      successBlock(error == nil);
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
              completion:^(NSDictionary *response, NSError *error) {
                  NSNumber *creditsLeft = [response objectForKey:@"credits"];
                  if (creditsLeft && error == nil) {
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

- (void)targetEvents:(NSArray *)events completionBlock:(void (^)(NSError *error))block
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
                   completion:^(NSDictionary *response, NSError *error) {
                       NSNumber *creditsLeft = [response objectForKey:@"credits"];
                       if (creditsLeft) {
                           NSLog(@"Targetting successful, user has %@ credits left", creditsLeft);
                           if (block) {
                               block(nil);
                           }
                       } else {
                           NSLog(@"Targetting failed with response %@, error = %@", response, error);
                           if (block) {
                               block(error);
                           }
                       }
                   }];

}

- (void)registerDeviceForPushNotifications:(NSData *)token completion:(void (^)(BOOL success))completion
{
    NSMutableURLRequest *req = [self mutableURLRequestForAPIEndpoint:@"notification_interface"
                                                          HTTPMethod:@"POST"
                                                  HTTPBodyParameters:@{
                                                                       @"kind" :
#ifdef DEBUG
                                                                           @"iOS-sandbox",
#else
                                                                           @"iOS",
#endif
                                                                       @"notification_interface_key" : [token hexString],
                                                                       @"notification_interface_name" : [[UIDevice currentDevice] name],
                                                                       }];
    [self makeURLRequest:req
  authenticationRequired:YES
          withAuthPolicy:CNForceAuthenticationOnAuthFailure
              completion:^(NSDictionary *response, NSError *error) {
                  completion(error == nil);
              }];
}

@end
