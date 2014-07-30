//
//  CNWelcomeViewController.m
//  ClassNinja
//
//  Created by Boris Suvorov on 7/27/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNWelcomeViewController.h"
#import "CNSchoolViewController.h"
#import "CNSiongNavigationViewController.h"

@interface CNWelcomeViewController ()
@property (nonatomic) UILabel *statusLabel;
@property (nonatomic) UILabel *welcomeLabel;
@property (nonatomic) UIButton *addClassesButton;
@end

@implementation CNWelcomeViewController

- (instancetype)init
{
    self = [super init];
    if(self) {
        self.view.backgroundColor = [UIColor colorWithRed:27/255.0 green:127/255.0 blue:247/255.0 alpha:1.0];
    }
    
    [self.view addSubview:self.welcomeLabel];
    [self.view addSubview:self.statusLabel];
    [self.view addSubview:self.addClassesButton];
    
    return self;
}

- (UIButton *)addClassesButton
{
    if (_addClassesButton == nil) {
        _addClassesButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _addClassesButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [_addClassesButton setTitle:@"+ Add classes" forState:UIControlStateNormal];
        [_addClassesButton setTitle:@"+ Add classes" forState:UIControlStateHighlighted];
        [_addClassesButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_addClassesButton setTitleColor:[UIColor yellowColor] forState:UIControlStateHighlighted];
        _addClassesButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
        [_addClassesButton addTarget:self action:@selector(addClassesButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _addClassesButton;
}

- (UILabel *)statusLabel
{
    if (_statusLabel == nil) {
        _statusLabel = [[UILabel alloc] init];
        _statusLabel.font = [UIFont systemFontOfSize:18.0];
        _statusLabel.text = @"Here are the classes you're tracking for this semester";
        _statusLabel.textColor = [UIColor whiteColor];
        _statusLabel.numberOfLines = 5;
    }
    return _statusLabel;
}

- (UILabel *)welcomeLabel
{
    if (_welcomeLabel == nil) {
        _welcomeLabel = [[UILabel alloc] init];
        _welcomeLabel.font = [UIFont systemFontOfSize:25.0];
        _welcomeLabel.text = @"Hello";
        _welcomeLabel.textColor = [UIColor whiteColor];
    }
    return _welcomeLabel;
}

- (void)viewWillLayoutSubviews
{
    self.welcomeLabel.frame = CGRectMake(25, 50, 70, 30);
    self.statusLabel.frame = CGRectMake(25, 100, 270, 60);
    self.addClassesButton.frame = CGRectMake(25, 170, 120, 40);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)addClassesButtonPressed:(id)sender
{
    CNSchoolViewController *deptVC = [[CNSchoolViewController alloc] init];
    CNSiongNavigationViewController *navController = [[CNSiongNavigationViewController alloc] initWithRootViewController:deptVC];
    navController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
