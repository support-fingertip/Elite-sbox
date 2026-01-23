public without sharing class PJPItemHandler {
    private static Boolean isUpdateInProgress = false;

    public static void updatePjpItemsAfterApproval(String pjpId) {
        // Query for PJP Items related to the PJP record
        List<PJP_Item__c> pjpItemsToUpdate = [SELECT Id, Status__c 
                                            FROM PJP_Item__c 
                                            WHERE PJP__c = :pjpId 
                                            AND Status__c NOT IN ('Approved', 'Rejected')];

        List<PJP_Item__c> itemsToUpdate = new List<PJP_Item__c>();

        for (PJP_Item__c pjpItem : pjpItemsToUpdate) {
            pjpItem.Status__c = 'Submitted'; // Set status to Submitted
            itemsToUpdate.add(pjpItem);
        }

        // If there are items to update, perform the update asynchronously
        if (!itemsToUpdate.isEmpty()) {
            try {
                update itemsToUpdate;
                System.debug('Updated PJP Items to Submitted');
            } catch (DmlException e) {
                ExceptionHandler.addLog(e, String.valueOf(itemsToUpdate), 'PJPItemHandler.updatePjpItemsAfterApproval');
                throw new AuraHandledException('Failed to update PJP Items');
            }
        }
    }

     public static void deactivateBeats(Set<Id> accIds) {

        List<Child_beat__c> beats = [select Id,Name from Child_beat__c where Primary_Customer__c IN: accIds OR Sub_Stockist__c IN: accIds];

        if(beats.size()> 0 ){
            for(Child_beat__c beat: beats){
                beat.Active__c = false;
            }

            try{
                Database.update(beats,false);
            }
            catch(Exception ex){
                 ExceptionHandler.addLog(ex, String.valueOf(beats), 'PJPItemHandler.deactivateBeats');
            }
        }

        List<JUnction_Beat__c> items = [select Id,Name from JUnction_Beat__c where Account__c IN: accIds ];

        if(items.size()> 0 ){
            for(JUnction_Beat__c beat: items){
                beat.Active__c = false;
            }

            try{
                Database.update(items,false);
            }
            catch(Exception ex){
                 ExceptionHandler.addLog(ex, String.valueOf(items), 'PJPItemHandler.deactivateBeats');
            }
        }



     }
    
     public static void handleValidations(List<PJP_Item__c> newItems) {
        if (isUpdateInProgress) return; // Prevent recursion

        Set<Id> pjpIds = new Set<Id>();
        Set<Id> beatIds = new Set<Id>();
        Set<Date> dateSet = new Set<Date>();

          // 1. Check for intra-batch duplicates
        Map<String, PJP_Item__c> seenKeys = new Map<String, PJP_Item__c>();
        for (PJP_Item__c item : newItems) {
            if (item.PJP__c != null)  pjpIds.add(item.PJP__c);
            if (item.Beat__c != null) beatIds.add(item.Beat__c);
            if (item.Date__c != null) dateSet.add(item.Date__c);
            
            String key = String.valueOf(item.PJP__c) + '_' + String.valueOf(item.Date__c);
            if (seenKeys.containsKey(key)) {
                item.addError('Duplicate PJP Item (same PJP and Date) found in this upload batch.');
            } else {
                seenKeys.put(key, item);
            }
        }
         
         system.debug('pjpIds:' + pjpIds);
         system.debug('beatIds:' + beatIds);
         system.debug('dateSet:' + dateSet);
         

        // Query existing items for upsert/duplicate check
        Map<String, PJP_Item__c> existingItems = new Map<String, PJP_Item__c>();
        for (PJP_Item__c rec : [
            SELECT Id, PJP__c, Beat__c, Date__c, Status__c
            FROM PJP_Item__c
            WHERE PJP__c IN :pjpIds AND Date__c IN :dateSet
        ]) {
            String key = String.valueOf(rec.PJP__c)  + '_' + String.valueOf(rec.Date__c);
            existingItems.put(key, rec);
        }

        // Query related Calendar_beat__c and Child_beat__c records
        Map<Id, Calendar_beat__c> pjpMap = new Map<Id, Calendar_beat__c>(
            [SELECT Id, User__c FROM Calendar_beat__c WHERE Id IN :pjpIds]
        );
        Map<Id, Child_beat__c> beatMap = new Map<Id, Child_beat__c>(
            [SELECT Id, OwnerId FROM Child_beat__c WHERE Id IN :beatIds]
        );

        // For user profile check
        Set<Id> userIds = new Set<Id>();
        for (Calendar_beat__c pjp : pjpMap.values()) {
            if (pjp.User__c != null) userIds.add(pjp.User__c);
        }
        Map<Id, User> userMap = new Map<Id, User>();
        if (!userIds.isEmpty()) {
            userMap = new Map<Id, User>([SELECT Id, Profile.Name FROM User WHERE Id IN :userIds]);
        }

       /*  List<PJP_Item__c> itemsToUpdate = new List<PJP_Item__c>(); */

        for (PJP_Item__c item : newItems) {
            String key = String.valueOf(item.PJP__c) + '_' + String.valueOf(item.Date__c);

            /*  // 1. If record exists, update it instead of inserting duplicate
            if (existingItems.containsKey(key)) {
               PJP_Item__c existing = existingItems.get(key);
                existing.Assigned_Beat__c = item.Beat__c;

                // Example: Copy fields you want to update
                existing.Status__c = item.Status__c;
                // Add more fields as needed

                itemsToUpdate.add(existing);

                // Prevent insert of duplicate
                item.addError('Existing record updated with new data. No duplicate created.');
            } */
            
            // 1. Prevent duplicate creation (enforce update instead)
            if (existingItems.containsKey(key) && Trigger.isInsert) {
                item.addError('A PJP Item for this PJP and Date already exists. Please update the existing item instead of creating a new one.');
            }

            // 2. Validate Beat assignment to user
            Id pjpUserId = pjpMap.containsKey(item.PJP__c) ? pjpMap.get(item.PJP__c).User__c : null;
            String beatAssignedTo = beatMap.containsKey(item.Beat__c) ? beatMap.get(item.Beat__c).OwnerId : null;
            if (pjpUserId != null && beatAssignedTo != null && userMap.containsKey(pjpUserId)) {
                String pjpUserProfile = userMap.get(pjpUserId).Profile.Name;
                if (pjpUserId != beatAssignedTo) {
                    item.addError('Beat is not assigned to the same user as the PJP. Please select the correct beat.');
                }
            }
        }

        /* // Update existing records with new data, safely (no recursion)
        if (!itemsToUpdate.isEmpty()) {
           
              try{
                    isUpdateInProgress = true;
                    update itemsToUpdate;
                    isUpdateInProgress = false;
            }
            catch(Exception ex){
                 ExceptionHandler.addLog(ex, String.valueOf(itemsToUpdate), 'PJPItemHandler.handleValidations');
            }
        } */
    }
    
}