//
//  CNWelcomeViewController.m
//  ClassNinja
//
//  Created by Boris Suvorov on 7/27/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNWelcomeViewController.h"
#import "CNGenericSelectionViewController.h"
#import "CNSiongNavigationViewController.h"
#import "CNAPIClient.h"
#import "AppearanceConstants.h"
#import "CNAppDelegate.h"
#import "CNTargetSectionHeaderView.h"
#import "CNCourseDetailsTableViewCell.h"

@interface CNWelcomeViewController ()

@property (nonatomic) UITableView *tableView;
@property (nonatomic) CNWelcomeStatusView *statusView;
@property (nonatomic) CNSiongNavigationViewController *siongsNavigationController;
@property (nonatomic) NSArray *targets;
@property (nonatomic, readonly) NSMutableArray *expandedIndexPaths;

@end

@implementation CNWelcomeViewController

#pragma mark - UIViewController lifecycle

- (void)didReceiveMemoryWarning
{
    // TODO: implement this
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setNeedsStatusBarAppearanceUpdate];
    [[CNAPIClient sharedInstance] list:[CNTargetedCourse class]
                            authPolicy:CNFailRequestOnAuthFailure
                            completion:^(NSArray *targets) {
        if (targets.count) {
            [self setStatus:@"Here are the classes you're tracking this semester"];
            [APP_DELEGATE registerForPushNotifications];
        } else {
            [self setStatus:@"You're not tracking any classes this semester :("];
        }
        self.targets = targets;
        [self.tableView reloadData];
    }];
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
    if ([self.statusView.statusLabel.text isEqualToString:newStatus]) return;
    
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        self.statusView.statusLabel.alpha = 0;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:ANIMATION_DURATION animations:^{
            self.statusView.statusLabel.text = newStatus;
            [self.statusView setNeedsLayout];
            [self.statusView layoutIfNeeded];
            
            [self.tableView beginUpdates];
            [self.tableView setTableHeaderView:self.statusView];
            [self.tableView endUpdates];
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:ANIMATION_DURATION animations:^{
                self.statusView.statusLabel.alpha = 1;
            }];
        }];
    }];
}

#pragma mark - Subview Setup

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = WELCOME_BLUE_COLOR;
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.clipsToBounds = YES;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.allowsMultipleSelection = YES;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.separatorStyle = UITableViewCellSelectionStyleNone;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:sectionCellId];
    [self.tableView registerClass:[CNCourseDetailsTableViewCell class] forCellReuseIdentifier:eventCellId];
    [self.view addSubview:self.tableView];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.backgroundColor = [UIColor clearColor];
    
    self.statusView = [[CNWelcomeStatusView alloc] initWithDelegate:self];
    [self.tableView setTableHeaderView:self.statusView];
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
    }
    [super updateViewConstraints];
}

- (void)addClassesButtonPressed:(id)sender
{
    CNSchoolViewController *schoolVC = [[CNSchoolViewController alloc] init];
    self.siongsNavigationController = [[CNSiongNavigationViewController alloc] initWithRootViewController:schoolVC];
    self.siongsNavigationController.searchDelegate = self;
    [self presentViewController:self.siongsNavigationController animated:YES completion:nil];
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

static void getSectionAndEventIndicesForCourse(CNCourse *course, NSUInteger rowIndex, NSInteger *sectionIndex, NSInteger *eventIndex)
{
    *sectionIndex = 0;
    while (rowIndex >= [[[course.sections objectAtIndex:*sectionIndex] events] count] + 1) {
        (*sectionIndex)++;
        rowIndex -= [[[course.sections objectAtIndex:*sectionIndex] events] count] + 1;
    }
    *eventIndex = rowIndex - 1;
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

static NSString *sectionCellId = @"Section_Cell";
static NSString *eventCellId = @"Event_Cell";

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CNCourse *course = [self.targets objectAtIndex:indexPath.section];
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
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        ((CNCourseDetailsTableViewCell *)cell).event = [[section events] objectAtIndex:eventIndex];
        if ([self.expandedIndexPaths containsObject:indexPath])
            [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) return; // There's no selecting of the section headers
    
    [self.expandedIndexPaths addObject:indexPath];
    
    [tableView beginUpdates];
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [tableView endUpdates];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) return; // There's no deselecting of the section headers
    
    [self.expandedIndexPaths removeObject:indexPath];
    [tableView beginUpdates];
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [tableView endUpdates];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    CNTargetSectionHeaderView *headerView = [[CNTargetSectionHeaderView alloc] init];
    [headerView setText:[[self.targets objectAtIndex:section] name]];
    [headerView removeConstraints:headerView.constraints];
    [headerView addConstraints:@[
                                 [NSLayoutConstraint constraintWithItem:headerView
                                                              attribute:NSLayoutAttributeHeight
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:nil
                                                              attribute:NSLayoutAttributeNotAnAttribute
                                                             multiplier:0.0
                                                               constant:70.0],
                                 [NSLayoutConstraint constraintWithItem:headerView
                                                              attribute:NSLayoutAttributeWidth
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:nil
                                                              attribute:NSLayoutAttributeNotAnAttribute
                                                             multiplier:0.0
                                                               constant:tableView.bounds.size.width]
                                 ]];
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 70.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CNCourse *course = [self.targets objectAtIndex:indexPath.section];
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
    NSLog(@"%@", view);
    view.opaque = NO;
    view.alpha = 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *footerView = [[UIView alloc] init];
    footerView.alpha = 0;
    [footerView addConstraints:@[
                                 [NSLayoutConstraint constraintWithItem:footerView
                                                              attribute:NSLayoutAttributeHeight
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:nil
                                                              attribute:NSLayoutAttributeNotAnAttribute
                                                             multiplier:0.0
                                                               constant:20.0],
                                 [NSLayoutConstraint constraintWithItem:footerView
                                                              attribute:NSLayoutAttributeWidth
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:nil
                                                              attribute:NSLayoutAttributeNotAnAttribute
                                                             multiplier:0.0
                                                               constant:tableView.bounds.size.width]
                                 ]];
    return footerView;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 20.0;
}

#pragma mark - Properties

@synthesize expandedIndexPaths = _expandedIndexPaths;

- (NSMutableArray *)expandedIndexPaths
{
    if (!_expandedIndexPaths) {
        _expandedIndexPaths = [NSMutableArray array];
    }
    return _expandedIndexPaths;
}

@end
