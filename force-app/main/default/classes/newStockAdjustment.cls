public class newStockAdjustment {
    public class StockAdjustmentDataBox {
        @AuraEnabled public List<Map<String, String>> adjustmentTypes = new List<Map<String, String>> ();
        @AuraEnabled public string distributorId;
        @AuraEnabled public List<Product__c> productsList;
    }
    @AuraEnabled
    public static StockAdjustmentDataBox getStockAdjustments()
    {
        StockAdjustmentDataBox dt = new StockAdjustmentDataBox();
        dt.adjustmentTypes = extractPicklistValues('Stock_Adjustment__c', 'Adjustment_Type__c');
        // Get Logged-in User's Account 
        Id accountId;
        List<User> partnerUser = [
            SELECT ContactId 
            FROM User 
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];
        
        if (!partnerUser.isEmpty() && partnerUser[0].ContactId != null) {
            List<Contact> contacts = [
                SELECT AccountId 
                FROM Contact 
                WHERE Id = :partnerUser[0].ContactId
                LIMIT 1
            ];
            if (!contacts.isEmpty()) {
                accountId = contacts[0].AccountId;
            }
        }
        dt.distributorId = accountId;

        Set<String> channelSet = new Set<String>();
        List<Product_Mapping__c> prodMappingsFromPrimary = [SELECT Chanel__c, Customer__c 
                                                            FROM Product_Mapping__c  where Customer__c = :accountId];
        // Populate channelSet and primaryCustomerIds
        for(Product_Mapping__c prodMap : prodMappingsFromPrimary) {
            if (prodMap.Chanel__c != null) {
                channelSet.add(prodMap.Chanel__c);
            }
        }
        List<Product__c> products = new List<Product__c>();
        if (!channelSet.isEmpty()) {
            Set<String> productIds = new Set<String>();
            List<Sales_Channel_To_SKU__c> channels = [SELECT Id, Name, SKU__r.Name,SKU__c,Delivery_Plant__c,Sales_Channel__c
                                                      FROM Sales_Channel_To_SKU__c WHERE Sales_Channel__c IN :channelSet
                                                      and SKU__r.Is_Active__c = true];
            map<String,String> skuNameToSkuId = new map<String,String>();
            for (Sales_Channel_To_SKU__c channel : channels) {
                productIds.add(channel.SKU__r.Name);
                skuNameToSkuId.put(channel.SKU__r.Name,channel.SKU__c);
            }
            
            
            dt.productsList = [
                SELECT Id, Name FROM Product__c  WHERE Is_Active__c = true AND Id IN :skuNameToSkuId.values()
                ORDER BY Name 
            ];
            
            
        }
        return dt;
    }
    /**Helper Methods **/  
    private static List<Map<String, String>> extractPicklistValues(String objectName, String fieldName) {
        // Get the global describe map
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        
        // Check if the object exists
        if (!schemaMap.containsKey(objectName)) {
            return new List<Map<String, String>>();
        }
        
        Schema.DescribeSObjectResult objDescribe = schemaMap.get(objectName).getDescribe();
        Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
        
        // Check if the field exists in the object
        if (!fieldMap.containsKey(fieldName)) {
            return new List<Map<String, String>>();
        }
        
        Schema.DescribeFieldResult fieldResult = fieldMap.get(fieldName).getDescribe();
        List<Map<String, String>> picklistValues = new List<Map<String, String>>();
        
        if (fieldResult != null && fieldResult.getType() == Schema.DisplayType.Picklist) {
            for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
                picklistValues.add(new Map<String, String>{
                    'label' => entry.getLabel(),
                        'value' => entry.getValue()
                        });
            }
        }
        return picklistValues;
    }
    
    
}