//
//  CNTargetsDiff.m
//  ClassNinja
//
//  Created by Vova Galchenko on 9/18/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNTargetsDiff.h"
#import "CNModels.h"

@interface CNTargetsDiff()

@property (nonatomic, readwrite) NSIndexSet *sectionsAdditions;
@property (nonatomic, readwrite) NSArray *rowsAdditions;
@property (nonatomic, readwrite) NSIndexSet *sectionsDeletions;
@property (nonatomic, readwrite) NSArray *rowsDeletions;
@property (nonatomic, readwrite) NSIndexSet *sectionsUpdates;
@property (nonatomic, readwrite) NSArray *rowsUpdates;
@property (nonatomic, readwrite) NSArray *fromTargets;
@property (nonatomic, readwrite) NSArray *toTargets;

@end

@implementation CNTargetsDiff

+ (instancetype)diffWithOldTargets:(NSArray *)oldTargets newTargets:(NSArray *)newTargets
{
    NSMutableArray *rowsDeletions = [NSMutableArray array];
    NSMutableIndexSet *sectionsDeletions = [NSMutableIndexSet indexSet];
    NSMutableArray *rowsAdditions = [NSMutableArray array];
    NSMutableIndexSet *sectionsAdditions = [NSMutableIndexSet indexSet];
    NSMutableArray *rowsUpdates = [NSMutableArray array];
    NSMutableIndexSet *sectionsUpdates = [NSMutableIndexSet indexSet];
    NSUInteger oldTargetIndex = 0;
    for (NSUInteger newTargetIndex = 0; newTargetIndex < newTargets.count; newTargetIndex++) {
        CNTargetedCourse *newTarget = [newTargets objectAtIndex:newTargetIndex];
        NSString *newTargetCourseId = newTarget.courseId;
        NSMutableIndexSet *deletionsBatch = [NSMutableIndexSet indexSet];
        BOOL foundAnchor = NO;
        for (NSUInteger i = oldTargetIndex; i < oldTargets.count; i++) {
            CNTargetedCourse *oldTargetedCourse = [oldTargets objectAtIndex:i];
            if ([[oldTargetedCourse courseId] isEqualToString:newTargetCourseId]) {
                [sectionsDeletions addIndexes:deletionsBatch];
                
                CNTargetsDiff *targetDiff = [self diffWithOldTarget:oldTargetedCourse
                                                          newTarget:newTarget
                                                     oldTargetIndex:i
                                                     newTargetIndex:newTargetIndex];
                [rowsDeletions addObjectsFromArray:targetDiff.rowsDeletions];
                [rowsAdditions addObjectsFromArray:targetDiff.rowsAdditions];
                [rowsUpdates addObjectsFromArray:targetDiff.rowsUpdates];
                
                if (![oldTargetedCourse isEqual:newTarget]) {
                    [sectionsUpdates addIndex:newTargetIndex];
                }
                
                oldTargetIndex = i + 1;
                foundAnchor = YES;
                break;
            } else {
                [deletionsBatch addIndex:i];
            }
        }
        if (!foundAnchor) {
            [sectionsAdditions addIndex:newTargetIndex];
        }
    }
    // All of the trailing old sections are deleted
    for (NSUInteger i = oldTargetIndex; i < oldTargets.count; i++) {
        [sectionsDeletions addIndex:i];
    }
    return [[self alloc] initWithSectionsAdditions:sectionsAdditions
                                     rowsAdditions:rowsAdditions
                                 sectionsDeletions:sectionsDeletions
                                     rowsDeletions:rowsDeletions
                                   sectionsUpdates:sectionsUpdates
                                       rowsUpdates:rowsUpdates
                                       fromTargets:oldTargets
                                         toTargets:newTargets];
}

+ (instancetype)diffWithOldTarget:(CNTargetedCourse *)oldTargetedCourse
                        newTarget:(CNTargetedCourse *)newTargetedCourse
                   oldTargetIndex:(NSUInteger)oldTargetIndex
                   newTargetIndex:(NSUInteger)newTargetIndex
{
    NSMutableArray *deletions = [NSMutableArray array];
    NSMutableArray *additions = [NSMutableArray array];
    NSMutableArray *updates = [NSMutableArray array];
    NSUInteger oldSectionIndex = 0;
    for (NSUInteger newSectionIndex = 0; newSectionIndex < newTargetedCourse.sections.count; newSectionIndex++) {
        CNSection *newSection = [newTargetedCourse.sections objectAtIndex:newSectionIndex];
        NSString *newSectionId = newSection.sectionid;
        NSMutableArray *deletionsBatch = [NSMutableArray array];
        BOOL foundAnchor = NO;
        for (NSUInteger i = oldSectionIndex; i < oldTargetedCourse.sections.count; i++) {
            CNSection *oldSection = [oldTargetedCourse.sections objectAtIndex:i];
            if ([[oldSection sectionid] isEqualToString:newSectionId]) {
                [deletions addObjectsFromArray:deletionsBatch];
                
                // Diff sections
                CNTargetsDiff *diff = [self diffWithOldSectionIndex:i
                                                          oldTarget:oldTargetedCourse
                                                    newSectionIndex:newSectionIndex
                                                          newTarget:newTargetedCourse
                                                     oldTargetIndex:oldTargetIndex
                                                     newTargetIndex:newTargetIndex];
                // This diff will only contain row updates
                [deletions addObjectsFromArray:diff.rowsDeletions];
                [additions addObjectsFromArray:diff.rowsAdditions];
                [updates addObjectsFromArray:diff.rowsUpdates];
                
                oldSectionIndex = i + 1;
                foundAnchor = YES;
                break;
            } else {
                NSUInteger rowIndex = 0;
                for (NSUInteger pastSectionIndex = 0; pastSectionIndex < oldSectionIndex; pastSectionIndex++) {
                    rowIndex += ([[[oldTargetedCourse.sections objectAtIndex:pastSectionIndex] events] count] + 1);
                }
                [deletionsBatch addObject:[NSIndexPath indexPathForRow:rowIndex++ inSection:oldTargetIndex]];
                for (NSUInteger j = 0; j < oldSection.events.count; j++) {
                    [deletionsBatch addObject:[NSIndexPath indexPathForRow:j + rowIndex inSection:oldTargetIndex]];
                }
            }
        }
        if (!foundAnchor) {
            NSUInteger rowIndex = 0;
            for (NSUInteger pastSectionIndex = 0; pastSectionIndex < newSectionIndex; pastSectionIndex++) {
                rowIndex += ([[[oldTargetedCourse.sections objectAtIndex:pastSectionIndex] events] count] + 1);
            }
            [additions addObject:[NSIndexPath indexPathForRow:rowIndex++ inSection:newTargetIndex]];
            for (NSUInteger j = 0; j < newSection.events.count; j++) {
                [additions addObject:[NSIndexPath indexPathForRow:j + rowIndex inSection:newTargetIndex]];
            }
        }
    }
    
    for (NSUInteger i = oldSectionIndex; i < oldTargetedCourse.sections.count; i++) {
        NSUInteger rowIndex = 0;
        for (NSUInteger pastSectionIndex = 0; pastSectionIndex < i; pastSectionIndex++) {
            rowIndex += ([[[oldTargetedCourse.sections objectAtIndex:pastSectionIndex] events] count] + 1);
        }
        [deletions addObject:[NSIndexPath indexPathForRow:rowIndex++ inSection:oldTargetIndex]];
        CNSection *section = oldTargetedCourse.sections[i];
        for (NSUInteger j = 0; j < section.events.count; j++) {
            [deletions addObject:[NSIndexPath indexPathForRow:j + rowIndex inSection:oldTargetIndex]];
        }
    }
    return [[self alloc] initWithSectionsAdditions:nil
                                     rowsAdditions:additions
                                 sectionsDeletions:nil
                                     rowsDeletions:deletions
                                   sectionsUpdates:nil
                                       rowsUpdates:updates
                                       fromTargets:@[oldTargetedCourse]
                                         toTargets:@[newTargetedCourse]];
}

+ (instancetype)diffWithOldSectionIndex:(NSUInteger)oldSectionIndex
                              oldTarget:(CNTargetedCourse *)oldTarget
                        newSectionIndex:(NSUInteger)newSectionIndex
                              newTarget:(CNTargetedCourse *)newTarget
                         oldTargetIndex:(NSUInteger)oldTargetIndex
                         newTargetIndex:(NSUInteger)newTargetIndex
{
    NSMutableArray *deletions = [NSMutableArray array];
    NSMutableArray *additions = [NSMutableArray array];
    NSMutableArray *updates = [NSMutableArray array];
    CNSection *oldSection = oldTarget.sections[oldSectionIndex];
    CNSection *newSection = newTarget.sections[newSectionIndex];
    if (![oldSection isEqual:newSection]) {
        [updates addObject:[NSIndexPath indexPathForRow:rowIndexForEventIndex(newTarget, newSectionIndex, -1)
                                               inSection:newTargetIndex]];
    }
    NSUInteger oldEventIndex = 0;
    for (NSUInteger newEventIndex = 0; newEventIndex < newSection.events.count; newEventIndex++) {
        CNEvent *newEvent = newSection.events[newEventIndex];
        BOOL foundAnchor = NO;
        NSMutableArray *deletionsBatch = [NSMutableArray array];
        for (NSUInteger i = oldEventIndex; i < oldSection.events.count; i++) {
            CNEvent *oldEvent = oldSection.events[i];
            if ([newEvent.eventId isEqualToString:oldEvent.eventId]) {
                [deletions addObjectsFromArray:deletionsBatch];
                if (![newEvent isEqual:oldEvent]) {
                    [updates addObject:[NSIndexPath indexPathForRow:rowIndexForEventIndex(newTarget, newSectionIndex, newEventIndex)
                                                          inSection:oldTargetIndex]];
                }
                oldEventIndex = i + 1;
                foundAnchor = YES;
                break;
            } else {
                [deletionsBatch addObject:[NSIndexPath indexPathForRow:rowIndexForEventIndex(oldTarget, oldSectionIndex, i)
                                                             inSection:oldTargetIndex]];
            }
        }
        if (!foundAnchor) {
            [additions addObject:[NSIndexPath indexPathForRow:rowIndexForEventIndex(newTarget, newSectionIndex, newEventIndex)
                                                    inSection:oldTargetIndex]];
        }
    }
    
    // All of the trailing old sections are deleted
    for (NSUInteger i = oldEventIndex; i < oldSection.events.count; i++) {
        [deletions addObject:[NSIndexPath indexPathForRow:rowIndexForEventIndex(oldTarget, oldSectionIndex, oldEventIndex)
                                                inSection:oldTargetIndex]];
    }
    return [[self alloc] initWithSectionsAdditions:nil
                                     rowsAdditions:additions
                                 sectionsDeletions:nil
                                     rowsDeletions:deletions
                                   sectionsUpdates:nil
                                       rowsUpdates:updates
                                       fromTargets:@[oldTarget]
                                         toTargets:@[newTarget]];
}

static inline NSUInteger rowIndexForEventIndex(CNTargetedCourse *targetedCourse, NSUInteger sectionIndex, NSUInteger eventIndex)
{
    NSUInteger rowIndex = 0;
    for (NSUInteger i = 0; i < sectionIndex; i++) {
        rowIndex += [[targetedCourse.sections[sectionIndex] events] count] + 1;
    }
    return rowIndex + eventIndex + 1;
}


- (instancetype)initWithSectionsAdditions:(NSIndexSet *)sectionsAdditions
                            rowsAdditions:(NSArray *)rowsAdditions
                        sectionsDeletions:(NSIndexSet *)sectionsDeletions
                            rowsDeletions:(NSArray *)rowsDeletions
                          sectionsUpdates:(NSIndexSet *)sectionsUpdates
                              rowsUpdates:(NSArray *)rowsUpdates
                              fromTargets:(NSArray *)fromTargets
                                toTargets:(NSArray *)toTargets
{
    if ((self = [super init])) {
        self.sectionsAdditions = [[NSIndexSet alloc] initWithIndexSet:sectionsAdditions];
        self.rowsAdditions = [NSArray arrayWithArray:rowsAdditions];
        self.sectionsDeletions = [[NSIndexSet alloc] initWithIndexSet:sectionsDeletions];
        self.rowsDeletions = [NSArray arrayWithArray:rowsDeletions];
        self.sectionsUpdates = [[NSIndexSet alloc] initWithIndexSet:sectionsUpdates];
        self.rowsUpdates = [NSArray arrayWithArray:rowsUpdates];
        self.fromTargets = [NSArray arrayWithArray:fromTargets];
        self.toTargets = [NSArray arrayWithArray:toTargets];
    }
    return self;
}

- (NSUInteger)singleAddition
{
    NSUInteger singleAddition = NSNotFound;
    if (self.rowsAdditions.count
        && !self.sectionsAdditions.count
        && !self.sectionsDeletions.count
        && !self.sectionsUpdates.count
        && !self.rowsDeletions.count
        && !self.rowsUpdates.count) {
        for (NSIndexPath *rowAddition in self.rowsAdditions) {
            if (singleAddition == NSNotFound) {
                singleAddition = rowAddition.section;
            } else if (singleAddition != rowAddition.section) {
                singleAddition = NSNotFound;
                break;
            }
        }
    } else if (self.sectionsAdditions.count == 1
               && !self.sectionsDeletions.count
               && !self.sectionsUpdates.count
               && !self.rowsAdditions.count
               && !self.rowsDeletions.count
               && !self.rowsUpdates.count) {
        singleAddition = self.sectionsAdditions.firstIndex;
    }
    return singleAddition;
}

- (NSString *)description
{
    NSString *result = @"";
    if ([self singleAddition] != NSNotFound) {
        result = [result stringByAppendingFormat:@"Single Addition: %lu", (unsigned long)[self singleAddition]];
    }
    if (self.sectionsDeletions.count > 0) {
        result = [result stringByAppendingFormat:@"\nSections Deletions: %@", self.sectionsDeletions];
    }
    if (self.rowsDeletions.count > 0) {
        result = [result stringByAppendingFormat:@"\nRows Deletions: %@", self.rowsDeletions];
    }
    if (self.sectionsAdditions.count > 0) {
        result = [result stringByAppendingFormat:@"\nSections Additions: %@", self.sectionsAdditions];
    }
    if (self.rowsAdditions.count > 0) {
        result = [result stringByAppendingFormat:@"\nRows Additions: %@", self.rowsAdditions];
    }
    if (self.sectionsUpdates.count > 0) {
        result = [result stringByAppendingFormat:@"\nSections Updates: %@", self.sectionsUpdates];
    }
    if (self.rowsUpdates.count > 0) {
        result = [result stringByAppendingFormat:@"\nRows Updates: %@", self.rowsUpdates];
    }
    return result;
}

@end
