//
//  CNAuthViewController.h
//  ClassNinja
//
//  Created by Vova Galchenko on 8/2/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CNNumberEntryTextField.h"
#import "CNLoggingViewController.h"

@protocol CNAuthViewControllerDelegate;
@interface CNAuthViewController : CNLoggingViewController <CNNumberEntryTextFieldDelegate>

- (instancetype)initWithDelegate:(id<CNAuthViewControllerDelegate>)delegate;

@end

@protocol CNAuthViewControllerDelegate <NSObject>

- (void)authViewController:(CNAuthViewController *)authViewController
   receivedUserPhoneNumber:(NSString *)phoneNumber
    doneProcessingCallback:(void (^)(BOOL))completionCallback;
- (void)authViewController:(CNAuthViewController *)authViewController
  receivedConfirmationCode:(NSString *)confirmationCode
            forPhoneNumber:(NSString *)phoneNumber
    doneProcessingCallback:(void (^)(BOOL))completionCallback;
- (void)authViewControllerCancelledAuthentication:(CNAuthViewController *)authViewController;

@end
