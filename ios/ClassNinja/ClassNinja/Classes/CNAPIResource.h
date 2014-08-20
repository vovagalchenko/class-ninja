//
//  CoreAPIResource.h
//  ClassNinja
//
//  Created by Vova Galchenko on 7/27/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CNModel;
@protocol CNAPIResource <NSObject>

@property (nonatomic) id<CNModel>model;

+ (id<CNModel>)modelWithDictionary:(NSDictionary *)dictionary;
- (Class<CNAPIResource>)childResourceClass;
- (NSString *)resourceTypeName;
- (NSString *)resourceIdentifier;
+ (BOOL)needsAuthentication;

@end

@interface CNAPIResourceFactory : NSObject

+ (id<CNAPIResource>)apiResourceWithModel:(id<CNModel>)model;

@end

@interface CNSchoolAPIResource : NSObject<CNAPIResource>
@end

@interface CNDepartmentAPIResource : NSObject<CNAPIResource>
@end

@interface CNCourseAPIResource : NSObject<CNAPIResource>
@end

@interface CNSectionAPIResource : NSObject<CNAPIResource>
@end

@interface CNTargetedCourseAPIResource : NSObject<CNAPIResource>
@end

@interface CNRootAPIResource : NSObject<CNAPIResource>

+ (instancetype)rootAPIResourceForModel:(Class<CNModel>)model;

@end