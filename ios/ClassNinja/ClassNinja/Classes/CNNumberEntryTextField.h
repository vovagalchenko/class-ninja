//
//  CNNumberEntryTextField.h
//  ClassNinja
//
//  Created by Vova Galchenko on 8/2/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    CNNumberEntryTextFieldTypePhone,
    CNNumberEntryTextFieldTypeVerificationCode,
} CNNumberEntryTextFieldType;

@protocol CNNumberEntryTextFieldDelegate;
@interface CNNumberEntryTextField : UITextField<UITextFieldDelegate>

- (instancetype)initWithDelegate:(id<CNNumberEntryTextFieldDelegate>)d;
@property (nonatomic, readwrite) NSArray *groupArray;
@property (nonatomic, readonly) unsigned short numberOfDigitsEntered;
@property (nonatomic, readonly) unsigned short digitsNeeded;

@end

@protocol CNNumberEntryTextFieldDelegate <NSObject>

@required
- (void)numberEntryTextFieldDidChangeText:(CNNumberEntryTextField *)tf;

@end