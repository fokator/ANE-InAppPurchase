package com.studiopixmix.anes.InAppPurchase.event {
    import com.studiopixmix.anes.InAppPurchase.Purchase;

    import flash.events.StatusEvent;

    /**
     * Event dispatched when the the request to the store to retrieve the user's previous purchases succeeded.
     * This event contains a collection of product IDs
     */
    public class PurchasesRetrievedEvent extends InAppPurchaseANEEvent {

        /** The collection of all the product IDs of the previous purchases of the user. */
        public var purchases:Vector.<Purchase>;

        public function PurchasesRetrievedEvent(purchases:Vector.<Purchase>)
        {
            super(InAppPurchaseANEEvent.PURCHASES_RETRIEVED);
            this.purchases = purchases;
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
                    const purchase:Purchase = Purchase.FromJSONPurchase(JSON.parse(dataArray[i]));
                    purchases.push(purchase);
                }

                return new PurchasesRetrievedEvent(purchases);
            } catch (e:Error) {
            }

            return new PurchasesRetrievedEvent(new <Purchase>[]);
        }
    }
}