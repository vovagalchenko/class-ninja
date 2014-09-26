//
//  ClassNinja
//
//  Created by Boris Suvorov on 8/9/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNCourseDetailsViewController.h"
#import "CNAPIClient.h"
#import "CNAppDelegate.h"
#import "CNInAppPurchaseHelper.h"
#import "CNCloseButton.h"
#import "AppearanceConstants.h"
#import "CNPaywallViewController.h"
#import "CNActivityIndicator.h"

#define kCloseButtonXOffset 17
#define kCloseButtonYOffset 17

#define kHeaderQuestionHeight  90
#define kHeaderQuestionOffsetX 19

#define kHeaderBackgroundColor ([UIColor r:57 g:65 b:76])
#define kHeaderClassNameTextColor  ([UIColor r:30 g:30 b:30])
#define kHeaderQuestionTextColor  ([UIColor whiteColor])

#define kClassNameLabelXOffset 0
#define kClassNameLabelHeight 60

#define kTableOffsetX 20
#define kTableOffsetY (44)
#define kTableHeaderHeight (kHeaderQuestionHeight + kClassNameLabelHeight)

#define kTrackButtonHeight 40

#define kTrackButtonBackgroundColorEnabled  ([UIColor colorWithRed:73/255.0 green:141/255.0 blue:203/255.0 alpha:1.0])
#define kTrackButtonBackgroundColorDisabled ([UIColor colorWithRed:135/255.0 green:144/255.0 blue:150/255.0 alpha:1.0])
#define kTrackButtonTextColorEnabled    ([UIColor whiteColor])
#define kTrackButtonTextColorDisabled   ([UIColor colorWithRed:210/255.0 green:211/255.0 blue:211/255.0 alpha:1.0])

#import "CNCourseDetailsTableViewCell.h"

@interface CNCourseDetailsViewController () <UITableViewDataSource, UITableViewDelegate, CourseDetailsTableViewCellProtocol>

@property (nonatomic) CAGradientLayer *backgroundGradientLayer;

@property (nonatomic) CNCloseButton *closeButton;
@property (nonatomic) UITableView *tableView;
@property (nonatomic) UIButton *trackButton;

@property (nonatomic) NSArray *listOfSections;

@property (nonatomic) NSMutableArray *expandedIndexPaths;
@property (nonatomic) NSMutableArray *targetEvents;

@property (nonatomic) CNActivityIndicator *activityIndicator;

@end

@implementation CNCourseDetailsViewController

- (UITableView *)tableView
{
    if (_tableView == nil) {
        _tableView = [[UITableView alloc] init];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.showsVerticalScrollIndicator = YES;
        _tableView.separatorInset = UIEdgeInsetsMake(0, kHeaderQuestionOffsetX, 0, 0);
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.allowsMultipleSelection = YES;
        _tableView.showsVerticalScrollIndicator = NO;
    }
    return _tableView;
}

- (NSString *)title
{
    return self.course.name;
}

- (void)viewDidLoad
{    
    [super viewDidLoad];
    self.expandedIndexPaths = [NSMutableArray array];
    self.targetEvents = [NSMutableArray array];
    self.activityIndicator = [[CNActivityIndicator alloc] initWithFrame:CGRectZero presentedOnLightBackground:YES];
    self.activityIndicator.alpha = 0.0;

    self.view.backgroundColor = [UIColor clearColor];
    self.view.autoresizingMask = UIViewAutoresizingNone;
    
    [self.view addSubview:self.activityIndicator];
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.closeButton];
    [self.view addSubview:self.trackButton];
    [self.view.layer insertSublayer:self.backgroundGradientLayer atIndex:0];
    
    [self loadContent];    
}



- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    CGSize size = self.tableView.bounds.size;
    self.tableView.tableHeaderView = [self headerViewWithWidth:size.width height:kTableHeaderHeight];
    
    CGFloat activityIndicatorDimension = TAPPABLE_AREA_DIMENSION;
    self.activityIndicator.frame = CGRectMake((self.view.bounds.size.width - activityIndicatorDimension)/2,
                                              (self.view.bounds.size.height - activityIndicatorDimension)/2,
                                              activityIndicatorDimension, activityIndicatorDimension);
}

- (CAGradientLayer*)backgroundGradientLayer
{
    if (_backgroundGradientLayer == nil) {
        UIColor *topViewColor = [UIColor colorWithWhite:230/255.0 alpha:1.0];
        UIColor *topOfTableViewHeaderColor = topViewColor;
        UIColor *bottomOfTableViewHeaderColor = [UIColor colorWithRed:208/255.0 green:209/255.0 blue:211/255.0 alpha:1.0];
        UIColor *bottomViewColor = bottomOfTableViewHeaderColor;
        
        NSArray *colors =  [NSArray arrayWithObjects:(id)topViewColor.CGColor,
                            topOfTableViewHeaderColor.CGColor,
                            bottomOfTableViewHeaderColor.CGColor,
                            bottomViewColor.CGColor,
                            nil];
        
        _backgroundGradientLayer = [CAGradientLayer layer];
        _backgroundGradientLayer.colors = colors;
    }
    
    return _backgroundGradientLayer;
}

- (void)updateBackgroundGradientLayerLocation
{
    NSNumber *topViewStop = [NSNumber numberWithFloat:0.0];

    CGFloat viewHeight = self.view.bounds.size.height;
    NSNumber *topOfTableViewHeaderStop = [NSNumber numberWithFloat:kTableOffsetY / viewHeight];
    NSNumber *bottomOfTableViewHeaderStop = [NSNumber numberWithFloat:(kTableOffsetY + kTableHeaderHeight)/viewHeight];
    NSNumber *bottomViewStop = [NSNumber numberWithFloat:1.0];

    NSArray *locations = [NSArray arrayWithObjects:topViewStop, topOfTableViewHeaderStop, bottomOfTableViewHeaderStop, bottomViewStop, nil];
    self.backgroundGradientLayer.locations = locations;
    self.backgroundGradientLayer.frame = self.view.bounds;
}

- (UIButton *)trackButton
{
    if  (_trackButton == nil) {
        _trackButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_trackButton addTarget:self action:@selector(trackButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        _trackButton.backgroundColor = kTrackButtonBackgroundColorDisabled;
        [_trackButton setTitle:@"Track" forState:UIControlStateNormal];
        [_trackButton setTitleColor:kTrackButtonTextColorEnabled forState:UIControlStateNormal];
        [_trackButton setTitleColor:kTrackButtonTextColorDisabled forState:UIControlStateDisabled];
    }
    return _trackButton;
}

- (UILabel *)classLabelWithWidth:(CGFloat)width
{
    UILabel *classLabel = [[UILabel alloc] initWithFrame:CGRectMake(kClassNameLabelXOffset,
                                                                    0,
                                                                    width - 2*kClassNameLabelXOffset,
                                                                    kClassNameLabelHeight)];
    classLabel.text = self.course.name;
    classLabel.numberOfLines = 2;
    classLabel.textColor = kHeaderClassNameTextColor;
    classLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    classLabel.font = [UIFont cnSystemFontOfSize:20];
    
    return classLabel;
}

- (UIView *)questionViewWithWidth:(CGFloat)width
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, kHeaderQuestionHeight)];
    [view setBackgroundColor:kHeaderBackgroundColor];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(kHeaderQuestionOffsetX,
                                                               0,
                                                               width - 2*kHeaderQuestionOffsetX,
                                                               kHeaderQuestionHeight)];
    
    label.text = @"Which classes do you want to track?";
    label.numberOfLines = 2;
    label.textColor = kHeaderQuestionTextColor;
    label.font = [UIFont cnSystemFontOfSize:20];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    label.clipsToBounds = YES;
    [view addSubview:label];
    
    return view;
}

- (UIView *)headerViewWithWidth:(CGFloat)width height:(CGFloat)height
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    UILabel *classLabel = [self classLabelWithWidth:width];
    UIView *questionView = [self questionViewWithWidth:width];
    CGRect titleFrame = questionView.frame;
    titleFrame.origin.y += classLabel.frame.size.height;
    questionView.frame = titleFrame;

    [view addSubview:classLabel];
    [view addSubview:questionView];
    
    view.backgroundColor = [UIColor clearColor];
    
    return view;
}


- (UIButton *)closeButton
{
    if (_closeButton == nil) {
        _closeButton = [[CNCloseButton alloc] initWithColor:DARK_CLOSE_BUTTON_COLOR];
        [_closeButton addTarget:self action:@selector(closeButtonPressed:)
               forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}

- (void)closeButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)updateTrackButtonState
{
    self.trackButton.enabled = self.targetEvents.count > 0;
    if (self.trackButton.enabled) {
        self.trackButton.backgroundColor = kTrackButtonBackgroundColorEnabled;
    } else {
        self.trackButton.backgroundColor = kTrackButtonBackgroundColorDisabled;
    }
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    self.closeButton.frame = CGRectMake(kCloseButtonXOffset, kCloseButtonYOffset,
                                        CLOSE_BUTTON_DIMENSION, CLOSE_BUTTON_DIMENSION);
    CGSize size = self.view.bounds.size;
    self.tableView.frame = CGRectMake(kTableOffsetX, kTableOffsetY, size.width - 2 * kTableOffsetX, size.height - kTableOffsetY - kTrackButtonHeight);
    self.tableView.tableHeaderView.frame = CGRectMake(0, 0, size.width - 2 * kTableOffsetX,  kTableHeaderHeight);
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(kTableHeaderHeight, 0, 0, 0);
    self.trackButton.frame = CGRectMake(0, size.height - kTrackButtonHeight, size.width, kTrackButtonHeight);
    [self updateTrackButtonState];
    [self updateBackgroundGradientLayerLocation];
}

- (void)loadContent
{
    self.activityIndicator.alpha = 1.0;
    [[CNAPIClient sharedInstance] listChildren:self.course
                                    completion:^(NSArray*children) {
                                        [UIView animateWithDuration:ANIMATION_DURATION animations:^{
                                            self.activityIndicator.alpha = 0.0;
                                        }];
                                        self.listOfSections = children;
                                        [self.tableView reloadData];
                                    }];
}

#pragma mark Collation related methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.listOfSections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    CNSection *cnSection = [self.listOfSections objectAtIndex:section];
    return cnSection.events.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    CNSection *courseSection = [self.listOfSections objectAtIndex:section];
    return [NSString stringWithFormat:@"%@: %@", courseSection.name, courseSection.staffName];
}

- (CNEvent *)eventForIndexPath:(NSIndexPath *)indexPath
{
    CNSection *cnSection = [self.listOfSections objectAtIndex:indexPath.section];
    return [cnSection.events objectAtIndex:indexPath.row];
}

#pragma Cell management
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CNCourseDetailsTableViewCell *cell = [[CNCourseDetailsTableViewCell alloc] initWithReuseIdentifier:@"classcell" usedForTargetting:YES];
    cell.delegate = self;
    cell.event = [self eventForIndexPath:indexPath];

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 32.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.expandedIndexPaths containsObject:indexPath]) {
        return [CNCourseDetailsTableViewCell expandedHeightForEvent:[self eventForIndexPath:indexPath]
                                                              width:self.tableView.bounds.size.width
                                                   usedForTargeting:YES];
    } else {
        return [CNCourseDetailsTableViewCell collapsedHeightForEvent:[self eventForIndexPath:indexPath]];
    }
}

- (void)targetingStateOnCell:(CNCourseDetailsTableViewCell *)cell changedTo:(BOOL)isTargeted
{
    if (isTargeted) {
        [self.targetEvents addObject:cell.event];
    } else {
        [self.targetEvents removeObject:cell.event];
    }
    [self updateTrackButtonState];
    
    NSString *analyticsCellAction = isTargeted? @"cell_target" : @"cell_untarget";
    [self logCellAction:analyticsCellAction
     forCellAtIndexPath:[self.tableView indexPathForCell:cell]];
}

- (void)expandStateOnCell:(CNCourseDetailsTableViewCell *)cell changedTo:(BOOL)isExpanded
{
    NSIndexPath *cellIndexPath = [self.tableView indexPathForCell:cell];
    
    if (cellIndexPath == nil) {
        return;
    }
    
    [self.tableView beginUpdates];
    if (isExpanded) {
        [self.expandedIndexPaths addObject:cellIndexPath];
    } else {
        [self.expandedIndexPaths removeObject:cellIndexPath];
    }
    [self.tableView endUpdates];

    if (isExpanded) {
        CGRect cellRect = [self.tableView convertRect:cell.frame
                                               toView:self.tableView.superview];
        
        CGFloat tableViewHeight = self.tableView.bounds.size.height;
        CGFloat originY = cellRect.origin.y;

        if (self.tableView.frame.origin.y + tableViewHeight < originY + cellRect.size.height) {
            [self.tableView scrollToRowAtIndexPath:cellIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
    }
    
    NSString *analyticsCellAction = isExpanded? @"cell_expand" : @"cell_collapse";
    [self logCellAction:analyticsCellAction
     forCellAtIndexPath:cellIndexPath];
    
}

- (void)logCellAction:(NSString *)cellAction forCellAtIndexPath:(NSIndexPath *)indexPath
{
    logUserAction(cellAction,
    @{
      @"event_id" : [[self eventForIndexPath:indexPath] eventId],
      @"table_type" : @"course_details"
    });
}

- (void)trackButtonPressed:(id)sender
{
    [[CNAPIClient sharedInstance] targetEvents:self.targetEvents successBlock:^(BOOL success){
        if (success) {
            [APP_DELEGATE.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
        } else {
            CNPaywallViewController *paywallVC = [[CNPaywallViewController alloc] init];
            paywallVC.modalPresentationStyle = UIModalPresentationFullScreen;
            [self presentViewController:paywallVC animated:YES completion:nil];
        }
    }];
}

@end
