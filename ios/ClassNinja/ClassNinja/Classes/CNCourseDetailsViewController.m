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

#define kCloseButtonWidth  44
#define kCloseButtonHeight 44

#define kCloseButtonXOffset 9
#define kCloseButtonYOffset 6

#define kHeaderQuestionHeight  60
#define kHeaderQuestionOffsetX 5

#define kHeaderBackgroundColor ([UIColor r:57 g:65 b:76])
#define kHeaderClassNameTextColor  ([UIColor r:30 g:30 b:30])
#define kHeaderQuestionTextColor  ([UIColor whiteColor])

#define kClassNameLabelXOffset 0
#define kClassNameLabelHeight 60

#define kTableOffsetX 20
#define kTableOffsetY (kCloseButtonYOffset + kCloseButtonHeight)
#define kTableHeaderHeight (kHeaderQuestionHeight + kClassNameLabelHeight)

#define kTrackButtonHeight 40

#define kTrackButtonBackgroundColorEnabled  ([UIColor colorWithRed:73/255.0 green:141/255.0 blue:203/255.0 alpha:1.0])
#define kTrackButtonBackgroundColorDisabled ([UIColor colorWithRed:135/255.0 green:144/255.0 blue:150/255.0 alpha:1.0])
#define kTrackButtonTextColorEnabled    ([UIColor whiteColor])
#define kTrackButtonTextColorDisabled   ([UIColor colorWithRed:210/255.0 green:211/255.0 blue:211/255.0 alpha:1.0])

#import "CNCourseDetailsTableViewCell.h"

@interface CNCourseDetailsViewController () <UITableViewDataSource, UITableViewDelegate, CourseDetailsTableViewCellProtocol>

@property (nonatomic) CAGradientLayer *backgroundGradientLayer;

@property (nonatomic) UIButton *closeButton;
@property (nonatomic) UITableView *tableView;
@property (nonatomic) UIButton *trackButton;

@property (nonatomic) NSArray *courseDetails;

@property (nonatomic) NSArray *listOfSections;

@property (nonatomic) NSMutableArray *expandedIndexPaths;
@property (nonatomic) NSMutableArray *targetEvents;
@end

@implementation CNCourseDetailsViewController

- (void)viewDidLoad
{    
    [super viewDidLoad];

    self.expandedIndexPaths = [NSMutableArray array];
    self.targetEvents = [NSMutableArray array];
    
    self.tableView = [[UITableView alloc] init];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsVerticalScrollIndicator = YES;

    CGSize size = self.view.bounds.size;
    self.tableView.tableHeaderView = [self headerViewWithWidth:size.width height:kTableHeaderHeight];
    
    self.view.backgroundColor = [UIColor clearColor];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.allowsSelection = YES;
    self.tableView.allowsMultipleSelection = YES;
    
    self.view.autoresizingMask = UIViewAutoresizingNone;
    
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.closeButton];
    [self.view addSubview:self.trackButton];
    [self.view.layer insertSublayer:self.backgroundGradientLayer atIndex:0];
    
    [self loadContent];    
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
    label.font = [UIFont cnSystemFontOfSize:18];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;

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
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeButton setImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(closeButtonPressed:)
               forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}



- (void)closeButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dealloc
{
    // FIXME: test code for testing deletion of the targets
    for (CNSection *cnSection in self.listOfSections) {
        for (CNEvent *event in cnSection.events) {
            [[CNAPIClient sharedInstance] removeEventFromTargetting:event successBlock:^(BOOL success){
                if (success) {
                    NSLog(@"Removed target for event %@", event);
                } else {
                    NSLog(@"Failed to removed target for event %@", event);
                }
            }];
        }
    }
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
                                        kCloseButtonWidth, kCloseButtonHeight);
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
    [[CNAPIClient sharedInstance] listChildren:self.course
                                    completion:^(NSArray*children) {
                                        self.listOfSections = children;
                                        [self.tableView reloadData];
                                        [self.tableView flashScrollIndicators];
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.expandedIndexPaths containsObject:indexPath]) {
        return [CNCourseDetailsTableViewCell expandedHeightForEvent:[self eventForIndexPath:indexPath]];
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
}

// code for testing deletion of the target

- (void)trackButtonPressed:(id)sender
{
    [[CNAPIClient sharedInstance] targetEvents:self.targetEvents successBlock:^(BOOL success){
        if (success) {
            [APP_DELEGATE.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
        } else {
            [[CNInAppPurchaseHelper sharedInstance] testIAP];
            [[[UIAlertView alloc] initWithTitle:@"Error"
                                        message:@"Unable to set the target"
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
            

        }
    }];
}

@end
