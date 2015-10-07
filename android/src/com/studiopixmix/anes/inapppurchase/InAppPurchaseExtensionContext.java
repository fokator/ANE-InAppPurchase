package com.studiopixmix.anes.inapppurchase;

import android.content.ComponentName;
import android.content.ServiceConnection;
import android.os.IBinder;
import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.android.vending.billing.IInAppBillingService;
import com.studiopixmix.anes.inapppurchase.functions.*;

import java.util.HashMap;
import java.util.Map;

public class InAppPurchaseExtensionContext extends FREContext {

    // PROPERTIES :
    /**
     * The service used to connect the application to the InAppBillingService on Google Play.
     */
    private IInAppBillingService mService;
    private ServiceConnection mServiceConn;

    // CONSTRUCTOR :
    public InAppPurchaseExtensionContext() {
        super();

        connectToService();
    }


    //////////////////////
    // SPECIFIC METHODS //
    //////////////////////


    /**
     * Starts a new ServiceConnection and sets the <code>mService</code> property on connection success. If the connection is lost,
     * re-opens a connection again.
     */
    private void connectToService() {

        InAppPurchaseExtension.logToAS("Connecting to the service ...");
        
        mServiceConn = new ServiceConnection() {
            @Override
            public void onServiceDisconnected(ComponentName name) {
                InAppPurchaseExtension.logToAS("Service connection lost ... reconnecting ...");
                mService = null;
                connectToService();
            }

            @Override
            public void onServiceConnected(ComponentName name, IBinder service) {
                mService = IInAppBillingService.Stub.asInterface(service);
                InAppPurchaseExtension.logToAS("Service connected.");

                dispatchStatusEventAsync(InAppPurchaseMessages.INITIALIZE, "done");
            }
        };
    }

    /**
     * Returns the activity's InAppBillingService that should be used to communicate with the
     * Google Play service.
     */
    public IInAppBillingService getInAppBillingService() {
        return mService;
    }

    /**
     * Returns the ServiceConnection used by the InAppBillingService. This method should only be
     * used at the initialization of the ANE.
     */
    public ServiceConnection getServiceConnection() {
        return mServiceConn;
    }


    /////////////////
    // FRE METHODS //
    /////////////////

    /**
     * Disposes the extension context instance.
     */
    @Override
    public void dispose() {

        // Unbinds the InAppBillingService if needed. This prevents memory leaks on the device.
        if (mService != null) {

            getActivity().unbindService(mServiceConn);
        }
    }


    /**
     * Declares the functions mappings.
     */
    @Override
    public Map<String, FREFunction> getFunctions() {
        Map<String, FREFunction> functions = new HashMap<String, FREFunction>();

        functions.put("initialize", new InAppPurchaseInitFunction());
        functions.put("getProducts", new InAppPurchaseGetProductsFunction());
        functions.put("buyProduct", new InAppPurchaseBuyProductFunction());
        functions.put("consumeProduct", new InAppPurchaseConsumeProductFunction());
        functions.put("restorePurchase", new InAppPurchaseRestorePurchasesFunction());

        InAppPurchaseExtension.log(functions.size() + " extension functions declared.");

        return functions;
    }

}
