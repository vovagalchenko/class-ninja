//
//  CNAPIClient.h
//  Class Ninja
//
//  Created by Boris Suvorov on 7/4/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"

@interface CNAPIClient : AFHTTPSessionManager

+ (instancetype)sharedInstance;
- (void)listSchoolsWithCompletionBlock:(void (^)(NSArray *schools))block;

@end
