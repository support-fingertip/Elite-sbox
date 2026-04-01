public class SecondaryCreditNoteSharingBatch implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Distributor__c, Customer__c
            FROM Secondary_Credit_Note__c
            WHERE Distributor__c != null AND Customer__c != null
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Secondary_Credit_Note__c> scope) {
        SecondaryCreditNoteSharingHandler.shareCustomerAccountsWithDistributorUsers(scope);
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('SecondaryCreditNoteSharingBatch completed.');
    }
}