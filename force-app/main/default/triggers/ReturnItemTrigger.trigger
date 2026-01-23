trigger ReturnItemTrigger on Return_Item__c (before insert) {
    
    if(trigger.isInsert)
    {
        if(trigger.isInsert)
        {
            ReturnItemTriggerHandler.beforeInsert(trigger.new);
        }
    }

}