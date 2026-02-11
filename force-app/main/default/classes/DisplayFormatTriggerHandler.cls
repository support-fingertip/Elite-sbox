public class DisplayFormatTriggerHandler {
    public static void afterInsert(List<Display_Format__c> newData) {
        Set<String> uniqueFileIds = new Set<String>();
        Map<String, Id> dataIdMap = new Map<String, Id>();
        Set<String> OwnerIds = new Set<String>();
        // Collect all unique file IDs from new accounts
        for (Display_Format__c dl : newData) {
            if (dl.UniqueFileId__c != null) {
                uniqueFileIds.add(dl.UniqueFileId__c);
                dataIdMap.put(dl.UniqueFileId__c, dl.Id);
            }
        }
        
        CustomSharingService.linkFilesToRecords(uniqueFileIds, dataIdMap);
        
    }
    
}