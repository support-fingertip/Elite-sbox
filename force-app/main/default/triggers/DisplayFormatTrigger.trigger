trigger DisplayFormatTrigger on Display_Format__c (after insert) {
    if(Trigger.isInsert)
    {
        if(Trigger.isAfter)
        {
            DisplayFormatTriggerHandler.afterInsert(Trigger.new);
        }
    }
    
    
}