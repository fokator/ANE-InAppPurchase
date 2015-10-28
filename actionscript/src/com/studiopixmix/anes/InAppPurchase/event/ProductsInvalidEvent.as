package com.studiopixmix.anes.inapppurchase.event {
    import flash.events.Event;
    import flash.events.StatusEvent;

    /**
     * Event dispatched when one or many products are declared invalid by the native store.
     */
    public class ProductsInvalidEvent extends Event {
        /** Event dispatched when one or more invalid product(s) have been passed to getProducts or buyProducts. */
        public static const PRODUCTS_INVALID:String = "EVENT_PRODUCTS_INVALID";

        private var _invalidProductsIds:Vector.<String>;

        public function ProductsInvalidEvent(invalidProductsIds:Vector.<String>)
        {
            super(PRODUCTS_INVALID);

            _invalidProductsIds = invalidProductsIds;
        }

        public function get invalidProductsIds():Vector.<String>
        {
            return _invalidProductsIds;
        }

        /**
         * Builds a ProductInvalidEvent from the given StatusEvent.
         * The invalid products ids are stored as a list of ids separated by "," in the "level" property of the event.
         */
        public static function FromStatusEvent(statusEvent:StatusEvent):ProductsInvalidEvent
        {
            try {
                const productIdsAsString:String = statusEvent.level as String;
                const invalidProductsIds:Vector.<String> = Vector.<String>(productIdsAsString.split(","));

                return new ProductsInvalidEvent(invalidProductsIds);
            } catch (e:Error) {
            }

            return new ProductsInvalidEvent(new <String>[]);
        }
    }
}