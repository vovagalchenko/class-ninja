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
    [self setRequestSerializer:[[AFJSONRequestSerializer alloc] init]];
    
    return self;
}

- (void)requestPhoneNumberVerification:(NSString *)phoneNumber withVendorId:(NSString *)deviceVendorId completionBlock:(void (^)(BOOL success))block
{
    // phone number must be set for us to attempt registration
    if (phoneNumber == nil) {
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(NO);
            });
        }
    }

    NSString *path = @"user";
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:phoneNumber,@"phone", nil];
    // user might or might not set device ID to notify him of push notificaitons.
    if (deviceVendorId) {
        [parameters setObject:deviceVendorId forKey:@"device_vendor_id"];
    }

    [self POST:path
    parameters:parameters
       success:^(NSURLSessionDataTask *task, id responseObject) {
           NSLog(@"Received request and will send SMS");
           if (block) {
               dispatch_async(dispatch_get_main_queue(), ^{
                   block(YES);
               });
           }
       }
       failure:^(NSURLSessionDataTask *task, NSError *error) {
           NSLog(@"Failed to process request with error %@", error);
           if (block) {
               dispatch_async(dispatch_get_main_queue(), ^{
                   block(NO);
               });
           }
       }];
}

- (void)exchangeConfirmationCodeInAuthCode:(NSString *)confirmationToken forPhoneNumber:(NSString *)phoneNumber completionBlock:(void (^)(NSString *accessToken))block
{
    // phone number must be set for us to attempt registration
    if (phoneNumber == nil || confirmationToken == nil) {
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(nil);
            });
        }
    }
    
    NSString *path = [@"user" stringByAppendingPathComponent:phoneNumber];
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:confirmationToken,@"confirmation_token", nil];

    [self POST:path parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        NSString *accessToken = [responseObject valueForKey:@"access_token"];
        NSLog(@"We're given authorization token %@", accessToken);
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(accessToken);
            });
        }

    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"Failed with error %@", error);
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(nil);
            });
        }

    }];
}

- (void)listSectionsInfoForCourse:(CNCourse *)course  withCompletionBlock:(void (^)(NSArray *sectionInfo))block
{
    NSString *path = [@"course" stringByAppendingPathComponent:course.courseId];
    [self GET:path parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        NSMutableArray *sections = [[NSMutableArray alloc] init];
        
        for (NSDictionary *sectionDict in [responseObject valueForKey:@"course_sections"]) {
            CNSection *section = [self createSectionFromAPIDictionary:sectionDict];
            [sections addObject:section];
        }
        
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block([sections copy]);
            });
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(nil);
            });
        }
    }];

    
}

- (void)listCoursesForDepartment:(CNDepartment *)department withCompletionBlock:(void (^)(NSArray *courses))block
{
    NSString *path = [@"department" stringByAppendingPathComponent:department.departmentId];
    [self GET:path parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        NSMutableArray *courses = [[NSMutableArray alloc] init];
        
        for (NSDictionary *courseDict in [responseObject valueForKey:@"department_courses"]) {
            CNCourse *course = [self createCourseFromAPIDictionary:courseDict];
            [courses addObject:course];
        }
        
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block([courses copy]);
            });
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(nil);
            });
        }
    }];
}

- (void)listDepartmentForSchool:(CNSchool *)school withCompletionBlock:(void (^)(NSArray *departments))block
{    
    NSString *path = [@"school" stringByAppendingPathComponent:school.schoolId];
    [self GET:path parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        NSMutableArray *departments = [[NSMutableArray alloc] init];

        for (NSDictionary *departmentDict in [responseObject valueForKey:@"school_departments"]) {
            CNDepartment *department = [self createDepartmentFromAPIDictionary:departmentDict];
            [departments addObject:department];
        }
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block([departments copy]);
            });
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(nil);
            });
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
            dispatch_async(dispatch_get_main_queue(), ^{
                block([schools copy]);
            });
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(nil);
            });
        }
    }];
}


- (CNEvent *)createEventFromAPIDictionary:(NSDictionary *)eventDict
{
    CNEvent *event = [[CNEvent alloc] init];
    event.sectionId = [eventDict valueForKey:@"section_id"];
    event.eventId = [eventDict valueForKey:@"event_id"];
    event.status = [eventDict valueForKey:@"status"];
    event.eventType = [eventDict valueForKey:@"event_type"];
    event.schoolSpecificEventId = [eventDict valueForKey:@"school_specific_event_id"];
    event.timesAndLocations = [eventDict valueForKey:@"times_and_locations"];
    event.enrollmentCap = [NSNumber numberWithUnsignedInteger:[[eventDict valueForKey:@"enrollment_cap"] unsignedIntegerValue]];
    event.numberWaitlisted = [NSNumber numberWithUnsignedInteger:[[eventDict valueForKey:@"number_waitlisted"] unsignedIntegerValue]];
    event.numberEnrolled = [NSNumber numberWithUnsignedInteger:[[eventDict valueForKey:@"number_enrolled"] unsignedIntegerValue]];
    event.waitlistCapacity = [NSNumber numberWithUnsignedInteger:[[eventDict valueForKey:@"waitlist_capacity"] unsignedIntegerValue]];
    return event;
}


- (CNSection *)createSectionFromAPIDictionary:(NSDictionary *)sectionDict
{
    CNSection *section = [[CNSection alloc] init];
    section.courseId = [sectionDict valueForKey:@"course_id"];
    section.sectionid = [sectionDict valueForKey:@"section_id"];

    section.staffName = [sectionDict valueForKey:@"staff_name"];
    section.name = [sectionDict valueForKey:@"section_name"];
    NSMutableArray *events = [[NSMutableArray alloc] init];
    for (NSDictionary *eventDict in [sectionDict valueForKey:@"events"]) {
        CNEvent *event = [self createEventFromAPIDictionary:eventDict];
        [events addObject:event];
    }

    section.events = [events copy];
    
    return section;
}

- (CNCourse *)createCourseFromAPIDictionary:(NSDictionary *)coursesDict
{
    CNCourse *course = [[CNCourse alloc] init];
    
    course.courseId = [coursesDict valueForKey:@"course_id"];
    course.name = [coursesDict valueForKey:@"name"];
    course.departmentSpecificCourseId = [coursesDict valueForKey:@"department_specific_course_id"];

    return course;
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
