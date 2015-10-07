package com.studiopixmix.anes.inapppurchase.functions;

import android.app.Activity;
import android.os.Bundle;
import android.os.RemoteException;
import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;
import com.android.vending.billing.IInAppBillingService;
import com.studiopixmix.anes.inapppurchase.InAppPurchaseExtension;
import com.studiopixmix.anes.inapppurchase.InAppPurchaseExtensionContext;
import com.studiopixmix.anes.inapppurchase.InAppPurchaseMessages;

import java.util.ArrayList;
import java.util.List;

/**
 * A function that retrieves the user's previous purchase by requesting the store. This method returns
 */
public class InAppPurchaseRestorePurchasesFunction implements FREFunction {

    @Override
    public FREObject call(FREContext context, FREObject[] args) {

        InAppPurchaseExtensionContext extensionContext = (InAppPurchaseExtensionContext) context;
        Activity activity = extensionContext.getActivity();
        String packageName = activity.getPackageName();
        IInAppBillingService iapService = extensionContext.getInAppBillingService();

        InAppPurchaseExtension.logToAS("Restoring the user's purchases ...");

        // Retrieves the products details.
        List<String> purchaseIds = null;
        try {
            purchaseIds = getPurchaseIds(iapService, packageName, "inapp", null);
            InAppPurchaseExtension.logToAS("PurchaseIds value : " + purchaseIds);
        } catch (Exception e) {
            InAppPurchaseExtension.logToAS("Error while retrieving the previous purchases : " + e.toString() + "\n at " + e.getStackTrace());
            extensionContext.dispatchStatusEventAsync(InAppPurchaseMessages.PURCHASES_RETRIEVING_FAILED, e.getMessage());
            return null;
        }

        if (purchaseIds == null || purchaseIds.size() == 0) {

            InAppPurchaseExtension.logToAS("no purchases to restore, returning ...");
            extensionContext.dispatchStatusEventAsync(InAppPurchaseMessages.PURCHASES_RETRIEVED, "");
            return null;
        }

        // We have at least 1 purchase to restore.
        String purchases = purchaseIds.get(0);
        for (int i = 1; i < purchaseIds.size(); i++) {
            purchases += "," + purchaseIds.get(i);
        }

        InAppPurchaseExtension.logToAS("Found " + purchaseIds.size() + " purchases to restore ... returning their IDs : " + purchases);
        extensionContext.dispatchStatusEventAsync(InAppPurchaseMessages.PURCHASES_RETRIEVED, purchases);

        return null;
    }

    /**
     * Recursively calls <code>getPruchases</code> to retrieve all the purchased products for the user. The method uses a continuation token
     * to handle the case where the list of purchases is too large to fit in one request.
     *
     * @throws RemoteException
     */
    private static List<String> getPurchaseIds(IInAppBillingService iapService, String packageName, String type, String continuationToken) throws RemoteException {
        Bundle bundle = iapService.getPurchases(InAppPurchaseExtension.API_VERSION, packageName, type, continuationToken);

        // Parsing the received JSON if the response code is success.
        int responseCode = bundle.getInt(PurchasesBundleKey.RESPONSE_CODE);
        ArrayList<String> productsIds = null;

        if (responseCode == ResponseCodes.BILLING_RESPONSE_RESULT_OK) {
            productsIds = bundle.getStringArrayList(PurchasesBundleKey.INAPP_PURCHASE_ITEM_LIST);

            // TODO ...
            InAppPurchaseExtension.logToAS(" --- " + bundle.getStringArrayList(PurchasesBundleKey.INAPP_PURCHASE_DATA_LIST));
            InAppPurchaseExtension.logToAS(" --- " + bundle.getStringArrayList(PurchasesBundleKey.INAPP_DATA_SIGNATURE_LIST));

            InAppPurchaseExtension.logToAS("Native store returned " + productsIds);
            String cToken = bundle.getString(PurchasesBundleKey.INAPP_CONTINUATION_TOKEN);

            if (continuationToken != null) {
                InAppPurchaseExtension.logToAS("There is a continuation token, fetching the next purchases ...");

                // There is a continuation token, retrieving next part ...
                List<String> ids = getPurchaseIds(iapService, packageName, type, cToken);
                if (ids != null)
                    productsIds.addAll(ids);
            }
        } else {
            InAppPurchaseExtension.logToAS("Error while loading the products: " + ErrorMessagesBillingCodes.ERRORS_MESSAGES.get(responseCode));
        }

        return productsIds;
    }

    /**
     * Keys, response data that is returned in the Bundle.
     * <p/>
     * http://developer.android.com/google/play/billing/billing_reference.html#getPurchases
     */
    private static class PurchasesBundleKey {

        /**
         * The response code key used when getting the products details. The differents codes are detailed below.
         * Value is 0 if the request was successful, error otherwise.
         */
        private static final String RESPONSE_CODE = "RESPONSE_CODE";

        /**
         * The list of the productIds previously bought by the user.
         * StringArrayList containing the list of productIds of purchases from this app.
         */
        private static final String INAPP_PURCHASE_ITEM_LIST = "INAPP_PURCHASE_ITEM_LIST";

        /**
         * StringArrayList containing the details for purchases from this app.
         * See table 4 for the list of detail information stored in each INAPP_PURCHASE_DATA item in the list.
         */
        private static final String INAPP_PURCHASE_DATA_LIST = "INAPP_PURCHASE_DATA_LIST";

        /**
         * StringArrayList containing the signatures
         * StringArrayList containing the signatures of purchases from this app.
         */
        private static final String INAPP_DATA_SIGNATURE_LIST = "INAPP_DATA_SIGNATURE_LIST";

        /**
         * The continuation token used if the list was too long to fit in one request. If this property is not null in the response Bundle, a new call to
         * <code>getPurchases</code> should be made with the continuation token as parameter..
         */
        private static final String INAPP_CONTINUATION_TOKEN = "INAPP_CONTINUATION_TOKEN";
    }
}
