trigger InvoiceHeaderTrigger on Invoice__c (before insert) {
    
    if(trigger.isinsert)
    {
        if(trigger.isBefore)
        {
            InvoiceHeaderTriggerHandler.beforeInsert(trigger.new);
        }
    }
}