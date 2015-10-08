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
        put("developerPayload", item.get("developerPayload"));
        put("purchaseToken", item.get("purchaseToken"));
        put("orderId", item.get("orderId"));
        put("signature", dataSignature);
        put("playStoreResponse", purchaseData);
    }
}
