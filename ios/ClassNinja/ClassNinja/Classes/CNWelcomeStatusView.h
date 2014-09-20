//
//  CNWelcomeStatusView.h
//  ClassNinja
//
//  Created by Vova Galchenko on 7/31/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    CNWelcomeStatusViewActionStatusButtonTypeNone,
    CNWelcomeStatusViewActionStatusButtonTypePay,
    CNWelcomeStatusViewActionStatusButtonTypeRefreshTargets,
} CNWelcomeStatusViewActionStatusButtonType;

@class CNWelcomeStatusView;
@protocol CNWelcomeStatusViewDelegate <NSObject>

@required
- (void)addClassesButtonPressed:(id)sender;
- (void)payToTrackMoreButtonPressed:(id)sender;
- (void)refreshTargetsButtonPressed:(id)sender;

@end

@interface CNWelcomeStatusView : UIView

@property (nonatomic, readonly) UIButton *actionButton;
@property (nonatomic, readonly) UIView *separatorLine;
@property (nonatomic, readonly) UILabel *statusLabel;
@property (nonatomic, assign) CNWelcomeStatusViewActionStatusButtonType actionButtonType;
- (instancetype)initWithDelegate:(id<CNWelcomeStatusViewDelegate>)delegate;

@end
