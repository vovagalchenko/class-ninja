//
//  CNSiongNavigationViewController.m
//  ClassNinja
//
//  Created by Boris Suvorov on 7/27/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNSiongNavigationViewController.h"

@interface CNSiongNavigationViewController ()
@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic,readwrite,strong) NSMutableArray *viewControllers;
@end

@implementation CNSiongNavigationViewController

- (id)initWithRootViewController:(UIViewController<SiongNavigationProtocol> *)rootViewController
{
    self = [super init];
    if (self) {
        _viewControllers = [NSMutableArray array];
        _scrollView = [[UIScrollView alloc] init];
        [_viewControllers addObject:rootViewController];
        rootViewController.siongNavigationController = self;
        [self.view addSubview:_scrollView];
    }
    return self;
}

- (void)viewWillLayoutSubviews
{
    self.scrollView.frame = self.view.bounds;
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * 3, self.scrollView.frame.size.height);
}

- (void)viewWillAppear:(BOOL)animated
{
    [self pushViewController:[self.viewControllers firstObject]];
}

#define kLeftBoundsOffset 24.0
#define kSpaceBetweenViews (kLeftBoundsOffset/2.0)

- (NSUInteger)indexOfVisibleViewController
{
    CGFloat xOffset = self.scrollView.contentOffset.x;
    CGFloat interVCWidth =  self.view.bounds.size.width - kLeftBoundsOffset - kSpaceBetweenViews;
    NSUInteger index = (NSUInteger)((xOffset / interVCWidth));
    return index;
}

- (void)scrollToIndex:(NSUInteger)index
{
    CGFloat interVCWidth =  self.view.bounds.size.width - kLeftBoundsOffset - kSpaceBetweenViews;
    CGPoint newContentOffset = CGPointMake(index * interVCWidth, 0);
    [self.scrollView setContentOffset:newContentOffset animated:YES];
}

- (void)pushViewController:(UIViewController<SiongNavigationProtocol> *)viewController
{
    NSUInteger currentVCIndex = [self indexOfVisibleViewController];
    viewController.siongNavigationController = self;
    // dismiss all view controllers to the right of current VC
    for (NSUInteger vcIndex = self.viewControllers.count-1; vcIndex > currentVCIndex; vcIndex--) {
        [self popViewController];
    }
    
    if ([self.viewControllers indexOfObject:viewController] == NSNotFound) {
        [self.viewControllers addObject:viewController];
    }
    
    [self.scrollView addSubview:viewController.view];
    
    CGFloat vcIndex = self.viewControllers.count - 1;
    CGSize size = self.view.bounds.size;
    CGFloat vcWidth = size.width - 2*kLeftBoundsOffset;
    CGFloat x = kLeftBoundsOffset + (vcWidth + kSpaceBetweenViews) * vcIndex;
    viewController.view.frame = CGRectMake(x, 0, vcWidth, size.height);
    
    [self scrollToIndex:self.viewControllers.count - 1];
}

- (UIViewController *)popViewController
{
    UIViewController *resultVC = self.topViewController;
    [resultVC.view removeFromSuperview];
    [self.viewControllers removeLastObject];
    return resultVC;
}

- (UIViewController *)topViewController
{
    return [self.viewControllers lastObject];
}

@end
