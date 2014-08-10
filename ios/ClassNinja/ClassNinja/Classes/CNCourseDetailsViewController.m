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

#define kClassNameLabelYOffset 10
#define kClassNameLabelHeight 75
#define kTitleViewHeight 90
#define kTitleLabelXOffset 20

@interface CNCourseDetailsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) UILabel *classLabel;
@property (nonatomic) UIView *titleView;

@property (nonatomic) UIButton *closeButton;
@property (nonatomic) UITableView *tableView;
@property (nonatomic) UIButton *trackButton;

@property (nonatomic) NSArray *courseDetails;

@property (nonatomic) NSArray *listOfSections;

@end

@implementation CNCourseDetailsViewController

- (void)viewDidLoad
{    
    [super viewDidLoad];
    self.tableView = [[UITableView alloc] init];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsVerticalScrollIndicator = NO;
    
    // FIXME: change color to gradient
    self.view.backgroundColor = SIONG_NAVIGATION_CONTROLLER_BACKGROUND_COLOR;
    self.tableView.backgroundColor = [UIColor clearColor];
    
    self.view.autoresizingMask = UIViewAutoresizingNone;
    
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.titleView];

    [self.view addSubview:self.classLabel];
    [self.view addSubview:self.closeButton];

    
    [self loadContent];

    
}

- (void)viewWillLayoutSubviews
{
    self.closeButton.frame = CGRectMake(kCloseButtonXOffset, kCloseButtonYOffset,
                                        kCloseButtonWidth, kCloseButtonHeight);
}

- (UILabel *)classLabel
{
    if (_classLabel == nil) {
        //UPDATEME: just a placeholder frame/title/colors
        _classLabel = [[UILabel alloc] init];
        _classLabel.text = self.course.name;
        _classLabel.textColor = [UIColor purpleColor];
    }
    return _classLabel;
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




- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    // set header first
    self.classLabel.frame = CGRectMake(0, kClassNameLabelYOffset, self.view.frame.size.width, kClassNameLabelHeight);
    
    // set table view
    CGRect rect = self.view.bounds;
    rect.origin.y += kClassNameLabelHeight;
    rect.size.height = kTitleViewHeight;
    
    self.titleView = [self titleView];
    self.titleView.frame = rect;
    
    rect.origin.y += kTitleViewHeight;
    rect.size.height = self.view.bounds.size.height - kTitleViewHeight - kClassNameLabelHeight;
    
    self.tableView.frame = rect;
}

- (void)loadContent
{
    [[CNAPIClient sharedInstance] listChildren:self.course
                                    completion:^(NSArray*children) {
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

#pragma Cell management
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"classcell"];
    CNSection *cnSection = [self.listOfSections objectAtIndex:indexPath.section];
    
    cell.textLabel.text = [[cnSection.events objectAtIndex:indexPath.row] name];
    return cell;
}

- (UIView *)titleView
{
    if (_titleView == nil) {
        UIView *view = [[UIView alloc] init];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(kTitleLabelXOffset, 0,
                                                                   self.view.frame.size.width - 2*kTitleLabelXOffset, kTitleViewHeight)];
        
        label.text = @"Which class(es) do you want to track?";
        label.numberOfLines = 3;
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont cnSystemFontOfSize:18];
        
        [view addSubview:label];
        [view setBackgroundColor:[UIColor colorWithRed:16/255.0 green:77/255.0 blue:147/255.0 alpha:1.0]];
        
        _titleView = view;
    }
    
    return _titleView;
}
@end
