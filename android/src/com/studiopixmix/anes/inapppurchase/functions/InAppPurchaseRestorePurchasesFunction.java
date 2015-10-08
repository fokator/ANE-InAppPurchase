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
import org.json.JSONArray;
import org.json.JSONException;

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
        List<String> purchasesList = null;
        try {
            purchasesList = getPurchasesData(iapService, packageName, "inapp", null);
            InAppPurchaseExtension.logToAS("PurchasesList value : " + purchasesList);
        } catch (Exception e) {
            InAppPurchaseExtension.logToAS("Error while retrieving the previous purchases : " + e.toString() + "\n at " + e.getStackTrace());
            extensionContext.dispatchStatusEventAsync(InAppPurchaseMessages.PURCHASES_RETRIEVING_FAILED, e.getMessage());
            return null;
        }

        if (purchasesList == null || purchasesList.size() == 0) {

            InAppPurchaseExtension.logToAS("no purchases to restore, returning ...");
            extensionContext.dispatchStatusEventAsync(InAppPurchaseMessages.PURCHASES_RETRIEVED, "");
            return null;
        }

        JSONArray purchasesToDispatch = new JSONArray();
        for (int i = 0; i < purchasesList.size(); i++) {
            purchasesToDispatch.put(purchasesList.get(i));
        }

        InAppPurchaseExtension.logToAS("Found " + purchasesList.size() + " purchases to restore ... returning:");
        InAppPurchaseExtension.logToAS("\t" + purchasesToDispatch);
        extensionContext.dispatchStatusEventAsync(InAppPurchaseMessages.PURCHASES_RETRIEVED, purchasesToDispatch.toString());

        return null;
    }

    private static List<String> getPurchasesData(IInAppBillingService iapService, String packageName, String type, String continuationToken) throws RemoteException, JSONException {
        Bundle bundle = iapService.getPurchases(InAppPurchaseExtension.API_VERSION, packageName, type, continuationToken);

        // Parsing the received JSON if the response code is success.
        int responseCode = bundle.getInt(PurchasesBundleKey.RESPONSE_CODE);
        ArrayList<String> purchases = null;
        ArrayList<String> signatures = null;

        if (responseCode == ResponseCodes.BILLING_RESPONSE_RESULT_OK) {

            purchases = bundle.getStringArrayList(PurchasesBundleKey.INAPP_PURCHASE_DATA_LIST);
            signatures = bundle.getStringArrayList(PurchasesBundleKey.INAPP_DATA_SIGNATURE_LIST);

            InAppPurchaseExtension.logToAS("Native store returned " + purchases);
            String cToken = bundle.getString(PurchasesBundleKey.INAPP_CONTINUATION_TOKEN);

            if (continuationToken != null) {
                InAppPurchaseExtension.logToAS("There is a continuation token, fetching the next purchases ...");

                // There is a continuation token, retrieving next part ... Recursive call.
                List<String> nextData = getPurchasesData(iapService, packageName, type, cToken);
                if (nextData != null) {
                    purchases.addAll(nextData);
                }
            }
        } else {
            InAppPurchaseExtension.logToAS("Error while loading the products: " + ErrorMessagesBillingCodes.ERRORS_MESSAGES.get(responseCode));
        }

        // merge data
        List<String> transactions = new ArrayList<String>();
        for (int i = 0; i < purchases.size(); i++) {
            Purchase transaction = new Purchase(purchases.get(i), signatures.get(i));
            transactions.add(transaction.toString());
        }

        return transactions;
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
