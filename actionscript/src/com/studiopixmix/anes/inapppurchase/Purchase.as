package com.studiopixmix.anes.inapppurchase {
    /**
     * Represents a successfull purchase.
     * For more informations about the fields, see the related stores documentations.
     */
    public class Purchase {
        // iOS and Android
        public var productId:String;
        public var transactionDate:Date;

        // iOS only
        public var applicationUsername:String;
        public var transactionId:String;
        // Deprecated https://developer.apple.com/documentation/storekit/skpaymenttransaction/1617722-transactionreceipt
        public var transactionReceipt:String;
        public var storeReceipt:String;

        // Android only
        public var developerPayload:String;
        public var purchaseToken:String;
        public var orderId:String;
        public var playStoreResponse:String;
        public var signature:String;
        public var purchaseState:String;

        public var raw:Object;

        public function Purchase()
        {
        }

        public function toString():String
        {
            return "<SuccessfullPurchase:[" +
                    "productId:" + productId + "," +
                    "transactionDate:" + transactionDate + ", " +
                    "applicationUsername:" + applicationUsername + ", " +
                    "transactionId:" + transactionId + ", " +
                    "transactionReceipt:" + transactionReceipt + ", " +
                    "developerPayload:" + developerPayload + ", " +
                    "purchaseToken:" + purchaseToken + ", " +
                    "orderId:" + orderId + ", " +
                    "playStoreResponse:" + playStoreResponse + ", " +
                    "purchaseState:" + purchaseState + ", " +
                    "signature:" + signature + "]>";
        }

        /**
         * Builds a SuccessfullPurchase from the given JSON object.
         */
        public static function FromJSONPurchase(jsonPurchase:Object):Purchase
        {
            const newPurchase:Purchase = new Purchase();

            newPurchase.raw = jsonPurchase;

            newPurchase.productId = jsonPurchase.productId;
            newPurchase.transactionDate = new Date();
            newPurchase.transactionDate.setTime(jsonPurchase.transactionTimestamp);

            newPurchase.applicationUsername = jsonPurchase.hasOwnProperty("applicationUsername") ? jsonPurchase.applicationUsername : "";
            newPurchase.transactionId = jsonPurchase.hasOwnProperty("transactionId") ? jsonPurchase.transactionId : "";
            newPurchase.transactionReceipt = jsonPurchase.hasOwnProperty("transactionReceipt") ? jsonPurchase.transactionReceipt : "";
            newPurchase.storeReceipt = jsonPurchase.hasOwnProperty("storeReceipt") ? jsonPurchase.storeReceipt : "";

            newPurchase.developerPayload = jsonPurchase.hasOwnProperty("developerPayload") ? jsonPurchase.developerPayload : "";
            newPurchase.purchaseToken = jsonPurchase.hasOwnProperty("purchaseToken") ? jsonPurchase.purchaseToken : "";
            newPurchase.orderId = jsonPurchase.hasOwnProperty("orderId") ? jsonPurchase.orderId : "";
            newPurchase.playStoreResponse = jsonPurchase.hasOwnProperty("playStoreResponse") ? jsonPurchase.playStoreResponse : "";
            newPurchase.signature = jsonPurchase.hasOwnProperty("signature") ? jsonPurchase.signature : "";
            newPurchase.purchaseState = jsonPurchase.hasOwnProperty("purchaseState") ? jsonPurchase.purchaseState : "";

            return newPurchase;
        }
    }
}