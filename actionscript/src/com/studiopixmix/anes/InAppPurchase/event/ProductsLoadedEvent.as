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

        public function ProductsLoadedEvent(products:Vector.<PurchaseProduct>)
        {
            super(PRODUCTS_LOADED);

            _products = products;
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
            try {
                const productsArray:Array = JSON.parse(statusEvent.level) as Array;
                const numProductsInArray:int = productsArray.length;
                const products:Vector.<PurchaseProduct> = new Vector.<PurchaseProduct>();

                for (var i:int = 0; i < numProductsInArray; i++)
                    products.push(PurchaseProduct.FromJSONProduct(productsArray[i]));

                return new ProductsLoadedEvent(products);
            } catch (e:Error) {
            }

            return new ProductsLoadedEvent(new <PurchaseProduct>[]);
        }
    }
}