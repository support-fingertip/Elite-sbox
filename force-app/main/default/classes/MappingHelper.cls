public without sharing class MappingHelper {
    
    //Save Data    
    @AuraEnabled
    public static void saveAutoMappingData(Account accountData, List<Product_Mapping__c> productMappingList) {
        
        list<Product_Mapping__c> productMappingToInsert = new list<Product_Mapping__c>();
        
        // Upsert Product Mappings with reference to Account
        if (productMappingList != null && !productMappingList.isEmpty()) {
            
            //Auto Mapping the secondary customeer st users who has the primary mapping
            if (accountData.Customer_Type__c == 'Secondary Customer') {
                set<Id> primaryCustomerIds = new set<Id>();
                set<Id> subStockiestIds = new set<Id>();
                set<String> existingMappingKey = new set<String>();
                for(Product_Mapping__c pm: productMappingList)
                {
                    string key = '';
                    if(pm.Primary_Customer__c != null && (pm.Sub_Stockiest__c == null || String.isBlank(pm.Sub_Stockiest__c)) ) 
                    { 
                        primaryCustomerIds.add(pm.Primary_Customer__c);
                        key= pm.Customer__c+'_'+pm.Primary_Customer__c+'_'+pm.Exectuive__c;
                    }
                    else if(pm.Sub_Stockiest__c != null) {  
                        subStockiestIds.add(pm.Sub_Stockiest__c);
                        key= pm.Customer__c+'_'+pm.Primary_Customer__c+'_'+pm.Sub_Stockiest__c+'_'+pm.Exectuive__c;
                    }
                    existingMappingKey.add(key);
                }
                
                //Auto Secondary Mapping Under Primary Customer
                List<Product_Mapping__c> payRollMapping = [ SELECT Id, Exectuive__c, Customer__c, Employee__c 
                                                           FROM Product_Mapping__c 
                                                           WHERE Customer__c IN :primaryCustomerIds  
                                                           AND (
                                                               (Exectuive__c != null AND Exectuive__r.IsActive = true)
                                                               OR (Exectuive__c = null AND Employee__c != null)
                                                           )];
                
                for(Product_Mapping__c pm : payRollMapping)
                {
                    string key=  accountData.Id+'_'+pm.Customer__c+'_'+pm.Exectuive__c;
                    if(!existingMappingKey.contains(key))
                    {
                        existingMappingKey.add(key);
                        Product_Mapping__c newPm = new Product_Mapping__c(
                            Exectuive__c = pm.Exectuive__c,                                   
                            Employee__c = pm.Employee__c,                                        
                            Primary_Customer__c = pm.Customer__c,                                     
                            Customer__c = accountData.Id                                      
                        );
                        productMappingToInsert.add(newPm);
                    }
                }
                
                List<Employee_Customer_Assignment__c> nonPayrollMapping = [SELECT Id, Executive__c, Employee__c, Customer__c 
                                                                           FROM Employee_Customer_Assignment__c 
                                                                           WHERE Customer__c IN :primaryCustomerIds 
                                                                           AND (
                                                                               (Executive__c != null AND Executive__r.IsActive = true)
                                                                               OR (Executive__c = null AND Employee__c != null)
                                                                           )];
                system.debug('nonPayrollMapping'+nonPayrollMapping);
                for(Employee_Customer_Assignment__c pm : nonPayrollMapping)
                {
                    string key=  accountData.Id+'_'+pm.Customer__c+'_'+pm.Executive__c;
                    if(!existingMappingKey.contains(key))
                    {
                        existingMappingKey.add(key);
                        Product_Mapping__c newPm = new Product_Mapping__c(Exectuive__c = pm.Executive__c, Employee__c = pm.Employee__c,Primary_Customer__c = pm.Customer__c,Customer__c = accountData.Id);
                        productMappingToInsert.add(newPm);
                    }
                }
                
                //Auto Secondary Mapping Under SubStockiest
                List<Product_Mapping__c> subStockiestMappings =  [SELECT Id, Exectuive__c, Employee__c, Customer__c, Primary_Customer__c 
                                                                  FROM Product_Mapping__c 
                                                                  WHERE Customer__c IN :subStockiestIds
                                                                  AND (
                                                                      (Exectuive__c != null AND Exectuive__r.IsActive = true)
                                                                      OR (Exectuive__c = null AND Employee__c != null)
                                                                  )];
                
                for(Product_Mapping__c pm : subStockiestMappings)
                {
                    string key= accountData.Id+'_'+pm.Primary_Customer__c+'_'+pm.Customer__c+'_'+pm.Exectuive__c;
                    if(!existingMappingKey.contains(key))
                    {
                        existingMappingKey.add(key);
                        Product_Mapping__c newPm = new Product_Mapping__c(Exectuive__c = pm.Exectuive__c,Employee__c = pm.Employee__c,Sub_Stockiest__c = pm.Customer__c,Primary_Customer__c = pm.Primary_Customer__c,Customer__c = accountData.Id);
                        productMappingToInsert.add(newPm);
                    }
                }
            }
            
            

            database.insert(productMappingToInsert,false);
        }
        
    }
    
    
}