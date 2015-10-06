package com.studiopixmix.anes.inapppurchase.functions;

/**
 * Created by rjuhasz on 6. 10. 2015.
 */
public class ResponseCodes {

    /**
     * Billing response codes
     * The error codes messages, in String, as described in the Google documentation.
     *
     * @see <a href="http://developer.android.com/google/play/billing/billing_reference.html#billing-codes">Google response codes documentation</a>
     */
    public static final int BILLING_RESPONSE_RESULT_OK = 0;
    public static final int BILLING_RESPONSE_RESULT_USER_CANCELED = 1;
    public static final int BILLING_RESPONSE_RESULT_BILLING_UNAVAILABLE = 3;
    public static final int BILLING_RESPONSE_RESULT_ITEM_UNAVAILABLE = 4;
    public static final int BILLING_RESPONSE_RESULT_DEVELOPER_ERROR = 5;
    public static final int BILLING_RESPONSE_RESULT_ERROR = 6;
    public static final int BILLING_RESPONSE_RESULT_ITEM_ALREADY_OWNED = 7;
    public static final int BILLING_RESPONSE_RESULT_ITEM_NOT_OWNED = 8;
}
