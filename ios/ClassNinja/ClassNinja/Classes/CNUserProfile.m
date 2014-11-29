//
//  CNUserProfile.m
//  ClassNinja
//
//  Created by Boris Suvorov on 9/2/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNUserProfile.h"
#import "CNAPIResource.h"

@implementation CNUserProfile

static CNSchool *currentSchool = nil;

+ (NSString *)defaultSchoolFilePath
{
    NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *pathString = [[pathArray objectAtIndex:0] stringByAppendingPathComponent:@"school"];
    return pathString;
}

+ (CNSchool *)defaultSchool
{
    if (currentSchool == nil) {
        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:[self defaultSchoolFilePath]];
        currentSchool = [CNSchoolAPIResource modelWithDictionary:dict];

    }

    return currentSchool;
}

+ (void)setDefaultSchool:(CNSchool *)school
{
    if ([[self defaultSchool] isEqual:school] == NO) {
        currentSchool = school;
        NSDictionary *dict = [CNSchoolAPIResource dictionaryFromSchool:school];
        [dict writeToFile:[self defaultSchoolFilePath] atomically:NO];
        logUserAction(@"default_school_selected", @{@"default_school_name" : school.name});
    }
}

@end
