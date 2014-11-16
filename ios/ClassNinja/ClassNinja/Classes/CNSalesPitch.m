//
//  CNSalesPitch.m
//  ClassNinja
//
//  Created by Boris Suvorov on 11/12/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNSalesPitch.h"

@implementation CNSalesPitch


+ (CNSalesPitch *)defaultPitch
{
    CNSalesPitch *pitch = [[CNSalesPitch alloc] init];
    pitch.shortMarketingMessage = @"Or for just %@, you will be able to track ten more classes.";
    pitch.longMarketingMessage = @"It costs us real money to run this service for you. We hope you enjoy using it.\n\nFor just %@, you will be able to track ten more classes.";
    pitch.sharing_pitch = @"Track another %@ fo free by helping us spread the word.";
    pitch.signup_reminder = @"You received first %@ classes you want to track for free for your signup.";
    
    pitch.freeClassesForSharing = @(3);
    pitch.freeClassesForSignup = @(3);
    
    return pitch;
}

@end
