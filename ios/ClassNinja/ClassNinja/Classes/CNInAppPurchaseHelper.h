//
//  CNInAppPurchaseHelper.h
//  ClassNinja
//
//  Created by Boris Suvorov on 7/19/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface CNInAppPurchaseHelper : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>

- (void)validateProductIdentifiers:(NSArray *)productIdentifiers;

@end
