package com.studiopixmix.anes.inapppurchase.event {
    import com.studiopixmix.anes.inapppurchase.PurchaseProduct;

    import flash.events.Event;
    import flash.events.StatusEvent;

    /**
     * Event dispatched when products are loaded from the native store.
     */
    public class ProductsLoadedEvent extends Event {
        /** Event dispatched when the products have been loaded. */
        public static const PRODUCTS_LOADED:String = "EVENT_PRODUCTS_LOADED";

        private var _products:Vector.<PurchaseProduct>;
        private var _invalidIds:Array;
        private var _error:Error;

        public function ProductsLoadedEvent(products:Vector.<PurchaseProduct>, invalidIds:Array, error:Error = null)
        {
            super(PRODUCTS_LOADED);

            _products = products;
            _invalidIds = invalidIds;

            _error = error;
        }

        public function get products():Vector.<PurchaseProduct>
        {
            return _products;
        }

        /**
         * Builds a ProductsLoadedEvent from the given status event dispatched by the native side.
         * The products are returned as a JSON string in the "level" property of the status event.
         */
        public static function FromStatusEvent(statusEvent:StatusEvent):ProductsLoadedEvent
        {
            // statusEvent.level = {resultIds:" + resultIds.toString() + ",invalidIds:" + invalidIds.toString() + "}
            try {
                var object:Object = JSON.parse(statusEvent.level);

                const productsArray:Array = object.resultIds as Array;
                const numProductsInArray:int = productsArray.length;
                const products:Vector.<PurchaseProduct> = new Vector.<PurchaseProduct>();

                for (var i:int = 0; i < numProductsInArray; i++) {
                    products.push(PurchaseProduct.FromJSONProduct(productsArray[i]));
                }
                trace("object.invalidIds: " + object.invalidIds);
                return new ProductsLoadedEvent(products, object.invalidIds as Array);
            } catch (e:Error) {

                return new ProductsLoadedEvent(new <PurchaseProduct>[], [], e);
            }

        }

	    public function get invalidIds():Array
	    {
		    return _invalidIds;
	    }

	    public function get error():Error
	    {
		    return _error;
	    }
    }
}