package com.studiopixmix.anes.inapppurchase.event {
    import com.studiopixmix.anes.inapppurchase.Purchase;

    import flash.events.Event;
    import flash.events.StatusEvent;

    /**
     * Event dispatched when the the request to the store to retrieve the user's previous purchases succeeded.
     * This event contains a collection of product IDs
     */
    public class PurchasesRetrievedEvent extends Event {
        /** Event dispatched when calling the <code>restorePurchase</code> function. Dispatched after having requested the store for the user's previous purchases. */
        public static const PURCHASES_RETRIEVED:String = "EVENT_PURCHASES_RETRIEVED";

        private var _purchases:Vector.<Purchase>;

        /**
         * Retrieve the user's previous purchases succeeded
         *
         * @param purchases
         */
        public function PurchasesRetrievedEvent(purchases:Vector.<Purchase>)
        {
            super(PURCHASES_RETRIEVED);

            _purchases = purchases;
        }

        public function get purchases():Vector.<Purchase>
        {
            return _purchases;
        }

        /**
         * Builds a PurchasesRetrievedEvent from the given StatusEvent.
         */
        public static function FromStatusEvent(statusEvent:StatusEvent):PurchasesRetrievedEvent
        {
            try {
                const purchases:Vector.<Purchase> = new <Purchase>[];
                const dataArray:Object = JSON.parse(statusEvent.level);
                for (var i:int = 0; i < dataArray.length; i++) {
                    const purchase:Purchase = Purchase.FromJSONPurchase(dataArray[i]);
                    purchases.push(purchase);
                }

                return new PurchasesRetrievedEvent(purchases);
            } catch (e:Error) {
                // TODO error
            }

            return new PurchasesRetrievedEvent(new <Purchase>[]);
        }
    }
}