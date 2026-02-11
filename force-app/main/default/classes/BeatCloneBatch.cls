public class BeatCloneBatch implements Database.Batchable<SObject>, Database.Stateful {

    Map<String, String> oldToNewExecMap;
    Map<Id, Id> oldBeatToNewBeat = new Map<Id, Id>();
    List<Child_beat__c> newBeatsBucket = new List<Child_beat__c>();
    List<Junction_Beat__c> newJunctionBucket = new List<Junction_Beat__c>();

    public BeatCloneBatch(Map<String, String> inputMap) {
        this.oldToNewExecMap = inputMap;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name, Primary_Customer__c, Sub_Stockist__c, Order_Number__c,
                   OwnerId, Beat_Type__c, Active__c,
                   (SELECT Account__c, Order_Number__c, Active__c FROM Junction_Beats__r)
            FROM Child_beat__c
            WHERE OwnerId IN :oldToNewExecMap.keySet()
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Child_beat__c> scope) {

        List<Child_beat__c> beatsToInsert = new List<Child_beat__c>();

        // STEP 1: Clone beats
        for (Child_beat__c oldBeat : scope) {
            String newOwnerId = oldToNewExecMap.get(oldBeat.OwnerId);
            if (String.isNotBlank(newOwnerId)) {
                Child_beat__c newBeat = new Child_beat__c();
                newBeat.Name = oldBeat.Name;
                newBeat.Primary_Customer__c = oldBeat.Primary_Customer__c;
                newBeat.Sub_Stockist__c = oldBeat.Sub_Stockist__c;
                newBeat.Order_Number__c = oldBeat.Order_Number__c;
                newBeat.Beat_Type__c = oldBeat.Beat_Type__c;
                newBeat.OwnerId = newOwnerId;
                newBeat.Active__c = oldBeat.Active__c;
                newBeat.Old_Beat_Id_Back_End_Purpose__c = oldBeat.Id;
                newBeat.Cloned_From_Employee_Replacement__c = true;
                beatsToInsert.add(newBeat);
            }
        }

        if (!beatsToInsert.isEmpty()) {
            database.insert(beatsToInsert,false);

            for (Child_beat__c inserted : beatsToInsert) {
                oldBeatToNewBeat.put(
                    (Id)inserted.Old_Beat_Id_Back_End_Purpose__c,
                    inserted.Id
                );
            }
        }

        // STEP 2: Clone Junction Items
        List<Junction_Beat__c> junctionsToInsert = new List<Junction_Beat__c>();

        for (Child_beat__c oldBeat : scope) {
            Id newBeatId = oldBeatToNewBeat.get(oldBeat.Id);
            if (newBeatId == null) continue;

            for (Junction_Beat__c jb : oldBeat.Junction_Beats__r) {
                Junction_Beat__c newJb = new Junction_Beat__c();
                newJb.Child_Beat__c = newBeatId;
                newJb.Account__c = jb.Account__c;
                newJb.Order_Number__c = jb.Order_Number__c;
                newJb.Active__c = jb.Active__c;
                newJb.Cloned_From_Employee_Replacement__c = true;
                junctionsToInsert.add(newJb);
            }
        }

        if (!junctionsToInsert.isEmpty()) {
            database.insert(junctionsToInsert,false);
        }
    }

    public void finish(Database.BatchableContext bc) {
        // optionally send email or log
    }
}