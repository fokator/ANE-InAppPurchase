package com.studiopixmix.anes.inapppurchase.functions;

import org.json.JSONException;
import org.json.JSONObject;

/**
 * Created by rjuhasz on 7. 10. 2015.
 */
public class Purchase extends JSONObject {

    public Purchase(String purchaseData, String dataSignature) throws JSONException {

        JSONObject item = new JSONObject(purchaseData);

        put("productId", item.getString("productId"));
        put("transactionTimestamp", item.getInt("purchaseTime"));
        put("purchaseToken", item.get("purchaseToken"));
        put("purchaseState", item.get("purchaseState"));
        if (item.has("orderId")) {
            // A unique order identifier for the transaction. This identifier corresponds to the Google payments order ID.
            put("orderId", item.get("orderId"));
        } else {
            // If the order is a test purchase made through the In-app Billing Sandbox, orderId is blank.
            put("orderId", "");
        }
        put("signature", dataSignature);
        put("playStoreResponse", purchaseData);
        if (item.has("developerPayload")) {

            put("developerPayload", item.get("developerPayload"));
        }
    }

    public String getProductId() {
        try {
            return (String) get("productId");
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return null;
    }

    public String getPurchaseToken() {
        try {
            return (String) get("purchaseToken");
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return null;
    }

}
