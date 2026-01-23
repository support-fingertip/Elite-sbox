global class EODReportBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id 
            FROM Daily_Log__c 
            WHERE Is_System_Ended__c = true and CreatedDate = today
            
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Daily_Log__c> scope) {
        for (Daily_Log__c dl : scope) {
            System.enqueueJob(new EODReportQueueableMail(dl.Id));
        }
    }

    global void finish(Database.BatchableContext bc) {
        // Optional: Send summary mail or log results
    }
}