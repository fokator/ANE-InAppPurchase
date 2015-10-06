package com.studiopixmix.anes.inapppurchase.functions;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;
import com.studiopixmix.anes.inapppurchase.InAppPurchaseExtension;
import com.studiopixmix.anes.inapppurchase.InAppPurchaseExtensionContext;
import com.studiopixmix.anes.inapppurchase.InAppPurchaseMessages;

/**
 * A function that consumes the given purchase token. On Android, consuming a purchase allows the user to purchase it again
 * (for example if your product is a pack of 5 lives for a game, the user should be allowed to buy it several times).
 */
public class InAppPurchaseConsumeProductFunction implements FREFunction {

    @Override
    public FREObject call(FREContext c, FREObject[] args) {
        InAppPurchaseExtensionContext context = (InAppPurchaseExtensionContext) c;
        String purchaseToken = null;

        try {
            purchaseToken = args[0].getAsString();
        } catch (Exception e) {
            InAppPurchaseExtension.logToAS("The consume product has failed : Could not retrieve the purchase token!");
            context.dispatchStatusEventAsync(InAppPurchaseMessages.CONSUME_FAILED, "The consume product has failed : Could not retrieve the purchase token!");
        }

        consumeProduct(purchaseToken, context);

        return null;
    }

    /**
     * Consumes the product related to the given purchase token.
     */
    public static void consumeProduct(String purchaseToken, InAppPurchaseExtensionContext context) {

        int response = -1;
        try {
            response = context.getInAppBillingService().consumePurchase(InAppPurchaseExtension.API_VERSION, context.getActivity().getPackageName(), purchaseToken);
        } catch (Exception e) {
            InAppPurchaseExtension.logToAS("The consume product has failed!");
            context.dispatchStatusEventAsync(InAppPurchaseMessages.CONSUME_FAILED, "The consume product has failed!");
            return;
        }

        if (response == 0) {

            try {
                InAppPurchaseExtension.logToAS("The product has been successfully consumed! returning it with the event ...");
                context.dispatchStatusEventAsync(InAppPurchaseMessages.CONSUME_SUCCESS, purchaseToken);
            } catch (Exception e) {
                InAppPurchaseExtension.logToAS("The consume product has failed!");
                context.dispatchStatusEventAsync(InAppPurchaseMessages.CONSUME_FAILED, "The consume product has failed!");
            }
        } else {

            InAppPurchaseExtension.logToAS("The consume product has failed!");
            context.dispatchStatusEventAsync(InAppPurchaseMessages.CONSUME_FAILED, "The consume product has failed!");
        }
    }

}
