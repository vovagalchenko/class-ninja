//
//  CNDepartmentViewController.m
//  ClassNinja
//
//  Created by Boris Suvorov on 7/27/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNDepartmentViewController.h"
#import "CNCourseViewController.h"
#import "CNAPIClient.h"

@interface CNDepartmentViewController ()
@property (nonatomic) UITableView *tableView;

@property (nonatomic) NSMutableArray *departmentsByCollationIndex;
@property (nonatomic) NSMutableOrderedSet *enUSCollation;

@end

@implementation CNDepartmentViewController

- (id)init
{
    self = [super init];
    if (self) {
        _enUSCollation = [[NSMutableOrderedSet alloc] init];
        _departmentsByCollationIndex = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView = [[UITableView alloc] init];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.view.autoresizingMask = UIViewAutoresizingNone;
    [self.view addSubview:self.tableView];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.tableView.frame = self.view.bounds;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self loadContent];
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

- (void)loadContent
{
    CNAPIClient *client = [CNAPIClient sharedInstance];
    [client listChildren:self.school
              completion:^(NSArray *departments) {
        [self collateDepartmentsByName:departments];
        [self.tableView reloadData];
    }];
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
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"deparmentcell"];
    NSArray *collatedDepartments = [self.departmentsByCollationIndex objectAtIndex:indexPath.section];
    CNDepartment *dept = [collatedDepartments objectAtIndex:indexPath.row];
    cell.textLabel.text = dept.name;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CNCourseViewController *courseVC = [[CNCourseViewController alloc] init];
    NSArray *collatedDepartments = [self.departmentsByCollationIndex objectAtIndex:indexPath.section];
    courseVC.department = [collatedDepartments objectAtIndex:indexPath.row];
    
    [self.siongNavigationController pushViewController:courseVC];
}

@end
