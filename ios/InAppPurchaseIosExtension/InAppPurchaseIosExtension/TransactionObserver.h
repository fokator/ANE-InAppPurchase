//
//  TransactionObserver.h
//  InAppPurchaseIosExtension
//
//  Created by Antoine Kleinpeter on 05/11/14.
//  Copyright (c) 2014 studiopixmix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "FlashRuntimeExtensions.h"

// helper method to generating dictionaries for json encoding
id convertNil(id value) { return value != nil ? value : [NSNull null]; }

@interface TransactionObserver : NSObject<SKPaymentTransactionObserver>

@property (nonatomic, assign) FREContext context;

+ (NSString *) buildJSONStringOfPurchaseWithTransaction:(SKPaymentTransaction *)transaction;
+ (NSString *) formatTypeToString:(SKPaymentTransactionState)transactionState;

@end
