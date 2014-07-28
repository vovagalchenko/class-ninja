//
//  CNSchoolViewController.m
//  ClassNinja
//
//  Created by Boris Suvorov on 7/29/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNSchoolViewController.h"
#import "CNDepartmentViewController.h"
#import "CNAPIClient.h"

@interface CNSchoolViewController ()
@property (nonatomic) UITableView *tableView;

@property (nonatomic) NSArray *schools;
@end

@implementation CNSchoolViewController

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

- (void)loadContent
{
    CNAPIClient *client = [CNAPIClient sharedInstance];
    [client list:[CNSchool class]
      completion:^(NSArray *schools) {
          self.schools = schools;
          [self.tableView reloadData];
      }];
}

#pragma mark Collation related methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.schools.count;
}


#pragma Cell management
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"schoolcell"];
    CNSchool *school = [self.schools objectAtIndex:indexPath.row];
    cell.textLabel.text = school.name;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CNDepartmentViewController *departmentVC = [[CNDepartmentViewController alloc] init];
    departmentVC.school = [self.schools objectAtIndex:indexPath.row];
    [self.siongNavigationController pushViewController:departmentVC];
}

@end
