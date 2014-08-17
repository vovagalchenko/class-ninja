//
//  CNModels.h
//  Class Ninja
//
//  Created by Boris Suvorov on 7/4/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CNModel <NSObject>

@required
- (NSString *)name;

@end

@interface CNSchool : NSObject<CNModel>

@property (nonatomic) NSString *schoolId;
@property (nonatomic) NSString *name;
@property (nonatomic) NSString *currentTermCode;
@property (nonatomic) NSString *currentTermName;

@end

@interface CNDepartment : NSObject<CNModel>

@property (nonatomic) NSString *schoolId;

@property (nonatomic) NSString *departmentId;
@property (nonatomic) NSString *name;

@end

@interface CNCourse : NSObject<CNModel>

@property (nonatomic) NSString *departmentId;
@property (nonatomic) NSString *departmentSpecificCourseId;
@property (nonatomic) NSString *courseId;
@property (nonatomic) NSString *name;

// Array of sections this course contains
@property (nonatomic) NSArray *sections;

@end

// A target is a course. It doesn't specialize this resource yet.
@interface CNTarget : CNCourse
@property (nonatomic) NSString *targetId;
@end

@interface CNSection : NSObject<CNModel>

@property (nonatomic) NSString *courseId;
@property (nonatomic) NSString *sectionid;

@property (nonatomic) NSString *staffName;
@property (nonatomic) NSString *name;
@property (nonatomic) NSArray *events;

@end

@interface CNEvent : NSObject<CNModel>

// Q: Why there is no pointer to CNSection?
// A: Because CNSection contains array of CNEvents. That would cause reference loop.

@property (nonatomic) NSString *sectionId;
@property (nonatomic) NSString *targetId; // Only set if the event is targeted by the logged in user
@property (nonatomic) NSString *eventId;
@property (nonatomic) NSString *status;
@property (nonatomic) NSString *eventType;
@property (nonatomic) NSString *schoolSpecificEventId;
@property (nonatomic) NSDictionary *timesAndLocations;
@property (nonatomic) NSNumber *enrollmentCap;
@property (nonatomic) NSNumber *numberWaitlisted;
@property (nonatomic) NSNumber *numberEnrolled;
@property (nonatomic) NSNumber *waitlistCapacity;

- (NSString *)daysOfWeek;
- (NSString *)hours;
- (NSString *)location;
- (BOOL)isClosed;
@end

// Implementing NSCoding, because we'll be persisting the logged in user in the keychain
@interface CNUser: NSObject <CNModel, NSCoding>

// We might want to create a CNPhoneNumber class and make this be an instance of that.
// Phone numbers have to go through some sanitization/standardization layer.
@property (nonatomic) NSString *phoneNumber;
@property (nonatomic) NSString *accessToken;

@end