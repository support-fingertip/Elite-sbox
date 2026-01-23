trigger BeatTrigger on Child_beat__c (after insert,before insert,before update,after update) {
    
    if(Label.Enable_Beat_Trigger == 'TRUE'){
        //Before Insert and After Insert
        if(trigger.isInsert)
        {
            if(trigger.isBefore)
            {
                for (Child_beat__c beat : Trigger.new) {
                    if (beat.User__c != null){
                        beat.OwnerId = beat.User__c;
                    }
                    if(beat.User__c == null && beat.OwnerId != null){
                        beat.User__c = beat.OwnerId;
                    }
                }
                if(Label.Enable_Mapping_Validation == 'TRUE'){
                    BeatTriggerHandler.handleValidations(Trigger.new);
                }
            }
            else
            {
                List<Child_beat__c> beatsToUpdate = new List<Child_beat__c>();
                for(Child_beat__c beat : Trigger.new) {
                    if(beat.Beat_Id__c != null && beat.Beat_Id_Text__c == null) {
                        beatsToUpdate.add(new Child_beat__c(
                            Id = beat.Id,
                            Beat_Id_Text__c = String.valueOf(beat.Beat_Id__c)
                        ));
                    }
                }
                if(!beatsToUpdate.isEmpty()) {
                    update beatsToUpdate;
                }
            }
        }
        //Before Update and After Update
        else if(trigger.isUpdate)
        {
            if(trigger.isBefore)
            {
                for (Child_beat__c beat : Trigger.new) {
                    if (beat.User__c != null && beat.User__c != Trigger.oldMap.get(beat.Id).User__c) {
                        beat.OwnerId = beat.User__c;
                    }
                }
                
                List<Child_beat__c> beats = new List<Child_beat__c>();
                for(Child_beat__c beat: trigger.new){
                    if(beat.OwnerId != Trigger.oldMap.get(beat.Id).OwnerId){
                        beats.add(beat);
                    }
                }
                if(!beats.isEmpty()){
                    if(Label.Enable_Mapping_Validation == 'TRUE'){
                        BeatTriggerHandler.handleValidations(beats);
                    }
                }
            }
            else
            {
                //Secondary Mapping will created and it will delete old PJP Items
                Set<Id> beatIds = new Set<Id>();
                Set<Id> ownerIds = new Set<Id>();
                for(Child_beat__c beat: trigger.new){
                    if(beat.OwnerId != Trigger.oldMap.get(beat.Id).OwnerId){
                        beatIds.add(beat.Id);
                        ownerIds.add(Trigger.oldMap.get(beat.Id).OwnerId); 
                    }
                }
                if(!beatIds.isEmpty() && !ownerIds.isEmpty()){
                    if(Label.Enable_Mapping_Validation == 'TRUE'){
                        BeatTriggerHandler.createSecMappings(Trigger.new);
                    }
                    
                    //For Old User we are Deleting the PJP Items
                    List<PJP_Item__c> items = [select Id from PJP_Item__c where Beat__c IN: beatIds and PJP__r.User__c IN: ownerIds];
                    
                    if(!items.isEmpty()){
                        try{
                            delete items;
                        }
                        catch(Exception ex){
                            ExceptionHandler.addLog(ex, String.valueof(items), 'BeatTrigger');
                        }
                    }
                }
            }
        }
    }
    
}