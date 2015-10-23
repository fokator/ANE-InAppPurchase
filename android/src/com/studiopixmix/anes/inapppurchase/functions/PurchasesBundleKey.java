package com.studiopixmix.anes.inapppurchase.functions;

/**
 * Keys, response data that is returned in the Bundle.
 * <p/>
 * http://developer.android.com/google/play/billing/billing_reference.html#getPurchases
 */
public class PurchasesBundleKey {

    /**
     * The response code key used when getting the products details. The differents codes are detailed below.
     * Value is 0 if the request was successful, error otherwise.
     */
    public static final String RESPONSE_CODE = "RESPONSE_CODE";

    /**
     * The list of the productIds previously bought by the user.
     * StringArrayList containing the list of productIds of purchases from this app.
     */
    public static final String INAPP_PURCHASE_ITEM_LIST = "INAPP_PURCHASE_ITEM_LIST";

    /**
     * StringArrayList containing the details for purchases from this app.
     * See table 4 for the list of detail information stored in each INAPP_PURCHASE_DATA item in the list.
     */
    public static final String INAPP_PURCHASE_DATA_LIST = "INAPP_PURCHASE_DATA_LIST";

    /**
     * StringArrayList containing the signatures
     * StringArrayList containing the signatures of purchases from this app.
     */
    public static final String INAPP_DATA_SIGNATURE_LIST = "INAPP_DATA_SIGNATURE_LIST";

    /**
     * The continuation token used if the list was too long to fit in one request. If this property is not null in the response Bundle, a new call to
     * <code>getPurchases</code> should be made with the continuation token as parameter..
     */
    public static final String INAPP_CONTINUATION_TOKEN = "INAPP_CONTINUATION_TOKEN";
}
