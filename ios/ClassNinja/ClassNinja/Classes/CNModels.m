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

typedef NS_ENUM(NSInteger, CNUserKeychainVersion) {
    CNUserKeychainVersion1_1__1_2,
    CNUserKeychainVersionLatestVersion,
};

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        _phoneNumber = [aDecoder decodeObjectForKey:@"phoneNumber"];
        _accessToken = [aDecoder decodeObjectForKey:@"accessToken"];
        _credits = [[aDecoder decodeObjectForKey:@"credits"] unsignedIntegerValue];
        
        if ([aDecoder containsValueForKey:@"didPostOnFb"]) {
            _didPostOnFb = [[aDecoder decodeObjectForKey:@"didPostOnFb"] boolValue];
        }
        
        if ([aDecoder containsValueForKey:@"didPostOnTwitter"]) {
            _didPostOnTwitter = [[aDecoder decodeObjectForKey:@"didPostOnTwitter"] boolValue];
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.phoneNumber forKey:@"phoneNumber"];
    [aCoder encodeObject:self.accessToken forKey:@"accessToken"];
    [aCoder encodeObject:@(self.credits) forKey:@"credits"];

    [aCoder encodeObject:@(self.didPostOnFb) forKey:@"didPostOnFb"];
    [aCoder encodeObject:@(self.didPostOnTwitter) forKey:@"didPostOnTwitter"];
    
    [aCoder encodeObject:@(CNUserKeychainVersionLatestVersion) forKey:@"version"];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"User phoneNumber %@, accessToken = %@, credits = %lu", self.phoneNumber, self.accessToken, (unsigned long)self.credits];
}

- (NSString *)name
{
    return [NSString stringWithFormat:@"%@", self.phoneNumber];
}

static inline NSMutableDictionary *keychainSearchDictionaryForLoggedInUser()
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:(__bridge_transfer id)kSecClassGenericPassword forKey:(__bridge_transfer id)kSecClass];
    [dict setObject:[@"logged_in_user" dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge_transfer id)kSecAttrGeneric];
    return dict;
}

+ (CNUser *)retrieveLoggedInUserFromKeychain
{
    CFTypeRef loggedInUser = nil;
    NSMutableDictionary *searchDict = keychainSearchDictionaryForLoggedInUser();
    [searchDict setObject:(__bridge_transfer id)kCFBooleanTrue forKey:(__bridge_transfer id)kSecReturnData];
    [searchDict setObject:(__bridge_transfer id)kSecMatchLimitOne forKey:(__bridge_transfer id)kSecMatchLimit];
    SecItemCopyMatching((__bridge CFDictionaryRef)searchDict, &loggedInUser);
    NSData *data = (__bridge_transfer NSData *)loggedInUser;
    return (data == nil)? nil : [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

+ (void)writeLoggedInUserToKeychain:(CNUser *)newLoggedInUser
{
    NSMutableDictionary *keychainSearchDict = keychainSearchDictionaryForLoggedInUser();
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:newLoggedInUser];
    [keychainSearchDict setObject:data forKey:(__bridge_transfer id)kSecValueData];
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)keychainSearchDict, NULL);
    if (status == errSecDuplicateItem) {
        status = SecItemUpdate((__bridge CFDictionaryRef)keychainSearchDict,
                               (__bridge CFDictionaryRef)[NSDictionary dictionaryWithObject:data forKey:(__bridge_transfer id)kSecValueData]);
    }
    CNAssert(status == errSecSuccess, @"keychain_write", @"Error writing to keychain: %d", status);
}

+ (void)deleteUserEntryFromKeychain
{
    NSMutableDictionary *keychainSearchDict = keychainSearchDictionaryForLoggedInUser();
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)keychainSearchDict);
    CNAssert(status == errSecSuccess || status == errSecItemNotFound, @"keychain_delete", @"Error writing to keychain: %d", status);
}

@end

