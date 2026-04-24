public class PriceBookSharingBatch implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Process all Price Books that have a Customer set
        return Database.getQueryLocator([
            SELECT Id, Customer__c
            FROM Price_Book__c
            WHERE Customer__c != null
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Price_Book__c> scope) {
        PriceBookTriggerHandler.sharePriceBooksWithPartners(scope);
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('PriceBookSharingBatch completed.');
    }
}