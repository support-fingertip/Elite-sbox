trigger CollectionTrigger on Collection__c (after insert,after Delete) {
    if(Trigger.isInsert)
    {
        if(Trigger.isAfter)
        {
            CollectionTriggerHandler.afterInsert(Trigger.new);
        }
    }
    else if(Trigger.isDelete)
    {
        if(Trigger.isAfter)
        {
            CollectionTriggerHandler.afterDelete(Trigger.old);
        }
    }
}