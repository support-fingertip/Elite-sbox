trigger ReturnTrigger on Return__c (before insert, after insert,after delete) {
    
    if(Trigger.isInsert)
    {
        if(Trigger.isBefore)
        {
            ReturnTriggerHandler.beforInsert(Trigger.new);
        }
        else
        {
            ReturnTriggerHandler.afterInsert(Trigger.new);
        }
    }
    else if(Trigger.isDelete)
    {
        if(Trigger.isAfter)
        {
            ReturnTriggerHandler.afterDelete(Trigger.old);
        }
    }
}