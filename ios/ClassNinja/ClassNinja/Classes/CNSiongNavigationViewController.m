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

@interface CNSiongNavigationViewController ()
@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) UIButton *backButton;
@property (nonatomic) UILabel *headerLabel;
@property (nonatomic) NSMutableArray *viewControllers;
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
    
    _scrollView = [[UIScrollView alloc] init];
    _scrollView.backgroundColor = [UIColor clearColor];

    [self.view addSubview:self.backButton];
    [self.view addSubview:self.headerLabel];
    [self.view addSubview:self.scrollView];
}

- (UILabel *)headerLabel
{
    if (_headerLabel ==nil) {
        _headerLabel = [[UILabel alloc] init];
        _headerLabel.textColor = [UIColor colorWithRed:32/255.0 green:48/255.0 blue:66/255.0 alpha:1.0];
        _headerLabel.text = @"Add Class";
        _headerLabel.font = [UIFont systemFontOfSize:14];
        _headerLabel.userInteractionEnabled = NO;
        _headerLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _headerLabel;
}

- (UIButton *)backButton
{
    if (_backButton == nil) {
        _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _backButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        _backButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
        _backButton.titleLabel.numberOfLines = 1;
        [_backButton setTitle:@"<" forState:UIControlStateNormal];
        [_backButton setTitle:@"<" forState:UIControlStateHighlighted];
        [_backButton setTitleColor:[UIColor colorWithRed:32/255.0 green:48/255.0 blue:66/255.0 alpha:1.0] forState:UIControlStateNormal];
        [_backButton setTitleColor:[UIColor yellowColor] forState:UIControlStateHighlighted];
        [_backButton addTarget:self
                        action:@selector(backButtonPressed:)
              forControlEvents:UIControlEventTouchUpInside];
        
        _backButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_backButton setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [_backButton setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    }
    return _backButton;
}

- (void)backButtonPressed:(id)sender
{
    [self popViewControllerAnimated:YES];
}

- (void)viewWillLayoutSubviews
{
    CGRect scrollFrame = self.view.bounds;
    scrollFrame.origin.y += kScrollYOffset;
    scrollFrame.size.height -= kScrollYOffset;
    self.scrollView.frame = scrollFrame;

    self.backButton.frame = CGRectMake(0, 0, kScrollYOffset, kScrollYOffset);
    self.headerLabel.frame = CGRectMake(0, 0, scrollFrame.size.width, kScrollYOffset);
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
    CGSize contentSize = self.scrollView.bounds.size;
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
 
    NSUInteger vcCount = self.viewControllers.count;
    if (vcCount >= 2) {
        NSUInteger vcIndex = vcCount - 2;
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
    } else {
        [self dismissViewControllerAnimated:animated completion:nil];
    }
    
    return resultVC;
}

- (UIViewController *)topViewController
{
    return [self.viewControllers lastObject];
}

@end
