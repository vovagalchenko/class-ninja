//
//  CNAPIClient.m
//  Class Ninja
//
//  Created by Boris Suvorov on 7/4/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNAPIClient.h"

@interface CNAPIClient()
@end

@implementation CNAPIClient

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static CNAPIClient *sharedAPIClient = nil;
    dispatch_once(&onceToken, ^{
        sharedAPIClient = [[CNAPIClient alloc] init];
    });
    
    return sharedAPIClient;
}

- (instancetype)init
{
    NSURL *baseURL = [NSURL URLWithString:@"http://boris.class-ninja.com/api"];
    self = [super initWithBaseURL:baseURL sessionConfiguration:nil];;
    return self;
}

- (void)listSchoolsWithCompletionBlock:(void (^)(NSArray *schools))block
{
    [self GET:@"school" parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        NSLog(@"JSON: %@", responseObject);        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"Error: %@", error);        
    }];
}

@end
