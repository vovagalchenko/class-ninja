//
//  CNCourseViewController.m
//  ClassNinja
//
//  Created by Boris Suvorov on 7/27/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNCourseViewController.h"
#import "CNAPIClient.h"

@interface CNCourseViewController ()
@property (nonatomic) UITableView *tableView;
@property (nonatomic) NSArray *courses;
@end

@implementation CNCourseViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView = [[UITableView alloc] init];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight;
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
    [client listCoursesForDepartment:self.department
                 withCompletionBlock:^(NSArray *courses) {
                     self.courses = courses;
                    [self.tableView reloadData];
                 }];
}

#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return self.courses.count;
    } else {
        NSLog(@"Invalid section request");
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"coursecell"];
    CNDepartment *course =[self.courses objectAtIndex:indexPath.row];
    cell.textLabel.text = course.name;
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.siongNavigationController popViewControllerAnimated:YES];
}

@end