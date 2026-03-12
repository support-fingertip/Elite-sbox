global class SystemEndDayBatch implements Database.Batchable<SObject> {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, OwnerId, Day_ended_time__c 
            FROM Daily_Log__c 
            WHERE CreatedDate = TODAY
              AND Clock_In_Location__Latitude__s != null 
              AND Clock_In_Location__Latitude__s != 0 
              AND Day_ended_time__c = null
        ]);
    }
    
    global void execute(Database.BatchableContext bc, List<Daily_Log__c> scope) {
        if (scope.isEmpty()) return;
        
        Datetime currentTime = Datetime.now();
        Daily_Log__c dl = scope[0]; // Since batch size is 1
        
        dl.Day_ended_time__c = currentTime;
        dl.Is_System_Ended__c = true;
        update dl; // Update the Daily Log record
        
        // Call Queueable instead of Future
        System.enqueueJob(new DistanceCalculationQueueable(dl.Id));
    }
    
    global void finish(Database.BatchableContext bc) {
        // Optional: implement post-processing notification logic if needed
    }
}