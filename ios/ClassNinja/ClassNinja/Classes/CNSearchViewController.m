//
//  CNSearchViewController.m
//  ClassNinja
//
//  Created by Boris Suvorov on 8/31/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNSearchViewController.h"
#import "CNAPIClient.h"
#import "CNUserProfile.h"
#import "CNCourseDetailsViewController.h"
#import "CNCloseButton.h"

#define kPaddingAroundSearchBar 14
#define kSearchBarOffsetX (kPaddingAroundSearchBar)
#define kSearchBarOffsetY 75
#define kSearchBarHeight 32
#define kSearchBarTextInset 10

#define kTableViewOffsetX 0
#define kTableViewOffsetY (kSearchBarOffsetY + kSearchBarHeight + kPaddingAroundSearchBar)

#define kTitleOriginY       35
#define kTitleOriginHeight  16

#define kSectionHeaderOffsetX 20
#define kDepartmentsResultsCellHeight 44
#define kCoursesResultsCellHeight 59

#define kCloseButtonXOffset (kSearchBarOffsetX + floorf(CLOSE_BUTTON_DIMENSION / 2))
#define kCloseButtonYOffset (kTitleOriginY +  floorf((kTitleOriginHeight - CLOSE_BUTTON_DIMENSION) / 2)+1)


#define kCellTitleFont ([UIFont systemFontOfSize:14.0])
#define kCellBoldTermFont ([UIFont boldSystemFontOfSize:14.0])

@interface CNSearchResultsCell : UITableViewCell
@property (nonatomic) UIView *separatorLine;
- (instancetype)init;
@end

@implementation CNSearchResultsCell

- (instancetype)init
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"search"];

    if(self) {
        // have to add our own separator line because it is not possible to adjust
        // 1) content inset that would not also be content inset for the tableview section
        // 2) height of separator line
        self.separatorLine = [[UIView alloc] init];
        self.separatorLine.backgroundColor = [UIColor opaqueWhiteWithIntensity:230];
        [self addSubview:self.separatorLine];
        
        self.textLabel.numberOfLines = 2;
        self.textLabel.font = [UIFont cnSystemFontOfSize:12];
        self.textLabel.textColor = [UIColor opaqueWhiteWithIntensity:90];
        
        self.detailTextLabel.font = [UIFont cnSystemFontOfSize:9];
        self.detailTextLabel.textColor = [UIColor opaqueWhiteWithIntensity:180];
        
        self.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGSize cellSize = self.frame.size;
    self.separatorLine.frame = CGRectMake(0, cellSize.height - 1, cellSize.width, 1);
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.detailTextLabel.text = nil;
}

- (void)setTitle:(NSString *)title subtitle:(NSString *)subtitle searchTerms:(NSArray *)searchTerms
{
    NSDictionary *defaultAttributes = @{NSFontAttributeName : kCellTitleFont};
    NSMutableAttributedString *boldedTitle = [[NSMutableAttributedString alloc] initWithString:title
                                                                                    attributes:defaultAttributes];
    
    for (NSString *term in searchTerms) {
        boldedTitle = [self setBoldTerms:term inText:boldedTitle];
    }
    
    self.textLabel.attributedText = boldedTitle;
    self.detailTextLabel.text = subtitle;
}

- (NSMutableAttributedString *)setBoldTerms:(NSString*)term inText:(NSMutableAttributedString*)boldedTitle
{
    NSUInteger length = [boldedTitle length];
    NSRange range = NSMakeRange(0, length);
    
    while(range.location != NSNotFound) {
        range = [[boldedTitle string] rangeOfString:term options:NSCaseInsensitiveSearch range:range];
        if(range.location != NSNotFound) {
            NSDictionary *boldAttrs = @{NSFontAttributeName : kCellBoldTermFont};
            [boldedTitle setAttributes:boldAttrs range:range];
            range = NSMakeRange(range.location + range.length, length - (range.location + range.length));
        }
    }
    
    return boldedTitle;
}


@end


@interface CNSearchViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) CNCloseButton *closeButton;
@property (nonatomic) UITextField *searchBar;
@property (nonatomic) UITableView *resultsView;

@property (nonatomic) NSArray *departmentsForLastSearch;
@property (nonatomic) NSArray *coursesForLastSearch;
@property (nonatomic) NSMutableDictionary *courseDepartmentNameByIDLookup;

@property (nonatomic) NSArray *lastUsedSearchTerms;
@property (nonatomic) NSString *lastSearchString;

@end


@implementation CNSearchViewController

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    self.view.backgroundColor = SEARCH_BACKGROUND_COLOR;
    
    [self.view addSubview:self.closeButton];
    [self.view addSubview:self.titleLabel];
    [self.view addSubview:self.searchBar];
    [self.view addSubview:self.resultsView];
    
    self.searchBar.delegate = self;
    self.titleLabel.text = @"Search Classes and Courses";
    self.searchBar.backgroundColor = [UIColor whiteColor];
    
    self.resultsView.hidden = YES;
    
    [self.searchBar addTarget:self action:@selector(searchBarTextDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.searchBar becomeFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}

- (void)searchWithinDefaultSchool
{
    CNSchool *school = [CNUserProfile defaultSchool];
    if (school == nil) {
        NSLog(@"%@ shown without user profile having deafult school", self);
        return;
    }

    __weak CNSearchViewController *me = self;
    NSString *searchString = [self.lastSearchString copy];
    
    NSLog(@"Searching for %@", searchString);
    
    [[CNAPIClient sharedInstance] searchInSchool:school
                                    searchString:self.lastSearchString
                                      completion:^(NSArray *departments, NSArray *courses, NSArray *departments_for_courses) {
                                          if ([me.lastSearchString isEqualToString:searchString]) {
                                              me.departmentsForLastSearch = departments;
                                              me.coursesForLastSearch = courses;
                                              
                                              self.courseDepartmentNameByIDLookup = [[NSMutableDictionary alloc] init];
                                              for (CNDepartment *dept in departments_for_courses) {
                                                  [self.courseDepartmentNameByIDLookup setObject:dept.name forKey:dept.departmentId];
                                              }
                                              
                                              me.lastUsedSearchTerms = [searchString componentsSeparatedByString:@" "];;
                                              if (courses.count > 0 || departments > 0) {
                                                  self.resultsView.hidden = NO;
                                              }
                                              
                                              [me.resultsView reloadData];
                                          }
                                      }];
    
}

- (void)searchBarTextDidChange:(id)sender
{

    NSString *searchString = [self.searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSArray *searchTerms = [searchString componentsSeparatedByString:@" "];
    
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"length"
                                                  ascending:NO];
    
    searchTerms = [searchTerms sortedArrayUsingDescriptors:@[sortDescriptor]];

    if ([searchTerms.firstObject length] >= 3) {
        self.lastSearchString = searchString;
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [self performSelector:@selector(searchWithinDefaultSchool) withObject:nil afterDelay:0.35];
    } else {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        self.lastSearchString = nil;
        self.resultsView.hidden = YES;
        self.departmentsForLastSearch = nil;
        self.coursesForLastSearch = nil;
        self.lastUsedSearchTerms = nil;
        [self.resultsView reloadData];
    }
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    NSDictionary* info = [notification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    CGFloat duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    UIViewAnimationOptions options = [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];

    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    
    [UIView animateWithDuration:duration delay:0 options:options animations:^{
        self.resultsView.contentInset = contentInsets;
        self.resultsView.scrollIndicatorInsets = contentInsets;
    } completion:nil];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    NSDictionary* info = [notification userInfo];
    CGFloat duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    UIViewAnimationOptions options = [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    
    [UIView animateWithDuration:duration delay:0 options:options animations:^{
        self.resultsView.contentInset = contentInsets;
        self.resultsView.scrollIndicatorInsets = contentInsets;
    } completion:nil];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.closeButton.frame = CGRectMake(kCloseButtonXOffset, kCloseButtonYOffset, CLOSE_BUTTON_DIMENSION, CLOSE_BUTTON_DIMENSION);
    
    self.titleLabel.frame = CGRectMake(0, kTitleOriginY,
                                       self.view.bounds.size.width, kTitleOriginHeight);
    
    self.searchBar.frame = CGRectMake(kSearchBarOffsetX,
                                      kSearchBarOffsetY,
                                      self.view.bounds.size.width - 2*kSearchBarOffsetX,
                                      kSearchBarHeight);

    self.searchBar.leftView.frame = CGRectMake(0, 0, kSearchBarTextInset, kSearchBarHeight);
    self.searchBar.rightView.frame = CGRectMake(self.searchBar.bounds.size.width - kSearchBarTextInset, 0, kSearchBarTextInset, kSearchBarHeight);
    
    self.resultsView.frame = CGRectMake(kTableViewOffsetX, kTableViewOffsetY,
                                        self.view.bounds.size.width - 2*kTableViewOffsetX,
                                        self.view.bounds.size.height - kTableViewOffsetY);
}

- (UITextField *)searchBar
{
    if (_searchBar == nil) {
        _searchBar = [[UITextField alloc] init];
        _searchBar.font = [UIFont systemFontOfSize:14.0];
        _searchBar.placeholder = @"Search";

        UIView *leftView = [[UIView alloc] init];
        UIView *rightView = [[UIView alloc] init];
        
        leftView.backgroundColor = _searchBar.backgroundColor;
        rightView.backgroundColor = _searchBar.backgroundColor;
        
        _searchBar.leftView = leftView;
        _searchBar.rightView = rightView;
        
        _searchBar.leftViewMode = UITextFieldViewModeAlways;
        _searchBar.rightViewMode = UITextFieldViewModeAlways;
        
    }
    return _searchBar;
}

- (UIButton *)closeButton
{
    if (_closeButton == nil) {
        _closeButton = [[CNCloseButton alloc] initWithColor:[UIColor whiteColor]];;
        [_closeButton addTarget:self action:@selector(closeButtonPressed:)
               forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}

- (UILabel *)titleLabel
{
    if (_titleLabel == nil) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text  = @"Search Classes";
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont cnSystemFontOfSize:16];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    
    return _titleLabel;
}

- (UITableView *)resultsView
{
    if (_resultsView == nil) {
        _resultsView = [[UITableView alloc] init];
        _resultsView.delegate = self;
        _resultsView.dataSource = self;
        [_resultsView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        _resultsView.backgroundColor = [UIColor whiteColor];
        [_resultsView setSeparatorInset:UIEdgeInsetsMake(0, 20, 0, 0)];
        _resultsView.sectionIndexBackgroundColor = [UIColor redColor];
        _resultsView.sectionIndexColor = [UIColor yellowColor];
        _resultsView.separatorInset = UIEdgeInsetsMake(0, kSearchBarOffsetX, 0, 0);
    }
    return _resultsView;
}

- (void)closeButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger numberOfSection = 0;
    if (self.departmentsForLastSearch.count > 0) {
        numberOfSection++;
    }
    
    if (self.coursesForLastSearch.count > 0) {
        numberOfSection++;
    }
    
    return numberOfSection;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([self isDepartmentsSection:section]) {
        return self.departmentsForLastSearch.count;
    } else if ([self isCoursesSection:section]) {
        return self.coursesForLastSearch.count;
    }
    
    NSLog(@"Requesting invalid section! departments = %@, courses = %@", self.departmentsForLastSearch, self.coursesForLastSearch);
    return 0;
}

- (BOOL)isDepartmentsSection:(NSInteger)section
{
    return section == 0 && self.departmentsForLastSearch.count > 0;
}

- (BOOL)isCoursesSection:(NSInteger)section
{
    return  (section == 0 && self.departmentsForLastSearch.count == 0 && self.coursesForLastSearch.count > 0) ||
            (section == 1 && self.departmentsForLastSearch.count > 0 && self.coursesForLastSearch.count > 0);
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([self isDepartmentsSection:section]) {
        return @"Departments";
    } else if ([self isCoursesSection:section]) {
        return @"Courses";
    }
    
    NSLog(@"Requesting invalid section! departments = %@, courses = %@", self.departmentsForLastSearch, self.coursesForLastSearch);
    return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    header.contentView.backgroundColor = [UIColor opaqueWhiteWithIntensity:240];
    [header.textLabel setTextColor:[UIColor opaqueWhiteWithIntensity:172]];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 32.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self isDepartmentsSection:indexPath.section]) {
        return kDepartmentsResultsCellHeight;
    } else {
        return kCoursesResultsCellHeight;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CNSearchResultsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"search"];
    if (cell == nil) {
        cell = [[CNSearchResultsCell alloc] init];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:12.0];
    }
    
    NSString *title = nil;
    if ([self isDepartmentsSection:indexPath.section]) {
        title = [[self.departmentsForLastSearch objectAtIndex:indexPath.row] name];
    } else if ([self isCoursesSection:indexPath.section]) {
        title = [[self.coursesForLastSearch objectAtIndex:indexPath.row] name];
    } else {
        NSLog(@"Requesting invalid cell for indexpath =%@ ! departments = %@, courses = %@",
              indexPath, self.departmentsForLastSearch, self.coursesForLastSearch);
    }

    NSString *subtitle = nil;
    if ([self isCoursesSection:indexPath.section]){
        CNCourse *course = [self.coursesForLastSearch objectAtIndex:indexPath.row];
        subtitle = [self.courseDepartmentNameByIDLookup objectForKey:course.departmentId];
    }

    [cell setTitle:title subtitle:subtitle searchTerms:self.lastUsedSearchTerms];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self isDepartmentsSection:indexPath.section]) {
        CNSchool *school = [CNUserProfile defaultSchool];
        NSMutableArray *searchResults = [NSMutableArray arrayWithObject:school];
        id <CNModel> model = [self.departmentsForLastSearch objectAtIndex:indexPath.row];
        [searchResults addObject:model];
        [self.searchDelegate buildUIForSearchResults:searchResults];
        [self dismissViewControllerAnimated:YES completion:nil];
    } else if ([self isCoursesSection:indexPath.section]) {
        CNCourse *course = [self.coursesForLastSearch objectAtIndex:indexPath.row];
        CNCourseDetailsViewController *nextVC = [[CNCourseDetailsViewController alloc] init];
        nextVC.course = course;
        nextVC.modalPresentationStyle = UIModalPresentationFullScreen;
        nextVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [self presentViewController:nextVC animated:YES completion:nil];
    } else {
        NSLog(@"Requesting invalid cell for indexpath =%@ ! departments = %@, courses = %@",
              indexPath, self.departmentsForLastSearch, self.coursesForLastSearch);
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

@end
