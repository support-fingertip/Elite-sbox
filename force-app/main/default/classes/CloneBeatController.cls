public with sharing class CloneBeatController {

    @AuraEnabled
    public static String cloneBeatAndItems(Id beatId, String clonedBeatName, String userName) {
        // Fetch the original Beat record
        Child_beat__c originalBeat = [SELECT Id, Name, User__c,OwnerId,Beat_Type__c,Primary_Customer__c,Sub_Stockist__c 
                                FROM Child_beat__c WHERE Id = :beatId LIMIT 1];
        
        // Create a new Beat record
        Child_beat__c clonedBeat = originalBeat.clone(false, true, true, true);
        clonedBeat.Name = clonedBeatName;  // Set the name of the cloned Beat
        clonedBeat.User__c = userName;  // Set the user for the cloned Beat
        clonedBeat.OwnerId = userName;  // Set the user for the cloned Beat
        /* clonedBeat.Beat_Type__c = originalBeat.Beat_Type__c;  // Retain the original Beat Type
        clonedBeat.Primary_Customer__c = originalBeat.Primary_Customer__c;  // Retain the original Primary Customer
        clonedBeat.Sub_Stockist__c = originalBeat.Sub_Stockist__c;  // Retain the original Sub Stockist  */
        clonedBeat.Active__c = true;  // Ensure the cloned Beat is active

        // Insert the cloned Beat record
        insert clonedBeat;

        // Fetch related Beat Items and clone them
        List<Junction_Beat__c> relatedBeatItems = [SELECT Id, Name, Child_beat__c,Account__c,
                                                    Active__c FROM Junction_Beat__c WHERE Child_beat__c = :beatId];
        List<Junction_Beat__c> clonedBeatItems = new List<Junction_Beat__c>();

        for (Junction_Beat__c item : relatedBeatItems) {
            Junction_Beat__c clonedItem = item.clone(false, true, true, true);
            clonedItem.Child_beat__c = clonedBeat.Id;  // Link the cloned items to the new Beat
           /*  clonedItem.Account__c = item.Account__c;  // Retain the original Account reference
            clonedItem.Active__c = item.Active__c;  // Set active to true for the cloned records */
            clonedBeatItems.add(clonedItem);
        }

        // Insert the cloned Beat Items
        insert clonedBeatItems;

        return clonedBeat.Id;  // Return the ID of the cloned Beat
    }

    @AuraEnabled(cacheable=true)
    public static List<User> getActiveUsers() {
        // Query all active users
        return [SELECT Id, Name FROM User WHERE IsActive = true];
    }
}