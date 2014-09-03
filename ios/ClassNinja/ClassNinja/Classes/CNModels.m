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

@end

@implementation CNCourse
- (NSString *)description
{
    return [NSString stringWithFormat:@"Course %@, id = %@,  dept spec course id = %@, deptId = %@, ", self.name, self.courseId, self.departmentSpecificCourseId, self.departmentId];
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

@end

@implementation CNUser

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        _phoneNumber = [aDecoder decodeObjectForKey:@"phoneNumber"];
        _accessToken = [aDecoder decodeObjectForKey:@"accessToken"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.phoneNumber forKey:@"phoneNumber"];
    [aCoder encodeObject:self.accessToken forKey:@"accessToken"];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"User phoneNumber %@, accessToken = %@", self.phoneNumber, self.accessToken];
}

- (NSString *)name
{
    return [NSString stringWithFormat:@"%@", self.phoneNumber];
}

@end

