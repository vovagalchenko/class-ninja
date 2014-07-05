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
