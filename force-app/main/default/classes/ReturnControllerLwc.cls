public class ReturnControllerLwc {
        
    @AuraEnabled
    public static Data getData(String accountId) 
    {
        system.debug('accountId'+accountId);
        data dt = new data();
        Account acc = [
            SELECT Id, Name, Region__c, Customer_Type__c, Secondary_Customer_Category__c 
            FROM Account 
            WHERE Id = :accountId
        ];
        list<Product__c> products = beatPlannerlwc.getProducts(accountId,acc.Customer_Type__c); 
        dt.productList = products;
            
       
        
        Map<String, Decimal> allProductwithPrice = new Map<String, Decimal>();
        
        for (Product__c p : products) {
            Price_Book__c bestPB;
            for (Price_Book__c pb : p.Price_Books__r) {
                Boolean matched = false;
                
                if (acc.Customer_Type__c == 'Primary Customer') {
                    if (pb.Customer__c == acc.Id) {
                        matched = true;
                    } 
                } else if (acc.Customer_Type__c == 'Secondary Customer') {
                    if (pb.Customer__c == acc.Id ||
                        pb.Secondary_Customer_Category__c == acc.Secondary_Customer_Category__c ||
                        pb.Region__c == acc.Region__c) {
                            matched = true;
                        }
                }
                
                if (matched) {
                    bestPB = pb;
                    break;
                }
            }
            
            Decimal finalPrice = 0;
            if (bestPB != null) {
                finalPrice = bestPB.Unit_Price__c;
            } else {
                finalPrice = p.MRP__c;
            }
            
            allProductwithPrice.put(p.Id, finalPrice);
        }
        
        dt.productIdWithMrp = allProductwithPrice;
        dt.resonForReturn = extractPicklistValues('Return_Item__c','Reason_For_Return__c');
        dt.uom = extractPicklistValues('Return_Item__c','UOM__c');
        
        return dt;
        
    }
    
    @AuraEnabled
    public static void saveReturn(Return__c returnData, List<Return_Item__c> returnItems) {
        insert returnData;
        for (Return_Item__c rtnItem : returnItems) {
            rtnItem.Return__c = returnData.Id;
        }
        insert returnItems;
    }

    
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
    public class Data {
        @AuraEnabled public list<Product__c> productList = new list<Product__c>();
        @AuraEnabled public List<Map<String, String>> resonForReturn = new List<Map<String, String>> ();
        @AuraEnabled public List<Map<String, String>> uom = new List<Map<String, String>> ();
        @AuraEnabled public Map<String, Decimal> productIdWithMrp = new Map<String, Decimal>();
    }
    
}