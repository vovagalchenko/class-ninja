//
//  CNInAppPurchaseHelper.m
//  ClassNinja
//
//  Created by Boris Suvorov on 7/19/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNInAppPurchaseManager.h"
#import "CNAPIClient.h"

@interface CNInAppPurchaseManager ()

@property (readonly) NSMutableArray *transactionsPendingReceiptRefresh;
@property (readonly) NSMutableDictionary *productDetailsCallbacks;

@end

#define TRANSACTION_STATE_CHANGE_EVENT_NAME     @"transaction_state_change"

@implementation CNInAppPurchaseManager

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static CNInAppPurchaseManager *iapHelper = nil;
    dispatch_once(&onceToken, ^{
        iapHelper = [[CNInAppPurchaseManager alloc] init];
    });
    return iapHelper;
}

#pragma mark - Product Details Fetching

- (void)fetchProductForProductId:(NSString *)productId completion:(void (^)(SKProduct *))callback
{
    [self addProductDetailCallback:callback forProductId:productId];
    NSArray *productIdentifiers = [[NSArray alloc] initWithObjects:productId, nil];
    SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:productIdentifiers]];
    productsRequest.delegate = self;
    [productsRequest start];
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    for (SKProduct *product in [response products]) {
        [self invokeProductDetailCallbacksForProduct:product];
    }
}

#pragma mark - Payment Queue Management

- (void)ensurePaymentQueueObserving
{
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
}

- (void)addProductToPaymentQueue:(SKProduct *)product
{
    SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
    payment.quantity = 1;
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
            case SKPaymentTransactionStateRestored:
                [self verifyReceiptForTransaction:transaction];
                break;
            case SKPaymentTransactionStateDeferred:
            case SKPaymentTransactionStateFailed:
            {
                NSString *transactionStateName = transaction.transactionState == SKPaymentTransactionStateFailed?
                                                    TRANSACTION_FAILED_NOTIFICATION_NAME : TRANSACTION_DEFERRED_NOTIFICATION_NAME;
                [[NSNotificationCenter defaultCenter] postNotificationName:transactionStateName
                                                                    object:transaction];
                logUserAction(TRANSACTION_STATE_CHANGE_EVENT_NAME,
                              @{
                                @"new_state" : transactionStateName,
                                @"error" : transaction.error.debugDescription
                                });
                break;
            }
            default:
                break;
        }
    }
}

#pragma mark - Receipt Refreshing

- (void)verifyReceiptForTransaction:(SKPaymentTransaction *)transaction
{
    NSData *receiptData = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]];
    if (!receiptData) {
        SKReceiptRefreshRequest *refreshReceiptRequest = [[SKReceiptRefreshRequest alloc] initWithReceiptProperties:nil];
        [refreshReceiptRequest setDelegate:self];
        [self addTransactionPendingReceiptRefresh:transaction];
        [refreshReceiptRequest start];
    } else {
        [[CNAPIClient sharedInstance] verifyPurchaseOfProduct:transaction.payment.productIdentifier withReceipt:receiptData completion:^(CNAPIClientInAppPurchaseReceiptStatus receiptStatus) {
            switch (receiptStatus) {
                case CNAPIClientInAppPurchaseReceiptStatusFailed:
                case CNAPIClientInAppPurchaseReceiptStatusPassed:
                {
                    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                    NSString *transactionStateName = receiptStatus == CNAPIClientInAppPurchaseReceiptStatusPassed? TRANSACTION_FINISHED_NOTIFICATION_NAME : TRANSACTION_FAILED_NOTIFICATION_NAME;
                    [[NSNotificationCenter defaultCenter] postNotificationName:transactionStateName
                                                                        object:transaction];
                    logUserAction(TRANSACTION_STATE_CHANGE_EVENT_NAME,
                                  @{
                                    @"new_state" : transactionStateName,
                                    @"processing" : @"receipt_verification"
                                    });
                    break;
                }
                default:
                    break;
            }
        }];
        [self removeTransactionPendingReceiptRefresh:transaction];
    }
}

- (void)requestDidFinish:(SKRequest *)request
{
    if ([request isKindOfClass:[SKReceiptRefreshRequest class]]) {
        for (SKPaymentTransaction *transaction in self.transactionsPendingReceiptRefresh)
            [self verifyReceiptForTransaction:transaction];
    }
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    logWarning(@"iap_error", @{
                               @"error"   : error.description,
                               @"request" : request.description
                               });
    if ([request isKindOfClass:[SKProductsRequest class]]) {
        // Product request failed
        for (NSString *productId in self.productDetailsCallbacks.allKeys) {
            [self invokeProductDetailCallbacksForProductId:productId product:nil];
        }
    }
    [[[UIAlertView alloc] initWithTitle:@"Error"
                                message:[NSString stringWithFormat:@"StoreKit error: %@", [error localizedDescription]]
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

#pragma mark - Read-Only Synchronized Collections for Internal Bookkeeping

@synthesize transactionsPendingReceiptRefresh = _transactionsPendingReceiptRefresh;
@synthesize productDetailsCallbacks = _productDetailsCallbacks;

- (void)addTransactionPendingReceiptRefresh:(SKPaymentTransaction *)transaction
{
    @synchronized(self) {
        [self.transactionsPendingReceiptRefresh addObject:transaction];
    }
}

- (void)removeTransactionPendingReceiptRefresh:(SKPaymentTransaction *)transaction
{
    @synchronized(self) {
        [self.transactionsPendingReceiptRefresh removeObject:transaction];
    }
}

- (NSMutableArray *)transactionsPendingReceiptRefresh
{
    @synchronized(self) {
        if (!_transactionsPendingReceiptRefresh) {
            _transactionsPendingReceiptRefresh = [NSMutableArray array];
        }
        return _transactionsPendingReceiptRefresh;
    }
}

- (void)addProductDetailCallback:(void (^)(SKProduct *))callback forProductId:(NSString *)productId
{
    @synchronized(self) {
        NSMutableArray *callbacksForProductId = [self.productDetailsCallbacks objectForKey:productId] ?: [NSMutableArray array];
        [callbacksForProductId addObject:callback];
        [self.productDetailsCallbacks setObject:callbacksForProductId forKey:productId];
    }
}

- (void)invokeProductDetailCallbacksForProduct:(SKProduct *)product
{
    [self invokeProductDetailCallbacksForProductId:product.productIdentifier product:product];
}

- (void)invokeProductDetailCallbacksForProductId:(NSString *)productId product:(SKProduct *)product
{
    @synchronized(self) {
        for (void (^callback)(SKProduct *) in [self.productDetailsCallbacks objectForKey:productId]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(product);
            });
        }
        [self.productDetailsCallbacks removeObjectForKey:productId];
    }
}

- (NSMutableDictionary *)productDetailsCallbacks
{
    @synchronized(self) {
        if (!_productDetailsCallbacks) {
            _productDetailsCallbacks = [NSMutableDictionary dictionary];
        }
        return _productDetailsCallbacks;
    }
}

@end
