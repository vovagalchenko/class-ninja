//
//  CNWelcomeViewController.h
//  ClassNinja
//
//  Created by Boris Suvorov on 7/27/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CNWelcomeStatusView.h"
#import "CNSearchViewController.h"

@interface CNWelcomeViewController : UIViewController <CNWelcomeStatusViewDelegate, CNSearchViewControllerDelegateProtocol>

@end
