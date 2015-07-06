//
//  CNContainerViewController.m
//  ClassNinja
//
//  Created by Boris Suvorov on 11/16/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNContainerViewController.h"
#import "CNUserProfile.h"
#import "CNDashboardViewController.h"
#import "CNSiongsTernaryViewController.h"

@interface CNContainerViewController ()
@property (nonatomic) CNDashboardViewController *dashboardVC;
@end

@implementation CNContainerViewController

- (void)addChildVC:(UIViewController *)vc
{
    [self addChildViewController:vc];
    [self.view addSubview:vc.view];
}

- (instancetype)init
{
    self = [super init];
    self.dashboardVC = [[CNDashboardViewController alloc] init];
    
    if ([CNUserProfile isFreshInstall]) {
        CNFirstPageViewController *firstPageVC = [[CNFirstPageViewController alloc] init];
        __weak CNFirstPageViewController *weakVC = firstPageVC;

        firstPageVC.completionBlock = ^{
            [UIView transitionFromView:weakVC.view
                                toView:self.dashboardVC.view
                              duration:0.3f
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            completion:^(BOOL finished){
                                [weakVC willMoveToParentViewController:nil];
                                [weakVC.view removeFromSuperview];
                                [weakVC removeFromParentViewController];
                                [weakVC didMoveToParentViewController:nil];

                                [self addChildVC:self.dashboardVC];

                                // present siongs VC in the next runloop
                                [self.dashboardVC performSelector:@selector(presentSchoolVC) withObject:nil afterDelay:0];
                            }];
        };
        
        [self addChildVC:firstPageVC];
    } else {
        [self addChildVC:self.dashboardVC];
    }

    return self;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end
