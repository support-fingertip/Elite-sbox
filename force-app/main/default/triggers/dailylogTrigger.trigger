trigger dailylogTrigger on Daily_Log__c (Before insert, After insert,Before Update,After update) {
    if(Trigger.isInsert)
    {
        if(trigger.isBefore)
        {
            dailylogTriggerHandler.beforeInsert(Trigger.new);
        }
        else
        {
            dailylogTriggerHandler.afterInsert(Trigger.new);
        }
    }
    else if(Trigger.isUpdate)
    {
        if(trigger.isBefore)
        {
            dailylogTriggerHandler.beforeUpdate(Trigger.new,trigger.oldMap);
        }
        else
        {
            dailylogTriggerHandler.afterUpdate(Trigger.new,trigger.oldMap);
        }
    }
    
}