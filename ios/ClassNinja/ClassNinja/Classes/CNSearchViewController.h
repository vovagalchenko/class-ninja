//
//  CNSearchViewController.h
//  ClassNinja
//
//  Created by Boris Suvorov on 8/31/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CNLoggingViewController.h"

@protocol CNSearchViewControllerDelegateProtocol <NSObject>
- (void)buildUIForSearchResults:(NSArray *)models;
@end

@interface CNSearchViewController : CNLoggingViewController
@property (nonatomic, weak) id <CNSearchViewControllerDelegateProtocol> searchDelegate;
@end
