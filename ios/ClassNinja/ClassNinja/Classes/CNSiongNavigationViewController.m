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
    self.scrollView.contentSize = self.scrollView.frame.size;
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
        [self popViewControllerAnimated:NO];
    }
    
    if ([self.viewControllers indexOfObject:viewController] == NSNotFound) {
        [self.viewControllers addObject:viewController];
    }
    
    NSUInteger vcIndex = self.viewControllers.count - 1;
    viewController.view.frame = [self frameForChildVCAtIndex:vcIndex];
    self.scrollView.contentSize = [self scrollViewcontentSizeForVCIndex:vcIndex];

    [self.scrollView addSubview:viewController.view];
    [self scrollToIndex:vcIndex];
}

- (CGSize)scrollViewcontentSizeForVCIndex:(NSUInteger)vcIndex
{
    CGSize contentSize = self.view.bounds.size;
    CGFloat vcWidth = [self childVCWidth];
    contentSize.width = kLeftBoundsOffset + (vcWidth) * (vcIndex+1) + vcIndex * kSpaceBetweenViews + kLeftBoundsOffset;
    return contentSize;
}

- (CGRect)frameForChildVCAtIndex:(NSUInteger)vcIndex
{
    CGFloat vcWidth = [self childVCWidth];
    CGFloat x = kLeftBoundsOffset + (vcWidth + kSpaceBetweenViews) * vcIndex;
    return CGRectMake(x, 0, vcWidth, self.view.bounds.size.height);
}

- (CGFloat)childVCWidth
{
    return self.view.bounds.size.width - 2*kLeftBoundsOffset;
}



- (UIViewController *)popViewControllerAnimated:(BOOL)animated
{
    UIViewController *resultVC = self.topViewController;
    
    NSUInteger vcIndex = self.viewControllers.count - 2;
    dispatch_block_t completionBlock = ^{
        [resultVC.view removeFromSuperview];
        [self.viewControllers removeLastObject];
    };
    
    
    if (animated) {
        [UIView animateWithDuration:0.3 animations:^{
            self.scrollView.contentSize = [self scrollViewcontentSizeForVCIndex:vcIndex];
        }completion:^(BOOL finished) {
            if (finished) {
                completionBlock();
            }
        }];
    } else {
        self.scrollView.contentSize = [self scrollViewcontentSizeForVCIndex:vcIndex];
        completionBlock();
    }
    
    return resultVC;
}

- (UIViewController *)topViewController
{
    return [self.viewControllers lastObject];
}

@end
