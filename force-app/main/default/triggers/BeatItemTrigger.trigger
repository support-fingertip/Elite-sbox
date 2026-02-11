trigger BeatItemTrigger on Junction_Beat__c (before insert) {
    
     if(Label.Enable_BeatItem_Trigger == 'TRUE'){
         if(Label.Enable_Mapping_Validation == 'TRUE'){
             List<Junction_Beat__c> secList = new List<Junction_Beat__c>();
             List<Junction_Beat__c> primList = new List<Junction_Beat__c>();
             
             for(Junction_Beat__c item: Trigger.new){
                 if(item.BeatFromAccount__c == false && item.Cloned_From_Employee_Replacement__c == false && 
                   item.Cloned_From_Customer_Deactivation__c == false)
                 {
                     if(item.Beat_Type__c == 'Secondary'){
                         secList.add(item);
                     }
                     else{
                         primList.add(item);
                     }
                 }
             }
             
             if(!secList.isEmpty()){
                 BeatItemTriggerHandler.handleSecValidations(secList);
             }
             
             if(!primList.isEmpty()){
                 BeatItemTriggerHandler.handlePrimValidations(primList);
             }
         }         
         
         Set<Id> accIds = new Set<Id>();
         Set<Id> beatIds = new Set<Id>();
         
         // Collect Account and Beat Ids from the incoming records
         for (Junction_Beat__c item : trigger.new) {
             if (item.Account__c != null && item.Child_beat__c != null) {
                 accIds.add(item.Account__c);
                 beatIds.add(item.Child_beat__c);
             }
         }
         
         // Query existing Junction_Beat__c records to check for duplicates
         Map<String, Junction_Beat__c> existingRecordsMap = new Map<String, Junction_Beat__c>();
         for (Junction_Beat__c record : [SELECT Account__c, Child_beat__c FROM Junction_Beat__c WHERE Account__c IN :accIds AND Child_beat__c IN :beatIds]) {
             String key = record.Account__c + '-' + record.Child_beat__c; // Unique key for Account and Beat
             existingRecordsMap.put(key, record);
         }
         
         // Loop through the new Junction_Beat__c records to check for duplicates
         for (Junction_Beat__c newItem : trigger.new) {
             if (newItem.Account__c != null && newItem.Child_beat__c != null) {
                 String key = newItem.Account__c + '-' + newItem.Child_beat__c;
                 if (existingRecordsMap.containsKey(key)) {
                     // If a record already exists for this Account and Beat, prevent insert
                     newItem.addError('This Account is already linked to this Beat.');
                 }
             }
         }
     }
}