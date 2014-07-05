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

- (void)listDepartmentForSchool:(CNSchool *)school withCompletionBlock:(void (^)(NSArray *departments))block
{    
    NSString *path = [@"school" stringByAppendingPathComponent:school.schoolId];
    [self GET:path parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        NSMutableArray *departments = [[NSMutableArray alloc] init];

        for (NSDictionary *departmentDict in [responseObject valueForKey:@"school_departments"]) {
            CNDepartment *department = [self createDepartmentFromAPIDictionary:departmentDict];
            department.school = school;
            [departments addObject:department];
        }
        if (block) {
            block(departments);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (block) {
            block(nil);
        }
    }];
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

 - (CNDepartment *)createDepartmentFromAPIDictionary:(NSDictionary *)departmentDict
 {
     CNDepartment *department = [[CNDepartment alloc] init];
     department.departmentId = [departmentDict valueForKey:@"department_id"];
     department.name = [departmentDict valueForKey:@"name"];
     return department;
 }
     
- (CNSchool *)createSchoolFromAPIDictionary:(NSDictionary *)schoolDict
{
    CNSchool *school = [[CNSchool alloc] init];
    school.currentTermCode = [schoolDict valueForKey:@"current_term_code"];
    school.currentTermName = [schoolDict valueForKey:@"current_term_name"];
    school.schoolId = [NSString stringWithFormat:@"%lu", (unsigned long)[[schoolDict valueForKey:@"school_id"] unsignedIntegerValue]];
    school.name = [schoolDict valueForKey:@"school_name"];
    return school;
}
@end
