public class EmployeeProductMappingCloneBatch 
    implements Database.Batchable<sObject>, Database.Stateful {

    Map<String, String> oldToNewUserMap;

    public EmployeeProductMappingCloneBatch(Map<String, String> oldToNewUserMap) {
        this.oldToNewUserMap = oldToNewUserMap;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Exectuive__c, Primary_Customer__c, Sub_Stockiest__c, Customer__c, Chanel__c,
                   Area__c, PDP_Name__c, PDP_Day__c, Parent_Depot__c, Child_Depot__c, Payment_Term__c, 
                   Credit_Description__c, Inco_Terms__c, Order_Type__c, Distribution_Channel__c, 
                   Sales_Office__c, Division__c, Customer_Type__c, Secondary_Customer_Type__c
            FROM Product_Mapping__c
            WHERE Exectuive__c IN :oldToNewUserMap.keySet()
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Product_Mapping__c> oldMappings) {

        List<Product_Mapping__c> clonedPrimary = new List<Product_Mapping__c>();
        List<Product_Mapping__c> clonedSubstockiest = new List<Product_Mapping__c>();
        List<Product_Mapping__c> clonedSecondary = new List<Product_Mapping__c>();

        // Clone Product Mappings
        for (Product_Mapping__c oldMap : oldMappings) {

            String newExec = oldToNewUserMap.get(oldMap.Exectuive__c);
            if (String.isBlank(newExec)) continue;

            Product_Mapping__c newMap = new Product_Mapping__c();
            
            // Clone field values
            newMap.Exectuive__c = newExec;
            newMap.Primary_Customer__c = oldMap.Primary_Customer__c;
            newMap.Sub_Stockiest__c = oldMap.Sub_Stockiest__c;
            newMap.Customer__c = oldMap.Customer__c;
            newMap.Chanel__c = oldMap.Chanel__c;
            newMap.Area__c = oldMap.Area__c;
            newMap.PDP_Name__c = oldMap.PDP_Name__c;
            newMap.PDP_Day__c = oldMap.PDP_Day__c;
            newMap.Parent_Depot__c = oldMap.Parent_Depot__c;
            newMap.Child_Depot__c = oldMap.Child_Depot__c;
            newMap.Payment_Term__c = oldMap.Payment_Term__c;
            newMap.Credit_Description__c = oldMap.Credit_Description__c;
            newMap.Inco_Terms__c = oldMap.Inco_Terms__c;
            newMap.Order_Type__c = oldMap.Order_Type__c;
            newMap.Distribution_Channel__c = oldMap.Distribution_Channel__c;
            newMap.Sales_Office__c = oldMap.Sales_Office__c;
            newMap.Division__c = oldMap.Division__c;
            newMap.Cloned_From_Employee_Replacement__c = true;
            
            if (oldMap.Customer_Type__c == 'Primary Customer') {
                clonedPrimary.add(newMap);
            } else if (oldMap.Customer_Type__c == 'Secondary Customer' &&
                       oldMap.Secondary_Customer_Type__c == 'Sub Stockiest') {
                clonedSubstockiest.add(newMap);
            } else {
                clonedSecondary.add(newMap);
            }
        }

         
        
        if (!clonedPrimary.isEmpty()) database.insert(clonedPrimary,false);

        //  Clone DSM Customer Assignments in the SAME batch chunk
        List<Employee_Customer_Assignment__c> oldDSM =
            [SELECT Id, Executive__c, Customer__c
             FROM Employee_Customer_Assignment__c
             WHERE Executive__c IN :oldToNewUserMap.keySet()
             LIMIT 2000]; // Safe chunk

        List<Employee_Customer_Assignment__c> newDSM = new List<Employee_Customer_Assignment__c>();

        for (Employee_Customer_Assignment__c oldRow : oldDSM) {
            String newExec = oldToNewUserMap.get(oldRow.Executive__c);
            if (String.isBlank(newExec)) continue;

            Employee_Customer_Assignment__c newRow = new Employee_Customer_Assignment__c();
            newRow.Customer__c = oldRow.Customer__c;
            newRow.Executive__c = newExec;

            newDSM.add(newRow);
        }

        
        if (!newDSM.isEmpty()) database.insert(newDSM,false);
        
        if (!clonedSubstockiest.isEmpty()) database.insert(clonedSubstockiest,false);        
        if (!clonedSecondary.isEmpty()) database.insert(clonedSecondary,false);  

    }

    public void finish(Database.BatchableContext bc) {}
}