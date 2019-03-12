//
//  InAppPurchaseANE.m
//  InAppPurchaseANE
//
//  Created by Antoine Kleinpeter on 30/10/14.
//  Copyright (c) 2014 studiopixmix. All rights reserved.
//
#import "FlashRuntimeExtensions.h"
#import "TypeConversionHelper.h"
#import "ExtensionDefs.h"
#import <StoreKit/StoreKit.h>
#import "ProductsRequestDelegate.h"
#import "TransactionObserver.h"

#define DEFINE_ANE_FUNCTION(fn) FREObject (fn)(FREContext context, void* functionData, uint32_t argc, FREObject argv[])

#define MAP_FUNCTION(fn, data) { (const uint8_t*)(#fn), (data), &(fn) }
#define SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)


TypeConversionHelper* typeConversionHelper;
ProductsRequestDelegate *productsRequestDelegate;
TransactionObserver *transactionObserver;

DEFINE_ANE_FUNCTION(initialize) {
    transactionObserver.context = context;
    [[SKPaymentQueue defaultQueue] addTransactionObserver:transactionObserver];

    DISPATCH_LOG_EVENT(context, @"In app purchase ANE initialized on iOS.");

    DISPATCH_ANE_EVENT(context, EVENT_INITIALIZED, (uint8_t*)"done");

    return NULL;
}

DEFINE_ANE_FUNCTION(getProducts) {
    NSArray *productIdsRequested = [typeConversionHelper FREGetObjectAsStringArray:argv[0]];
    
    NSString *logMessage = [NSString stringWithFormat:@"Starting an SKProductsRequest with products %@", [productIdsRequested componentsJoinedByString:@", "]];
    DISPATCH_LOG_EVENT(context, logMessage);
    
    SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:productIdsRequested]];
    
    productsRequestDelegate.context = context;
    productsRequest.delegate = productsRequestDelegate;

    [productsRequest start];
    
    return NULL;
}

DEFINE_ANE_FUNCTION(buyProduct) {
    NSString *productId;
    if ([typeConversionHelper FREGetObject:argv[0] asString:&productId] != FRE_OK) {
        DISPATCH_ANE_EVENT(context, EVENT_PURCHASE_FAILURE, (uint8_t*)"No productId provided");
        return NULL;
    }
    
    NSString *logMessage = [NSString stringWithFormat:@"Buying product %@", productId];
    DISPATCH_LOG_EVENT(context, logMessage);
  
    SKProduct *product = [productsRequestDelegate getProductWithId:productId];
    
    if (product == nil) {
        DISPATCH_ANE_EVENT(context, EVENT_PURCHASE_FAILURE, (uint8_t*)"Product was not loaded with getProducts, cannot buy it");
        return NULL;
    }
    
    SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
    payment.quantity = 1;
    
    DISPATCH_LOG_EVENT(context, @"Adding SKPayment to the SKPaymentQueue...");
    [[SKPaymentQueue defaultQueue] addPayment:payment];
    
    return NULL;
}

DEFINE_ANE_FUNCTION(consumeProduct) {
    NSString *productId;
    if ([typeConversionHelper FREGetObject:argv[0] asString:&productId] != FRE_OK) {
        DISPATCH_ANE_EVENT(context, EVENT_PURCHASE_FAILURE, (uint8_t*)"No productId provided");
        return NULL;
    }

    NSString *logMessage = [NSString stringWithFormat:@"Consume purchase by product %@", productId];
    DISPATCH_LOG_EVENT(context, logMessage);

    SKProduct *product = [productsRequestDelegate getProductWithId:productId];
    if (product == nil) {
        NSString *errorMessage = [NSString stringWithFormat:@"Product was not loaded with getProductWithId productId:%@, cannot consume it", productId];
        DISPATCH_ANE_EVENT(context, EVENT_CONSUME_FAILURE, (uint8_t*)[errorMessage UTF8String]);
        return NULL;
    }

    NSArray *transactions = [[SKPaymentQueue defaultQueue] transactions];
    SKPaymentTransaction *toConsume = nil;
    for (SKPaymentTransaction *transaction in transactions) {
        if ([productId isEqualToString:transaction.payment.productIdentifier]) {
            toConsume = transaction;
            break;
        }
    }

    if (toConsume != nil) {
        [[SKPaymentQueue defaultQueue] finishTransaction:toConsume];

        NSString *message = [NSString stringWithFormat:@"Consume transaction: [%@]", toConsume.payment.productIdentifier];
        DISPATCH_LOG_EVENT(context, message);

        NSString *transactionJson = [TransactionObserver buildJSONStringOfPurchaseWithTransaction:toConsume];
        DISPATCH_ANE_EVENT(context, EVENT_CONSUME_SUCCESS, (uint8_t*)[transactionJson UTF8String]);

    } else {
        NSString *errorMessage = [NSString stringWithFormat:@"Can't find transaction for productId:%@, cannot consume it", productId];
        DISPATCH_ANE_EVENT(context, EVENT_CONSUME_FAILURE, (uint8_t*)[errorMessage UTF8String]);
    }

    return NULL;
}


DEFINE_ANE_FUNCTION(restorePurchase) {
    
    DISPATCH_LOG_EVENT(context, @"Restoring the previous purchases ... (only state purchased are sent)");

    NSMutableArray *transactionsArray = [NSMutableArray array];
    NSString *logMessage;

    NSArray *transactions = [[SKPaymentQueue defaultQueue] transactions];
    for (SKPaymentTransaction *transaction in transactions) {

        NSString *transactionState = [TransactionObserver formatTypeToString:transaction.transactionState];
        logMessage = [NSString stringWithFormat:@"transaction id: %@, state: %@, error: %@, productId: %@",
                                                transaction.transactionIdentifier, transactionState, transaction.error,
                                                transaction.payment.productIdentifier];
        DISPATCH_LOG_EVENT(context, logMessage);

        if (transaction.transactionState == SKPaymentTransactionStatePurchased) {

            NSString *transactionJson = [TransactionObserver buildJSONStringOfPurchaseWithTransaction:transaction];
            DISPATCH_LOG_EVENT(context, transactionJson);

            [transactionsArray addObject: transactionJson];
        }
    }

    DISPATCH_LOG_EVENT(context, @"Purchases array completed.");
    NSString *result = [transactionsArray componentsJoinedByString:@","];
    logMessage = [NSString stringWithFormat:@"Complete. Returning the following product IDs list : %@", result];
    DISPATCH_LOG_EVENT(context, logMessage);

    result = [NSString stringWithFormat:@"[%@]", result];
    DISPATCH_ANE_EVENT(context, EVENT_PURCHASES_RETRIEVED, (uint8_t*) result.UTF8String);

    return NULL;
}

// used for debug only - not in public api
DEFINE_ANE_FUNCTION(printTransactions) {

    DISPATCH_LOG_EVENT(context, @"Print transactions ...");

    NSArray *transactions = [[SKPaymentQueue defaultQueue] transactions];
    for (SKPaymentTransaction *transaction in transactions) {
        NSString *transactionState = [TransactionObserver formatTypeToString:transaction.transactionState];
        NSLog(@"transaction id: %@, state: %@", transaction.transactionIdentifier, transactionState);
    }

    return NULL;
}

void InAppPurchaseIosExtensionContextInitializer( void* extData, const uint8_t* ctxType, FREContext ctx, uint32_t* numFunctionsToSet, const FRENamedFunction** functionsToSet )
{
    static FRENamedFunction mopubFunctionMap[] =
    {
        MAP_FUNCTION(initialize, NULL),
        MAP_FUNCTION(getProducts, NULL),
        MAP_FUNCTION(consumeProduct, NULL),
        MAP_FUNCTION(buyProduct, NULL),
        MAP_FUNCTION(restorePurchase, NULL),
        MAP_FUNCTION(printTransactions, NULL)
    };
        
    *numFunctionsToSet = sizeof( mopubFunctionMap ) / sizeof( FRENamedFunction );
    *functionsToSet = mopubFunctionMap;
}

void InAppPurchaseIosExtensionContextFinalizer( FREContext ctx )
{
	return;
}

void InAppPurchaseIosExtensionInitializer( void** extDataToSet, FREContextInitializer* ctxInitializerToSet, FREContextFinalizer* ctxFinalizerToSet )
{
    extDataToSet = NULL;
    *ctxInitializerToSet = &InAppPurchaseIosExtensionContextInitializer;
    *ctxFinalizerToSet = &InAppPurchaseIosExtensionContextFinalizer;
    
    typeConversionHelper = [[TypeConversionHelper alloc] init];
    productsRequestDelegate = [[ProductsRequestDelegate alloc] init];
    transactionObserver = [[TransactionObserver alloc] init];
}

void InAppPurchaseIosExtensionFinalizer()
{
    return;
}
