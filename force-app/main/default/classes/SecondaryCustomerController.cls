public with sharing class SecondaryCustomerController {

    @AuraEnabled(cacheable=true)
    public static ReturnData getProductMappings(Id recordId) {
        ReturnData rt = new ReturnData();
        String fileName = '';
        
        List<Account> lstAccount = [
            SELECT Id, Name, Customer_Type__c, SAP_Customer_Code__c, Customer_Code__c, Outlet_Id__c 
            FROM Account 
            WHERE Id = :recordId 
        ];
        
        List<Junction_Beat__c> beatItems = [  SELECT Id, Account__c, Beat_Id__c  FROM Junction_Beat__c WHERE Primary_Customer_Record_Id__c = :recordId];
        
        Map<Id, Set<String>> outletToBeatIds = new Map<Id, Set<String>>();
        
        for (Junction_Beat__c bt : beatItems) {
            if (!outletToBeatIds.containsKey(bt.Account__c)) {
                outletToBeatIds.put(bt.Account__c, new Set<String>());
            }
            outletToBeatIds.get(bt.Account__c).add(bt.Beat_Id__c);
        }
        

        List<Product_Mapping__c> mappings = new List<Product_Mapping__c>();

        if (!lstAccount.isEmpty()) {
            Account acc = lstAccount[0];

            if (acc.Customer_Type__c == 'Primary Customer') {
                fileName = acc.Name + (String.isNotBlank(acc.SAP_Customer_Code__c) ? ('_' + acc.SAP_Customer_Code__c) : '');

                mappings = [
                    SELECT Id, Customer__c, Secondary_Customer_Outlet_Id__c,Customer__r.State__c,Customer__r.District__c,Customer__r.Primary_Phone_Number__c,
                    Secondary_Customer_Customer_Code__c, Customer__r.Name,Executive_Employee_Code__c,Exectuive__r.Name,
                    Customer__r.Secondary_Customer_Type__c,
                    Primary_Customer__r.SAP_Customer_Code__c,Sub_Stockiest__r.Outlet_Id__c,
                    Primary_Customer__r.Name,Sub_Stockiest__r.Name
                    FROM Product_Mapping__c
                    WHERE Primary_Customer__c = :recordId
                    WITH SECURITY_ENFORCED
                ];
            } else {
                fileName = acc.Name
                    + (String.isNotBlank(acc.Customer_Code__c) ? ('_' + acc.Customer_Code__c) : '')
                    + (String.isNotBlank(acc.Outlet_Id__c) ? ('_' + acc.Outlet_Id__c) : '');

                mappings = [
                    SELECT Id, Customer__c, Secondary_Customer_Outlet_Id__c,Customer__r.State__c,Customer__r.District__c,Customer__r.Primary_Phone_Number__c,
                    Secondary_Customer_Customer_Code__c, Customer__r.Name,Executive_Employee_Code__c,Exectuive__r.Name,
                    Primary_Customer__r.SAP_Customer_Code__c,Sub_Stockiest__r.Outlet_Id__c,  Customer__r.Secondary_Customer_Type__c,
                    Primary_Customer__r.Name,Sub_Stockiest__r.Name
                    FROM Product_Mapping__c
                    WHERE Sub_Stockiest__c = :recordId
                    WITH SECURITY_ENFORCED
                ];
            }
        }

        rt.fileName = fileName;

        Set<String> seenCustomerIds = new Set<String>();
        List<Data> uniqueSecondaryCustomers = new List<Data>();
        Set<Id> uniqueCustomers = new Set<Id>();
        Set<Id> subStockiestCustomers = new Set<Id>();
        decimal secondaryCustomerCount = 0;
        decimal subStockiestCount = 0;
        decimal totalCustomersCount = 0;
        
        for (Product_Mapping__c pm : mappings) {
            if (String.isNotBlank(pm.Customer__c) && String.isNotBlank(pm.Exectuive__c)) {
                uniqueCustomers.add(pm.Customer__c);
                
                if (pm.Customer__r.Secondary_Customer_Type__c == 'Sub Stockiest') {
                    subStockiestCustomers.add(pm.Customer__c);
                }
                
                Data d = new Data();
                d.recordId = pm.Id;
                d.secondaryCustomerName = pm.Customer__r != null ? pm.Customer__r.Name : '';
                d.secondaryCustomerId = pm.Customer__c;
                d.secondaryCustomerOutletId = pm.Secondary_Customer_Outlet_Id__c;
                d.secondaryCustomerCode = pm.Secondary_Customer_Customer_Code__c;
                d.primaryPhoneNumber = pm.Customer__r != null  ? pm.Customer__r.Primary_Phone_Number__c : '';
                d.state = pm.Customer__r != null  ? pm.Customer__r.State__c : '';
                d.disrict =  pm.Customer__r != null  ?   pm.Customer__r.District__c :'';
                d.executiveName = pm.Exectuive__r != null ? pm.Exectuive__r.Name : '';
                d.executiveCode = pm.Executive_Employee_Code__c;
                d.primaryCustomer = pm.Primary_Customer__r != null  ? pm.Primary_Customer__r.SAP_Customer_Code__c : '';
                d.subStockiest = pm.Sub_Stockiest__r != null ? pm.Sub_Stockiest__r.Outlet_Id__c : ''; 
                d.primaryCustomerName = pm.Primary_Customer__r != null  ? pm.Primary_Customer__r.Name : '';
                d.subStockiestName = pm.Sub_Stockiest__r != null ? pm.Sub_Stockiest__r.Name : ''; 
                // Set BeatId using outletToBeatIds
                if (outletToBeatIds.containsKey(pm.Customer__c)) {
                    d.beatId = String.join(new List<String>(outletToBeatIds.get(pm.Customer__c)), ';');
                } else {
                    d.beatId = '';
                }
                uniqueSecondaryCustomers.add(d);
            }
        }
        // final counts
        subStockiestCount = subStockiestCustomers.size();
        secondaryCustomerCount = uniqueCustomers.size() - subStockiestCount;
        totalCustomersCount = uniqueCustomers.size();
        rt.customerData = uniqueSecondaryCustomers;
        rt.subStockiestCount = subStockiestCount;
        rt.secondaryCustomerCount = secondaryCustomerCount;
        rt.totalCustomersCount = totalCustomersCount;
        return rt;
    }

    public class ReturnData {
        @AuraEnabled public String fileName;
        @AuraEnabled public List<Data> customerData;
        @AuraEnabled public Decimal secondaryCustomerCount;
        @AuraEnabled public Decimal subStockiestCount;
        @AuraEnabled public Decimal totalCustomersCount;
    }

    public class Data {
        @AuraEnabled public String recordId;
        @AuraEnabled public String secondaryCustomerName;
        @AuraEnabled public String secondaryCustomerId;
        @AuraEnabled public String secondaryCustomerOutletId;
        @AuraEnabled public String secondaryCustomerCode;
        @AuraEnabled public String primaryPhoneNumber;
        @AuraEnabled public String primaryCustomer;
        @AuraEnabled public String subStockiest;
        @AuraEnabled public String primaryCustomerName;
        @AuraEnabled public String subStockiestName;
        @AuraEnabled public String state;
        @AuraEnabled public String disrict;
        @AuraEnabled public String executiveName;
        @AuraEnabled public String executiveCode;
        @AuraEnabled public String beatId;
        
        
        
    }
}