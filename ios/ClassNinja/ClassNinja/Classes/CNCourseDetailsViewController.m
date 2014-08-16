//
//  ClassNinja
//
//  Created by Boris Suvorov on 8/9/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNCourseDetailsViewController.h"
#import "CNAPIClient.h"

#define kCloseButtonWidth  22
#define kCloseButtonHeight 22

#define kCloseButtonXOffset 20
#define kCloseButtonYOffset 15

#define kHeaderQuestionHeight  60
#define kHeaderQuestionOffsetX 5


#define kClassNameLabelXOffset 0
#define kClassNameLabelHeight 60

#define kTableOffsetX 20
#define kTableOffsetY (20 + kCloseButtonYOffset)
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
    
    // FIXME: change color to gradient
    self.view.backgroundColor = [UIColor clearColor];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.allowsSelection = NO;
    
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
    classLabel.textColor = [UIColor purpleColor];
    classLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    return classLabel;
}

- (UIView *)questionViewWithWidth:(CGFloat)width
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, kHeaderQuestionHeight)];
    [view setBackgroundColor:[UIColor colorWithRed:16/255.0 green:77/255.0 blue:147/255.0 alpha:1.0]];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(kHeaderQuestionOffsetX,
                                                               0,
                                                               width - 2*kHeaderQuestionOffsetX,
                                                               kHeaderQuestionHeight)];
    
    label.text = @"Which classes do you want to track?";
    label.numberOfLines = 2;
    label.textColor = [UIColor whiteColor];
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

#pragma Cell management
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CNCourseDetailsTableViewCell *cell = [[CNCourseDetailsTableViewCell alloc] initWithReuseIdentifier:@"classcell" usedForTargetting:YES];
    CNSection *cnSection = [self.listOfSections objectAtIndex:indexPath.section];
    
    cell.event = [cnSection.events objectAtIndex:indexPath.row];
    cell.delegate = self;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.expandedIndexPaths containsObject:indexPath]) {
        return [CNCourseDetailsTableViewCell expandedHeight];
    } else {
        return [CNCourseDetailsTableViewCell collapsedHeight];
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

    if (isExpanded) {
        [self.expandedIndexPaths addObject:cellIndexPath];
    } else {
        [self.expandedIndexPaths removeObject:cellIndexPath];
    }

    [self.tableView beginUpdates];
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

- (void)trackButtonPressed:(id)sender
{
    NSLog(@"Track button pressed");
}

@end
