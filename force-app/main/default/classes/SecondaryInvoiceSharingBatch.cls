public class SecondaryInvoiceSharingBatch implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Store__c, Customer__c
            FROM Secondary_Invoice__c
            WHERE Store__c != null AND Customer__c != null
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Secondary_Invoice__c> scope) {
        SecondaryInvoiceSharingHandler.shareCustomerAccountsWithDistributorUsers(scope);
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('SecondaryInvoiceSharingBatch completed.');
    }
}