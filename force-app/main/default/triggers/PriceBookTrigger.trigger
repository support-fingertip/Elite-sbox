trigger PriceBookTrigger on Price_Book__c (after insert, after update) {
    PriceBookTriggerHandler.handle(Trigger.new, Trigger.oldMap);
}