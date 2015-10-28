package com.studiopixmix.anes.inapppurchase.event {

    import flash.events.Event;
    import flash.events.StatusEvent;

    /**
     * Event dispatched when the init is complete.
     */
    public class InAppPurchaseInitializeEvent extends Event {

        /** Event dispatched when the init is complete. */
        public static const INITIALIZED:String = "EVENT_INITIALIZED";

        private var _success:Boolean;
        private var _message:String;

        public function InAppPurchaseInitializeEvent()
        {
            super(INITIALIZED);

            _success = true;
        }

        public function get success():Boolean
        {
            return _success;
        }

        public function get message():String
        {
            return _message;
        }
        
        public static function FromStatusEvent(statusEvent:StatusEvent):InAppPurchaseInitializeEvent
        {
            return new InAppPurchaseInitializeEvent();
        }
    }
}