//
//  CNAPIClient.m
//  Class Ninja
//
//  Created by Boris Suvorov on 7/4/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNAPIClient.h"
#import "CNModels.h"

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
        NSMutableArray *schools = [[NSMutableArray alloc] init];
        for(NSDictionary *schoolDict in [responseObject valueForKey:@"schools"]) {
            CNSchool *school = [self createSchoolFromAPIDictionary:schoolDict];
            [schools addObject:school];
        }

        if (block) {
            block([schools copy]);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (block) {
            block(nil);
        }
    }];
}

- (CNSchool *)createSchoolFromAPIDictionary:(NSDictionary *)schoolDict
{
    CNSchool *school = [[CNSchool alloc] init];
    school.currentTermCode = [schoolDict valueForKey:@"current_term_code"];
    school.currentTermName = [schoolDict valueForKey:@"current_term_name"];
    school.schoolId = [schoolDict valueForKey:@"school_id"];
    school.name = [schoolDict valueForKey:@"school_name"];
    return school;
}
@end
