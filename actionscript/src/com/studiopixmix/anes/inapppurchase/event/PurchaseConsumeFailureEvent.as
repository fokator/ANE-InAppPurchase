package com.studiopixmix.anes.inapppurchase.event {
    import flash.events.Event;
    import flash.events.StatusEvent;

    /**
     * Event dispatched when a call to consumePurchase has failed. Contains the error message in the <code>message</code> property.
     */
    public class PurchaseConsumeFailureEvent extends Event {
        /** Event dispatched when a product consumption has failed. */
        public static const CONSUME_FAILED:String = "EVENT_CONSUME_FAILED";

        private var _message:String;

        public function PurchaseConsumeFailureEvent(message:String)
        {
            super(CONSUME_FAILED);

            _message = message;
        }

        public function get message():String
        {
            return _message;
        }

        public static function FromStatusEvent(statusEvent:StatusEvent):PurchaseConsumeFailureEvent
        {
            return new PurchaseConsumeFailureEvent(statusEvent.level);
        }
    }
}