public with sharing class AccountCalendarController {
    
    public class PjpItemWrapper {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String dates { get; set; }
        @AuraEnabled public String accountId { get; set; }
        @AuraEnabled public String accountName { get; set; }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Child_beat__c> getBeats(String userId) {
        return [SELECT Id, Name 
                FROM Child_beat__c ];
    }
    
    @AuraEnabled
    public static List<PjpItemWrapper> getPjpItems(String userId, Integer month, Integer year) {
        List<PjpItemWrapper> items = new List<PjpItemWrapper>();
        
        List<PJP_Item__c> existingItems = [
            SELECT Id, Date__c, Assigned_Beat__c, Assigned_Beat__r.Name
            FROM PJP_Item__c
            WHERE PJP__r.OwnerId = :userId
            AND CALENDAR_MONTH(Date__c) = :month
            AND CALENDAR_YEAR(Date__c) = :year
        ];
        
        for (PJP_Item__c item : existingItems) {
            PjpItemWrapper wrapper = new PjpItemWrapper();
            wrapper.id = item.Id;
            wrapper.dates = String.valueOf(item.Date__c);
            wrapper.accountId = item.Assigned_Beat__c;
            wrapper.accountName = item.Assigned_Beat__r.Name;
            items.add(wrapper);
        }
        
        return items;
    }
    
    @AuraEnabled
    public static void savePjpItems(String userId, Integer month, Integer year, List<PjpItemWrapper> pjpItems) {
        List<Calendar_beat__c> existingPjp = [
            SELECT Id FROM Calendar_beat__c 
            WHERE OwnerId = :userId 
            AND CALENDAR_MONTH(Start_Month__c) = :month
            AND CALENDAR_YEAR(Start_Month__c) = :year
            LIMIT 1
        ];
        
        Calendar_beat__c pjp;
        if (existingPjp.isEmpty()) {
            // Create new PJP if none exists
            pjp = new Calendar_beat__c(
                OwnerId = userId,
                Start_Month__c = Date.newInstance(year, month, 1)
            );
            insert pjp;
        } else {
            pjp = existingPjp[0];
        }
        
        List<PJP_Item__c> itemsToUpsert = new List<PJP_Item__c>();
        
        for (PjpItemWrapper wrapper : pjpItems) {
            PJP_Item__c item = new PJP_Item__c(
                PJP__c = pjp.Id,
                Date__c = Date.valueOf(wrapper.dates),
                Assigned_Beat__c = wrapper.accountId,
                Status__c = 'Planned'
            );
            
            if (wrapper.id != null) {
                item.Id = wrapper.id;
            }
            
            itemsToUpsert.add(item);
        }
        
        Set<Id> existingItemIds = new Map<Id, PJP_Item__c>([
            SELECT Id FROM PJP_Item__c 
            WHERE PJP__c = :pjp.Id
        ]).keySet();
        
        Set<Id> newItemIds = new Set<Id>();
        for (PjpItemWrapper wrapper : pjpItems) {
            if (wrapper.id != null) {
                newItemIds.add(wrapper.id);
            }
        }
        
        List<PJP_Item__c> itemsToDelete = new List<PJP_Item__c>();
        for (Id existingId : existingItemIds) {
            if (!newItemIds.contains(existingId)) {
                itemsToDelete.add(new PJP_Item__c(Id = existingId));
            }
        }
        
        if (!itemsToDelete.isEmpty()) {
            delete itemsToDelete;
        }
        
        if (!itemsToUpsert.isEmpty()) {
            upsert itemsToUpsert;
        }
    }
}