//
//  CNCourseDetailsTableViewCell.h
//  ClassNinja
//
//  Created by Boris Suvorov on 8/10/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CNModels.h"

@class CNCourseDetailsTableViewCell;

@protocol CourseDetailsTableViewCellProtocol
- (void)targetingStateOnCell:(CNCourseDetailsTableViewCell *)cell changedTo:(BOOL)isTargeted;
- (void)expandStateOnCell:(CNCourseDetailsTableViewCell *)cell changedTo:(BOOL)isExpanded;

@optional
- (void)removeFromTargetsPressedIn:(CNCourseDetailsTableViewCell *)cell;

@end

@interface CNCourseDetailsTableViewCell : UITableViewCell

@property (nonatomic) CNEvent *event;
@property (nonatomic, weak) id <CourseDetailsTableViewCellProtocol>delegate;

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier usedForTargetting:(BOOL)usedForTargetting;
+ (CGFloat)collapsedHeightForEvent:(CNEvent *)event;
+ (CGFloat)expandedHeightForEvent:(CNEvent *)event width:(CGFloat)viewWidth usedForTargeting:(BOOL)usedForTargeting;

@end
