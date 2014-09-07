//
//  CNSiongNavigationViewController.h
//  ClassNinja
//
//  Created by Boris Suvorov on 7/27/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CNSearchViewController.h"

@class CNSiongNavigationViewController;

@protocol SiongNavigationProtocol <NSObject>
- (NSString *)siongNavBarTitle;
@property (nonatomic, weak) CNSiongNavigationViewController *siongNavigationController;

- (void)nextViewControllerWillPop;
@end

@interface CNSiongNavigationViewController : UIViewController

@property (nonatomic, weak) id <CNSearchViewControllerDelegateProtocol> searchDelegate;
@property (nonatomic, copy, readonly) NSMutableArray *viewControllers;

// Convenience method pushes the root view controller without animation.
- (id)initWithRootViewController:(UIViewController<SiongNavigationProtocol> *)rootViewController;

 // Uses a horizontal scroll transition. Has no effect if the view controller is already in the stack.
- (void)pushViewController:(UIViewController<SiongNavigationProtocol> *)viewController animated:(BOOL)animated;
- (UIViewController *)popViewControllerAtIndex:(NSUInteger)vcIndex
                                      animated:(BOOL)animated
                                  deselectRows:(BOOL)deselectRows;
- (UIViewController <SiongNavigationProtocol> *)rootVC;

@end

