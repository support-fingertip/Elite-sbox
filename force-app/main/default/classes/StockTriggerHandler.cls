public class StockTriggerHandler 
{
    public static void afterInsert(List<Dealer_Stock__c> newStockList)
    {
        Set<Id> userIds = new Set<Id>();
        for (Dealer_Stock__c dl : newStockList) {
            userIds.add(dl.OwnerId);
        }
        if(!userIds.isEmpty())
        {
            updateStockCount(userIds);
        }
    }
    
    public static void afterDelete(List<Dealer_Stock__c> oldStockList)
    {
        Set<Id> userIds = new Set<Id>();
        for (Dealer_Stock__c dl : oldStockList) {
            userIds.add(dl.OwnerId);
        }
        if(!userIds.isEmpty())
        {
            updateStockCount(userIds);
        }
    }
    
    
    public static void updateStockCount(Set<Id> userIds)
    {
        // Maps with userId → count of collections created today
        Map<Id, Integer> stockCountMap = new Map<Id, Integer>();
        
        for (AggregateResult ar : [
                                   SELECT OwnerId, COUNT_DISTINCT(Store__c) stockCount
                                   FROM Dealer_Stock__c
                                   WHERE CreatedDate = TODAY
                                   GROUP BY OwnerId
                                  ]) 
        {
            Id ownerId = (Id) ar.get('ownerId');
            Integer stockCount = (Integer) ar.get('stockCount');
            stockCountMap.put( ownerId, (stockCountMap.containsKey(ownerId) ? stockCountMap.get(ownerId) : 0) + stockCount);
        }
        
        // Query daily logs for those users
        List<Daily_Log__c> dailyLogs = [SELECT Id, OwnerId, Date__c FROM Daily_Log__c WHERE OwnerId IN :userIds AND Date__c = TODAY ];
        
        List<Daily_Log__c> logsToUpdate = new List<Daily_Log__c>();
        for (Daily_Log__c dl : dailyLogs) {
            dl.Stock_Calls__c = stockCountMap.get(dl.OwnerId) != null ? stockCountMap.get(dl.OwnerId) : 0;
            logsToUpdate.add(dl);
        }
        
        if (!logsToUpdate.isEmpty()) { update logsToUpdate;} 
    }

}