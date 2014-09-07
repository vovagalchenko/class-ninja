//
//  CNSiongNavigationView.h
//  ClassNinja
//
//  Created by Boris Suvorov on 8/9/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CNGenericNavigationProtocol <NSObject>
- (void)backButtonPressed:(id)sender;
- (void)searchButtonPressed:(id)sender;
- (NSString *)navbarTitleForIndex:(NSInteger)index;
@end

@interface CNSiongNavigationView : UIView

@property (nonatomic, weak) id <CNGenericNavigationProtocol> navigationDelegate;
@property (nonatomic) NSUInteger currentPageIndex;
@property (nonatomic, readonly) UILabel *headerLabel;

- (void)pushView:(UIView *)view;
- (void)popViewAtIndex:(NSUInteger)viewIndex
              animated:(BOOL)animated
       completionBlock:(dispatch_block_t)completionBlock;

@end
