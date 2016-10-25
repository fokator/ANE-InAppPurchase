package com.studiopixmix.anes.inapppurchase.event {
    import com.studiopixmix.anes.inapppurchase.Purchase;

    import flash.events.Event;
    import flash.events.StatusEvent;

    /**
     * Event dispatched when a consume product call has succeeded.
     */
    public class PurchaseConsumeSuccessEvent extends Event {
        /** Event dispatched when a product consumption succeeded. */
        public static const CONSUME_SUCCESS:String = "EVENT_CONSUME_SUCCESS";

        private var _purchase:Purchase;

        public function PurchaseConsumeSuccessEvent(purchase:Purchase)
        {
            super(CONSUME_SUCCESS);

            _purchase = purchase;
        }

        public function get purchase():Purchase
        {
            return _purchase;
        }

        /**
         * Builds a PurchaseConsumeSuccessEvent from the given status event dispatched by the native side.
         * The products are returned as a JSON string in the "level" property of the status event.
         */
        public static function FromStatusEvent(statusEvent:StatusEvent):PurchaseConsumeSuccessEvent
        {
            try {
                const purchase:Purchase = Purchase.FromJSONPurchase(JSON.parse(statusEvent.level));
                return new PurchaseConsumeSuccessEvent(purchase);
            } catch (e:Error) {
            }

            return new PurchaseConsumeSuccessEvent(new Purchase());
        }
    }
}