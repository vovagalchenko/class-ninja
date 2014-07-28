//
//  CNWelcomeStatusView.h
//  ClassNinja
//
//  Created by Vova Galchenko on 7/31/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CNWelcomeStatusView;
@protocol CNWelcomeStatusViewDelegate <NSObject>

@required
- (void)addClassesButtonPressed:(id)sender;

@end

@interface CNWelcomeStatusView : UIView

@property (nonatomic, readonly) UILabel *statusLabel;
- (instancetype)initWithDelegate:(id<CNWelcomeStatusViewDelegate>)delegate;

@end
