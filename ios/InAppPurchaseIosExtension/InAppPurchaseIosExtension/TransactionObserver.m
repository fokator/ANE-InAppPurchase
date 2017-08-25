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
    NSString *logMessage;
    for (SKPaymentTransaction *transaction in transactions) {
        NSString *logMessage;
        switch (transaction.transactionState) {
            case SKPaymentTransactionStateFailed:
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                logMessage = [NSString stringWithFormat:@"updatedTransactions transactionState:SKPaymentTransactionStateFailed error.code: %ld", transaction.error.code];
                if(transaction.error.code == SKErrorPaymentCancelled)
                    DISPATCH_ANE_EVENT(self.context, EVENT_PURCHASE_CANCELED, (uint8_t*)[transaction.error.localizedDescription UTF8String]);
                else
                    DISPATCH_ANE_EVENT(self.context, EVENT_PURCHASE_FAILURE, (uint8_t*)[transaction.error.localizedDescription UTF8String]);
                break;
            
            case SKPaymentTransactionStatePurchased:
                logMessage = [NSString stringWithFormat:@"updatedTransactions transactionState:SKPaymentTransactionStatePurchased"];
                //[[SKPaymentQueue defaultQueue] finishTransaction:transaction]; // TODO consume after purchase? optional configuration.
                DISPATCH_ANE_EVENT(self.context, EVENT_PURCHASE_SUCCESS, (uint8_t*)[[self buildJSONStringOfPurchaseWithTransaction:transaction] UTF8String]);
                break;
                
            case SKPaymentTransactionStateRestored:
                logMessage = [NSString stringWithFormat:@"updatedTransactions transactionState:SKPaymentTransactionStateRestored"];
                // Does nothing, the restore process will be executed in the paymentQueueRestoreCompletedTransationFinished method.
                break;

            case SKPaymentTransactionStateDeferred:
                logMessage = [NSString stringWithFormat:@"updatedTransactions transactionState:SKPaymentTransactionStateDeferred"];
                // Does nothing?
                break;

            case SKPaymentTransactionStatePurchasing:
                logMessage = [NSString stringWithFormat:@"updatedTransactions transactionState:SKPaymentTransactionStatePurchasing"];
                // Does nothing?
                break;

            default:
                logMessage = [NSString stringWithFormat:@"updatedTransactions transactionState:DEFAULT"];
        }

        if (logMessage != NULL) {
             DISPATCH_LOG_EVENT(self.context, logMessage);
        }

    }
}

-(void) paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    DISPATCH_ANE_EVENT(self.context, EVENT_PURCHASES_RETRIEVING_FAILED, (uint8_t*) [error.localizedDescription UTF8String]);
}

-(void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    NSMutableArray *purchasesSrt = [NSMutableArray array];
    NSString *logMessage;

    DISPATCH_LOG_EVENT(self.context, @"Let's get ready for a loop!");
    for(SKPaymentTransaction *transaction in queue.transactions) {
        logMessage = [NSString stringWithFormat:@"product identifier value : %@", transaction.payment.productIdentifier];
        DISPATCH_LOG_EVENT(self.context, logMessage);

        [purchasesSrt addObject: [self buildJSONStringOfPurchaseWithTransaction:transaction]];
    }
    
    DISPATCH_LOG_EVENT(self.context, @"Purchases array completed.");
    NSString *result = [purchasesSrt componentsJoinedByString:@","];
    logMessage = [NSString stringWithFormat:@"Complete. Returning the following product IDs list : %@", result];
    DISPATCH_LOG_EVENT(self.context, logMessage);
    
    result = [NSString stringWithFormat:@"[%@]", result];
    DISPATCH_ANE_EVENT(self.context, EVENT_PURCHASES_RETRIEVED, (uint8_t*) result.UTF8String);
}


- (NSString *) buildJSONStringOfPurchaseWithTransaction:(SKPaymentTransaction *)transaction {
    NSNumber *transactionTimestamp = [NSNumber numberWithDouble:[transaction.transactionDate timeIntervalSince1970]];
    
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receipt = [NSData dataWithContentsOfURL:receiptURL];
    NSString *receiptString = [receipt base64EncodedStringWithOptions:0];
    
    NSDictionary *purchaseDictionary = @{
        @"productId" : transaction.payment.productIdentifier,
        @"transactionTimestamp" : transactionTimestamp,
        @"applicationUsername" : (transaction.payment.applicationUsername != nil ? transaction.payment.applicationUsername : @""),
        @"transactionId" : transaction.transactionIdentifier,
        @"transactionReceipt" : [[NSString alloc] initWithData:transaction.transactionReceipt encoding:NSUTF8StringEncoding],
        @"storeReceipt" : receiptString
    };
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:purchaseDictionary options:NSJSONWritingPrettyPrinted error:nil];
    
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}
@end
