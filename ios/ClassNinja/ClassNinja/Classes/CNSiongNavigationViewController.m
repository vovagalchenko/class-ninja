//
//  CNSiongNavigationViewController.m
//  ClassNinja
//
//  Created by Boris Suvorov on 7/27/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNSiongNavigationViewController.h"
#import "AppearanceConstants.h"

#define kScrollYOffset 75.0

#define kBackButtonWidth 22
#define kButtonOriginX 20
#define kButtonOriginY 35

#define kLeftBoundsOffset 24.0
#define kSpaceBetweenViews (kLeftBoundsOffset/2.0)


#define kPushDuration 0.3

@interface CNSiongNavigationViewController () <UIScrollViewDelegate>
@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) UIButton *backButton;
@property (nonatomic) UILabel *headerLabel;
@property (nonatomic) NSMutableArray *viewControllers;
@property (nonatomic) NSUInteger currentPageIndex;
@property (nonatomic) UIView *leftBlendedView;
@property (nonatomic) UIView *rightBlendedView;

@property (nonatomic) BOOL firstLoad;
@end

@implementation CNSiongNavigationViewController

- (id)initWithRootViewController:(UIViewController<SiongNavigationProtocol> *)rootViewController
{
    self = [super init];
    if (self) {
        _viewControllers = [NSMutableArray array];
        [_viewControllers addObject:rootViewController];
        
        rootViewController.siongNavigationController = self;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = SIONG_NAVIGATION_CONTROLLER_BACKGROUND_COLOR;
    
    [self.view addSubview:self.backButton];
    [self.view addSubview:self.headerLabel];
    [self.view addSubview:self.scrollView];
    
    // always last
    [self.view addSubview:self.leftBlendedView];
    [self.view addSubview:self.rightBlendedView];
    
    UIViewController *vc = [self.viewControllers firstObject];
    [self.scrollView addSubview:vc.view];
}

- (UIView *)createGenericBlendedView
{
    UIView *view = [[UIView alloc] init];
    view.alpha = 0.5;
    view.backgroundColor = SIONG_NAVIGATION_CONTROLLER_BACKGROUND_COLOR;

    return view;
}

- (UIView *)leftBlendedView
{
    if (_leftBlendedView == nil) {
        _leftBlendedView = [self createGenericBlendedView];
    }
    return _leftBlendedView;
}

- (UIView *)rightBlendedView
{
    if (_rightBlendedView == nil) {
        _rightBlendedView = [self createGenericBlendedView];
    }
    return _rightBlendedView;
}

- (UIScrollView *)scrollView
{
    if (_scrollView == nil) {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.backgroundColor = [UIColor clearColor];
        _scrollView.showsHorizontalScrollIndicator = NO;
        
        _scrollView.showsVerticalScrollIndicator = YES;
        _scrollView.pagingEnabled = NO;
        _scrollView.delegate = self;
    }
    return _scrollView;
}

- (UILabel *)headerLabel
{
    if (_headerLabel == nil) {
        _headerLabel = [[UILabel alloc] init];
        _headerLabel.textColor = [UIColor colorWithRed:32/255.0 green:48/255.0 blue:66/255.0 alpha:1.0];
        _headerLabel.text = @"Add Class";
        _headerLabel.font = [UIFont cnSystemFontOfSize:14];
        _headerLabel.userInteractionEnabled = NO;
        _headerLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _headerLabel;
}

- (UIButton *)backButton
{
    if (_backButton == nil) {
        _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _backButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        [_backButton setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
        [_backButton addTarget:self
                        action:@selector(backButtonPressed:)
              forControlEvents:UIControlEventTouchUpInside];
        
        _backButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_backButton setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [_backButton setContentCompressionResistancePriority:UILayoutPriorityRequired
                                                     forAxis:UILayoutConstraintAxisVertical];
    }
    return _backButton;
}


- (void)backButtonPressed:(id)sender
{
    [self popViewControllerAnimated:YES deselectRows:YES];
}

- (void)viewWillLayoutSubviews
{
    CGRect scrollFrame = self.view.bounds;
    scrollFrame.origin.y += kScrollYOffset;
    scrollFrame.size.height -= kScrollYOffset;
    self.scrollView.frame = scrollFrame;

    CGRect rect = CGRectMake(kButtonOriginX, kButtonOriginY, kBackButtonWidth, kBackButtonWidth);
    self.backButton.frame = rect;
    self.headerLabel.frame = CGRectMake(0, kButtonOriginY, scrollFrame.size.width, 20);

    self.scrollView.contentSize = self.scrollView.frame.size;
    
    self.rightBlendedView.frame = CGRectMake(self.view.bounds.size.width - kSpaceBetweenViews,
                                             0,
                                             kSpaceBetweenViews,
                                             self.view.bounds.size.height);

    self.leftBlendedView.frame = CGRectMake(0,
                                            0,
                                            kSpaceBetweenViews,
                                            self.view.bounds.size.height);
    
    [self layoutViewControllersInScrollView];
}

- (void)layoutViewControllersInScrollView
{
    NSUInteger vcCount = self.viewControllers.count;
    for (NSUInteger vcIndex = 0; vcIndex < vcCount; vcIndex++) {
        UIViewController *vc = [self.viewControllers objectAtIndex:vcIndex];
        vc.view.frame = [self frameForChildVCAtIndex:vcIndex];
    }

    self.scrollView.contentSize = [self scrollViewcontentSizeForVCIndex:self.viewControllers.count - 1];

    [self scrollToIndex:self.currentPageIndex];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    self.currentPageIndex = [self indexOfVisibleViewController];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    NSInteger newPage = self.currentPageIndex;
    if (velocity.x == 0) {
        newPage = [self indexOfPageForContentOffset:targetContentOffset->x];
    } else {
        if (velocity.x > 0) {
            newPage++;
        } else {
            newPage--;
        }
        
        if (newPage < 0) {
            newPage = 0;
        }
        
        if (newPage >= self.viewControllers.count) {
            newPage = self.viewControllers.count - 1;
        }
    }
    
    *targetContentOffset = [self targetPointForPageIndex:newPage];
    [self scrollToIndex:newPage];
}

- (NSUInteger)indexOfPageForContentOffset:(CGFloat)contentXOffset
{
    CGFloat midOfPageXOffset = contentXOffset + self.view.bounds.size.width / 2;
    CGFloat interVCWidth =  self.view.bounds.size.width - kLeftBoundsOffset - kSpaceBetweenViews;
    NSUInteger index = (NSUInteger)((midOfPageXOffset / interVCWidth));
    return index;
}

- (NSUInteger)indexOfVisibleViewController
{
    return [self indexOfPageForContentOffset:self.scrollView.contentOffset.x];
}



- (CGPoint)targetPointForPageIndex:(NSUInteger)index
{
    CGFloat interVCWidth =  self.view.bounds.size.width - kLeftBoundsOffset - kSpaceBetweenViews;
    CGPoint newContentOffset = CGPointMake(index * interVCWidth, 0);
    return newContentOffset;
}

- (void)scrollToIndex:(NSUInteger)index
{
    self.currentPageIndex = index;
    // I wanted to keep contant velocity for all the kinds of scrolling to index page.
    // user might select next view controller, or drag to the next one.
    // thus in this two scenarios distance is going to be different.
    // V = pushDistance / kPushDuration.
    // We want V to be const for all kinds of scrolling to the next page (next VC)
    // Thus for drag induced scrolls we have following formula for duration:
    // duration = currentScrollDistance * (kPushDuration / viewControllerPushDistance)
    CGFloat viewControllerPushDistance = [self childVCWidth];
    CGPoint targetPoint = [self targetPointForPageIndex:index];
    CGFloat currentScrollDistance = fabs(self.scrollView.contentOffset.x  - targetPoint.x);
    CGFloat duration = currentScrollDistance * kPushDuration / viewControllerPushDistance;

    // UIViewAnimationOptionCurveLinear option also felt good IMO
    UIViewAnimationOptions animationOptions = UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState;
    [UIView animateWithDuration:duration
                          delay:0
                        options:animationOptions
                     animations:^{ self.scrollView.contentOffset = targetPoint; }
                     completion:nil];
}

- (void)pushViewController:(UIViewController<SiongNavigationProtocol> *)viewController
{
    NSUInteger currentVCIndex = [self indexOfVisibleViewController];
    viewController.siongNavigationController = self;

    // dismiss all view controllers to the right of current VC
    [self popViewControllerAtIndex:currentVCIndex + 1 animated:NO deselectRows:NO];
    
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
    CGSize contentSize = self.scrollView.bounds.size;
    CGFloat vcWidth = [self childVCWidth];
    contentSize.width = kLeftBoundsOffset + (vcWidth) * (vcIndex+1) + vcIndex * kSpaceBetweenViews + kLeftBoundsOffset;
    return contentSize;
}

- (CGRect)frameForChildVCAtIndex:(NSUInteger)vcIndex
{
    CGFloat vcWidth = [self childVCWidth];
    CGFloat x = kLeftBoundsOffset + (vcWidth + kSpaceBetweenViews) * vcIndex;
    return CGRectMake(x, 0, vcWidth, self.scrollView.bounds.size.height);
}

- (CGFloat)childVCWidth
{
    return self.view.bounds.size.width - 2*kLeftBoundsOffset;
}

-(UIViewController *)popViewControllerAtIndex:(NSUInteger)vcIndex
                         animated:(BOOL)animated
                         deselectRows:(BOOL)deselectRows
{
    UIViewController *resultVC = nil;
    NSInteger vcCount = self.viewControllers.count;

    if (vcIndex >= vcCount){
        return nil;
    }
    
    resultVC = [self.viewControllers objectAtIndex:vcIndex];
    
    if (vcIndex >= 1) {
        dispatch_block_t completionBlock = ^{
            for (NSInteger i = vcCount-1; i >= vcIndex; i--) {
                UIViewController <SiongNavigationProtocol> *currentVC = [self.viewControllers objectAtIndex:i];
                [currentVC.view removeFromSuperview];
                [self.viewControllers removeObjectAtIndex:i];
            }
            
            self.currentPageIndex = self.viewControllers.count - 1;
        };
        
        NSInteger targetVCIndex = vcIndex - 1;
        if (deselectRows) {
            for (NSInteger i = vcCount-2; i >= targetVCIndex; i--) {
                UIViewController <SiongNavigationProtocol> *vc = [self.viewControllers objectAtIndex:i];
                if ([vc respondsToSelector:@selector(nextViewControllerWillPop)]) {
                    [vc nextViewControllerWillPop];
                }
            }
        }
        
        if (animated) {
            [UIView animateWithDuration:0.3 animations:^{
                self.scrollView.contentSize = [self scrollViewcontentSizeForVCIndex:targetVCIndex];
            }completion:^(BOOL finished) {
                if (finished) {
                    completionBlock();
                }
            }];
        } else {
            self.scrollView.contentSize = [self scrollViewcontentSizeForVCIndex:targetVCIndex];
            completionBlock();
        }
    } else {
        [self.presentingViewController dismissViewControllerAnimated:animated completion:nil];
    }
    
    return resultVC;
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated deselectRows:(BOOL)deselectRows
{
    NSUInteger currentPageIndex = [self indexOfVisibleViewController];
    return [self popViewControllerAtIndex:currentPageIndex animated:animated deselectRows:deselectRows];
}

- (UIViewController *)topViewController
{
    return [self.viewControllers lastObject];
}

@end
