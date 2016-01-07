//
//  ProductsRequestDelegate.m
//  InAppPurchaseIosExtension
//
//  Created by Antoine Kleinpeter on 04/11/14.
//  Copyright (c) 2014 studiopixmix. All rights reserved.
//

#import "ProductsRequestDelegate.h"
#import "ExtensionDefs.h"
#import <StoreKit/StoreKit.h>

@interface ProductsRequestDelegate () <SKProductsRequestDelegate>

@end

@implementation ProductsRequestDelegate

- (void) productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    DISPATCH_LOG_EVENT(self.context, @"Products request did receive response.");
    
    self.currentResponse = response;
    
    //[self dispatchEventForInvalidProducts];
	
    NSMutableArray *result = [NSMutableArray arrayWithArray:self.products];
    for (SKProduct *product in response.products) {
		bool isNew = true;
		for (SKProduct *prod in result) {
			if ([product.productIdentifier isEqualToString:prod.productIdentifier]) {
				isNew = false;
			}
		}
		if (isNew) [result addObject:product];
	}
	self.products = result;
    
    DISPATCH_LOG_EVENT(self.context, @"Building JSON of the loaded products.");

    NSString *productsReturned = [self buildJSONStringOfProducts:response.products];
	NSData *invalidJsonData = [NSJSONSerialization dataWithJSONObject:self.currentResponse.invalidProductIdentifiers options:NSJSONWritingPrettyPrinted error:nil];
	NSString *invalid = [[NSString alloc] initWithData:invalidJsonData encoding:NSUTF8StringEncoding];	
	NSString *jsonString = [NSString stringWithFormat:@"{\"resultIds\":%@ ,\"invalidIds\":%@}", productsReturned, invalid];

	NSString *debugMessage = [NSString stringWithFormat:@"Dispatching JSON built.  %@", jsonString];
    DISPATCH_LOG_EVENT(self.context, debugMessage);
	
    DISPATCH_ANE_EVENT(self.context, EVENT_PRODUCTS_LOADED, (uint8_t*)jsonString.UTF8String);
}

- (SKProduct *) getProductWithId:(NSString *)productId {
    if (self.products == nil)
        return nil;
  
    for (SKProduct *product in self.products) {
        if ([product.productIdentifier isEqualToString:productId])
            return product;
    }
    
    return nil;
}

- (NSString *) buildJSONStringOfProducts:(NSArray *)products {
    NSMutableArray *productsJSONArray = [[NSMutableArray alloc] init];
    NSString *logMessage;
    for (SKProduct *product in products) {
	    logMessage = [NSString stringWithFormat:@" - product : %@", [self buildJSONDictionaryOfProduct:product]];
		DISPATCH_LOG_EVENT(self.context, logMessage);

        [productsJSONArray addObject:[self buildJSONDictionaryOfProduct:product]];
	}

    NSData *data = [NSJSONSerialization dataWithJSONObject:productsJSONArray options:NSJSONWritingPrettyPrinted error:nil];
    
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (NSDictionary *) buildJSONDictionaryOfProduct:(SKProduct *)product {
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [numberFormatter setLocale:product.priceLocale];
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
     product.productIdentifier, @"id",
     product.localizedTitle, @"title",
     product.localizedDescription, @"description",
     product.price, @"price",
     [product.priceLocale objectForKey:NSLocaleCurrencyCode], @"priceCurrencyCode",
     [product.priceLocale objectForKey:NSLocaleCurrencySymbol], @"priceCurrencySymbol",
     [numberFormatter stringFromNumber:product.price], @"displayPrice",
     nil];
}
@end
