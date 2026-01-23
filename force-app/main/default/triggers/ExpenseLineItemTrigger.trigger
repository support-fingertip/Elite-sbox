trigger ExpenseLineItemTrigger on Expenses_Line_Item__c (after insert) {
    if(Trigger.isInsert)
    {
        if(Trigger.isAfter)
        {
            ExpenseLineItemTriggerHandler.afterInsert(trigger.new);
        }
    }
    
}