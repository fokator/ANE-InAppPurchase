package com.studiopixmix.anes.InAppPurchase {
    import com.studiopixmix.anes.InAppPurchase.event.InAppPurchaseANEEvent;
    import com.studiopixmix.anes.InAppPurchase.event.LogEvent;
    import com.studiopixmix.anes.InAppPurchase.event.ProductsInvalidEvent;
    import com.studiopixmix.anes.InAppPurchase.event.ProductsLoadedEvent;
    import com.studiopixmix.anes.InAppPurchase.event.PurchaseCanceledEvent;
    import com.studiopixmix.anes.InAppPurchase.event.PurchaseConsumeFailureEvent;
    import com.studiopixmix.anes.InAppPurchase.event.PurchaseConsumeSuccessEvent;
    import com.studiopixmix.anes.InAppPurchase.event.PurchaseFailureEvent;
    import com.studiopixmix.anes.InAppPurchase.event.PurchaseSuccessEvent;
    import com.studiopixmix.anes.InAppPurchase.event.PurchasesRetrievedEvent;
    import com.studiopixmix.anes.InAppPurchase.event.PurchasesRetrievingFailed;

    import flash.events.EventDispatcher;
    import flash.events.StatusEvent;
    import flash.external.ExtensionContext;
    import flash.system.Capabilities;

    /**
     * To use this extension, create a new instance and call initialize() before trying to interact with it.
     * Once the ANE is initialized,
     *
     * TODO rewrite evens system
     * TODO add Event metadata tags
     * TODO add optional signature verification (Android)
     * TODO add optional automatic consumable purchases 
     *
     */
    public class InAppPurchaseANE extends EventDispatcher {

        // TODO events meta
        //[Event(name="EVENT_LOG", type="com.studiopixmix.anes.InAppPurchase.event.InAppPurchaseANEEvent")]

        /**
         * Whether the ANE is supported on the current device or not.
         * This ANE only works on iOS and Android.
         */
        public static function isSupported():Boolean
        {
            return Capabilities.manufacturer.indexOf('iOS') > -1 || Capabilities.manufacturer.indexOf('Android') > -1;
        }

        // CONSTANTS
        public static const VERSION:String = "1.0.0";
        private static const EXTENSION_ID:String = "com.studiopixmix.anes.inapppurchase";

        private static const NATIVE_METHOD_GET_PRODUCTS:String = "getProducts";
        private static const NATIVE_METHOD_INITIALIZE:String = "initialize";
        private static const NATIVE_METHOD_BUY_PRODUCT:String = "buyProduct";
        private static const NATIVE_METHOD_CONSUME_PRODUCT:String = "consumeProduct";
        private static const NATIVE_METHOD_RESTORE_PURCHASES:String = "restorePurchase";

        // PROPERTIES
        private var _extContext:ExtensionContext;

        // CONSTRUCTOR
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
            var eventToDispatch:InAppPurchaseANEEvent;

            switch (event.code) {
                case InAppPurchaseANEEvent.INITIALIZED:
                    eventToDispatch = new InAppPurchaseANEEvent(InAppPurchaseANEEvent.INITIALIZED);

                    break;
                case InAppPurchaseANEEvent.LOG:
                    eventToDispatch = LogEvent.FromStatusEvent(event);

                    break;
                case InAppPurchaseANEEvent.PRODUCTS_LOADED:
                    eventToDispatch = ProductsLoadedEvent.FromStatusEvent(event);

                    break;
                case InAppPurchaseANEEvent.PRODUCTS_INVALID:
                    eventToDispatch = ProductsInvalidEvent.FromStatusEvent(event);

                    break;
                case InAppPurchaseANEEvent.PURCHASE_SUCCESS:
                    eventToDispatch = PurchaseSuccessEvent.FromStatusEvent(event);

                    break;
                case InAppPurchaseANEEvent.PURCHASE_CANCELED:
                    eventToDispatch = PurchaseCanceledEvent.FromStatusEvent(event);

                    break;
                case InAppPurchaseANEEvent.PURCHASE_FAILURE:
                    eventToDispatch = PurchaseFailureEvent.FromStatusEvent(event);

                    break;
                case InAppPurchaseANEEvent.CONSUME_SUCCESS:
                    eventToDispatch = PurchaseConsumeSuccessEvent.FromStatusEvent(event);

                    break;
                case InAppPurchaseANEEvent.CONSUME_FAILED:
                    eventToDispatch = PurchaseConsumeFailureEvent.FromStatusEvent(event);

                    break;
                case InAppPurchaseANEEvent.PURCHASES_RETRIEVED:
                    eventToDispatch = PurchasesRetrievedEvent.FromStatusEvent(event);

                    break;
                case InAppPurchaseANEEvent.PURCHASES_RETRIEVING_FAILED:
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