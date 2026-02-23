global class PushToLogiSchedular implements Schedulable {
    
    global void execute(SchedulableContext sc) {
        PushToLogisticsBatch batchJob = new PushToLogisticsBatch();
        
        // Execute the batch with optional scope size (default is 200)
        Database.executeBatch(batchJob, 5); // You can adjust the batch size as needed
    }
    
}