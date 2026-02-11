public with sharing class ProductControllerGRIDVIEW {
    @AuraEnabled(cacheable=true)
    public static List<ProductWrapper> getActiveProducts() {
        List<Product__c> products = [
            SELECT Id, Name, List_Price__c, Product_Category1__r.Name, Size__c, Is_Active__c
            FROM Product__c
            WHERE Is_Active__c = TRUE
            ORDER BY Name, Size__c
            
        ];

        Map<String, ProductWrapper> grouped = new Map<String, ProductWrapper>();

        for (Product__c p : products) {
            if (!grouped.containsKey(p.Name)) {
                grouped.put(p.Name, new ProductWrapper(p.Name, p.Product_Category1__r != null ? p.Product_Category1__r.Name : '', p.List_Price__c));
            }
            if (p.Size__c != null) {
                grouped.get(p.Name).addSize(p.Size__c, p.List_Price__c, p.Id);
                
            }
        }

        return grouped.values();
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getSizePicklistValues() {
        Schema.DescribeFieldResult fieldResult = Product__c.Size__c.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        List<String> values = new List<String>();
        for (Schema.PicklistEntry pe : picklistValues) {
            values.add(pe.getLabel());
        }
        return values;
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getProductCategories() {
        List<Product_Category__c> categories = [SELECT Name FROM Product_Category__c];
        List<String> catNames = new List<String>();
        for (Product_Category__c c : categories) {
            catNames.add(c.Name);
        }
        return catNames;
    }

@AuraEnabled
public static void savePrimaryOrder(Order__c order, List<Order_Item__c> items) {
    if (items == null || items.isEmpty()) {
        throw new AuraHandledException('No order items provided.');
    }
    System.debug('Order received: ' + order);
    System.debug('Order Items count: ' + items.size());
    
    // Get current user's Contact and Account
    User currentUser = [SELECT Contact_Id__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
    if (currentUser.Contact_Id__c == null) {
        throw new AuraHandledException('User is not linked to any Contact.');
    }
    Contact con = [SELECT AccountId FROM Contact WHERE Id = :currentUser.Contact_Id__c LIMIT 1];
    if (con.AccountId == null) {
        throw new AuraHandledException('Contact is not linked to any Account.');
    }
    order.Account__c = con.AccountId;
    order.Visit_for__c = 'Primary Customer';

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

    Decimal grandTotal = 0;
    List<Order_Item__c> orderItemsToInsert = new List<Order_Item__c>();

    for (Order_Item__c item : items) {
        if (item.Quantity__c <= 0) continue; // Skip invalid qty

        Product__c prod = productMap.get(item.Product__c);
        Decimal unitPrice = (prod != null && prod.List_Price__c != null) ? prod.List_Price__c : 0;
        Decimal totalAmount = unitPrice * item.Quantity__c;

        // Use Tax_Percent__c from input item if provided, else 0
        Decimal taxPercent = item.Tax_Percent__c != null ? item.Tax_Percent__c : 18;

        // Calculate tax amount = totalAmount * taxPercent / 100
        Decimal taxAmount = (unitPrice * taxPercent *item.Quantity__c) / 100;

        grandTotal += totalAmount + taxAmount;

        Order_Item__c newItem = new Order_Item__c(
            Order__c = order.Id,
            Product__c = item.Product__c,
            Quantity__c = item.Quantity__c,
            Size__c = item.Size__c,
            Product_Category__c = prod != null ? prod.Product_Category__c : null,
            Unit_price__c = unitPrice,
            Total_Amount__c = totalAmount,
            Tax_Percent__c = taxPercent,
            Tax_Amount__c = taxAmount
        );
        orderItemsToInsert.add(newItem);
    }

    insert orderItemsToInsert;

    // Update order with grand total including tax
    
    update order;
}



    public class ProductWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String category;
        @AuraEnabled public Decimal basePrice;
        @AuraEnabled public Map<String, SizeDetail> sizes = new Map<String, SizeDetail>();

        public ProductWrapper(String name, String category, Decimal basePrice) {
            this.name = name;
            this.category = category;
            this.basePrice = basePrice;
        }

        public void addSize(String size, Decimal price, Id productId) {
            sizes.put(size, new SizeDetail(size, price, productId));
        }
    }

    public class SizeDetail {
        @AuraEnabled public String size;
        @AuraEnabled public Decimal price;
        @AuraEnabled public Id productId;

        public SizeDetail(String size, Decimal price, Id productId) {
            this.size = size;
            this.price = price;
            this.productId = productId;
        }
    }
}