//
//  CNWelcomeViewController.m
//  ClassNinja
//
//  Created by Boris Suvorov on 7/27/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNWelcomeViewController.h"
#import "CNGenericSelectionViewController.h"
#import "CNSiongNavigationViewController.h"
#import "CNAPIClient.h"
#import "AppearanceConstants.h"

@interface CNWelcomeViewController ()

@property (nonatomic) UITableViewController *tableViewController;
@property (nonatomic) CNWelcomeStatusView *statusView;

@end

@implementation CNWelcomeViewController

#pragma mark - UIViewController lifecycle

- (void)didReceiveMemoryWarning
{
    // TODO: implement this
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)viewDidAppear:(BOOL)animated
{
    self.view.backgroundColor = [UIColor colorWithRed:27/255.0 green:127/255.0 blue:247/255.0 alpha:1.0];
    [super viewDidAppear:animated];
    [self setNeedsStatusBarAppearanceUpdate];
    [[CNAPIClient sharedInstance] list:[CNTarget class]
                            authPolicy:CNForceAuthenticationOnAuthFailure
                            completion:^(NSArray *targets) {
        NSLog(@"Targets: %@", targets);
    }];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self.statusView setNeedsLayout];
    [self.statusView layoutIfNeeded];
    dispatch_async(dispatch_get_main_queue(), ^{
        // Let all the layout for the statusView settle and set the tableHeaderView
        // on the next iteration of the runloop.
        [self.tableViewController.tableView setTableHeaderView:self.statusView];
    });
}

#pragma mark - Updating UI with Data

- (void)setStatus:(NSString *)newStatus
{
    if ([self.statusView.statusLabel.text isEqualToString:newStatus]) return;
    
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        self.statusView.statusLabel.alpha = 0;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:ANIMATION_DURATION animations:^{
            self.statusView.statusLabel.text = newStatus;
            [self.statusView setNeedsLayout];
            [self.statusView layoutIfNeeded];
            
            [self.tableViewController.tableView beginUpdates];
            [self.tableViewController.tableView setTableHeaderView:self.statusView];
            [self.tableViewController.tableView endUpdates];
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:ANIMATION_DURATION animations:^{
                self.statusView.statusLabel.alpha = 1;
            }];
        }];
    }];
}

#pragma mark - Subview Setup

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.view.backgroundColor = WELCOME_BLUE_COLOR;
    
    self.tableViewController = [[UITableViewController alloc] init];
    [self addChildViewController:self.tableViewController];
    [self.view addSubview:self.tableViewController.tableView];
    [self.tableViewController didMoveToParentViewController:self];
    self.tableViewController.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableViewController.tableView.backgroundColor = [UIColor clearColor];
    NSLayoutConstraint *top = [NSLayoutConstraint constraintWithItem:_tableViewController.tableView
                                                           attribute:NSLayoutAttributeTop
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:self.view
                                                           attribute:NSLayoutAttributeTop
                                                          multiplier:1.0
                                                            constant:0.0];
    NSLayoutConstraint *bottom = [NSLayoutConstraint constraintWithItem:_tableViewController.tableView
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.view
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1.0
                                                               constant:0.0];
    NSLayoutConstraint *left = [NSLayoutConstraint constraintWithItem:_tableViewController.tableView
                                                            attribute:NSLayoutAttributeLeft
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:self.view
                                                            attribute:NSLayoutAttributeLeft
                                                           multiplier:1.0
                                                             constant:0.0];
    NSLayoutConstraint *right = [NSLayoutConstraint constraintWithItem:_tableViewController.tableView
                                                             attribute:NSLayoutAttributeRight
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self.view
                                                             attribute:NSLayoutAttributeRight
                                                            multiplier:1.0
                                                              constant:0.0];
    [self.view addConstraints:@[top, bottom, left, right]];
    
    
    self.statusView = [[CNWelcomeStatusView alloc] initWithDelegate:self];
    [self.tableViewController.tableView setTableHeaderView:self.statusView];
    top = [NSLayoutConstraint constraintWithItem:self.statusView
                                 attribute:NSLayoutAttributeTop
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:self.tableViewController.tableView
                                 attribute:NSLayoutAttributeTop
                                multiplier:1.0
                                  constant:0.0];
    left = [NSLayoutConstraint constraintWithItem:self.statusView
                                       attribute:NSLayoutAttributeLeft
                                       relatedBy:NSLayoutRelationEqual
                                          toItem:self.tableViewController.tableView
                                       attribute:NSLayoutAttributeLeft
                                      multiplier:1.0
                                        constant:0.0];
    right = [NSLayoutConstraint constraintWithItem:self.statusView
                                       attribute:NSLayoutAttributeRight
                                       relatedBy:NSLayoutRelationEqual
                                          toItem:self.tableViewController.tableView
                                       attribute:NSLayoutAttributeRight
                                      multiplier:1.0
                                        constant:0.0];
    NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:self.statusView
                                         attribute:NSLayoutAttributeWidth
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:self.tableViewController.tableView
                                         attribute:NSLayoutAttributeWidth
                                        multiplier:1.0
                                          constant:0.0];
    [self.view addConstraints:@[top, left, right, width]];
    
    [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(testAnimation) userInfo:nil repeats:YES];
}

- (void)testAnimation
{
    NSArray *statuses = @[@"This is a short string.",
                          @"Holy tits, look at this awesome animation. It's super smooth with multiple lines and shit.",
                          @"The long string instrument is an instrument where the string is of such a length that the fundamental transverse wave is below what we can hear as a tone (±20 Hz). If the tension and the length result in sounds with such a frequency the tone becomes a beating frequency ranging from a short reverb (approx 5–10 meters) to longer echo sounds (longer than 10 meter). Besides the beating frequency, the string also gives higher pitched natural overtones. Since the length is that long this has an effect on the attack tone.",
                          @"Orientation flipping also works."];
    [self setStatus:[statuses objectAtIndex:rand()%statuses.count]];
}

- (void)addClassesButtonPressed:(id)sender
{
    CNSchoolViewController *schoolVC = [[CNSchoolViewController alloc] init];
    CNSiongNavigationViewController *navController = [[CNSiongNavigationViewController alloc] initWithRootViewController:schoolVC];
    navController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:navController animated:YES completion:nil];
}

@end
