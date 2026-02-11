public class CollectionTriggerHandler {
    public static void afterInsert(List<Collection__c> newCollections) {
       Set<String> uniqueFileIds = new Set<String>();
        Map<String, Id> collectionIdMap = new Map<String, Id>();
        Set<Id> userIds = new Set<Id>();
        // Collect all unique file IDs from new accounts
        for (Collection__c dl : newCollections) {
            userIds.add(dl.OwnerId);
            if (dl.UniqueFileId__c != null) {
                uniqueFileIds.add(dl.UniqueFileId__c);
                collectionIdMap.put(dl.UniqueFileId__c, dl.Id);
            }
        }
        
        CustomSharingService.linkFilesToRecords(uniqueFileIds, collectionIdMap);
        if(!userIds.isEmpty())
        {
            updateCollectionCount(userIds);
        }
        
    }

    
    public static void afterDelete(List<Collection__c> oldCollections)
    {
        Set<Id> userIds = new Set<Id>();
        for(Collection__c col: oldCollections)
        {
            userIds.add(col.OwnerId);
        }
        if(!userIds.isEmpty())
        {
            updateCollectionCount(userIds);
        }
    }
    
    public static void updateCollectionCount(Set<Id> userIds)
    {
        // Maps with userId → count of collections created today
        Map<Id, Integer> collectionCountMap = new Map<Id, Integer>();
        
        for (AggregateResult ar : [ SELECT OwnerId ownerId, COUNT(Id) colectionCount
            FROM Collection__c WHERE OwnerId IN :userIds AND Date__c = TODAY GROUP BY OwnerId
        ]) {
            Id ownerId = (Id) ar.get('ownerId');
            Integer accountCount = (Integer) ar.get('colectionCount');
            collectionCountMap.put( ownerId, (collectionCountMap.containsKey(ownerId) ? collectionCountMap.get(ownerId) : 0) + accountCount);
        }
        
        // Query daily logs for those users
        List<Daily_Log__c> dailyLogs = [SELECT Id, OwnerId, Date__c FROM Daily_Log__c WHERE OwnerId IN :userIds AND Date__c = TODAY ];
        
        List<Daily_Log__c> logsToUpdate = new List<Daily_Log__c>();
        for (Daily_Log__c dl : dailyLogs) {
            dl.Collection_Calls__c = collectionCountMap.get(dl.OwnerId) != null ? collectionCountMap.get(dl.OwnerId) : 0;
            logsToUpdate.add(dl);
        }
        
        if (!logsToUpdate.isEmpty()) { update logsToUpdate;} 
    }
}