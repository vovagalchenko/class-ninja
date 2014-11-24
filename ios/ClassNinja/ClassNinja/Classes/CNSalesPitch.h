//
//  CNSalesPitch.h
//  ClassNinja
//
//  Created by Boris Suvorov on 11/12/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CNSalesPitch : NSObject

@property (nonatomic) NSString *shortMarketingMessage;
@property (nonatomic) NSString *longMarketingMessage;
@property (nonatomic) NSString *signup_reminder;
@property (nonatomic) NSString *sharing_pitch;

@property (nonatomic) NSNumber *freeClassesForSharing;
@property (nonatomic) NSNumber *freeClassesForSignup;
@property (nonatomic) NSNumber *classesForPurchase;

@property (nonatomic) NSString *sharingLinkString;
@property (nonatomic) NSString *sharingMessagePlaceholder;
@property (nonatomic) NSString *fbCaption;

+ (CNSalesPitch *)defaultPitch;

@end
