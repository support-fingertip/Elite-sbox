public class PushToLogisticsBatch
    implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, Name, Status__c, Push_to_Logistics__c ' +
            'FROM Order__c ' +
            'WHERE Order_Type__c = \'Primary Order\' ' +
            'AND Push_to_Logistics__c = null'
        );
    }

    public void execute(Database.BatchableContext bc, List<Order__c> scope) {

        for (Order__c ord : scope) {
            // Enqueue ONE order per Queueable
          //  System.enqueueJob(new PushOrderToSAQueueable(ord.Id));
	PostHandler.orderPost(ord);
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('PushToLogistics batch completed');
    }
}