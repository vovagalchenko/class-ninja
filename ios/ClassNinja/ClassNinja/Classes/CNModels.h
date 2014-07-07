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

@interface CNSection : NSObject

@property (nonatomic) NSString *courseId;
@property (nonatomic) NSString *sectionid;

@property (nonatomic) NSString *staffName;
@property (nonatomic) NSString *name;
@property (nonatomic) NSArray *events;

@end

@interface CNEvent : NSObject

// Q: Why there is no pointer to CNSection?
// A: Because CNSection contains array of CNEvents. That would cause reference loop.
// FIXME: removes strong references from objects above. use NSString *<>Id instead;

@property (nonatomic) NSString *sectionId;
@property (nonatomic) NSString *eventId;

@property (nonatomic) NSString *status;
@property (nonatomic) NSString *eventType;
@property (nonatomic) NSString *schoolSpecificEventId;
@property (nonatomic) NSDictionary *timesAndLocations;
@property (nonatomic) NSNumber *enrollmentCap;
@property (nonatomic) NSNumber *numberWaitlisted;
@property (nonatomic) NSNumber *numberEnrolled;
@property (nonatomic) NSNumber *waitlistCapacity;
@end