package com.studiopixmix.anes.inapppurchase.functions;

import java.util.ArrayList;
import java.util.Arrays;

/**
 * Created by rjuhasz on 5. 10. 2015.
 */
public class ErrorMessagesBillingCodes {

    /**
     * The error codes messages, in String, as described in the Google documentation.
     *
     * @see <a href="http://developer.android.com/google/play/billing/billing_reference.html#billing-codes">Google response codes documentation</a>
     */
    static final ArrayList<String> ERRORS_MESSAGES = new ArrayList<String>(Arrays.asList(
            "Success.",
            "User interrupted the request or cancelled the dialog!",
            "The network connection is down!",
            "Billing API version is not supported for the type requested!",
            "Requested product is not available for purchase!",
            "Invalid arguments provided to the API! Have you checked that your application is set for in-app purchases and has the necessary permissions in the manifest?",
            "Fatal error during the API action!",
            "Failure to purchase since item is already owned!",
            "Failure to consume since item is not owned"
    ));
}
