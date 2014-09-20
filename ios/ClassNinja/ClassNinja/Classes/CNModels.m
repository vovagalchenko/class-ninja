//
//  CNModels.m
//  Class Ninja
//
//  Created by Boris Suvorov on 7/4/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNModels.h"
@implementation CNSchool

- (NSString *)description
{
    return [NSString stringWithFormat:@"School %@, id = %@, term code = %@, term name = %@", self.name, self.schoolId, self.currentTermCode, self.currentTermName];
    
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[self class]]) {
        CNSchool *rightSchool = (CNSchool *)object;
        return [self.schoolId isEqualToString:rightSchool.schoolId] && [self.name isEqualToString:rightSchool.name];
    }
    return NO;
}
@end

@implementation CNDepartment
- (NSString *)description
{
    return [NSString stringWithFormat:@"Department %@, id = %@, school id = %@", self.name, self.departmentId, self.schoolId];
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[self class]]) {
        CNDepartment *rightDepartment = (CNDepartment *)object;
        return  [self.schoolId isEqualToString:rightDepartment.schoolId] &&
                [self.departmentId isEqualToString:rightDepartment.departmentId] &&
                [self.name isEqualToString:rightDepartment.name];
    }
    return NO;
}


@end

@implementation CNCourse
- (NSString *)description
{
    return [NSString stringWithFormat:@"Course %@, id = %@,  dept spec course id = %@, deptId = %@, ", self.name, self.courseId, self.departmentSpecificCourseId, self.departmentId];
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[self class]]) {
        CNCourse *rightCourse = (CNCourse *)object;
        return  [self.courseId isEqualToString:rightCourse.courseId] &&
                [self.departmentSpecificCourseId isEqualToString:rightCourse.departmentSpecificCourseId] &&
                [self.departmentId isEqualToString:rightCourse.departmentId] &&
                [self.name isEqualToString:rightCourse.name];
    }
    return NO;
}
@end

@implementation CNTargetedCourse

- (NSString *)description
{
    return [NSString stringWithFormat:@"Target %@, id = %@,  dept spec course id = %@, deptId = %@, ", self.name, self.courseId, self.departmentSpecificCourseId, self.departmentId];
}

@end

@implementation CNSection
- (NSString *)description
{
    return [NSString stringWithFormat:@"Section %@, id = %@, staff name = %@, course id = %@\n\nlist of events = %@", self.name, self.sectionid, self.staffName, self.courseId, self.events];
}

- (BOOL)isEqual:(id)object
{
    BOOL retVal = NO;
    if ([object isKindOfClass:[self class]]) {
        CNSection *properSection = (CNSection *)object;
        retVal = [self.sectionid isEqualToString:properSection.sectionid] &&
                 [self.staffName isEqualToString:properSection.staffName] &&
                 [self.name isEqualToString:properSection.name];
    }
    return retVal;
}

@end

@implementation CNScheduleSlot

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ at %@ in %@", [self daysOfWeek], [self hours], [self location]];
}


- (NSString *)daysOfWeek
{
    return [self.timesAndLocations objectForKey:@"weekdays"];
}

- (NSString *)hours
{
    return [self.timesAndLocations objectForKey:@"timeInterval"];
}

- (NSString *)location
{
    return [self.timesAndLocations objectForKey:@"location"];
}

@end

@implementation CNEvent
- (NSString *)description
{
    return [NSString stringWithFormat:@"Event id %@, targetId = %@, type = %@, times / location = %@, status = %@, waitlisted = %@, enrolled = %@, waitlist capacity = %@", self.eventId, self.targetId, self.eventType, self.scheduleSlots, self.status, self.numberWaitlisted, self.numberEnrolled, self.waitlistCapacity];
}

- (NSString *)name
{
    return [NSString stringWithFormat:@"%@ %@ %@", self.eventType, self.scheduleSlots, self.status];
}

- (BOOL)isClosed
{
    return [self.status isEqual:@"Closed"];
}

- (BOOL)isOpened
{
    return [self.status isEqual:@"Open"];
}

- (BOOL)isCancelled
{
    return [self.status isEqualToString:@"Cancelled"];
}

- (BOOL)isWaitlisted
{
    return [self.status isEqualToString:@"W-List"];
}

- (NSString *)eventSectionId
{
    NSString *result = nil;
    NSArray *typeAndSectionID = [self.eventType componentsSeparatedByString:@" "];
    if (typeAndSectionID.count > 1) {
        result = [typeAndSectionID objectAtIndex:1];
    }
    return result;
}

- (NSString *)eventSectionType
{
    NSArray *typeAndSectionID = [self.eventType componentsSeparatedByString:@" "];
    return [typeAndSectionID firstObject];
}

- (BOOL)isEqual:(id)object
{
    BOOL retVal = NO;
    if ([object isKindOfClass:[self class]]) {
        CNEvent *properEvent = (CNEvent *)object;
        retVal = [self.name isEqualToString:properEvent.name];
    }
    return retVal;
}


@end

@implementation CNUser

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        _phoneNumber = [aDecoder decodeObjectForKey:@"phoneNumber"];
        _accessToken = [aDecoder decodeObjectForKey:@"accessToken"];
        _credits = [[aDecoder decodeObjectForKey:@"credits"] unsignedIntegerValue];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.phoneNumber forKey:@"phoneNumber"];
    [aCoder encodeObject:self.accessToken forKey:@"accessToken"];
    [aCoder encodeObject:@(self.credits) forKey:@"credits"];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"User phoneNumber %@, accessToken = %@, credits = %lu", self.phoneNumber, self.accessToken, (unsigned long)self.credits];
}

- (NSString *)name
{
    return [NSString stringWithFormat:@"%@", self.phoneNumber];
}

@end

