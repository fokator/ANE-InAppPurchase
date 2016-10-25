package com.studiopixmix.anes.inapppurchase.event {
    import flash.events.Event;
    import flash.events.StatusEvent;

    /**
     * Event dispatched if the request to the native store to retrieve the previous purchases of the user failed.
     * This event contains the error message and the stacktrace.
     */
    public class PurchasesRetrievingFailed extends Event {
        /** Event dispatched when the call to <code>getPurchases</code> failed. */
        public static const PURCHASES_RETRIEVING_FAILED:String = "EVENT_PURCHASES_RETRIEVING_FAILED";

        private var _error:String;

        public function PurchasesRetrievingFailed(error:String)
        {
            super(PURCHASES_RETRIEVING_FAILED);
            _error = error;
        }

        public function get error():String
        {
            return _error;
        }

        /**
         * Builds a PurchasesRetrievingFailed from the given StatusEvent.
         */
        public static function FromStatusEvent(statusEvent:StatusEvent):PurchasesRetrievingFailed
        {
            try {
                const error:String = statusEvent.level as String;
                return new PurchasesRetrievingFailed(error);
            } catch (e:Error) {
            }

            return new PurchasesRetrievingFailed(null);
        }
    }
}