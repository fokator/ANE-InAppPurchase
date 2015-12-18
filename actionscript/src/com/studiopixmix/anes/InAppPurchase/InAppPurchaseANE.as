package com.studiopixmix.anes.inapppurchase {
    import com.studiopixmix.anes.inapppurchase.event.InAppPurchaseInitializeEvent;
    import com.studiopixmix.anes.inapppurchase.event.InAppPurchaseLogEvent;
    import com.studiopixmix.anes.inapppurchase.event.ProductsInvalidEvent;
    import com.studiopixmix.anes.inapppurchase.event.ProductsLoadedEvent;
    import com.studiopixmix.anes.inapppurchase.event.PurchaseCanceledEvent;
    import com.studiopixmix.anes.inapppurchase.event.PurchaseConsumeFailureEvent;
    import com.studiopixmix.anes.inapppurchase.event.PurchaseConsumeSuccessEvent;
    import com.studiopixmix.anes.inapppurchase.event.PurchaseFailureEvent;
    import com.studiopixmix.anes.inapppurchase.event.PurchaseSuccessEvent;
    import com.studiopixmix.anes.inapppurchase.event.PurchasesRetrievedEvent;
    import com.studiopixmix.anes.inapppurchase.event.PurchasesRetrievingFailed;

    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.StatusEvent;
    import flash.external.ExtensionContext;
    import flash.system.Capabilities;

    /** Event dispatched when the init is complete. */
    [Event(name="EVENT_INITIALIZED", type="com.studiopixmix.anes.inapppurchase.event.InAppPurchaseInitializeEvent")]

    /** Event dispatched when the init is complete. */
    [Event(name="EVENT_LOG", type="com.studiopixmix.anes.inapppurchase.event.InAppPurchaseLogEvent")]

    /** Event dispatched when the products have been loaded. */
    [Event(name="EVENT_PRODUCTS_LOADED", type="com.studiopixmix.anes.inapppurchase.event.ProductsLoadedEvent")]

    /** Event dispatched when one or more invalid product(s) have been passed to getProducts or buyProducts. */
    [Event(name="EVENT_PRODUCTS_INVALID", type="com.studiopixmix.anes.inapppurchase.event.ProductsInvalidEvent")]

    /** Event dispatched when the buy intent has succeeded and the product has been consumed. */
    [Event(name="EVENT_PURCHASE_SUCCESS", type="com.studiopixmix.anes.inapppurchase.event.PurchaseSuccessEvent")]

    /** Event dispatched when the user explicitely canceled the purchase. */
    [Event(name="EVENT_PURCHASE_CANCELED", type="com.studiopixmix.anes.inapppurchase.event.PurchaseCanceledEvent")]

    /** Event dispatched when the buy intent has failed. */
    [Event(name="EVENT_PURCHASE_FAILURE", type="com.studiopixmix.anes.inapppurchase.event.PurchaseFailureEvent")]

    /** Event dispatched when a product consumption succeeded. */
    [Event(name="EVENT_CONSUME_SUCCESS", type="com.studiopixmix.anes.inapppurchase.event.PurchaseConsumeSuccessEvent")]

    /** Event dispatched when a product consumption has failed. */
    [Event(name="EVENT_CONSUME_FAILED", type="com.studiopixmix.anes.inapppurchase.event.PurchaseConsumeFailureEvent")]

    /** Event dispatched when calling the <code>restorePurchase</code> function. Dispatched after having requested the store for the user's previous purchases. */
    [Event(name="EVENT_PURCHASES_RETRIEVED", type="com.studiopixmix.anes.inapppurchase.event.PurchasesRetrievedEvent")]

    /** Event dispatched when the call to <code>getPurchases</code> failed. */
    [Event(name="EVENT_PURCHASES_RETRIEVING_FAILED", type="com.studiopixmix.anes.inapppurchase.event.PurchasesRetrievingFailed")]

    /**
     * To use this extension, create a new instance and call initialize() before trying to interact with it.
     * Once the ANE is initialized,
     *
     * TODO add optional signature verification (Android)
     * TODO add optional automatic consumable purchases
     * TODO nice service dispose
     *
     */
    public class InAppPurchaseANE extends EventDispatcher {

        /**
         * Whether the ANE is supported on the current device or not.
         * This ANE only works on iOS and Android.
         */
        public static function isSupported():Boolean
        {
            return isIOS() || isAndroid();
        }

        public static function isIOS():Boolean
        {
            return Capabilities.manufacturer.indexOf('iOS') > -1;
        }

        public static function isAndroid():Boolean
        {
            return Capabilities.manufacturer.indexOf('Android') > -1;
        }

        // CONSTANTS
        public static const VERSION:String = "1.0.4";
        private static const EXTENSION_ID:String = "com.studiopixmix.anes.inapppurchase";

        private static const NATIVE_METHOD_GET_PRODUCTS:String = "getProducts";
        private static const NATIVE_METHOD_INITIALIZE:String = "initialize";
        private static const NATIVE_METHOD_BUY_PRODUCT:String = "buyProduct";
        private static const NATIVE_METHOD_CONSUME_PRODUCT:String = "consumeProduct";
        private static const NATIVE_METHOD_RESTORE_PURCHASES:String = "restorePurchase";

        // PROPERTIES
        private var _extContext:ExtensionContext;

        /**
         * Creates the extension context if possible. Call <code>initialize()</code> before using the rest of the extension.
         */
        public function InAppPurchaseANE()
        {
            trace("InAppPurchaseANE", VERSION);

            _extContext = ExtensionContext.createExtensionContext(EXTENSION_ID, null);
            if (_extContext != null) {

                _extContext.addEventListener(StatusEvent.STATUS, onStatusEvent);
            } else {

                trace("ERROR - Extension context is null. Please check if extension.xml is setup correctly.");
            }
        }

        /**
         * Dispose extension context object.
         *
         * @return Return true if it success.
         */
        public function dispose():Boolean
        {
            if (_extContext != null) {

                _extContext.removeEventListener(StatusEvent.STATUS, onStatusEvent);
                _extContext.dispose();

                return true;
            }
            return false;
        }

        ////////////////
        // PUBLIC API //
        ////////////////

        /**
         * Calls the <code>initialize</code> method in the native code. This method MUST be called before doing any in-app purchase.
         */
        public function initialize():void
        {
            if (!isSupported())
                return;

            _extContext.call(NATIVE_METHOD_INITIALIZE);
        }

        /**
         * Request the given products information. Dispatches PRODUCTS_LOADED and PRODUCTS_INVALID events.
         */
        public function getProducts(productsIds:Vector.<String>):void
        {
            if (!isSupported())
                return;

            if (productsIds.length == 0) {

                dispatchEvent(new ProductsInvalidEvent(productsIds));
                return;
            }

            _extContext.call(NATIVE_METHOD_GET_PRODUCTS, productsIds);
        }

        /**
         * Buys the given product. Dispatches PURCHASE_SUCCESS, PURCHASE_CANCELED and PURCHASE_FAILURE events.
         *
         * @param productId        The native product ID
         * @param devPayload    An optional developer payload (Android-only)
         */
        public function buyProduct(productId:String, devPayload:String = null):void
        {
            if (!isSupported())
                return;

            _extContext.call(NATIVE_METHOD_BUY_PRODUCT, productId, devPayload);
        }

        /**
         * Consume purchase by productId. Dispatches CONSUME_SUCCESS, CONSUME_FAILED events.
         *
         * @param productId Native store products ID.
         */
        public function consumePurchase(productId:String):void
        {
            if (!isSupported())
                return;

            _extContext.call(NATIVE_METHOD_CONSUME_PRODUCT, productId);
        }

        /**
         * Requests the native store to get the user's previous purchases. This will return a list of product IDs previously purchased
         * on the store by the current user. You can use this list in your app to update the unlocked content of your player, for example.
         * Dispatches PURCHASES_RETRIEVED or PURCHASES_RETRIEVING_FAILED events.
         */
        public function restorePurchases():void
        {
            if (!isSupported())
                return;

            _extContext.call(NATIVE_METHOD_RESTORE_PURCHASES);
        }

        /////////////////
        // PRIVATE API //
        /////////////////

        /**
         * Called on each Status Event from the native code.
         * According to the event type, we dispatch the corresponding event filled with its data.
         */
        private function onStatusEvent(event:StatusEvent):void
        {
            var eventToDispatch:Event;

            switch (event.code) {
                case InAppPurchaseInitializeEvent.INITIALIZED:
                    eventToDispatch = InAppPurchaseInitializeEvent.FromStatusEvent(event);

                    break;
                case InAppPurchaseLogEvent.LOG:
                    eventToDispatch = InAppPurchaseLogEvent.FromStatusEvent(event);

                    break;
                case ProductsLoadedEvent.PRODUCTS_LOADED:
                    eventToDispatch = ProductsLoadedEvent.FromStatusEvent(event);

                    break;
                case ProductsInvalidEvent.PRODUCTS_INVALID:
                    eventToDispatch = ProductsInvalidEvent.FromStatusEvent(event);

                    break;
                case PurchaseSuccessEvent.PURCHASE_SUCCESS:
                    eventToDispatch = PurchaseSuccessEvent.FromStatusEvent(event);

                    break;
                case PurchaseCanceledEvent.PURCHASE_CANCELED:
                    eventToDispatch = PurchaseCanceledEvent.FromStatusEvent(event);

                    break;
                case PurchaseFailureEvent.PURCHASE_FAILURE:
                    eventToDispatch = PurchaseFailureEvent.FromStatusEvent(event);

                    break;
                case PurchaseConsumeSuccessEvent.CONSUME_SUCCESS:
                    eventToDispatch = PurchaseConsumeSuccessEvent.FromStatusEvent(event);

                    break;
                case PurchaseConsumeFailureEvent.CONSUME_FAILED:
                    eventToDispatch = PurchaseConsumeFailureEvent.FromStatusEvent(event);

                    break;
                case PurchasesRetrievedEvent.PURCHASES_RETRIEVED:
                    eventToDispatch = PurchasesRetrievedEvent.FromStatusEvent(event);

                    break;
                case PurchasesRetrievingFailed.PURCHASES_RETRIEVING_FAILED:
                    eventToDispatch = PurchasesRetrievingFailed.FromStatusEvent(event);

                    break;
                default :
            }

            if (eventToDispatch != null) {

                dispatchEvent(eventToDispatch);
            }
        }
    }
}