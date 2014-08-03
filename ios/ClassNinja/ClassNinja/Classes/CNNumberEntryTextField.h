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

@interface CNNumberEntryTextField : UITextField<UITextFieldDelegate>

@property (nonatomic, readwrite) NSArray *groupArray;

@end
