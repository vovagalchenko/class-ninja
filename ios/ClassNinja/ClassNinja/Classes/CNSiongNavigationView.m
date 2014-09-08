//
//  CNSiongNavigationView.m
//  ClassNinja
//
//  Created by Boris Suvorov on 8/9/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNSiongNavigationView.h"
#import "CNUserProfile.h"

#define kScrollYOffset 75.0

#define kBackButtonWidth 44
#define kButtonOriginX 9
#define kButtonOriginY 24


#define kSearchButtonWidth 44
#define kSearchButtonPaddingX 9
#define kSearchButtonPaddingY 24

#define kNavbarTitleOriginX (kButtonOriginX + kBackButtonWidth + 5)
#define kNavbarTitlePaddingX (kSearchButtonWidth + kSearchButtonPaddingX + 5)

#define kHeaderOriginY 35

#define kLeftBoundsOffset 24.0
#define kSpaceBetweenViews (kLeftBoundsOffset/2.0)

#define kPushDuration 0.3

#define kAlphaForViewsOnSides 0.5

@interface CNSiongNavigationView () <UIScrollViewDelegate>

@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) UIButton *backButton;
@property (nonatomic) UIButton *searchButton;
@property (nonatomic) UILabel *headerLabel;
@property (nonatomic) NSMutableArray *scrollViews;
@property (nonatomic) BOOL didSetFrames;
@end

@implementation CNSiongNavigationView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = SIONG_NAVIGATION_CONTROLLER_BACKGROUND_COLOR;
        _scrollViews = [[NSMutableArray alloc] init];
        
        [self addSubview:self.backButton];
        [self addSubview:self.searchButton];
        [self addSubview:self.headerLabel];
        [self addSubview:self.scrollView];
        
        [self.scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (void)dealloc
{
    [self.scrollView removeObserver:self forKeyPath:@"contentOffset"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    UIView *leftView = nil;
    UIView *rightView = nil;

    NSInteger index = self.currentPageIndex;
    
    NSInteger leftViewIndex = index - 1;
    NSInteger rightViewIndex = index + 1;

    CGFloat scrollContentOffsetX = self.scrollView.contentOffset.x;
    
    UIView *centerView = [self.scrollViews objectAtIndex:index];
    centerView.alpha = [self alphaViewAtIndex:self.currentPageIndex withScrollViewContentOffsetX:scrollContentOffsetX];
    
    if (leftViewIndex >= 0) {
        leftView = [self.scrollViews objectAtIndex:leftViewIndex];
        leftView.alpha  = [self alphaViewAtIndex:leftViewIndex
                    withScrollViewContentOffsetX:scrollContentOffsetX];
        
    }
    
    if (rightViewIndex < self.scrollViews.count) {
        rightView = [self.scrollViews objectAtIndex:rightViewIndex];
        rightView.alpha = [self alphaViewAtIndex:rightViewIndex
                    withScrollViewContentOffsetX:scrollContentOffsetX];
    }

    self.headerLabel.text = [self.navigationDelegate navbarTitleForIndex:[self indexOfVisibleViewController]];
    self.headerLabel.alpha = [self headerAlphaForViewAtIndex:self.currentPageIndex
                                withScrollViewContentOffsetX:scrollContentOffsetX];
}

#pragma public methods
- (void)pushView:(UIView *)view animated:(BOOL)animated
{
    NSUInteger viewIndex = self.scrollViews.count;
    
    view.frame = [self frameForChildVCAtIndex:viewIndex];
    self.scrollView.contentSize = [self scrollViewcontentSizeForVCIndex:viewIndex];
    
    [self.scrollViews addObject:view];
    [self.scrollView addSubview:view];
    [self scrollToIndex:viewIndex animated:animated];

    [self.searchButton setHidden:([CNUserProfile defaultSchool] == nil)];
}


#pragma mark private helpers

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
        _headerLabel.font = [UIFont cnSystemFontOfSize:14];
        _headerLabel.text = @"Add class";
        _headerLabel.userInteractionEnabled = NO;
        _headerLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _headerLabel;
}

- (UIButton *)searchButton
{
    if (_searchButton == nil) {
        _searchButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_searchButton setImage:[UIImage imageNamed:@"search"] forState:UIControlStateNormal];
        [_searchButton addTarget:self.navigationDelegate
                          action:@selector(searchButtonPressed:)
                forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _searchButton;
}

- (UIButton *)backButton
{
    if (_backButton == nil) {
        _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _backButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        [_backButton setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
        [_backButton addTarget:self.navigationDelegate
                        action:@selector(backButtonPressed:)
              forControlEvents:UIControlEventTouchUpInside];
        
        _backButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_backButton setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [_backButton setContentCompressionResistancePriority:UILayoutPriorityRequired
                                                     forAxis:UILayoutConstraintAxisVertical];
    }
    return _backButton;
}


- (void)layoutSubviews
{
    if (self.didSetFrames == NO) {
        self.didSetFrames = YES;
        CGRect scrollFrame = self.bounds;
        scrollFrame.origin.y += kScrollYOffset;
        scrollFrame.size.height -= kScrollYOffset;
        self.scrollView.frame = scrollFrame;
        
        CGRect rect = CGRectMake(kButtonOriginX, kButtonOriginY, kBackButtonWidth, kBackButtonWidth);
        self.backButton.frame = rect;
        self.headerLabel.frame = CGRectMake(kNavbarTitleOriginX, kHeaderOriginY, scrollFrame.size.width - kNavbarTitleOriginX - kNavbarTitlePaddingX, 20);
        
        self.searchButton.frame = CGRectMake(self.bounds.size.width - kSearchButtonWidth - kSearchButtonPaddingX,
                                             kSearchButtonPaddingY,
                                             kSearchButtonWidth, kSearchButtonWidth);
        
        self.scrollView.contentSize = self.scrollView.frame.size;
        
        [self layoutViewControllersInScrollView];
    }
    
    [super layoutSubviews];
}

- (void)layoutViewControllersInScrollView
{
    NSUInteger vcCount = self.scrollViews.count;
    for (NSUInteger vcIndex = 0; vcIndex < vcCount; vcIndex++) {
        UIView *view = [self.scrollViews objectAtIndex:vcIndex];
        view.frame = [self frameForChildVCAtIndex:vcIndex];
    }
    
    self.scrollView.contentSize = [self scrollViewcontentSizeForVCIndex:self.scrollViews.count - 1];
    
    [self scrollToIndex:self.currentPageIndex animated:NO];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    self.currentPageIndex = [self indexOfVisibleViewController];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset
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
        
        NSUInteger subviewCount = self.scrollViews.count;
        if (newPage >= subviewCount) {
            newPage = subviewCount - 1;
        }
    }
    
    *targetContentOffset = [self targetPointForPageIndex:newPage];
    [self scrollToIndex:newPage animated:YES];
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
    return self.bounds.size.width - 2*kLeftBoundsOffset;
}


- (CGFloat)headerAlphaForViewAtIndex:(NSUInteger)index withScrollViewContentOffsetX:(CGFloat)contentXOffset
{
    CGPoint basePoint = [self targetPointForPageIndex:index];
    CGFloat interVCWidth =  self.bounds.size.width - kLeftBoundsOffset - kSpaceBetweenViews;
    CGFloat alpha = fabs(1- 2*(fabs((contentXOffset - basePoint.x)) / interVCWidth));
    // hack to prevent showing navbar title when scrolling between two views and having
    // same navbar title fade out and fade in again.
    // This has also an upside of having no title when views take almost equal amount of space on the screen
    if (alpha < 0.04) {
        alpha = 0;
    }
    return (alpha < 1.0) ? alpha : 1;
}


- (CGFloat)alphaViewAtIndex:(NSUInteger)index withScrollViewContentOffsetX:(CGFloat)contentXOffset
{
    CGPoint basePoint = [self targetPointForPageIndex:index];
    CGFloat interVCWidth =  self.bounds.size.width - kLeftBoundsOffset - kSpaceBetweenViews;
    CGFloat alpha = 1 - 0.5 * (fabs((contentXOffset - basePoint.x)) / interVCWidth);
    return (alpha < 1.0) ? alpha : 1;
}

- (NSUInteger)indexOfPageForContentOffset:(CGFloat)contentXOffset
{
    CGFloat midOfPageXOffset = contentXOffset + self.bounds.size.width / 2;
    CGFloat interVCWidth =  self.bounds.size.width - kLeftBoundsOffset - (kSpaceBetweenViews / 2);
    NSUInteger index = (NSUInteger)((midOfPageXOffset / interVCWidth));
    return index;
}

- (NSUInteger)indexOfVisibleViewController
{
    return [self indexOfPageForContentOffset:self.scrollView.contentOffset.x];
}

- (CGPoint)targetPointForPageIndex:(NSUInteger)index
{
    CGFloat interVCWidth =  self.bounds.size.width - kLeftBoundsOffset - kSpaceBetweenViews;
    CGPoint newContentOffset = CGPointMake(index * interVCWidth, 0);
    return newContentOffset;
}

- (void)scrollToIndex:(NSUInteger)index animated:(BOOL)animated
{
    self.currentPageIndex = index;
    CGPoint targetPoint = [self targetPointForPageIndex:index];
    dispatch_block_t localCompletion = ^{
        self.scrollView.contentOffset = targetPoint;
    };
    
    if (animated) {
        // I wanted to keep contant velocity for all the kinds of scrolling to index page.
        // user might select next view controller, or drag to the next one.
        // thus in this two scenarios distance is going to be different.
        // V = pushDistance / kPushDuration.
        // We want V to be const for all kinds of scrolling to the next page (next VC)
        // Thus for drag induced scrolls we have following formula for duration:
        // duration = currentScrollDistance * (kPushDuration / viewControllerPushDistance)
        CGFloat viewControllerPushDistance = [self childVCWidth];
        
        CGFloat currentScrollDistance = fabs(self.scrollView.contentOffset.x  - targetPoint.x);
        CGFloat duration = currentScrollDistance * kPushDuration / viewControllerPushDistance;
        
        // UIViewAnimationOptionCurveLinear option also felt good IMO
        UIViewAnimationOptions animationOptions = UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState;
        [UIView animateWithDuration:duration
                              delay:0
                            options:animationOptions
                         animations:localCompletion
                         completion:nil];
    } else {
        localCompletion();
    }
}


- (void)popViewAtIndex:(NSUInteger)viewIndex
              animated:(BOOL)animated
       completionBlock:(dispatch_block_t)completionBlock
{
    // simple boundary check
    if (viewIndex >= self.scrollViews.count && viewIndex < 1) {
        return;
    }

    self.currentPageIndex = viewIndex - 1;
    
    dispatch_block_t localCompletion = ^{
        // code here should keep using self.scrollViews.count and not any cached value,
        // because it can be async
        NSInteger countOfPoppedViews = self.scrollViews.count - viewIndex;
        for (NSInteger i = 0; i < countOfPoppedViews; i++) {
            [[self.scrollViews lastObject] removeFromSuperview];
            [self.scrollViews removeLastObject];            
        }

        self.scrollView.contentSize = [self scrollViewcontentSizeForVCIndex:self.currentPageIndex];
        [self.searchButton setHidden:([CNUserProfile defaultSchool] == nil)];
        if (completionBlock) {
            completionBlock();
        }
    
    };
    
    if (animated) {
        [UIView animateWithDuration:kPushDuration animations:^{
            self.scrollView.contentOffset = [self targetPointForPageIndex:self.currentPageIndex];
        } completion:^(BOOL finished) {
            localCompletion();
        }];
    } else {
        self.scrollView.contentOffset = [self targetPointForPageIndex:self.currentPageIndex];
        localCompletion();
    }
}

@end
