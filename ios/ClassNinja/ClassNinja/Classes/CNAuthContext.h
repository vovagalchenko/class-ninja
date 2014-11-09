//
//  CNAuthContext.h
//  ClassNinja
//
//  Created by Vova Galchenko on 7/29/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CNAuthViewController.h"

@class CNUser;
@interface CNAuthContext : NSObject <CNAuthViewControllerDelegate>

@property (nonatomic, readonly) CNUser *loggedInUser;

- (void)authenticateWithCompletion:(void (^)(BOOL))completionBlock;
- (void)logUserOut;

- (void)setCreditsForLoggedInUser:(NSUInteger)credits;
- (void)setDidPostOnFbForLoggedInUser:(BOOL)didPostOnFb;
- (void)setDidPostOnTwitterForLoggedInUser:(BOOL)didPostOnTwitter;

@end
