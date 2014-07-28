//
//  CoreAPIResource.m
//  ClassNinja
//
//  Created by Vova Galchenko on 7/27/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNAPIResource.h"
#import "CNModels.h"

static inline Class<CNAPIResource>resourceClassForModelClass(Class<CNModel>modelClass)
{
    NSString *modelClassName = NSStringFromClass(modelClass);
    NSString *resourceClassName = [modelClassName stringByAppendingString:@"APIResource"];
    Class<CNAPIResource> resourceClass = NSClassFromString(resourceClassName);
    NSCAssert(resourceClass != nil, @"Can't find an API resource for model: %@", modelClassName);
    return resourceClass;
}

@implementation CNAPIResourceFactory

+ (id)apiResourceWithModel:(id<CNModel>)model
{
    Class resourceClass = resourceClassForModelClass([model class]);
    id<CNAPIResource> instance = [[resourceClass alloc] init];
    instance.model = model;
    return instance;
}

@end

#pragma mark ##### SCHOOL #####

@implementation CNSchoolAPIResource

@synthesize model;

+ (id<CNModel>)modelWithDictionary:(NSDictionary *)dictionary
{
    CNSchool *school = [[CNSchool alloc] init];
    school.currentTermCode = [dictionary valueForKey:@"current_term_code"];
    school.currentTermName = [dictionary valueForKey:@"current_term_name"];
    school.schoolId = [NSString stringWithFormat:@"%lu", (unsigned long)[[dictionary valueForKey:@"school_id"] unsignedIntegerValue]];
    school.name = [dictionary valueForKey:@"school_name"];
    return school;
}

- (Class<CNAPIResource>)childResourceClass
{
    return [CNDepartmentAPIResource class];
}

- (NSString *)resourceTypeName
{
    return @"school";
}

- (NSString *)resourceIdentifier
{
    return [(CNSchool *)self.model schoolId];
}

+ (BOOL)needsAuthentication { return NO; }

@end

#pragma mark ##### DEPARTMENT #####

@implementation CNDepartmentAPIResource

@synthesize model;

+ (id<CNModel>)modelWithDictionary:(NSDictionary *)dictionary
{
    CNDepartment *department = [[CNDepartment alloc] init];
    department.departmentId = [dictionary valueForKey:@"department_id"];
    department.name = [dictionary valueForKey:@"name"];
    department.schoolId = [dictionary valueForKey:@"school_id"];
    return department;
}

- (Class<CNAPIResource>)childResourceClass
{
    return [CNCourseAPIResource class];
}

- (NSString *)resourceTypeName
{
    return @"department";
}

- (NSString *)resourceIdentifier
{
    return [(CNDepartment *)self.model departmentId];
}

+ (BOOL)needsAuthentication { return NO; }

@end

#pragma mark ##### COURSE #####

@implementation CNCourseAPIResource

@synthesize model;

+ (id<CNModel>)modelWithDictionary:(NSDictionary *)dictionary
{
    CNCourse *course = [[CNCourse alloc] init];
    course.courseId = [dictionary valueForKey:@"course_id"];
    course.name = [dictionary valueForKey:@"name"];
    course.departmentSpecificCourseId = [dictionary valueForKey:@"department_specific_course_id"];
    course.departmentId = [dictionary valueForKey:@"department_id"];
    return course;
}

- (Class<CNAPIResource>)childResourceClass
{
    return [CNSectionAPIResource class];
}

- (NSString *)resourceTypeName
{
    return @"course";
}

- (NSString *)resourceIdentifier
{
    return [(CNCourse *)self.model courseId];
}

+ (BOOL)needsAuthentication { return NO; }

@end

#pragma mark ##### SECTION #####

static inline CNEvent *createEventFromAPIDictionary(NSDictionary *eventDict)
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

@implementation CNSectionAPIResource

@synthesize model;

+ (id<CNModel>)modelWithDictionary:(NSDictionary *)dictionary
{
    CNSection *section = [[CNSection alloc] init];
    section.courseId = [dictionary valueForKey:@"course_id"];
    section.sectionid = [dictionary valueForKey:@"section_id"];
    
    section.staffName = [dictionary valueForKey:@"staff_name"];
    section.name = [dictionary valueForKey:@"section_name"];
    NSMutableArray *events = [[NSMutableArray alloc] init];
    for (NSDictionary *eventDict in [dictionary valueForKey:@"events"]) {
        CNEvent *event = createEventFromAPIDictionary(eventDict);
        [events addObject:event];
    }
    
    section.events = [NSArray arrayWithArray:events];
    
    return section;
}

- (Class<CNAPIResource>)childResourceClass
{
    NSAssert(NO, @"CNSectionAPIResource doesn't have child API resources.");
    return nil;
}

- (NSString *)resourceTypeName
{
    return @"section";
}

- (NSString *)resourceIdentifier
{
    NSAssert(NO, @"CNSectionAPIResource doesn't have child API resources.");
    return [(CNSection *)self.model sectionid];
}

+ (BOOL)needsAuthentication { return NO; }

@end

#pragma mark ##### TARGET #####

@implementation CNTargetAPIResource

@synthesize model;

+ (id<CNModel>)modelWithDictionary:(NSDictionary *)dictionary
{
    CNTarget *target = [[CNTarget alloc] init];
    target.courseId = [dictionary valueForKey:@"course_id"];
    target.name = [dictionary valueForKey:@"name"];
    target.departmentSpecificCourseId = [dictionary valueForKey:@"department_specific_course_id"];
    target.departmentId = [dictionary valueForKey:@"department_id"];
    
    NSArray *courseSectionsJson = [dictionary valueForKey:@"course_sections"];
    NSMutableArray *sections = [NSMutableArray arrayWithCapacity:courseSectionsJson.count];
    for (NSDictionary *courseSectionDict in courseSectionsJson) {
        CNSection *section = [CNSectionAPIResource modelWithDictionary:courseSectionDict];
        [sections addObject:section];
    }
    target.sections = courseSectionsJson;
    return target;
}

- (Class<CNAPIResource>)childResourceClass
{
    NSAssert(NO, @"CNTargetAPIResource doesn't have child API resources.");
    return nil;
}

- (NSString *)resourceTypeName
{
    return @"target";
}

- (NSString *)resourceIdentifier
{
    NSAssert(NO, @"CNTargetAPIResource doesn't have child API resources.");
    return [(CNEvent *)self.model eventId];
}

+ (BOOL)needsAuthentication { return YES; }

@end

#pragma mark ##### ROOT #####

@interface CNRootAPIResource()

@property (nonatomic) id<CNAPIResource> childResource;

@end

@implementation CNRootAPIResource

@synthesize model;

+ (instancetype)rootAPIResourceForModel:(Class<CNModel>)modelClass
{
    CNRootAPIResource *rootResource = [[CNRootAPIResource alloc] init];
    Class actualResourceClass = resourceClassForModelClass(modelClass);
    rootResource.childResource = [[actualResourceClass alloc] init];
    return rootResource;
}

+ (id<CNModel>)modelWithDictionary:(NSDictionary *)dictionary
{
    NSAssert(NO, @"There is no model for CNRootAPIResource");
    return nil;
}

- (Class<CNAPIResource>)childResourceClass
{
    return [self.childResource class];
}

- (NSString *)resourceTypeName
{
    return [self.childResource resourceTypeName];
}

- (NSString *)resourceIdentifier
{
    return @"";
}

+ (BOOL)needsAuthentication { return NO; }

@end
