package com.studiopixmix.anes.inapppurchase.event {
    import flash.events.Event;
    import flash.events.StatusEvent;

    /**
     * Dispatched when a purchase fails.
     */
    public class PurchaseFailureEvent extends Event {
        /** Event dispatched when the buy intent has failed. */
        public static const PURCHASE_FAILURE:String = "EVENT_PURCHASE_FAILURE";

        private var _message:String;

        public function PurchaseFailureEvent(message:String)
        {
            super(PURCHASE_FAILURE);

            _message = message;
        }

        public function get message():String
        {
            return _message;
        }

        public static function FromStatusEvent(statusEvent:StatusEvent):PurchaseFailureEvent
        {
            return new PurchaseFailureEvent(statusEvent.level);
        }
    }
}