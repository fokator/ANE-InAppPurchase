package com.studiopixmix.anes.inapppurchase.event {
    import flash.events.Event;
    import flash.events.StatusEvent;

    public class PurchaseCanceledEvent extends Event {
        /** Event dispatched when the user explicitely canceled the purchase. */
        public static const PURCHASE_CANCELED:String = "EVENT_PURCHASE_CANCELED";

        public function PurchaseCanceledEvent()
        {
            super(PURCHASE_CANCELED);
        }

        /**
         * Builds a PurchaseCanceledEvent from the given status event.
         */
        public static function FromStatusEvent(statusEvent:StatusEvent):PurchaseCanceledEvent
        {
            return new PurchaseCanceledEvent();
        }
    }
}