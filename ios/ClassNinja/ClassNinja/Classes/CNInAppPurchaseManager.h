//
//  CNInAppPurchaseHelper.h
//  ClassNinja
//
//  Created by Boris Suvorov on 7/19/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

#define TRANSACTION_FINISHED_NOTIFICATION_NAME      @"transaction_finished"
#define TRANSACTION_DEFERRED_NOTIFICATION_NAME      @"transaction_deferred"
#define TRANSACTION_FAILED_NOTIFICATION_NAME        @"transaction_failed"

@interface CNInAppPurchaseManager : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>

+ (instancetype)sharedInstance;
- (void)ensurePaymentQueueObserving;

- (void)fetchProductForProductId:(NSString *)productId completion:(void (^)(SKProduct *))callback;
- (void)addProductToPaymentQueue:(SKProduct *)product;

@end
