//
//  CNUserProfile.h
//  ClassNinja
//
//  Created by Boris Suvorov on 9/2/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CNModels.h"

@interface CNUserProfile : NSObject

+ (CNSchool *)defaultSchool;
+ (void)setDefaultSchool:(CNSchool *)school;

@end
