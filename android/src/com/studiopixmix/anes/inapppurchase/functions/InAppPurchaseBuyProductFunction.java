package com.studiopixmix.anes.inapppurchase.functions;

import android.app.Activity;
import android.app.PendingIntent;
import android.content.Intent;
import android.os.Bundle;
import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;
import com.android.vending.billing.IInAppBillingService;
import com.studiopixmix.anes.inapppurchase.InAppPurchaseExtension;
import com.studiopixmix.anes.inapppurchase.InAppPurchaseExtensionContext;
import com.studiopixmix.anes.inapppurchase.InAppPurchaseMessages;
import com.studiopixmix.anes.inapppurchase.activities.BillingActivity;
import org.json.JSONObject;

/**
 * A function that handles the purchase flow and has also a <code>consumeProduct</code> static method
 * that can be used anywhere on the native side.
 */
public class InAppPurchaseBuyProductFunction implements FREFunction {

    // CONSTANTS :
    /**
     * The bundle key of the response code after a buy intent.
     */
    private static final String RESPONSE_CODE = "RESPONSE_CODE";
    /**
     * The request code for the buy intent.
     */
    private static final int BUY_REQUEST_CODE = 111111;  //  -> arbitrary picked request code.

    // PROPERTIES :
    /**
     * The context passed to the main method, it will be used in the activity response.
     * TODO need the static?
     */
    private static InAppPurchaseExtensionContext mContext;

    /////////////
    // METHODS //
    /////////////

    @Override
    public FREObject call(FREContext c, FREObject[] args) {
        mContext = (InAppPurchaseExtensionContext) c;

        String productId;
        String payload = null;
        try {
            productId = args[0].getAsString();
            if (args[1] != null) {

                payload = args[1].getAsString();
            }

        } catch (Exception e) {
            InAppPurchaseExtension.logToAS("Error while retrieving the product ID! " + e.toString());
            mContext.dispatchStatusEventAsync(InAppPurchaseMessages.PURCHASE_FAILURE, e.toString());
            return null;
        }

        buyProduct(productId, payload);

        return null;
    }

    private void buyProduct(String productId, String payload) {

        Bundle buyIntentBundle;
        try {
            IInAppBillingService service = mContext.getInAppBillingService();
            Activity activity = mContext.getActivity();
            String packageName = activity.getPackageName();

            buyIntentBundle = service.getBuyIntent(InAppPurchaseExtension.API_VERSION, packageName, productId, "inapp", payload);

        } catch (Exception e) {
            InAppPurchaseExtension.logToAS("Error while the buy intent! " + e.toString());
            mContext.dispatchStatusEventAsync(InAppPurchaseMessages.PURCHASE_FAILURE, e.toString());
            return;
        }

        int responseCode = buyIntentBundle.getInt(RESPONSE_CODE);
        switch (responseCode) {
            case ResponseCodes.BILLING_RESPONSE_RESULT_OK:
                // Everything's fine, starting the buy intent.
                PendingIntent pendingIntent = buyIntentBundle.getParcelable("BUY_INTENT");
                try {
                    // Creates the new activity to do the billing process, and adding it the extra info to start the request.
                    Intent intent = new Intent(mContext.getActivity(), BillingActivity.class);
                    intent.putExtra("PENDING_INTENT", pendingIntent);
                    intent.putExtra("REQUEST_CODE", BUY_REQUEST_CODE);
                    intent.putExtra("DEV_PAYLOAD", payload);
                    mContext.getActivity().startActivity(intent);
                } catch (Exception e) {
                    InAppPurchaseExtension.logToAS("Error while the buy intent!\n " + e.toString() + "\n" + InAppPurchaseExtension.getStackString(e));
                    mContext.dispatchStatusEventAsync(InAppPurchaseMessages.PURCHASE_FAILURE, e.toString());
                }

                break;
            case ResponseCodes.BILLING_RESPONSE_RESULT_USER_CANCELED:
                InAppPurchaseExtension.logToAS("User cancelled the purchase.");
                mContext.dispatchStatusEventAsync(InAppPurchaseMessages.PURCHASE_CANCELED, "");

                break;
            default:
                InAppPurchaseExtension.logToAS("Error while the buy intent : " + ErrorMessagesBillingCodes.ERRORS_MESSAGES.get(responseCode));
                mContext.dispatchStatusEventAsync(InAppPurchaseMessages.PURCHASE_FAILURE, ErrorMessagesBillingCodes.ERRORS_MESSAGES.get(responseCode));

        }
    }

    /**
     * The response of the pending intent.
     */
    public static void onIntentFinished(Activity sourceActivity, int requestCode, int resultCode, Intent buyIntent, String devPayload) {

        InAppPurchaseExtension.logToAS("Intent finished");

        sourceActivity.finish();

        if (requestCode == BUY_REQUEST_CODE) {

            if (resultCode == Activity.RESULT_CANCELED) {

                InAppPurchaseExtension.logToAS("Purchase has been cancelled!");
                mContext.dispatchStatusEventAsync(InAppPurchaseMessages.PURCHASE_CANCELED, "");
            } else {
                // http://developer.android.com/google/play/billing/billing_reference.html#getBuyIntent
                int responseCode = buyIntent.getIntExtra("RESPONSE_CODE", 0);
                String purchaseData = buyIntent.getStringExtra("INAPP_PURCHASE_DATA");
                String dataSignature = buyIntent.getStringExtra("INAPP_DATA_SIGNATURE");

                switch (responseCode) {
                    case ResponseCodes.BILLING_RESPONSE_RESULT_OK:

                        JSONObject item = null;
                        Boolean hasSimilarPayload = true;
                        try {
                            item = new JSONObject(purchaseData);
                            if (item.has("developerPayload")) {

                                hasSimilarPayload = devPayload.equals(item.getString("developerPayload"));
                            }
                        } catch (Exception e) {
                            mContext.dispatchStatusEventAsync(InAppPurchaseMessages.PURCHASE_FAILURE, "Error while converting the bought product data to JSONObject!");
                            return;
                        }

                        if (!hasSimilarPayload) {

                            onPurchaseVerificationFailed(item, mContext.getActivity().getPackageName());
                            return;
                        }

                        Purchase purchase;
                        try {
                            purchase = new Purchase(purchaseData, dataSignature);

                        } catch (Exception e) {
                            mContext.dispatchStatusEventAsync(InAppPurchaseMessages.PURCHASE_FAILURE, "Error while creating the returned JSONObject!");
                            return;
                        }

                        InAppPurchaseExtension.logToAS("The product has been successfully bought! returning it with the event ...");
                        mContext.dispatchStatusEventAsync(InAppPurchaseMessages.PURCHASE_SUCCESS, purchase.toString());

                        break;
                    case ResponseCodes.BILLING_RESPONSE_RESULT_USER_CANCELED:
                        InAppPurchaseExtension.logToAS("Purchase has been cancelled!");
                        mContext.dispatchStatusEventAsync(InAppPurchaseMessages.PURCHASE_CANCELED, "");

                        break;
                    default:
                        InAppPurchaseExtension.logToAS("The purchase failed! " + ErrorMessagesBillingCodes.ERRORS_MESSAGES.get(responseCode));
                        mContext.dispatchStatusEventAsync(InAppPurchaseMessages.PURCHASE_FAILURE, ErrorMessagesBillingCodes.ERRORS_MESSAGES.get(responseCode));

                }
            }
        }
    }

    ///////////////////
    // FAULT HANDLER //
    ///////////////////

    /**
     * Executed after processing the purchase, if the purchase payload does not match the developer payload given when
     * calling the <code>buyProduct</code> method. Consumes the product, otherwise the product will be "blocked" as it
     * cannot be bought again if not consumed, and dispatches a purchase failed event.
     */
    private static void onPurchaseVerificationFailed(JSONObject item, String packageName) {

        int response = -1;
        try {
            IInAppBillingService service = mContext.getInAppBillingService();
            String purchaseToken = item.getString("purchaseToken");

            response = service.consumePurchase(InAppPurchaseExtension.API_VERSION, packageName, purchaseToken);

        } catch (Exception e) {
            InAppPurchaseExtension.logToAS(InAppPurchaseExtension.getStackString(e));
        }

        if (response != 0) {

            InAppPurchaseExtension.logToAS("Failed to consume a non-verified purchase!");
            mContext.dispatchStatusEventAsync(InAppPurchaseMessages.PURCHASE_FAILURE, "Failed to consume a non-verified purchase!");
        } else {

            InAppPurchaseExtension.logToAS("Received a purchase with an unknown payload! Purchase aborted and successfully consumed.");
            mContext.dispatchStatusEventAsync(InAppPurchaseMessages.PURCHASE_FAILURE, "Received a purchase with an unknown payload! Purchase aborted and successfully consumed.");
        }
    }
}

