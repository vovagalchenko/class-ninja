//
//  CNSchoolViewController.h
//  ClassNinja
//
//  Created by Boris Suvorov on 7/29/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CNSiongNavigationViewController.h"
#import "CNModels.h"
#import "CNLoggingViewController.h"

@interface CNGenericSelectionViewController : CNLoggingViewController <UITableViewDataSource, UITableViewDelegate, SiongNavigationProtocol>
@property (nonatomic, weak) CNSiongNavigationViewController *siongNavigationController;

- (void)handleSearchResult:(NSArray *)searchModels;

@end

@interface CNSchoolViewController : CNGenericSelectionViewController
@end
