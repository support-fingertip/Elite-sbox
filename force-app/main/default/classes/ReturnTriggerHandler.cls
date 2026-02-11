public class ReturnTriggerHandler {
    public static void beforInsert(List<Return__c> newReturns) {
        set<String> customerCodes = new set<String>();
        set<String> customerWithExecutiveIds = new set<String>();
        // Collect all unique file IDs from new accounts
        for (Return__c dl : newReturns) {
            if(dl.Customer__c !=null && dl.Customer_Type__c == 'Secondary Customer')
            {
                string key = dl.Customer__c +'-'+dl.OwnerId;
                customerWithExecutiveIds.add(key);
                customerCodes.add(dl.Customer__c);
            }
        }
        
        
        list<Product_Mapping__c> secondaryMappings = [select Id,Primary_Customer__c,Customer__c,Customer_Executive_Pair__c,Sub_Stockiest__c
                                                      from Product_Mapping__c where 
                                                      Customer_Executive_Pair__c In:customerWithExecutiveIds and Primary_Customer__c != null];
        list<Product_Mapping__c> allsecondaryMappings = [select Id,Primary_Customer__c,Customer__c,Customer_Executive_Pair__c,Sub_Stockiest__c
                                                         from Product_Mapping__c where Customer__c In:customerCodes and Primary_Customer__c != null];
        
        if(!secondaryMappings.isEmpty() || !allsecondaryMappings.isEmpty())
        {
            map<String,String> keyWithPrimaryCustomer = new map<String,String>();
            map<String,String> keyWithSubStockiest = new map<String,String>();
            for(Product_Mapping__c pm :secondaryMappings)
            {
                keyWithPrimaryCustomer.put(pm.Customer_Executive_Pair__c,pm.Primary_Customer__c);
                if(pm.Sub_Stockiest__c != null)
                {
                    keyWithSubStockiest.put(pm.Customer_Executive_Pair__c,pm.Sub_Stockiest__c);
                }
            }
            
            map<String,String> secondaryCustomerWithPrimaryCustomer = new map<String,String>();
            map<String,String> secondaryCustomerWithSubStockiest = new map<String,String>();
            for(Product_Mapping__c pm :allsecondaryMappings)
            {
                secondaryCustomerWithPrimaryCustomer.put(pm.Customer__c,pm.Primary_Customer__c);
                if(pm.Sub_Stockiest__c != null)
                {
                    secondaryCustomerWithSubStockiest.put(pm.Customer__c,pm.Sub_Stockiest__c);
                }
            }
            
            for(Return__c rtn : newReturns) {
                if(rtn.Customer__c !=null && rtn.Customer_Type__c == 'Secondary Customer')
                {
                    string key = rtn.Customer__c +'-'+rtn.OwnerId;
                    if(keyWithPrimaryCustomer.containsKey(key))
                    {
                        string DistributorId =  keyWithPrimaryCustomer.get(key);
                        rtn.Distributor__c = DistributorId;
                    }
                    else if(secondaryCustomerWithPrimaryCustomer.containsKey(rtn.Customer__c))
                    {
                        string DistributorId =  secondaryCustomerWithPrimaryCustomer.get(rtn.Customer__c);
                        rtn.Distributor__c = DistributorId;
                    }
                    
                    
                    if(keyWithSubStockiest.containsKey(key))
                    {
                        string subStockiestId =  keyWithSubStockiest.get(key);
                        rtn.Sub_Stockiest__c = subStockiestId;
                    }
                    else if(secondaryCustomerWithPrimaryCustomer.containsKey(rtn.Customer__c))
                    {
                        string subStockiestId =  secondaryCustomerWithSubStockiest.get(rtn.Customer__c);
                        rtn.Sub_Stockiest__c = subStockiestId;
                    }
                }
                
            }
            
        }
        
    }
    public static void afterInsert(List<Return__c> newReturns) {
        Set<String> uniqueFileIds = new Set<String>();
        Map<String, Id> idMap = new Map<String, Id>();
        Set<Id> userIds = new Set<Id>();
        set<String> customerCodes = new set<String>();
        set<String> customerWithExecutiveIds = new set<String>();
        // Collect all unique file IDs from new accounts
        for (Return__c dl : newReturns) {
            userIds.add(dl.OwnerId);
            if (dl.UniqueFileId__c != null) {
                uniqueFileIds.add(dl.UniqueFileId__c);
                idMap.put(dl.UniqueFileId__c, dl.Id);
            }
        }
        
        CustomSharingService.linkFilesToRecords(uniqueFileIds, idMap);
        if(!userIds.isEmpty())
        {
            updateReturnCount(userIds);
        }
        
    }
    public static void afterDelete(List<Return__c> oldReturns)
    {
        Set<Id> userIds = new Set<Id>();
        for(Return__c col: oldReturns)
        {
            userIds.add(col.OwnerId);
        }
        if(!userIds.isEmpty())
        {
            updateReturnCount(userIds);
        }
    }
    public static void updateReturnCount(Set<Id> userIds)
    {
        // Maps with userId → count of returns created today
        Map<Id, Integer> returnCountMap = new Map<Id, Integer>();
        
        for (AggregateResult ar : [ SELECT OwnerId ownerId, COUNT(Id) returnCount
                                   FROM Return__c WHERE OwnerId IN :userIds AND Return_Date__c = TODAY GROUP BY OwnerId
                                  ]) {
                                      Id ownerId = (Id) ar.get('ownerId');
                                      Integer returnCount = (Integer) ar.get('returnCount');
                                      returnCountMap.put( ownerId, (returnCountMap.containsKey(ownerId) ? returnCountMap.get(ownerId) : 0) + returnCount);
                                  }
        
        // Query daily logs for those users
        List<Daily_Log__c> dailyLogs = [SELECT Id, OwnerId, Date__c FROM Daily_Log__c WHERE OwnerId IN :userIds AND Date__c = TODAY ];
        
        List<Daily_Log__c> logsToUpdate = new List<Daily_Log__c>();
        for (Daily_Log__c dl : dailyLogs) {
            dl.Return_Calls__c = returnCountMap.get(dl.OwnerId) != null ? returnCountMap.get(dl.OwnerId) : 0;
            logsToUpdate.add(dl);
        }
        
        if (!logsToUpdate.isEmpty()) { update logsToUpdate;} 
    }
}