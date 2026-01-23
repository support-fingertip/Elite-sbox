public class primaryorderTABLEVIEW {

    // Save primary order and related order items
  @AuraEnabled
public static void savePrimaryOrder(Order__c order, List<Order_Item__c> items) {
    if (order == null) {
        throw new AuraHandledException('Order record must be provided.');
    }
    
    if (items == null || items.isEmpty()) {
        throw new AuraHandledException('No order items provided.');
    }
    
    for (Order_Item__c item : items) {
        if (item.Product__c == null) {
            throw new AuraHandledException('One or more order items have no product selected.');
        }
        if (item.Quantity__c == null || item.Quantity__c <= 0) {
            throw new AuraHandledException('Quantity must be greater than zero for all order items.');
        }
    }
    
    User currentUser = [SELECT Contact_Id__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
    if (currentUser == null || currentUser.Contact_Id__c == null) {
        throw new AuraHandledException('User is not linked to any Contact.');
    }
    
    Contact con = [SELECT AccountId FROM Contact WHERE Id = :currentUser.Contact_Id__c LIMIT 1];
    if (con == null || con.AccountId == null) {
        throw new AuraHandledException('Contact is not linked to any Account.');
    }
    
    Id accountId = con.AccountId;
    
    order.Account__c = accountId;
    order.Visit_for__c = 'Distributor';
    
    if (order.Order_Date__c == null) {
        order.Order_Date__c = System.today();
    }
    
    insert order;
    
    Set<Id> productIds = new Set<Id>();
    for (Order_Item__c item : items) {
        productIds.add(item.Product__c);
    }
    
    Map<Id, Product__c> productMap = new Map<Id, Product__c>(
        [SELECT Id, Name, List_Price__c, Product_Category__c FROM Product__c WHERE Id IN :productIds]
    );
    
    List<Order_Item__c> orderItemsToInsert = new List<Order_Item__c>();
    for (Order_Item__c item : items) {
        Product__c prod = productMap.get(item.Product__c);
        if (prod == null) {
            throw new AuraHandledException('Product not found for Order Item.');
        }
        
        Decimal unitPrice = prod.List_Price__c != null ? prod.List_Price__c : 0;
        Decimal totalAmount = unitPrice * item.Quantity__c;
        
        Order_Item__c newItem = new Order_Item__c(
            Order__c = order.Id,
            Product__c = item.Product__c,
            Quantity__c = item.Quantity__c,
            Product_Category__c = prod.Product_Category__c,
            Unit_Price__c = unitPrice,
            Total_Amount__c = totalAmount
        );
        
        orderItemsToInsert.add(newItem);
    }
    
    if (!orderItemsToInsert.isEmpty()) {
        insert orderItemsToInsert;
    }
}


    // Fetch all products for search
    @AuraEnabled(cacheable=true)
    public static List<Product__c> getAllProducts() {
        return [
            SELECT Id, Name,Tax_Class__c, List_Price__c, Product_Category__c
            FROM Product__c
            ORDER BY Name ASC
            LIMIT 50000
        ];
    }
}