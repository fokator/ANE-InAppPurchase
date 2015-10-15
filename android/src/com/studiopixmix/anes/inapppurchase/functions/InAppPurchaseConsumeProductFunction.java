package com.studiopixmix.anes.inapppurchase.functions;

import android.app.Activity;
import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;
import com.android.vending.billing.IInAppBillingService;
import com.studiopixmix.anes.inapppurchase.InAppPurchaseExtension;
import com.studiopixmix.anes.inapppurchase.InAppPurchaseExtensionContext;
import com.studiopixmix.anes.inapppurchase.InAppPurchaseMessages;

import java.util.List;

public class InAppPurchaseConsumeProductFunction implements FREFunction {

    @Override
    public FREObject call(FREContext context, FREObject[] args) {
        InAppPurchaseExtensionContext extensionContext = (InAppPurchaseExtensionContext) context;

        String productId = null;
        try {
            productId = args[0].getAsString();
        } catch (Exception e) {
            InAppPurchaseExtension.logToAS("The consume product has failed : Could not retrieve the purchase productId!");
            extensionContext.dispatchStatusEventAsync(InAppPurchaseMessages.CONSUME_FAILED, "The consume product has failed : Could not retrieve the purchase productId!");
            return null;
        }

        Purchase currentPurchase = null;
        try {
            Activity activity = extensionContext.getActivity();
            String packageName = activity.getPackageName();
            IInAppBillingService iapService = extensionContext.getInAppBillingService();

            List<Purchase> purchases = PurchasesHelper.getPurchasesData(iapService, packageName, "inapp", null);
            for (int i = 0; i < purchases.size(); i++) {
                Purchase purchase = purchases.get(i);
                if (productId.equals(purchase.getProductId())) {
                    currentPurchase = purchase;
                    break;
                }
            }

        } catch (Exception e) {
            String message = "Purchase for productId:" + productId + " has failed Exception:" + InAppPurchaseExtension.getStackString(e);

            InAppPurchaseExtension.logToAS(message);
            extensionContext.dispatchStatusEventAsync(InAppPurchaseMessages.CONSUME_FAILED, message);
        }

        if (currentPurchase == null) {

            InAppPurchaseExtension.logToAS("The consume product has failed : Could not retrieve the transaction for productId:" + productId);
            extensionContext.dispatchStatusEventAsync(InAppPurchaseMessages.CONSUME_FAILED, "The consume product has failed : Could not retrieve the transaction for productId:" + productId);
            return null;
        }

        consumeProduct(currentPurchase, extensionContext);

        return null;
    }

    /**
     * Consumes the product related to the given purchase.
     *
     * @param purchase
     * @param extensionContext
     */
    private static void consumeProduct(Purchase purchase, InAppPurchaseExtensionContext extensionContext) {

        int responseCode = -1;
        try {

            IInAppBillingService service = extensionContext.getInAppBillingService();
            Activity activity = extensionContext.getActivity();
            String packageName = activity.getPackageName();

            responseCode = service.consumePurchase(InAppPurchaseExtension.API_VERSION, packageName, purchase.getPurchaseToken());

        } catch (Exception e) {

            InAppPurchaseExtension.logToAS("The consume product has failed!");
            extensionContext.dispatchStatusEventAsync(InAppPurchaseMessages.CONSUME_FAILED, "The consume product has failed!");
            return;
        }

        switch (responseCode) {
            case ResponseCodes.BILLING_RESPONSE_RESULT_OK:
                InAppPurchaseExtension.logToAS("The product has been successfully consumed! returning it with the event ...");
                extensionContext.dispatchStatusEventAsync(InAppPurchaseMessages.CONSUME_SUCCESS, purchase.toString());

                break;
            default:
                String message = ErrorMessagesBillingCodes.ERRORS_MESSAGES.get(responseCode);

                InAppPurchaseExtension.logToAS("The consume product has failed! response:" + responseCode + ". " + message);
                extensionContext.dispatchStatusEventAsync(InAppPurchaseMessages.CONSUME_FAILED, "The consume product has failed! response:" + responseCode + ". " + message);

        }
    }

}
