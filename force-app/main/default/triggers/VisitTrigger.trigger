trigger VisitTrigger on Visit__c (after insert,after Update, after Delete,after undelete) 
{
    if(Trigger.isInsert)
    {
        if(Trigger.isAfter)
        {
            VisitTriggerHandler.afterInsert(Trigger.new);
        }
    }
    else if(Trigger.isUpdate)
    {
        if(Trigger.isAfter)
        {
            VisitTriggerHandler.afterUpdate(Trigger.new,trigger.oldMap);
        }
    }
    else if(Trigger.isUndelete)
    {
        if(Trigger.isAfter)
        {
            VisitTriggerHandler.afterInsert(Trigger.new);
        }
    }
    else if(Trigger.isDelete)
    {
        if(Trigger.isAfter)
        {
            VisitTriggerHandler.afterDelete(Trigger.old);
        }
    }

}