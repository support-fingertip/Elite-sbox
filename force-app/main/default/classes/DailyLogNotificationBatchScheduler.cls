global class DailyLogNotificationBatchScheduler implements Schedulable {
    global void execute(SchedulableContext SC) 
    {
        
        // create the batch class object
        DailyLogNotificationBatch revenueBatch = new DailyLogNotificationBatch();
        
        
        //invoke the batch class...
        Database.executeBatch(revenueBatch, 200);
    }
}