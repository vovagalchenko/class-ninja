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
@property (nonatomic, strong) SKProductsRequest *productsRequest;
@end

@implementation CNInAppPurchaseHelper

// Custom method
- (void)validateProductIdentifiers:(NSArray *)productIdentifiers
{
    self.productsRequest = [[SKProductsRequest alloc]
                                          initWithProductIdentifiers:[NSSet setWithArray:productIdentifiers]];
    self.productsRequest.delegate = self;
    [self.productsRequest start];
}

- (void)dealloc
{
    
}


- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    NSLog(@"response = %@, request = %@", request, response);
    NSArray *products = [response products];
    
    if ([products count] > 0) {
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        SKProduct *product = products[0];
        SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
        payment.quantity = 1;
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }
}

- (void)requestDidFinish:(SKRequest *)request
{
    
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    
}



// Sent when the transaction array has changed (additions or state changes).  Client should check state of transactions and finish as appropriate
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions) {
        SKPaymentTransactionState transactionState = transaction.transactionState;
        if (transactionState == SKPaymentTransactionStatePurchased) {
            NSData *receipt = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]];
            NSLog(@"Make post to our server to verify receipt with %@", receipt);
            
        } else if (transactionState == SKPaymentTransactionStateFailed) {
            NSLog(@"State failed");
        } else if (transactionState == SKPaymentTransactionStateRestored) {
            NSLog(@"State restored");
        }
    }
    
}

// Sent when transactions are removed from the queue (via finishTransaction:).
- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions
{
    
}

// Sent when an error is encountered while adding transactions from the user's purchase history back to the queue.
- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    
}

// Sent when all transactions from the user's purchase history have successfully been added back to the queue.
- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    
}

// Sent when the download state has changed.
- (void)paymentQueue:(SKPaymentQueue *)queue updatedDownloads:(NSArray *)downloads
{
    
}



@end