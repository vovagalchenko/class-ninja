//
//  CNDepartmentViewController.h
//  ClassNinja
//
//  Created by Boris Suvorov on 7/27/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CNSiongNavigationViewController.h"

@class CNSchool;
@interface CNDepartmentViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, SiongNavigationProtocol>
@property (nonatomic, weak) CNSiongNavigationViewController *siongNavigationController;
@property (nonatomic) CNSchool *school;
@end
