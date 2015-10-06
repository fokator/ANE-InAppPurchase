package com.studiopixmix.anes.inapppurchase.functions;

import android.app.Activity;
import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;
import com.android.vending.billing.IInAppBillingService;
import com.studiopixmix.anes.inapppurchase.InAppPurchaseExtension;
import com.studiopixmix.anes.inapppurchase.InAppPurchaseExtensionContext;
import com.studiopixmix.anes.inapppurchase.InAppPurchaseMessages;

/**
 * A function that consumes the given purchase token. On Android, consuming a purchase allows the user to purchase it again
 * (for example if your product is a pack of 5 lives for a game, the user should be allowed to buy it several times).
 */
public class InAppPurchaseConsumeProductFunction implements FREFunction {

    @Override
    public FREObject call(FREContext context, FREObject[] args) {
        InAppPurchaseExtensionContext extensionContext = (InAppPurchaseExtensionContext) context;
        String purchaseToken = null;

        try {
            purchaseToken = args[0].getAsString();
        } catch (Exception e) {
            InAppPurchaseExtension.logToAS("The consume product has failed : Could not retrieve the purchase token!");
            extensionContext.dispatchStatusEventAsync(InAppPurchaseMessages.CONSUME_FAILED, "The consume product has failed : Could not retrieve the purchase token!");
        }

        consumeProduct(purchaseToken, extensionContext);

        return null;
    }

    /**
     * Consumes the product related to the given purchase token.
     *
     * @param purchaseToken
     * @param context
     */
    public static void consumeProduct(String purchaseToken, InAppPurchaseExtensionContext context) {

        int response = -1;
        try {

            IInAppBillingService service = context.getInAppBillingService();
            Activity act = context.getActivity();
            String packageName = act.getPackageName();

            response = service.consumePurchase(InAppPurchaseExtension.API_VERSION, packageName, purchaseToken);

        } catch (Exception e) {

            InAppPurchaseExtension.logToAS("The consume product has failed!");
            context.dispatchStatusEventAsync(InAppPurchaseMessages.CONSUME_FAILED, "The consume product has failed!");
            return;
        }

        if (response == 0) { // 0 if consumption succeeded. Appropriate error values for failures.

            try {

                InAppPurchaseExtension.logToAS("The product has been successfully consumed! returning it with the event ...");
                context.dispatchStatusEventAsync(InAppPurchaseMessages.CONSUME_SUCCESS, purchaseToken);

            } catch (Exception e) {

                InAppPurchaseExtension.logToAS("The consume product has failed!");
                context.dispatchStatusEventAsync(InAppPurchaseMessages.CONSUME_FAILED, "The consume product has failed!");

            }
        } else {

            InAppPurchaseExtension.logToAS("The consume product has failed! response:" + response);
            context.dispatchStatusEventAsync(InAppPurchaseMessages.CONSUME_FAILED, "The consume product has failed! response:" + response);
        }
    }

}
