trigger AccountTrigger on Account (before insert,after insert,before update,after update,after delete) {
    
    if(Trigger.isInsert)
    {
        if(Trigger.isBefore)
        {
            AccountTriggerHandler.beforeInsert(Trigger.new);
        }
        else
        {
            AccountTriggerHandler.afterInsert(Trigger.new);
            
            List<Account> accsToUpdate = new List<Account>();
            
            for(Account acc : Trigger.new) {
                if(acc.Customer_Code__c != null) {
                    accsToUpdate.add(new Account(
                        Id = acc.Id,
                        Customer_Code_Text__c = String.valueOf(acc.Customer_Code__c)
                    ));
                }
            }
            
            if(!accsToUpdate.isEmpty()) {
                //  Prevent Azure call for this internal update
                AccountTriggerRecursion.skipAzureCall = true;
                update accsToUpdate;
                //  Prevent Azure call for this internal update
                AccountTriggerRecursion.skipAzureCall = false;
            }
        }
    }
    if(trigger.isUpdate)
    {
        if(Trigger.isBefore)
        {
            AccountTriggerHandler.beforeUpdate(trigger.new,trigger.oldMap);
        }
        else
        {
            AccountTriggerHandler.afterUpdate(trigger.new,trigger.oldMap);
            
            Set<Id> accIds = new Set<Id>();
            for(Account acc: trigger.new){
                if(acc.Customer_Status__c == 'Inactive' && acc.Customer_Status__c != trigger.oldMap.get(acc.Id).Customer_Status__c){
                    accIds.add(acc.Id);
                }
            }
            if(accIds.size() > 0){
                PJPItemHandler.deactivateBeats(accIds);
            }
        }
       
    }
    
    if(trigger.isDelete)
    {
        if(trigger.isAfter)
        {
            AccountTriggerHandler.afterDelete(trigger.old);
        }
    }
  
}