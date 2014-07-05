//
//  CNModels.h
//  Class Ninja
//
//  Created by Boris Suvorov on 7/4/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CNSchool : NSObject

@property (nonatomic) NSString *schoolId;
@property (nonatomic) NSString *name;
@property (nonatomic) NSString *currentTermCode;
@property (nonatomic) NSString *currentTermName;

@end

@interface CNDepartment : NSObject

@property (nonatomic) CNSchool *school;

@property (nonatomic) NSString *departmentId;
@property (nonatomic) NSString *name;

@end

@interface CNCourse : NSObject

@property (nonatomic) CNDepartment *department;

@property (nonatomic) NSString *departmentSpecificCourseId;
@property (nonatomic) NSString *courseId;
@property (nonatomic) NSString *name;

@end