//
//  CNSiongNavigationView.m
//  ClassNinja
//
//  Created by Boris Suvorov on 8/9/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNSiongNavigationView.h"

#define kScrollYOffset 75.0

#define kBackButtonWidth 22
#define kButtonOriginX 20
#define kButtonOriginY 35

#define kLeftBoundsOffset 24.0
#define kSpaceBetweenViews (kLeftBoundsOffset/2.0)

#define kPushDuration 0.3

@interface CNSiongNavigationView () <UIScrollViewDelegate>

@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) UIButton *backButton;
@property (nonatomic) UILabel *headerLabel;
@property (nonatomic) UIView *leftBlendedView;
@property (nonatomic) UIView *rightBlendedView;

@property (nonatomic) NSMutableArray *scrollViews;

@end

@implementation CNSiongNavigationView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = SIONG_NAVIGATION_CONTROLLER_BACKGROUND_COLOR;
        _scrollViews = [[NSMutableArray alloc] init];
        
        [self addSubview:self.backButton];
        [self addSubview:self.headerLabel];
        [self addSubview:self.scrollView];
        
        // always last
        [self addSubview:self.leftBlendedView];
        [self addSubview:self.rightBlendedView];
    }
    return self;
}

#pragma public methods
- (void)pushView:(UIView *)view
{
    NSUInteger viewIndex = self.scrollViews.count;
    
    view.frame = [self frameForChildVCAtIndex:viewIndex];
    self.scrollView.contentSize = [self scrollViewcontentSizeForVCIndex:viewIndex];
    
    [self.scrollViews addObject:view];
    [self.scrollView addSubview:view];
    [self scrollToIndex:viewIndex];
}

- (void)addNavigationView:(UIView *)view
{
    [self.scrollViews addObject:view];
    [self.scrollView addSubview:view];
}

#pragma mark private helpers

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
    [super layoutSubviews];
    
    CGRect scrollFrame = self.bounds;
    scrollFrame.origin.y += kScrollYOffset;
    scrollFrame.size.height -= kScrollYOffset;
    self.scrollView.frame = scrollFrame;
    
    CGRect rect = CGRectMake(kButtonOriginX, kButtonOriginY, kBackButtonWidth, kBackButtonWidth);
    self.backButton.frame = rect;
    self.headerLabel.frame = CGRectMake(0, kButtonOriginY, scrollFrame.size.width, 20);
    
    self.scrollView.contentSize = self.scrollView.frame.size;
    
    self.rightBlendedView.frame = CGRectMake(self.bounds.size.width - kSpaceBetweenViews,
                                             0,
                                             kSpaceBetweenViews,
                                             self.bounds.size.height);
    
    self.leftBlendedView.frame = CGRectMake(0,
                                            0,
                                            kSpaceBetweenViews,
                                            self.bounds.size.height);
    
    [self layoutViewControllersInScrollView];
}

- (void)layoutViewControllersInScrollView
{
    NSUInteger vcCount = self.scrollViews.count;
    for (NSUInteger vcIndex = 0; vcIndex < vcCount; vcIndex++) {
        UIView *view = [self.scrollViews objectAtIndex:vcIndex];
        view.frame = [self frameForChildVCAtIndex:vcIndex];
    }
    
    self.scrollView.contentSize = [self scrollViewcontentSizeForVCIndex:self.scrollViews.count - 1];
    
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
        
        NSUInteger subviewCount = self.scrollViews.count;
        if (newPage >= subviewCount) {
            newPage = subviewCount - 1;
        }
    }
    
    *targetContentOffset = [self targetPointForPageIndex:newPage];
    [self scrollToIndex:newPage];
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

- (NSUInteger)indexOfPageForContentOffset:(CGFloat)contentXOffset
{
    CGFloat midOfPageXOffset = contentXOffset + self.bounds.size.width / 2;
    CGFloat interVCWidth =  self.bounds.size.width - kLeftBoundsOffset - kSpaceBetweenViews;
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
        if (completionBlock) {
            completionBlock();
        }
    
    };
    
    if (animated) {
        [UIView animateWithDuration:kPushDuration animations:^{
            self.scrollView.contentSize = [self scrollViewcontentSizeForVCIndex:self.currentPageIndex];
        }completion:^(BOOL finished) {
            localCompletion();
        }];
    } else {
        localCompletion();
    }
}

@end
