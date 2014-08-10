//
//  CNSiongNavigationViewController.m
//  ClassNinja
//
//  Created by Boris Suvorov on 7/27/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNSiongNavigationViewController.h"
#import "AppearanceConstants.h"

#import "CNSiongNavigationView.h"

@interface CNSiongNavigationViewController () <CNGenericNavigationProtocol>
@property (nonatomic) NSMutableArray *viewControllers;
@property (nonatomic) BOOL firstLoad;
@property (nonatomic) CNSiongNavigationView *siongView;
@end

@implementation CNSiongNavigationViewController

- (id)initWithRootViewController:(UIViewController<SiongNavigationProtocol> *)rootViewController
{
    self = [super init];
    if (self) {
        _viewControllers = [NSMutableArray array];
        [_viewControllers addObject:rootViewController];
        
        self.siongView = [[CNSiongNavigationView alloc] init];
        self.siongView.navigationDelegate = self;
        self.view = self.siongView;

        rootViewController.siongNavigationController = self;
        [self.siongView pushView:rootViewController.view];
    }
    return self;
}

- (void)backButtonPressed:(id)sender
{
    [self popViewControllerAnimated:YES deselectRows:YES];
}

- (void)pushViewController:(UIViewController<SiongNavigationProtocol> *)viewController
{
    NSUInteger currentVCIndex = self.siongView.currentPageIndex;
    viewController.siongNavigationController = self;

    // dismiss all view controllers to the right of current VC
    [self popViewControllerAtIndex:currentVCIndex + 1 animated:NO deselectRows:NO];
    
    if ([self.viewControllers indexOfObject:viewController] == NSNotFound) {
        [self.viewControllers addObject:viewController];
    }
    
    [self.siongView pushView:viewController.view];
}

- (UIViewController *)popViewControllerAtIndex:(NSUInteger)vcIndex
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
        NSInteger targetVCIndex = vcIndex - 1;
        if (deselectRows) {
            for (NSInteger i = vcCount-2; i >= targetVCIndex; i--) {
                UIViewController <SiongNavigationProtocol> *vc = [self.viewControllers objectAtIndex:i];
                if ([vc respondsToSelector:@selector(nextViewControllerWillPop)]) {
                    [vc nextViewControllerWillPop];
                }
            }
        }

        NSRange removalRange = NSMakeRange(vcIndex, self.viewControllers.count - vcIndex);
        [self.viewControllers removeObjectsInRange:removalRange];

        [self.siongView popViewAtIndex:vcIndex
                              animated:animated
                       completionBlock:nil];
        
    } else {
        [self.presentingViewController dismissViewControllerAnimated:animated completion:nil];
    }
    
    return resultVC;
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated deselectRows:(BOOL)deselectRows
{
    NSUInteger currentPageIndex = [self.siongView currentPageIndex];
    return [self popViewControllerAtIndex:currentPageIndex
                                 animated:animated
                             deselectRows:deselectRows];
}

- (UIViewController *)topViewController
{
    return [self.viewControllers lastObject];
}

@end
