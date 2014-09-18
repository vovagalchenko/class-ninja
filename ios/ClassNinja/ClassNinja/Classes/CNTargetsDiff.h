//
//  CNTargetsDiff.h
//  ClassNinja
//
//  Created by Vova Galchenko on 9/18/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import <Foundation/Foundation.h>

// Objects of this class calculate deltas to apply to tableviews when a list of targets changes
@interface CNTargetsDiff : NSObject

@property (nonatomic, readonly) NSIndexSet *sectionsAdditions;
@property (nonatomic, readonly) NSArray *rowsAdditions;
@property (nonatomic, readonly) NSIndexSet *sectionsDeletions;
@property (nonatomic, readonly) NSArray *rowsDeletions;
@property (nonatomic, readonly) NSIndexSet *sectionsUpdates;
@property (nonatomic, readonly) NSArray *rowsUpdates;

+ (instancetype)diffWithOldTargets:(NSArray *)oldTargets newTargets:(NSArray *)newTargets;
- (NSUInteger)singleAddition;

@end
