package com.studiopixmix.anes.inapppurchase.functions;

import android.app.Activity;
import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;
import com.android.vending.billing.IInAppBillingService;
import com.studiopixmix.anes.inapppurchase.InAppPurchaseExtension;
import com.studiopixmix.anes.inapppurchase.InAppPurchaseExtensionContext;
import com.studiopixmix.anes.inapppurchase.InAppPurchaseMessages;
import org.json.JSONArray;

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

        List<Purchase> purchasesList = null;
        try {
            purchasesList = PurchasesHelper.getPurchasesData(iapService, packageName, "inapp", null);
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
        InAppPurchaseExtension.logToAS("\t" + purchasesToDispatch.toString());
        extensionContext.dispatchStatusEventAsync(InAppPurchaseMessages.PURCHASES_RETRIEVED, purchasesToDispatch.toString());

        return null;
    }
}
