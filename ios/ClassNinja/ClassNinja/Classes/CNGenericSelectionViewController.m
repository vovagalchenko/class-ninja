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
#import "CNActivityIndicator.h"
#import "CNUserProfile.h"

#define kTitleViewHeight 90
#define kTitleLabelXOffset 20

@interface CNGenericSelectionViewController ()
@property (nonatomic, readonly) NSString *headerText;
@property (nonatomic) UITableView *tableView;
@property (nonatomic) NSArray *childrenOfRootModel;
@property (nonatomic) id <CNModel> rootModel;
@property (nonatomic) UIView *titleView;
@property (nonatomic) NSIndexPath *lastSelectedRow;
@property (nonatomic) CNActivityIndicator *activityIndicator;
@property (nonatomic) id <CNModel> selectedModel;
@property (nonatomic) BOOL didNavigateToSelectedModel;

- (void)reloadResults:(NSArray *)children;
- (id <CNModel>)modelForIndexPath:(NSIndexPath *)indexPath;

@end

@interface CNCourseViewController : CNGenericSelectionViewController
@end

@interface CNDepartmentViewController : CNGenericSelectionViewController
@end


@implementation CNGenericSelectionViewController

- (NSString *)siongNavBarTitle
{
    return self.rootModel.name;
}

- (NSIndexPath *)selectRowForSelectedModel:(id <CNModel>)selectedModel
{
    if (self.childrenOfRootModel != nil) {
        NSUInteger selectedModelIndex = [self.childrenOfRootModel indexOfObject:selectedModel];
        if (selectedModelIndex != NSNotFound && selectedModelIndex < self.childrenOfRootModel.count) {
            self.didNavigateToSelectedModel = YES;
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:selectedModelIndex inSection:0];
            [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
            return indexPath;
        }
    }
    return nil;
}

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
    
    self.activityIndicator = [[CNActivityIndicator alloc] initWithFrame:CGRectZero presentedOnLightBackground:YES];
    self.activityIndicator.alpha = 0.0;
    
    self.view.autoresizingMask = UIViewAutoresizingNone;
    
    [self.view addSubview:self.activityIndicator];
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
    
    CGFloat activityIndicatorDimension = TAPPABLE_AREA_DIMENSION;
    self.activityIndicator.frame = CGRectMake((self.view.bounds.size.width - activityIndicatorDimension)/2,
                                              (self.view.bounds.size.height - activityIndicatorDimension)/2,
                                              activityIndicatorDimension, activityIndicatorDimension);
}

- (void)loadContent
{
    self.activityIndicator.alpha = 1.0;
    [[CNAPIClient sharedInstance] listChildren:self.rootModel
                                    completion:^(NSArray*children) {
                                        [UIView animateWithDuration:ANIMATION_DURATION animations:^{
                                            self.activityIndicator.alpha = 0.0;
                                        }];
                                        [self reloadResults:children];
                                    }];
}

- (void)handleSearchResult:(NSArray *)searchModels
{
    [self.siongNavigationController popViewControllerAtIndex:searchModels.count
                                                    animated:NO
                                                deselectRows:YES];
    NSArray *VCs = [self.siongNavigationController viewControllers];
    
    CNGenericSelectionViewController *cursorVC = nil;
    NSIndexPath *indexPath = nil;
    for (int i = 0; i < VCs.count; i++) {
        cursorVC = [VCs objectAtIndex:i];
        cursorVC.selectedModel = [searchModels objectAtIndex:i];
        indexPath = [cursorVC selectRowForSelectedModel:cursorVC.selectedModel];
    }
    
    if (VCs.count < searchModels.count) {
        for (int i = VCs.count; i < searchModels.count; i++) {
            cursorVC = [[[cursorVC nextVCClass] alloc] init];
            cursorVC.selectedModel = [searchModels objectAtIndex:i];;
            [self.siongNavigationController pushViewController:cursorVC];
        }
    } else {
        [cursorVC tableView:cursorVC.tableView didSelectRowAtIndexPath:indexPath];
    }
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
    self.selectedModel = [self modelForIndexPath:indexPath];
    CNGenericSelectionViewController *nextVC = [[[self nextVCClass] alloc] init];
    nextVC.rootModel = self.selectedModel;
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
        [view setBackgroundColor:QUESTION_TITLE_BACKGROUND_COLOR];

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

@interface CNSchoolViewController()
@property (nonatomic) BOOL didNavigateToDefaultSchool;
@end

@implementation CNSchoolViewController

- (NSString *)siongNavBarTitle
{
    return @"Add class";
}

- (void)tryNavigatingToDefaultSchool
{
    if (self.didNavigateToDefaultSchool == NO) {
        CNSchool *school = [CNUserProfile defaultSchool];
        self.selectedModel = school;
        NSIndexPath *indexPath = [self selectRowForSelectedModel:self.selectedModel];
        if (indexPath) {
            self.didNavigateToDefaultSchool = YES;
            [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self tryNavigatingToDefaultSchool];
}

- (NSString *)headerText
{
    return @"Which university are you attending?";
}

- (void)loadContent
{
    self.activityIndicator.alpha = 1.0;
    [[CNAPIClient sharedInstance] list:[CNSchool class]
                            completion:^(NSArray *children){
                                [UIView animateWithDuration:ANIMATION_DURATION animations:^{
                                    self.activityIndicator.alpha = 0.0;
                                }];
                                [self reloadResults:children];
                                [self tryNavigatingToDefaultSchool];
                            }];
}

- (Class)nextVCClass
{
    return [CNDepartmentViewController class];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CNSchool *school = [self modelForIndexPath:indexPath];
    [CNUserProfile  setDefaultSchool:school];
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
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

@end


@implementation CNCourseViewController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
}

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
    self.selectedModel = [self modelForIndexPath:indexPath];
    CNCourseDetailsViewController *nextVC = [[CNCourseDetailsViewController alloc] init];
    nextVC.course = (CNCourse *)self.selectedModel;
    self.lastSelectedRow =  indexPath;
    nextVC.modalPresentationStyle = UIModalPresentationFullScreen;
    nextVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    nextVC.modalPresentationCapturesStatusBarAppearance = YES;
    [self.siongNavigationController presentViewController:nextVC animated:YES completion:nil];
}




@end
