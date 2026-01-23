trigger StockTrigger on Dealer_Stock__c (After insert,After Delete) {
    if(Trigger.isInsert)
    {
        if(Trigger.isAfter)
        {
            StockTriggerHandler.afterInsert(Trigger.new);
        }
    }
    else if(Trigger.isDelete)
    {
        if(Trigger.isAfter)
        {
            StockTriggerHandler.afterDelete(Trigger.old);
        }
    }
}