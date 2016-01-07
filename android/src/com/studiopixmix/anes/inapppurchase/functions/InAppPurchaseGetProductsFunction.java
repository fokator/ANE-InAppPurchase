package com.studiopixmix.anes.inapppurchase.functions;

import android.app.Activity;
import android.os.Bundle;
import com.adobe.fre.FREArray;
import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;
import com.android.vending.billing.IInAppBillingService;
import com.studiopixmix.anes.inapppurchase.InAppPurchaseExtension;
import com.studiopixmix.anes.inapppurchase.InAppPurchaseExtensionContext;
import com.studiopixmix.anes.inapppurchase.InAppPurchaseMessages;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.text.NumberFormat;
import java.util.ArrayList;
import java.util.List;

/**
 * A function used to retrieve the product info for the given product IDs (formated in a String Vector). This method
 * dispatches an event <code>InAppPurchaseMessages.PRODUCTS_LOADED</code> if at least one product info has been loaded, with
 * its data, and can dispatch a <code>InAppPurchaseMessages.PRODUCTS_INVALID</code> if one of the given product IDs has not
 * been found on the in-app billing service, with the related ID(s) in its data.
 */
public class InAppPurchaseGetProductsFunction implements FREFunction {

    /**
     * The response code key used when getting the products details. The differents codes are detailed below.
     */
    private static final String RESPONSE_CODE = "RESPONSE_CODE";

    /**
     * The key used for the products IDs bundle.
     */
    private static final String ITEM_ID_LIST = "ITEM_ID_LIST";

    /**
     * The key used for the products details, formated in an ArrayList of JSONs.
     * http://developer.android.com/google/play/billing/billing_reference.html#getSkuDetails
     */
    private static final String DETAILS_LIST = "DETAILS_LIST";

    private static final int MAX_ONE_REQUEST_COUNT = 20;

    @Override
    public FREObject call(FREContext context, final FREObject[] args) {

        InAppPurchaseExtension.logToAS("Getting products from the native store ...");

        InAppPurchaseExtensionContext extensionContext = (InAppPurchaseExtensionContext) context;
        ArrayList<String> productsIds = FREArrayToArrayList((FREArray) args[0]);

        SkuDetailResponder responder = null;

        if (productsIds.size() > MAX_ONE_REQUEST_COUNT) {
            InAppPurchaseExtension.logToAS("Warning, max items for one request is " + MAX_ONE_REQUEST_COUNT);

            List<List<String>> parts = chopped(productsIds, MAX_ONE_REQUEST_COUNT);
            for (int i = 0; i < parts.size(); i++) {
                ArrayList<String> portionIds = (ArrayList<String>) parts.get(i);

                SkuDetailResponder re = getSkuDetailsFromStore(extensionContext, portionIds);
                if (responder == null) responder = re;
                else responder.add(re);
            }
        } else {

            responder = getSkuDetailsFromStore(extensionContext, productsIds);
        }

        // TODO added invalidIds to event
        // TODO create message object for AS
        extensionContext.dispatchStatusEventAsync(InAppPurchaseMessages.PRODUCTS_LOADED, responder.resultIds.toString());

//        if (responder.hasResultIds()) {
//
//            extensionContext.dispatchStatusEventAsync(InAppPurchaseMessages.PRODUCTS_LOADED, responder.resultIds.toString());
//        }
//        if (responder.hasInvalidIds()) {
//
//            InAppPurchaseExtension.logToAS("Invalid products IDs count: " + responder.invalidIds.size());
//            dispatchInvalidProducts(responder.invalidIds, context);
//        }

        return null;
    }

    // chops a list into non-view sublists of length L
    static <T> List<List<T>> chopped(List<T> list, final int L) {
        List<List<T>> parts = new ArrayList<List<T>>();
        final int N = list.size();
        for (int i = 0; i < N; i += L) {
            parts.add(new ArrayList<T>(
                            list.subList(i, Math.min(N, i + L)))
            );
        }
        return parts;
    }

    private static SkuDetailResponder getSkuDetailsFromStore(InAppPurchaseExtensionContext extensionContext, ArrayList<String> productsIds) {

        InAppPurchaseExtension.logToAS("Requesting the store for the products " + productsIds.toString());

        Activity activity = extensionContext.getActivity();
        String packageName = activity.getPackageName();
        IInAppBillingService iapService = extensionContext.getInAppBillingService();

        // create responder
        SkuDetailResponder responder = new SkuDetailResponder();

        // create request
        Bundle request = new Bundle();
        request.putStringArrayList(ITEM_ID_LIST, productsIds);

        // response from service
        Bundle response;
        try {
            response = iapService.getSkuDetails(InAppPurchaseExtension.API_VERSION, packageName, "inapp", request);
        } catch (Exception e) {
            InAppPurchaseExtension.logToAS("Error while retrieving the products details : " + e.toString());
            return responder;
        }

        if (response == null) {
            InAppPurchaseExtension.logToAS("Error while retrieving the products details : The returned products bundle is null!");
            return responder;
        }

        InAppPurchaseExtension.logToAS("Processing the received products bundle from the store ...");

        // Parsing the received JSON if the response code is success.
        int responseCode = response.getInt(RESPONSE_CODE);
        InAppPurchaseExtension.logToAS("Response code : " + ErrorMessagesBillingCodes.ERRORS_MESSAGES.get(responseCode));
        switch (responseCode) {
            case ResponseCodes.BILLING_RESPONSE_RESULT_OK:

                ArrayList<String> detailsJson = response.getStringArrayList(DETAILS_LIST);
                if (detailsJson == null || detailsJson.size() == 0) {
                    InAppPurchaseExtension.logToAS("No products details retrieved!");

                    if (productsIds.size() > 0) responder.addInvalidIds(productsIds);

                } else {

                    JSONArray result = createResult(detailsJson, productsIds);

                    // Check if there is IDs left in productIds. If this is the case, there were invalid products in the parameters.
                    if (productsIds.size() > 0) responder.addInvalidIds(productsIds);

                    responder.addResultIds(result);
                }
                break;
            default:
                InAppPurchaseExtension.logToAS("Error while loading the products : " + ErrorMessagesBillingCodes.ERRORS_MESSAGES.get(responseCode));
        }

        return responder;
    }

    /**
     * This method removes the received product ID from the "productsIds" received as parameters.
     * It remains only invalid ids in ArrayList.
     *
     * @param detailsJson Service result.
     * @param productsIds Removes the received product ID from the ids received as parameters.
     * @return
     */
    private static JSONArray createResult(ArrayList<String> detailsJson, ArrayList<String> productsIds) {

        ArrayList<JSONObject> details = new ArrayList<JSONObject>();

        // Number formatter used to format the localized price returned by Google to a normal double.
        NumberFormat format = NumberFormat.getInstance();
        format.setMinimumFractionDigits(2);

        int i, length = detailsJson.size();
        for (i = 0; i < length; i++) {
            try {
                // http://developer.android.com/google/play/billing/billing_reference.html#getSkuDetails
                JSONObject currentJsonObject = new JSONObject(detailsJson.get(i));

                JSONObject currentObject = new JSONObject();
                currentObject.put("id", currentJsonObject.get("productId"));
                currentObject.put("title", currentJsonObject.get("title"));
                currentObject.put("description", currentJsonObject.get("description"));

                // Formats the price to an amount rounded to 2 decimals.
                Number number = format.parse(currentJsonObject.get("price_amount_micros").toString());
                currentObject.put("price", format.parse(String.format("%.2f", number.doubleValue() / 1000000.0)).doubleValue());

                currentObject.put("priceCurrencyCode", currentJsonObject.get("price_currency_code"));
                currentObject.put("priceCurrencySymbol", currentJsonObject.get("price").toString().replaceAll("[0-9.,\\s]", ""));

                // The fully formated price to display in your app, with the currency symbol.
                currentObject.put("displayPrice", currentJsonObject.get("price").toString());

                details.add(currentObject);

                // removes the current product ID from the ids received as parameters.
                productsIds.remove(currentObject.get("id"));
            } catch (Exception e) {
                InAppPurchaseExtension.logToAS("Error while parsing the products JSON! " + e.toString());
                return null;
            }
        }

        InAppPurchaseExtension.logToAS("Processed.");
        InAppPurchaseExtension.logToAS("Found " + details.size() + " products.");

        JSONArray data = new JSONArray(details);

        InAppPurchaseExtension.logToAS("Returning " + data.toString() + " to the app.");

        return data;
    }

    /**
     * Returns the given FREArray as an String ArrayList. This method is used to cast the products IDs in FREArray
     * into a java collection to communicate with the Google in-app billing service.
     */
    private static ArrayList<String> FREArrayToArrayList(FREArray array) {
        int i;
        long length = 0;
        ArrayList<String> list = new ArrayList<String>();

        try {
            length = array.getLength();
        } catch (Exception e) {
            InAppPurchaseExtension.logToAS("Error while reading the products IDs : " + e.toString());
        }

        for (i = 0; i < length; i++) {
            try {
                list.add(array.getObjectAt(i).getAsString());
            } catch (Exception e) {
                InAppPurchaseExtension.logToAS("Error while reading the products IDs : " + e.toString());
            }
        }

        return list;
    }

    /**
     * Dispatches a <code>PRODUCTS_INVALID</code> with the given collection of string as related product IDs.
     */
//    private static void dispatchInvalidProducts(ArrayList<String> productIds, FREContext context) {
//        JSONArray invalidProductsJson = new JSONArray();
//        int i, length;
//        for (i = 0, length = productIds.size(); i < length; i++) {
//            invalidProductsJson.put(productIds.get(i));
//        }
//        context.dispatchStatusEventAsync(InAppPurchaseMessages.PRODUCTS_INVALID, invalidProductsJson.toString());
//    }

    private static class SkuDetailResponder {
        private ArrayList<String> invalidIds = new ArrayList<String>();
        private JSONArray resultIds = new JSONArray();

        void addInvalidIds(ArrayList<String> ids) {
            for (int j = 0; j < ids.size(); j++) {
                invalidIds.add(ids.get(j));
            }
        }

        Boolean hasInvalidIds() {
            return invalidIds.size() > 0;
        }

        void addResultIds(JSONArray ids) {
            for (int i = 0; i < ids.length(); i++) {
                try {
                    resultIds.put(ids.get(i));
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            }
        }

        Boolean hasResultIds() {
            return resultIds.length() > 0;
        }

        void add(SkuDetailResponder responder) {
            addInvalidIds(responder.invalidIds);
            addResultIds(responder.resultIds);
        }
    }
}
