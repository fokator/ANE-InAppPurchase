//
//  TransactionObserver.m
//  InAppPurchaseIosExtension
//
//  Created by Antoine Kleinpeter on 05/11/14.
//  Copyright (c) 2014 studiopixmix. All rights reserved.
//

#import "TransactionObserver.h"
#import "FlashRuntimeExtensions.h"
#import "ExtensionDefs.h"

@interface TransactionObserver () <SKPaymentTransactionObserver>

@end

@implementation TransactionObserver

- (void) paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    for (SKPaymentTransaction *transaction in transactions) {
        NSString *logMessage;
        switch (transaction.transactionState) {
            case SKPaymentTransactionStateFailed:
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                logMessage = [NSString stringWithFormat:@"updatedTransactions id:%@ transactionState:SKPaymentTransactionStateFailed error.code: %ld", transaction.transactionIdentifier, transaction.error.code];
                if(transaction.error.code == SKErrorPaymentCancelled)
                    DISPATCH_ANE_EVENT(self.context, EVENT_PURCHASE_CANCELED, (uint8_t*)[transaction.error.localizedDescription UTF8String]);
                else
                    DISPATCH_ANE_EVENT(self.context, EVENT_PURCHASE_FAILURE, (uint8_t*)[transaction.error.localizedDescription UTF8String]);
                break;

            case SKPaymentTransactionStatePurchased:
                logMessage = [NSString stringWithFormat:@"updatedTransactions id:%@ transactionState:SKPaymentTransactionStatePurchased", transaction.transactionIdentifier];
                //[[SKPaymentQueue defaultQueue] finishTransaction:transaction]; // TODO consume after purchase? optional configuration.
                DISPATCH_ANE_EVENT(self.context, EVENT_PURCHASE_SUCCESS, (uint8_t*)[[TransactionObserver buildJSONStringOfPurchaseWithTransaction:transaction] UTF8String]);
                break;

            case SKPaymentTransactionStateRestored:
                logMessage = [NSString stringWithFormat:@"updatedTransactions id:%@ transactionState:SKPaymentTransactionStateRestored", transaction.transactionIdentifier];
                // Does nothing, the restore process will be executed in the paymentQueueRestoreCompletedTransationFinished method.
                break;

            case SKPaymentTransactionStateDeferred:
                logMessage = [NSString stringWithFormat:@"updatedTransactions id:%@ transactionState:SKPaymentTransactionStateDeferred", transaction.transactionIdentifier];
                // Does nothing?
                break;

            case SKPaymentTransactionStatePurchasing:
                logMessage = [NSString stringWithFormat:@"updatedTransactions id:%@ transactionState:SKPaymentTransactionStatePurchasing", transaction.transactionIdentifier];
                // Does nothing?
                break;

            default:
                logMessage = [NSString stringWithFormat:@"updatedTransactions id:%@ transactionState:DEFAULT", transaction.transactionIdentifier];
        }

        if (logMessage != NULL) {
             DISPATCH_LOG_EVENT(self.context, logMessage);
        }

    }
}

// Sent when a user initiates an IAP buy from the App Store TODO
// - (BOOL)paymentQueue:(SKPaymentQueue *)queue shouldAddStorePayment:(SKPayment *)payment forProduct:(SKProduct *)product NS_SWIFT_NAME(paymentQueue(_:shouldAddStorePayment:for:)) {
//     DISPATCH_LOG_EVENT(self.context, @"execute shouldAddStorePayment");
//     return TRUE;
// }

-(void) paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    DISPATCH_ANE_EVENT(self.context, EVENT_PURCHASES_RETRIEVING_FAILED, (uint8_t*) [error.localizedDescription UTF8String]);
}

// TODO: this method is obsolete until we use only consumable products
-(void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    NSMutableArray *purchasesSrt = [NSMutableArray array];
    NSString *logMessage;

    DISPATCH_LOG_EVENT(self.context, @"Let's get ready for a loop!");
    for(SKPaymentTransaction *transaction in queue.transactions) {
        NSString *transactionState = [TransactionObserver formatTypeToString:transaction.transactionState];
        logMessage = [NSString stringWithFormat:@"transaction id: %@, state: %@, error: %@, productId: %@",
                                                transaction.transactionIdentifier, transactionState, transaction.error,
                                                transaction.payment.productIdentifier];
        DISPATCH_LOG_EVENT(self.context, logMessage);

        switch (transaction.transactionState) {
          case SKPaymentTransactionStateFailed:
              // Transaction was cancelled or failed before being added to the server queue.
              break;
            default:

              [purchasesSrt addObject: [TransactionObserver buildJSONStringOfPurchaseWithTransaction:transaction]];
        }
    }

    DISPATCH_LOG_EVENT(self.context, @"Purchases array completed.");
    NSString *result = [purchasesSrt componentsJoinedByString:@","];
    logMessage = [NSString stringWithFormat:@"Complete. Returning the following product IDs list : %@", result];
    DISPATCH_LOG_EVENT(self.context, logMessage);

    result = [NSString stringWithFormat:@"[%@]", result];
    DISPATCH_ANE_EVENT(self.context, EVENT_PURCHASES_RETRIEVED, (uint8_t*) result.UTF8String);
}


+ (NSString *) buildJSONStringOfPurchaseWithTransaction:(SKPaymentTransaction *)transaction {

    NSNumber *transactionTimestamp = [NSNumber numberWithDouble:[transaction.transactionDate timeIntervalSince1970]];
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receipt = [NSData dataWithContentsOfURL:receiptURL];
    NSString *receiptString = [receipt base64EncodedStringWithOptions:0];

    NSString *transactionReceipt = [[NSString alloc] initWithData:transaction.transactionReceipt encoding:NSUTF8StringEncoding];

    NSDictionary *purchaseDictionary = @{
        @"productId" : convertNil(transaction.payment.productIdentifier),
        @"transactionTimestamp" : transactionTimestamp,
        @"applicationUsername" : convertNil(transaction.payment.applicationUsername),
        @"transactionId" : convertNil(transaction.transactionIdentifier),
        @"transactionState" : [TransactionObserver formatTypeToString:transaction.transactionState],
        @"transactionReceipt" : convertNil(transactionReceipt),
        @"storeReceipt" : convertNil(receiptString)
    };

    NSData *data = [NSJSONSerialization dataWithJSONObject:purchaseDictionary options:NSJSONWritingPrettyPrinted error:nil];

    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

+ (NSString*)formatTypeToString:(SKPaymentTransactionState)transactionState {
    NSString *result = nil;

    switch (transactionState) {
        case SKPaymentTransactionStatePurchasing:
            // Transaction is being added to the server queue.
            result = @"SKPaymentTransactionStatePurchasing";
            break;
        case SKPaymentTransactionStatePurchased:
            // Transaction is in queue, user has been charged.  Client should complete the transaction.
            result = @"SKPaymentTransactionStatePurchased";
            break;
        case SKPaymentTransactionStateFailed:
            // Transaction was cancelled or failed before being added to the server queue.
            result = @"SKPaymentTransactionStateFailed";
            break;
        case SKPaymentTransactionStateRestored:
            // Transaction was restored from user's purchase history.  Client should complete the transaction.
            result = @"SKPaymentTransactionStateRestored";
            break;
        case SKPaymentTransactionStateDeferred:
            // The transaction is in the queue, but its final status is pending external action.
            result = @"SKPaymentTransactionStateDeferred 8_0";
            break;
        default:
            [NSException raise:NSGenericException format:@"Unexpected transactionState."];
    }

    return result;
}

@end
