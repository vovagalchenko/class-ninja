//
//  CNLoggingViewController.m
//  ClassNinja
//
//  Created by Vova Galchenko on 9/21/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNLoggingViewController.h"

@implementation CNLoggingViewController

- (void)viewDidAppear:(BOOL)animated
{
    NSString *viewName = self.title;
    if (!viewName.length) {
        viewName = NSStringFromClass([self class]);
    }
    logViewChange(viewName, [self analyticsDictionary]);
    [super viewDidAppear:animated];
}

- (NSDictionary *)analyticsDictionary
{
    return nil;
}

@end
