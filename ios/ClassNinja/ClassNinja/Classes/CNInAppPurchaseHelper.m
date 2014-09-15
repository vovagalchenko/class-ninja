//
//  CNInAppPurchaseHelper.m
//  ClassNinja
//
//  Created by Boris Suvorov on 7/19/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNInAppPurchaseHelper.h"
#import "CNAPIClient.h"

@interface CNInAppPurchaseHelper ()
@property (nonatomic) SKProductsRequest *productsRequest;
@property (nonatomic) SKReceiptRefreshRequest *refresh;
@property (nonatomic, strong) dispatch_block_t completion;
@end

@implementation CNInAppPurchaseHelper

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static CNInAppPurchaseHelper *iapHelper = nil;
    dispatch_once(&onceToken, ^{
        iapHelper = [[CNInAppPurchaseHelper alloc] init];
    });
    return iapHelper;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    return self;
}

- (void)restoreTransactions
{
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (void)purchase:(NSString *)productId withCompletionBlock:(dispatch_block_t)completionBlock
{
    if (productId == nil) {
        if (completionBlock) {
            completionBlock();
        }
        return;
    }
    self.completion = completionBlock;
    NSArray *productIdentifiers = [[NSArray alloc] initWithObjects:productId, nil];
    self.productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:productIdentifiers]];
    self.productsRequest.delegate = self;
    [self.productsRequest start];

}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    NSArray *products = [response products];
    
    if ([products count] > 0) {
        SKProduct *product = products[0];
        SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
        payment.quantity = 1;
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }
}
// Sent when the transaction array has changed (additions or state changes).  Client should check state of transactions and finish as appropriate
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    SKPaymentTransaction *transaction = [transactions firstObject];
    if (transaction) {
        SKPaymentTransactionState transactionState = transaction.transactionState;
        if (transactionState == SKPaymentTransactionStatePurchased) {
            NSData *receipt = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]];
            [[CNAPIClient sharedInstance] verify:receipt successBlock:^(BOOL success){
                if (success) {
                    [queue finishTransaction:transaction];
                }
            }];
        } else if (transactionState == SKPaymentTransactionStateFailed || transactionState == SKPaymentTransactionStateRestored){
            [queue finishTransaction:transaction];
        }
    }
}

// Sent when transactions are removed from the queue (via finishTransaction:).
- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions
{
    if (self.completion) {
        self.completion();
    }
}


@end
