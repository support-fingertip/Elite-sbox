public with sharing class LookupController {
    @AuraEnabled
    public static List<sObject> searchRecords(String searchKey, String objectApiName, String filterField, String filterValue) {
        system.debug('searchKey'+searchKey+'objectApiName'+objectApiName+'filterField'+filterField+'filterValue'+filterValue);
        if(filterField == 'Channel__c'){
            List<Sales_Channel_To_SKU__c> channels = [SELECT Id, Name, SKU__c FROM Sales_Channel_To_SKU__c WHERE Sales_Channel__c  =:filterValue];
            Set<Id> productIds = new Set<Id>();
            for (Sales_Channel_To_SKU__c channel : channels) {
                productIds.add(channel.SKU__c);
            }
            List<sObject> prodList = new List<sObject>();
            if (!productIds.isEmpty()) {
                prodList = [SELECT Id, Name FROM Product__c WHERE Is_Active__c = true AND Id IN :productIds AND Name LIKE :('%' + searchKey + '%')];
            }
            return prodList;
        }
        else if(filterField == 'Order_Owner__c') {
            // Get the Product Mappings for the Account
            List<Product_Mapping__c> prodMap = [
                SELECT Id, Exectuive__c 
                FROM Product_Mapping__c 
                WHERE Customer__c = :filterValue
            ];
            
            // Collect the Executive IDs
            Set<Id> executiveIds = new Set<Id>();
            for(Product_Mapping__c pm : prodMap) {
                if(pm.Exectuive__c != null) {
                    executiveIds.add(pm.Exectuive__c);
                }
            }
            
            // Return empty list if no executives found
            if(executiveIds.isEmpty()) {
                return new List<SObject>();
            }
            
            // Safe dynamic query with binding
            String query = 'SELECT Id, Name FROM ' + objectApiName + ' WHERE Id IN :executiveIds';
            return Database.query(query);
        }
        else{
            String query = 'SELECT Id, Name FROM ' + objectApiName + ' WHERE Name LIKE \'%' + searchKey + '%\'';
            
            if (String.isNotBlank(filterField) && String.isNotBlank(filterValue)) {
                query += ' AND ' + filterField + ' = \'' + filterValue + '\'';
            }
            
            query += ' LIMIT 10';
            system.debug('query' +query );
            return Database.query(query);
        }
        
    }
}