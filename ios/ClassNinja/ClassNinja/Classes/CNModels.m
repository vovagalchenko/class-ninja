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
@end

@implementation CNDepartment
- (NSString *)description
{
    return [NSString stringWithFormat:@"Department %@, id = %@, school name = %@", self.name, self.departmentId, self.school.name];
}

@end

@implementation CNCourse
- (NSString *)description
{
    return [NSString stringWithFormat:@"Course %@, id = %@,  dept spec course id = %@, dept name = %@, ", self.name, self.courseId, self.departmentSpecificCourseId, self.department.name];
}

@end

@implementation CNSection
- (NSString *)description
{
    return [NSString stringWithFormat:@"Section %@, id = %@, staff name = %@, course id = %@\n\nlist of events = %@", self.name, self.sectionid, self.staffName, self.courseId, self.events];
}

@end

@implementation CNEvent
- (NSString *)description
{
    return [NSString stringWithFormat:@"Event id %@, type = %@, status = %@, waitlisted = %@, enrolled = %@, waitlist capacity = %@", self.eventId, self.eventType, self.status, self.numberWaitlisted, self.numberEnrolled, self.waitlistCapacity];
}
@end



