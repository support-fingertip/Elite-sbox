public class SecondaryCustomerMappingBatch implements Database.Batchable<SObject>, Database.Stateful {

    public static final Integer BATCH_SIZE = 200;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id 
            FROM Account 
            WHERE Customer_Type__c = 'Secondary Customer' 
                  AND Outlet_Id__c = null
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Account> secondaryCustomers) {
        Set<Id> secondaryCustomerIds = new Set<Id>();
        for (Account acc : secondaryCustomers) {
            secondaryCustomerIds.add(acc.Id);
        }

        // Step 1: Find all mappings for Secondary Customers
        List<Product_Mapping__c> productMappingList = [
            SELECT Id, Customer__c, Primary_Customer__c, Sub_Stockiest__c
            FROM Product_Mapping__c
            WHERE Customer__c IN :secondaryCustomerIds
        ];

        // Build reverse maps
        Map<Id, Set<Id>> primaryToSecondaryMap = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> subStockiestToSecondaryMap = new Map<Id, Set<Id>>();
        Set<Id> primaryCustomerIds = new Set<Id>();
        Set<Id> subStockiestIds = new Set<Id>();

        for (Product_Mapping__c pm : productMappingList) {
            if (pm.Primary_Customer__c != null && pm.Sub_Stockiest__c == null) {
                primaryCustomerIds.add(pm.Primary_Customer__c);
                if (!primaryToSecondaryMap.containsKey(pm.Primary_Customer__c)) {
                    primaryToSecondaryMap.put(pm.Primary_Customer__c, new Set<Id>());
                }
                primaryToSecondaryMap.get(pm.Primary_Customer__c).add(pm.Customer__c);
            }
            else if (pm.Sub_Stockiest__c != null) {
                subStockiestIds.add(pm.Sub_Stockiest__c);
                if (!subStockiestToSecondaryMap.containsKey(pm.Sub_Stockiest__c)) {subStockiestToSecondaryMap.put(pm.Sub_Stockiest__c, new Set<Id>());}
                subStockiestToSecondaryMap.get(pm.Sub_Stockiest__c).add(pm.Customer__c);
            }
        }

        List<Product_Mapping__c> productMappingToInsert = new List<Product_Mapping__c>();

        // Step 2: Payroll mappings under Primary
        if (!primaryCustomerIds.isEmpty()) {
            List<Product_Mapping__c> payRollMapping = [
                SELECT Id, Exectuive__c, Customer__c, Employee__c  
                FROM Product_Mapping__c 
                WHERE Customer__c IN :primaryCustomerIds
            ];

            for (Product_Mapping__c pm : payRollMapping) {
                if (primaryToSecondaryMap.containsKey(pm.Customer__c)) {
                    for (Id secondaryId : primaryToSecondaryMap.get(pm.Customer__c)) {
                        productMappingToInsert.add(new Product_Mapping__c(
                            Exectuive__c = pm.Exectuive__c,
                            Employee__c = pm.Employee__c,
                            Primary_Customer__c = pm.Customer__c,
                            Customer__c = secondaryId
                        ));
                    }
                }
            }

            // Step 3: Non-Payroll mappings
            List<Employee_Customer_Assignment__c> nonPayrollMapping = [
                SELECT Id, Executive__c, Employee__c, Customer__c 
                FROM Employee_Customer_Assignment__c
                WHERE Customer__c IN :primaryCustomerIds
            ];

            for (Employee_Customer_Assignment__c pm : nonPayrollMapping) {
                if (primaryToSecondaryMap.containsKey(pm.Customer__c)) {
                    for (Id secondaryId : primaryToSecondaryMap.get(pm.Customer__c)) {
                        productMappingToInsert.add(new Product_Mapping__c(
                            Exectuive__c = pm.Executive__c,
                            Employee__c = pm.Employee__c,
                            Primary_Customer__c = pm.Customer__c,
                            Customer__c = secondaryId
                        ));
                    }
                }
            }
        }

        // Step 4: SubStockiest mappings
        if (!subStockiestIds.isEmpty()) {
            List<Product_Mapping__c> subStockiestMappings = [SELECT Id, Exectuive__c, Employee__c, Customer__c, Primary_Customer__c  FROM Product_Mapping__c WHERE Customer__c IN :subStockiestIds  ];
          

            for (Product_Mapping__c pm : subStockiestMappings) {
                if (subStockiestToSecondaryMap.containsKey(pm.Customer__c)) {
                    for (Id secondaryId : subStockiestToSecondaryMap.get(pm.Customer__c)) {
                        productMappingToInsert.add(new Product_Mapping__c(
                            Exectuive__c = pm.Exectuive__c,
                            Employee__c = pm.Employee__c,
                            Sub_Stockiest__c = pm.Customer__c,
                            Primary_Customer__c = pm.Primary_Customer__c,
                            Customer__c = secondaryId
                        ));
                    }
                }
            }
        }

        // Step 5: Insert
        if (!productMappingToInsert.isEmpty()) {
            Database.insert(productMappingToInsert, false);
        }
    }

    public void finish(Database.BatchableContext bc) {
        // Optional logging/notification
    }
}