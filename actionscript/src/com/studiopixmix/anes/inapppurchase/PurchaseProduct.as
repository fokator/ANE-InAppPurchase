package com.studiopixmix.anes.inapppurchase {
    /**
     * Represents a product that can be purchased in the app
     * On iOS, this is the AS equivalent of SKProduct.
     */
    public class PurchaseProduct {
        // PROPERTIES

        /**
         * iOS equivalent : productIdentifier
         */
        public var id:String;

        /**
         * iOS equivalent : localizedTitle
         */
        public var title:String;

        /**
         * iOS equivalent : localizedDescription
         */
        public var description:String;

        /**
         * iOS equivalent : price
         */
        public var price:Number;

        public var priceAmountMicros:String;

        public var priceCurrencyCode:String;

        public var priceCurrencySymbol:String;

        public var displayPrice:String;

        // CONSTRUCTOR
        public function PurchaseProduct()
        {
        }

        /**
         * Builds an InAppPurchaseProduct from the given JSON object.
         */
        public static function FromJSONProduct(jsonProduct:Object):PurchaseProduct
        {
            const product:PurchaseProduct = new PurchaseProduct();

            product.id = jsonProduct.id;
            product.title = jsonProduct.title;
            product.description = jsonProduct.description;
            product.price = jsonProduct.price;
            product.priceAmountMicros = jsonProduct.priceAmountMicros;
            product.priceCurrencyCode = jsonProduct.priceCurrencyCode;
            product.priceCurrencySymbol = jsonProduct.priceCurrencySymbol;
            product.displayPrice = jsonProduct.displayPrice;

            return product;
        }

        public function getPriceToDisplay(withNbsp:Boolean = false):String
        {
            if (withNbsp)
                return displayPrice.replace(" ", "&nbsp;");

            return displayPrice;
        }

        public function toString():String
        {
            return "<InAppPurchaseProduct[id:" + id + ", title:" + title + ", price:" + price + ", priceCurrencyCode:" + priceCurrencyCode + ", priceCurrencySymbol:" + priceCurrencySymbol + ", displayPrice:" + displayPrice + "]>";
        }
    }
}
