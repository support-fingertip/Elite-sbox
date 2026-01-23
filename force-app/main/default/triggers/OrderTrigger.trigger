trigger OrderTrigger on Order__c (before insert,After Insert,before update,After Update,after Delete) {
    
    if(Trigger.isInsert){ 
        if(Trigger.isBefore)
        {
            OrderTriggerHandler.serialNumberMethod(trigger.new);
            
        }
        else 
        {
            
            OrderTriggerHandler.afterInsert(trigger.new);
        }
    }
    else if(Trigger.isUpdate)
    {
        if(Trigger.isBefore)
        {
            OrderTriggerHandler.beforeUpdate(trigger.new,trigger.oldMap); 
        }
        else
        {
            OrderTriggerHandler.afterUpdate(trigger.new,trigger.oldMap); 
        }
    }
    else if(trigger.isDelete)
    {
        if(Trigger.isAfter)
        {
            OrderTriggerHandler.afterDelete(trigger.old);
        }
    }
    

}