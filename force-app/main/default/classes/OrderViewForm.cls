public class OrderViewForm {
    public class OrderItemWrapper {
        @AuraEnabled public Id Id {get; set;}
        @AuraEnabled public String Name {get; set;}
        @AuraEnabled public String recordUrl {get; set;}
        @AuraEnabled public String ProductName {get; set;}
        @AuraEnabled public String productUrl {get; set;}
        @AuraEnabled public Decimal eachQuantity {get; set;}
        @AuraEnabled public Decimal CaseQuantity {get; set;}
        @AuraEnabled public Decimal UnitPrice {get; set;}
        @AuraEnabled public Decimal AmountWithOutTax {get; set;}
        @AuraEnabled public Decimal taxPercent {get; set;}
        @AuraEnabled public Decimal taxAmount {get; set;}
        @AuraEnabled public Decimal totalAmount {get; set;}
        @AuraEnabled public Decimal NetWeight {get; set;}
        @AuraEnabled public Decimal DeliveredQty {get; set;}
        @AuraEnabled public Decimal DeliveredQtyInCases {get; set;}
        @AuraEnabled public Decimal DeliveredNetWeight {get; set;} 
    }

    @AuraEnabled(cacheable=true)
    public static List<OrderItemWrapper> getOrderItems(Id orderId) {
        List<Order_Item__c> items = [
            SELECT Id, Name, Product__c, Product__r.Name, Quantity__c, Unit_price__c,
            Tax_Amount__c,Tax__c,Non_Taxable_Order_Value__c,Total_Amount__c,Order_Qty_in_Case__c,
            NET_WEIGHT__c,Delivered_Quantity__c,Fulfilled_Quantity_in_Cases__c,Delivered_Net_Weight__c
            FROM Order_Item__c
            WHERE Order__c = :orderId
        ];

        List<OrderItemWrapper> results = new List<OrderItemWrapper>();
        for (Order_Item__c oi : items) {
            OrderItemWrapper w = new OrderItemWrapper();
            w.Id = oi.Id;
            w.Name = oi.Name;
            w.recordUrl = '/' + oi.Id;             
            w.ProductName = oi.Product__r.Name;
            w.productUrl = '/' + oi.Product__c;    
            w.eachQuantity = oi.Quantity__c;
            w.UnitPrice = oi.Unit_price__c;
            w.AmountWithOutTax = oi.Non_Taxable_Order_Value__c;
            w.taxPercent = oi.Tax__c;
            w.taxAmount = oi.Tax_Amount__c;
            w.totalAmount = oi.Total_Amount__c;
            w.CaseQuantity = oi.Order_Qty_in_Case__c;
            w.NetWeight = oi.NET_WEIGHT__c;
            w.DeliveredQty = oi.Delivered_Quantity__c;
            w.DeliveredQtyInCases = oi.Fulfilled_Quantity_in_Cases__c;
			w.DeliveredNetWeight = oi.Delivered_Net_Weight__c;
            
            
            results.add(w);
        }
        return results;
    }
}