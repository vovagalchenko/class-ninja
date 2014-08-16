//
//  CNSchoolViewController.m
//  ClassNinja
//
//  Created by Boris Suvorov on 7/29/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNGenericSelectionViewController.h"
#import "CNAPIClient.h"
#import "CNGenericSelectionTableViewCell.h"
#import "AppearanceConstants.h"
#import "CNCourseDetailsViewController.h"

#define kTitleViewHeight 90
#define kTitleLabelXOffset 20

@interface CNGenericSelectionViewController ()
@property (nonatomic, readonly) NSString *headerText;
@property (nonatomic) UITableView *tableView;
@property (nonatomic) NSArray *childrenOfRootModel;
@property (nonatomic) id <CNModel> rootModel;
@property (nonatomic) UIView *titleView;
@property (nonatomic) NSIndexPath *lastSelectedRow;

- (void)reloadResults:(NSArray *)children;
- (id <CNModel>)modelForIndexPath:(NSIndexPath *)indexPath;

@end

@interface CNCourseViewController : CNGenericSelectionViewController
@end

@interface CNDepartmentViewController : CNGenericSelectionViewController
@property (nonatomic) NSMutableArray *departmentsByCollationIndex;
@property (nonatomic) NSMutableOrderedSet *enUSCollation;
@end


@implementation CNGenericSelectionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView = [[UITableView alloc] init];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsVerticalScrollIndicator = NO;
    
    self.view.backgroundColor = SIONG_NAVIGATION_CONTROLLER_BACKGROUND_COLOR;
    self.tableView.backgroundColor = [UIColor clearColor];
    
    self.view.autoresizingMask = UIViewAutoresizingNone;
    
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.titleView];

    [self loadContent];
}


- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];


    // set table view
    CGRect tableRect = self.view.bounds;
    tableRect.origin.y += kTitleViewHeight;
    tableRect.size.height -= kTitleViewHeight;
    
    self.tableView.frame = tableRect;
    [self layoutTitleView];
}

- (void)loadContent
{
    [[CNAPIClient sharedInstance] listChildren:self.rootModel
                                    completion:^(NSArray*children) {
                                        [self reloadResults:children];
                                    }];
}

- (Class)nextVCClass
{
    return [CNGenericSelectionViewController class];
}

- (void)reloadResults:(NSArray *)children
{
    self.childrenOfRootModel = children;
    [self.tableView reloadData];
}

#pragma mark Collation related methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.childrenOfRootModel.count;
}

#pragma Cell management
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[CNGenericSelectionTableViewCell alloc] initWithReuseIdentifier:@"genericcell"];
    id <CNModel> model = [self.childrenOfRootModel objectAtIndex:indexPath.row];
    cell.textLabel.text = [model name];
    return cell;
}

- (id <CNModel>)modelForIndexPath:(NSIndexPath *)indexPath
{
    return [self.childrenOfRootModel objectAtIndex:indexPath.row];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id <CNModel> model = [self modelForIndexPath:indexPath];
    CNGenericSelectionViewController *nextVC = [[[self nextVCClass] alloc] init];
    nextVC.rootModel = model;
    self.lastSelectedRow =  indexPath;
    [self.siongNavigationController pushViewController:nextVC];
}

- (void)setLastSelectedRow:(NSIndexPath *)indexPath
{
    _lastSelectedRow = indexPath;
}

- (UIView *)titleView
{
    if (_titleView == nil) {
        UIView *view = [[UIView alloc] init];
        
        UILabel *label = [[UILabel alloc] init];
        
        label.text = [self headerText];
        label.numberOfLines = 3;
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont cnSystemFontOfSize:18];
        
        [view addSubview:label];
        [view setBackgroundColor:[UIColor colorWithRed:16/255.0 green:77/255.0 blue:147/255.0 alpha:1.0]];

        _titleView = view;
    }
    
    return _titleView;
}

- (void)layoutTitleView
{
    self.titleView.frame = CGRectMake(0, 0, self.view.frame.size.width, kTitleViewHeight);
    [[self.titleView.subviews objectAtIndex:0] setFrame:CGRectMake(kTitleLabelXOffset, 0,
                                                                  self.view.frame.size.width - 2*kTitleLabelXOffset, kTitleViewHeight)];
}

#pragma mark SiongNavigationProtocol
- (void)nextViewControllerWillPop
{
    [self.tableView deselectRowAtIndexPath:self.lastSelectedRow animated:YES];
}

@end

@implementation CNSchoolViewController
- (NSString *)headerText
{
    return @"Which university are you attending?";
}

- (void)loadContent
{
    [[CNAPIClient sharedInstance] list:[CNSchool class]
                            completion:^(NSArray *children){
                                [self reloadResults:children];
                            }];
}

- (Class)nextVCClass
{
    return [CNDepartmentViewController class];
}
@end

@implementation CNDepartmentViewController

- (NSString *)headerText
{
    return @"Which department are you enrolled in?";
}

- (Class)nextVCClass
{
    return [CNCourseViewController class];
}

- (id)init
{
    self = [super init];
    if (self) {
        _enUSCollation = [[NSMutableOrderedSet alloc] init];
        _departmentsByCollationIndex = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)collateDepartmentsByName:(NSArray *)departments
{
    self.departmentsByCollationIndex = [[NSMutableArray alloc] init];
    
    for (CNDepartment *dept in departments) {
        NSString *firstChar = [[dept.name substringToIndex:1] uppercaseString];
        NSUInteger index = [self.enUSCollation indexOfObject:firstChar];
        if (index == NSNotFound) {
            NSMutableArray *collatedArray = [[NSMutableArray alloc] initWithObjects:dept, nil];
            [self.departmentsByCollationIndex addObject:collatedArray];
            [self.enUSCollation addObject:firstChar];
        } else {
            NSMutableArray *collatedArray = [self.departmentsByCollationIndex objectAtIndex:index];
            [collatedArray addObject:dept];
        }
    }
}

- (void)reloadResults:(NSArray *)children
{
    [self collateDepartmentsByName:children];
    [self.tableView reloadData];
}

#pragma mark Collation related methods
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self.enUSCollation objectAtIndex:section];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.departmentsByCollationIndex.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSMutableArray *collatedArray = [self.departmentsByCollationIndex objectAtIndex:section];
    return collatedArray.count;
}


- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return [self.enUSCollation array];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index;
{
    return index;
}

#pragma Cell management
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[CNGenericSelectionTableViewCell alloc] initWithReuseIdentifier:@"deparmentcell"];
    
    NSArray *collatedDepartments = [self.departmentsByCollationIndex objectAtIndex:indexPath.section];
    CNDepartment *dept = [collatedDepartments objectAtIndex:indexPath.row];
    cell.textLabel.text = dept.name;
    return cell;
}

- (id <CNModel>)modelForIndexPath:(NSIndexPath *)indexPath
{
    NSArray *collatedDepartments = [self.departmentsByCollationIndex objectAtIndex:indexPath.section];
    return [collatedDepartments objectAtIndex:indexPath.row];
}

@end


@implementation CNCourseViewController
- (NSString *)headerText
{
    return @"Which course are you looking to take?";
}

- (Class)nextVCClass
{
    return nil;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id <CNModel> model = [self modelForIndexPath:indexPath];
    CNCourseDetailsViewController *nextVC = [[CNCourseDetailsViewController alloc] init];
    nextVC.course = (CNCourse *)model;
    self.lastSelectedRow =  indexPath;
    nextVC.modalPresentationStyle = UIModalPresentationFullScreen;
    nextVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    nextVC.modalPresentationCapturesStatusBarAppearance = YES;
    [self.siongNavigationController presentViewController:nextVC animated:YES completion:nil];
}


@end