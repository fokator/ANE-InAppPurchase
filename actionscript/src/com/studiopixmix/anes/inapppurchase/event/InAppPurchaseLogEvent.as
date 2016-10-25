package com.studiopixmix.anes.inapppurchase.event {
    import flash.events.Event;
    import flash.events.StatusEvent;

    /**
     * Event dispatched when the ANE wants to log something.
     */
    public class InAppPurchaseLogEvent extends Event {
        /** Event used for each log that have to bubble to the AS app. */
        public static const LOG:String = "EVENT_LOG";

        private var _message:String;

        public function InAppPurchaseLogEvent(message:String)
        {
            super(LOG);

            _message = message;
        }

        public function get message():String
        {
            return _message;
        }

        /**
         * Builds a LogEvent from the given status event.
         * The log message is in the "level" property of the event.
         */
        public static function FromStatusEvent(statusEvent:StatusEvent):InAppPurchaseLogEvent
        {
            return new InAppPurchaseLogEvent(statusEvent.level);
        }
    }
}