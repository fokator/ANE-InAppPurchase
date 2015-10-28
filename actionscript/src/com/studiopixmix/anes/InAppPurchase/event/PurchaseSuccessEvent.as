package com.studiopixmix.anes.inapppurchase.event {
    import com.studiopixmix.anes.inapppurchase.Purchase;

    import flash.events.Event;
    import flash.events.StatusEvent;

    /**
     * Event dispatched when a purchase is successful.
     */
    public class PurchaseSuccessEvent extends Event {
        /** Event dispatched when the buy intent has succeeded and the product has been consumed. */
        public static const PURCHASE_SUCCESS:String = "EVENT_PURCHASE_SUCCESS";

        private var _purchase:Purchase;

        public function PurchaseSuccessEvent(purchase:Purchase)
        {
            super(PURCHASE_SUCCESS);

            _purchase = purchase;
        }

        public function get purchase():Purchase
        {
            return _purchase;
        }

        /**
         * Builds a PurchaseSuccessEvent from the given status event.
         * The purchase JSON data is stored in the "level" property of the status event.
         */
        public static function FromStatusEvent(statusEvent:StatusEvent):PurchaseSuccessEvent
        {
            try {
                const purchase:Purchase = Purchase.FromJSONPurchase(JSON.parse(statusEvent.level));
                return new PurchaseSuccessEvent(purchase);
            } catch (e:Error) {
            }

            return new PurchaseSuccessEvent(new Purchase());
        }
    }
}