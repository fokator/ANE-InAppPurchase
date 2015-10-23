package com.studiopixmix.anes.inapppurchase.functions;

import android.os.Bundle;
import android.os.RemoteException;
import com.android.vending.billing.IInAppBillingService;
import com.studiopixmix.anes.inapppurchase.InAppPurchaseExtension;
import org.json.JSONException;

import java.util.ArrayList;
import java.util.List;

/**
 * Created by rjuhasz on 13. 10. 2015.
 */
public class PurchasesHelper {

    public static List<Purchase> getPurchasesData(IInAppBillingService iapService, String packageName, String type, String continuationToken) throws RemoteException, JSONException {
        Bundle bundle = iapService.getPurchases(InAppPurchaseExtension.API_VERSION, packageName, type, continuationToken);
        List<Purchase> result = new ArrayList<Purchase>();

        int responseCode = bundle.getInt(PurchasesBundleKey.RESPONSE_CODE);
        switch (responseCode) {
            case ResponseCodes.BILLING_RESPONSE_RESULT_OK:
                ArrayList<String> purchases = bundle.getStringArrayList(PurchasesBundleKey.INAPP_PURCHASE_DATA_LIST);
                ArrayList<String> signatures = bundle.getStringArrayList(PurchasesBundleKey.INAPP_DATA_SIGNATURE_LIST);

                for (int i = 0; i < purchases.size(); i++) {
                    Purchase transaction = new Purchase(purchases.get(i), signatures.get(i));
                    result.add(transaction);
                }

                InAppPurchaseExtension.logToAS("Native store returned " + purchases);
                String cToken = bundle.getString(PurchasesBundleKey.INAPP_CONTINUATION_TOKEN);
                if (cToken != null) {
                    InAppPurchaseExtension.logToAS("There is a continuation token, fetching the next purchases ...");

                    // There is a continuation token, retrieving next part ... Recursive call.
                    List<Purchase> nextData = getPurchasesData(iapService, packageName, type, cToken);
                    if (nextData != null) {

                        result.addAll(nextData);
                    }
                }

                break;
            default:
                InAppPurchaseExtension.logToAS("Error while loading the products: " + ErrorMessagesBillingCodes.ERRORS_MESSAGES.get(responseCode));

        }

        return result;
    }
}
