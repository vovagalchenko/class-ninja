//
//  Created by Boris Suvorov on 7/27/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNDashboardViewController.h"
#import "CNGenericSelectionViewController.h"
#import "CNSiongNavigationViewController.h"
#import "CNAPIClient.h"
#import "AppearanceConstants.h"
#import "CNAppDelegate.h"
#import "CNTargetSectionHeaderView.h"
#import "CNCourseDetailsTableViewCell.h"
#import "CNTargetsDiff.h"
#import "CNPaywallViewController.h"
#import "CNGradientView.h"

#define SECTION_HEADER_HEIGHT       70.0

@interface CNDashboardViewController () <CourseDetailsTableViewCellProtocol>

@property (nonatomic) UITableView *tableView;
@property (nonatomic) CNWelcomeStatusView *statusView;
@property (nonatomic) CNSiongNavigationViewController *siongsNavigationController;
@property (nonatomic) NSArray *targets;
@property (nonatomic, readonly) NSMutableArray *expandedIndexPaths;
@property (nonatomic, readonly) NSMutableArray *processingRows;
@property (nonatomic) NSArray *highlightedTargetRows;
@property (nonatomic, assign) NSUInteger numOngoingTargetFetches;
@property (nonatomic) CNGradientView *gradientOccluder;

@end

@implementation CNDashboardViewController

#pragma mark - UIViewController lifecycle

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setNeedsStatusBarAppearanceUpdate];
    [self refreshTargets];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self.statusView setNeedsLayout];
    [self.statusView layoutIfNeeded];
    dispatch_async(dispatch_get_main_queue(), ^{
        // Let all the layout for the statusView settle and set the tableHeaderView
        // on the next iteration of the runloop.
        [self.tableView setTableHeaderView:self.statusView];
    });
}

#pragma mark - Updating UI with Data

- (void)setStatus:(NSString *)newStatus
{
    [self setStatus:newStatus actionButtonType:CNWelcomeStatusViewActionStatusButtonTypeNone completion:nil];
}

- (void)setStatus:(NSString *)newStatus actionButtonType:(CNWelcomeStatusViewActionStatusButtonType)actionButtonType completion:(void (^)())completion
{
    if ([self.statusView.statusLabel.layer animationKeys].count) {
        [self.statusView.statusLabel.layer removeAllAnimations];
        [self.statusView.actionButton.layer removeAllAnimations];
        [self.statusView.separatorLine.layer removeAllAnimations];
    }
    [UIView animateWithDuration:ANIMATION_DURATION/2 animations:^{
        self.statusView.statusLabel.alpha = 0;
        self.statusView.separatorLine.alpha = 0;
        self.statusView.actionButton.alpha = 0;
    } completion:^(BOOL finished) {
        if (finished) {
            [UIView animateWithDuration:ANIMATION_DURATION/2 animations:^{
                self.statusView.statusLabel.text = newStatus;
                [self.statusView setActionButtonType:actionButtonType];
                [self.statusView setNeedsLayout];
                [self.statusView layoutIfNeeded];
                
                [self.tableView setTableHeaderView:self.statusView];
            } completion:^(BOOL finished) {
                if (finished) {
                    [UIView animateWithDuration:ANIMATION_DURATION/2 animations:^{
                        self.statusView.statusLabel.alpha = 1;
                        self.statusView.separatorLine.alpha = 1;
                        self.statusView.actionButton.alpha = 1;
                        if (completion) completion();
                    }];
                }
            }];
        }
    }];
}

- (void)refreshTargets
{
    [self setStatus:@"Fetching targets..."];
    self.numOngoingTargetFetches++;
    CNAPIClient *apiClient = [CNAPIClient sharedInstance];
    [apiClient list:[CNTargetedCourse class]
         authPolicy:CNFailRequestOnAuthFailure
         completion:^(NSArray *targets, NSError *error)
     {
         self.numOngoingTargetFetches--;
         if (self.numOngoingTargetFetches == 0)
         {
             void (^refreshTargetsTable)() = ^{
                 // Now we'll animate the change from the old list of targets to the new
                 NSArray *oldTargets = self.targets ?: @[];
                 CNTargetsDiff *diff = [CNTargetsDiff diffWithOldTargets:oldTargets newTargets:targets];
                 
                 self.targets = targets;
                 // Deselect everything for starters
                 for (UITableViewCell *cell in self.tableView.visibleCells) {
                     [cell setSelected:NO animated:YES];
                 }
                 // Take the first
                 NSUInteger singleAddition = [diff singleAddition];
                 if (singleAddition != NSNotFound) {
                     [self.expandedIndexPaths removeAllObjects];
                     [self.processingRows removeAllObjects];
                     // In case only additions to a single targeted course were performed
                     // we're going to want to highlight this change to the user by scrolling
                     // the tableview to the newly added cells and highlighting them for a second.
                     NSArray *indexPathsToScrollTo = @[];
                     
                     // The single addition change could be performed two ways:
                     //  1. Addition of a new targeted course with one or more targeted events.
                     //  2. Addition of one or more targeted events to an existing targeted course.
                     // Below, we calculate the indexPaths to highlight for each of those cases.
                     if (diff.sectionsAdditions.count) {
                         [self.tableView insertSections:diff.sectionsAdditions withRowAnimation:UITableViewRowAnimationTop];
                         NSMutableArray *sectionsIndexPaths = [NSMutableArray array];
                         NSUInteger numRowsInSection = [self tableView:self.tableView numberOfRowsInSection:singleAddition];
                         for (NSUInteger i = 0; i < numRowsInSection; i++) {
                             [sectionsIndexPaths addObject:[NSIndexPath indexPathForRow:i
                                                                              inSection:singleAddition]];
                         }
                         indexPathsToScrollTo = [NSArray arrayWithArray:sectionsIndexPaths];
                     } else if (diff.rowsAdditions.count) {
                         [self.tableView insertRowsAtIndexPaths:diff.rowsAdditions withRowAnimation:UITableViewRowAnimationAutomatic];
                         indexPathsToScrollTo = diff.rowsAdditions;
                     }
                     // Finally, change the model for the highlightedTargetRows and reload the corresponding rows in the UI.
                     self.highlightedTargetRows = [NSArray arrayWithArray:indexPathsToScrollTo];
                     [self.tableView reloadRowsAtIndexPaths:indexPathsToScrollTo
                                           withRowAnimation:UITableViewRowAnimationFade];
                     
                     // Scroll to make sure the first and the last indexPaths of the indexPathsToScrollTo are visible.
                     [self.tableView scrollToRowAtIndexPath:indexPathsToScrollTo.firstObject
                                           atScrollPosition:UITableViewScrollPositionNone
                                                   animated:YES];
                     [self.tableView scrollToRowAtIndexPath:indexPathsToScrollTo.lastObject
                                           atScrollPosition:UITableViewScrollPositionNone
                                                   animated:YES];
                     // Dismiss the highlighting after 1 second.
                     dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                         self.highlightedTargetRows = nil;
                         NSMutableArray *indexPathsToReload = [NSMutableArray array];
                         for (NSIndexPath *candidate in indexPathsToScrollTo) {
                             if ([self.tableView numberOfSections] > candidate.section
                                 && [self.tableView numberOfRowsInSection:candidate.section] > candidate.row)
                                 [indexPathsToReload addObject:candidate];
                         }
                         [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationFade];
                     });
                 } else {
                     // The diff between the old and new targets isn't a change to a single targeted course.
                     // We don't have anything to highlight – we're just going to apply the diff to the tableview.
                     // TODO: apply updates.
                     [self.tableView beginUpdates];
                     if (self.expandedIndexPaths.count) {
                         [self.tableView reloadRowsAtIndexPaths:self.expandedIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
                         [self.expandedIndexPaths removeAllObjects];
                     }
                     [self.processingRows removeAllObjects];
                     if (diff.sectionsAdditions.count) {
                         [self.tableView insertSections:diff.sectionsAdditions withRowAnimation:UITableViewRowAnimationBottom];
                     }
                     if (diff.rowsAdditions.count) {
                         [self.tableView insertRowsAtIndexPaths:diff.rowsAdditions withRowAnimation:UITableViewRowAnimationAutomatic];
                     }
                     if (diff.sectionsDeletions.count) {
                         [self.tableView deleteSections:diff.sectionsDeletions withRowAnimation:UITableViewRowAnimationBottom];
                     }
                     if (diff.rowsDeletions.count) {
                         [self.tableView deleteRowsAtIndexPaths:diff.rowsDeletions withRowAnimation:UITableViewRowAnimationAutomatic];
                     }
                     if (diff.rowsUpdates.count) {
                         [self.tableView reloadRowsAtIndexPaths:diff.rowsUpdates withRowAnimation:UITableViewRowAnimationAutomatic];
                     }
                     if (diff.sectionsUpdates.count) {
                         [self.tableView reloadSections:diff.sectionsUpdates withRowAnimation:UITableViewRowAnimationAutomatic];
                     }
                     [self.tableView endUpdates];
                 }
             };
             if (targets == nil && apiClient.authContext.loggedInUser != nil) {
                 [self setStatus:@"Unable to fetch targets."
                actionButtonType:CNWelcomeStatusViewActionStatusButtonTypeRefreshTargets
                      completion:refreshTargetsTable];
             } else if (apiClient.authContext.loggedInUser.credits <= 5 && apiClient.authContext.loggedInUser.credits > 0) {
                 NSString *classesString = (apiClient.authContext.loggedInUser.credits > 1)? @"classes" : @"class";
                 [self setStatus:[NSString stringWithFormat:@"You can track %lu more %@ for free", (unsigned long)apiClient.authContext.loggedInUser.credits, classesString]
                actionButtonType:CNWelcomeStatusViewActionStatusButtonTypePay
                      completion:refreshTargetsTable];
             } else if (targets.count) {
                 [self setStatus:@"Here are the classes you're tracking"
                actionButtonType:CNWelcomeStatusViewActionStatusButtonTypeNone
                      completion:refreshTargetsTable];
             } else {
                 [self setStatus:@"You're not tracking any classes :("
                actionButtonType:CNWelcomeStatusViewActionStatusButtonTypeNone
                      completion:refreshTargetsTable];
             }
             
             if (targets.count > 0) {
                 [APP_DELEGATE registerForPushNotifications];
             }
         }
         
    }];
}

#pragma mark - Subview Setup

static NSString *sectionCellId = @"Section_Cell";
static NSString *eventCellId = @"Event_Cell";
static NSString *sectionHeaderViewId = @"Section_Header";

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = WELCOME_BLUE_COLOR;
    
    // UITableViewStylePlain is the nicer style for us, however, on iOS 7, there's a bug that causes
    // crashes during cell animations if there are footers involved and the table style is UITableViewStylePlain:
    // http://stackoverflow.com/questions/11664766/cell-animation-stop-fraction-must-be-greater-than-start-fraction
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero
                                                  style:(floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1)?
                                                            UITableViewStylePlain : UITableViewStyleGrouped];
    self.tableView.clipsToBounds = YES;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.allowsMultipleSelection = YES;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.separatorStyle = UITableViewCellSelectionStyleNone;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:sectionCellId];
    [self.tableView registerClass:[CNCourseDetailsTableViewCell class] forCellReuseIdentifier:eventCellId];
    [self.tableView registerClass:[CNTargetSectionHeaderView class] forHeaderFooterViewReuseIdentifier:sectionHeaderViewId];
    [self.view addSubview:self.tableView];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.backgroundColor = [UIColor clearColor];
    
    self.statusView = [[CNWelcomeStatusView alloc] initWithDelegate:self];
    [self.tableView setTableHeaderView:self.statusView];
    
    self.gradientOccluder = [[CNGradientView alloc] initWithColor:WELCOME_BLUE_COLOR];
    [self.view addSubview:self.gradientOccluder];
}

- (void)updateViewConstraints
{
    if (self.view.constraints.count == 0) {
        NSLayoutConstraint *top = [NSLayoutConstraint constraintWithItem:self.tableView
                                                               attribute:NSLayoutAttributeTop
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.view
                                                               attribute:NSLayoutAttributeTop
                                                              multiplier:1.0
                                                                constant:self.topLayoutGuide.length];
        NSLayoutConstraint *bottom = [NSLayoutConstraint constraintWithItem:self.tableView
                                                                  attribute:NSLayoutAttributeBottom
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.view
                                                                  attribute:NSLayoutAttributeBottom
                                                                 multiplier:1.0
                                                                   constant:0.0];
        NSLayoutConstraint *left = [NSLayoutConstraint constraintWithItem:self.tableView
                                                                attribute:NSLayoutAttributeLeft
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self.view
                                                                attribute:NSLayoutAttributeLeft
                                                               multiplier:1.0
                                                                 constant:HORIZONTAL_MARGIN];
        NSLayoutConstraint *right = [NSLayoutConstraint constraintWithItem:self.tableView
                                                                 attribute:NSLayoutAttributeRight
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.view
                                                                 attribute:NSLayoutAttributeRight
                                                                multiplier:1.0
                                                                  constant:-HORIZONTAL_MARGIN];
        [self.view addConstraints:@[top, bottom, left, right]];
        
        
        top = [NSLayoutConstraint constraintWithItem:self.statusView
                                           attribute:NSLayoutAttributeTop
                                           relatedBy:NSLayoutRelationEqual
                                              toItem:self.tableView
                                           attribute:NSLayoutAttributeTop
                                          multiplier:1.0
                                            constant:0.0];
        left = [NSLayoutConstraint constraintWithItem:self.statusView
                                            attribute:NSLayoutAttributeLeft
                                            relatedBy:NSLayoutRelationEqual
                                               toItem:self.tableView
                                            attribute:NSLayoutAttributeLeft
                                           multiplier:1.0
                                             constant:0.0];
        right = [NSLayoutConstraint constraintWithItem:self.statusView
                                             attribute:NSLayoutAttributeRight
                                             relatedBy:NSLayoutRelationEqual
                                                toItem:self.tableView
                                             attribute:NSLayoutAttributeRight
                                            multiplier:1.0
                                              constant:0.0];
        NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:self.statusView
                                                                 attribute:NSLayoutAttributeWidth
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.tableView
                                                                 attribute:NSLayoutAttributeWidth
                                                                multiplier:1.0
                                                                  constant:0.0];
        [self.view addConstraints:@[top, left, right, width]];
        
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_gradientOccluder]|"
                                                                          options:0
                                                                          metrics:0
                                                                            views:NSDictionaryOfVariableBindings(_gradientOccluder)]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-%f-[_gradientOccluder(%f)]", self.topLayoutGuide.length, SECTION_HEADER_HEIGHT/4]
                                                                          options:0
                                                                          metrics:0
                                                                            views:NSDictionaryOfVariableBindings(_gradientOccluder)]];
    }
    [super updateViewConstraints];
}

- (void)buildUIForSearchResults:(NSArray *)models
{
    CNSchoolViewController *schoolVC= nil;
    if (self.siongsNavigationController == nil) {
        schoolVC = [[CNSchoolViewController alloc] init];
        self.siongsNavigationController = [[CNSiongNavigationViewController alloc] initWithRootViewController:schoolVC];
        [self presentViewController:self.siongsNavigationController animated:NO completion:nil];
    } else {
        schoolVC = (CNSchoolViewController *)[self.siongsNavigationController rootVC];
    }
    [schoolVC handleSearchResult:models];
}

#pragma mark - UITableViewController stuff

static void getSectionAndEventIndicesForCourse(CNTargetedCourse *course, NSUInteger rowIndex, NSInteger *sectionIndex, NSInteger *eventIndex)
{
    *sectionIndex = 0;
    NSInteger currRowIndex = rowIndex;
    while (currRowIndex >= (NSInteger)[[[course.sections objectAtIndex:*sectionIndex] events] count] + 1) {
        currRowIndex -= ([[[course.sections objectAtIndex:*sectionIndex] events] count] + 1);
        (*sectionIndex)++;
    }
    *eventIndex = currRowIndex - 1;
    CNAssert(course.sections.count > *sectionIndex && ((NSInteger)[course.sections[*sectionIndex] events].count) > *eventIndex,
             @"getSectionAndEventIndicesForCourse_integrity", @"getSectionAndEventIndicesForCourse returned impossible results.");
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.targets.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *sections = [[self.targets objectAtIndex:section] sections];
    NSUInteger numSections = 0;
    for (CNSection *section in sections) {
        numSections++; // Increment once for the section header cell
        numSections += section.events.count;
    }
    return numSections; // + 1 because for the section cell at the top
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CNTargetedCourse *course = [self.targets objectAtIndex:indexPath.section];
    NSInteger sectionIndex, eventIndex;
    getSectionAndEventIndicesForCourse(course, indexPath.row, &sectionIndex, &eventIndex);
    
    NSString *cellId = nil;
    UITableViewCell *cell = nil;
    CNSection *section = [course.sections objectAtIndex:sectionIndex];
    if (eventIndex < 0) {
        cellId = sectionCellId;
        cell = [tableView dequeueReusableCellWithIdentifier:cellId forIndexPath:indexPath];
        cell.textLabel.text = [NSString stringWithFormat:@"%@: %@", section.name, section.staffName];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:12];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundColor = [UIColor colorWithRed:.92 green:.92 blue:.92 alpha:1.0];
    } else {
        cellId = eventCellId;
        cell = (CNCourseDetailsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellId forIndexPath:indexPath];
        ((CNCourseDetailsTableViewCell *)cell).delegate = self;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        ((CNCourseDetailsTableViewCell *)cell).event = [[section events] objectAtIndex:eventIndex];
        if ([self.expandedIndexPaths containsObject:indexPath])
            [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        else {
            [tableView deselectRowAtIndexPath:indexPath animated:NO];
            [(CNCourseDetailsTableViewCell *)cell setProcessing:[self.processingRows containsObject:indexPath]];
        }
        
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0 || [self.processingRows containsObject:indexPath]) return; // There's no selecting of the section headers or rows that are being processed
    
    [tableView beginUpdates];
    [self.expandedIndexPaths addObject:indexPath];
    [tableView endUpdates];
 
    [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
    
    [self logCellAction:@"cell_expand" forCellAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) return; // There's no deselecting of the section headers
    
    [tableView beginUpdates];
    [self.expandedIndexPaths removeObject:indexPath];
    [tableView endUpdates];
    
    [self logCellAction:@"cell_collapse" forCellAtIndexPath:indexPath];
}

- (void)logCellAction:(NSString *)cellAction forCellAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionIndex, eventIndex;
    CNTargetedCourse *target = self.targets[indexPath.section];
    getSectionAndEventIndicesForCourse(target, indexPath.row, &sectionIndex, &eventIndex);
    logUserAction(cellAction,
                  @{
                    @"event_id" : ((CNEvent *)((CNSection *)target.sections[sectionIndex]).events[eventIndex]).eventId,
                    @"table_type" : @"targets"
                    });
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    CNTargetSectionHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:sectionHeaderViewId];
    [headerView setText:[[self.targets objectAtIndex:section] name]];
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return SECTION_HEADER_HEIGHT;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CNTargetedCourse *course = [self.targets objectAtIndex:indexPath.section];
    NSInteger sectionIndex, eventIndex;
    getSectionAndEventIndicesForCourse(course, indexPath.row, &sectionIndex, &eventIndex);
    
    CNSection *section = [course.sections objectAtIndex:sectionIndex];
    CGFloat retVal = 0;
    if (eventIndex < 0) {
        retVal = 20;
    } else {
        if ([self.expandedIndexPaths containsObject:indexPath]) {
            retVal = [CNCourseDetailsTableViewCell expandedHeightForEvent:[section.events objectAtIndex:eventIndex]
                                                                    width:tableView.bounds.size.width
                                                         usedForTargeting:NO];
        } else {
            retVal = [CNCourseDetailsTableViewCell collapsedHeightForEvent:[section.events objectAtIndex:eventIndex]];
        }
    }
    return retVal;
}

// The footer is for separation between sections
- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    view.opaque = NO;
    view.alpha = 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *footerView = [[UIView alloc] init];
    return footerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 20.0;
}

- (void)expandStateOnCell:(CNCourseDetailsTableViewCell *)cell changedTo:(BOOL)isExpanded
{
    // TODO: it's not clear why we should ever need these callbacks at all
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.highlightedTargetRows containsObject:indexPath]) {
        [cell setHighlighted:YES animated:NO];
    } else {
        [cell setHighlighted:NO animated:NO];
    }
}

- (void)removeFromTargetsPressedIn:(CNCourseDetailsTableViewCell *)cell
{
    NSIndexPath *cellIndexPath = [self.tableView indexPathForCell:cell];
    [self removeTargetForIndexPath:cellIndexPath];
}

- (void)removeTargetForIndexPath:(NSIndexPath *)indexPath
{
    CNTargetedCourse *targetedCourse = [self.targets objectAtIndex:indexPath.section];
    NSInteger sectionIndex, eventIndex;
    getSectionAndEventIndicesForCourse(targetedCourse, indexPath.row, &sectionIndex, &eventIndex);
    
    CNAPIClient *client = [CNAPIClient sharedInstance];
    CNSection *relevantSection = [targetedCourse.sections objectAtIndex:sectionIndex];
    CNEvent *relevantEvent = [relevantSection.events objectAtIndex:eventIndex];
    logUserAction(@"target_remove", @{
        @"targeted_course" : targetedCourse.name,
        @"targeted_event" : relevantEvent.eventId,
        @"target_id" : relevantEvent.targetId
    });
    [self.processingRows addObject:indexPath];
    if ([self.expandedIndexPaths containsObject:indexPath]) {
        [self.expandedIndexPaths removeObject:indexPath];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
    [client removeEventFromTargetting:relevantEvent
                         successBlock:^(BOOL success)
    {
        [self refreshTargets];
    }];
}

#pragma mark - CNWelcomeStatusViewDelegate
- (void)presentSchoolVC
{
    CNSchoolViewController *schoolVC = [[CNSchoolViewController alloc] init];
    self.siongsNavigationController = [[CNSiongNavigationViewController alloc] initWithRootViewController:schoolVC];
    self.siongsNavigationController.searchDelegate = self;
    [self presentViewController:self.siongsNavigationController animated:YES completion:nil];
}

- (void)addClassesButtonPressed:(id)sender
{
    [self presentSchoolVC];
}

- (void)refreshTargetsButtonPressed:(id)sender
{
    [self refreshTargets];
}

- (void)payToTrackMoreButtonPressed:(id)sender
{
    CNPaywallViewController *paywallVC = [[CNPaywallViewController alloc] init];
    paywallVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:paywallVC animated:YES completion:nil];
}

#pragma mark - Properties

@synthesize expandedIndexPaths = _expandedIndexPaths;
@synthesize processingRows = _processingRows;

- (NSMutableArray *)expandedIndexPaths
{
    if (!_expandedIndexPaths) {
        _expandedIndexPaths = [NSMutableArray array];
    }
    return _expandedIndexPaths;
}

- (NSMutableArray *)processingRows
{
    if (!_processingRows) {
        _processingRows = [NSMutableArray array];
    }
    return _processingRows;
}

@end
