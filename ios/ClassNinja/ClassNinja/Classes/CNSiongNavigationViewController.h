//
//  CNSiongNavigationViewController.h
//  ClassNinja
//
//  Created by Boris Suvorov on 7/27/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CNSiongNavigationViewController;

@protocol SiongNavigationProtocol <NSObject>
@property (nonatomic, weak) CNSiongNavigationViewController *siongNavigationController;
@end

@interface CNSiongNavigationViewController : UIViewController

- (id)initWithRootViewController:(UIViewController<SiongNavigationProtocol> *)rootViewController; // Convenience method pushes the root view controller without animation.

 // Uses a horizontal scroll transition. Has no effect if the view controller is already in the stack.
- (void)pushViewController:(UIViewController<SiongNavigationProtocol> *)viewController;
- (UIViewController *)popViewControllerAnimated:(BOOL)animated;

@property(nonatomic,readonly) UIViewController *topViewController; // The top view controller on the stack.

@end

