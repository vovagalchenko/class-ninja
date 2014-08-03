//
//  CNAppDelegate.h
//  ClassNinja
//
//  Created by Boris Suvorov on 7/5/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import <UIKit/UIKit.h>

#define APP_DELEGATE        ((CNAppDelegate *)[[UIApplication sharedApplication] delegate])

@interface CNAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@end
