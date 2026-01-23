global class StockUpdateScheduler implements Schedulable {
    
    global void execute(SchedulableContext sc) {
        // Call your main logic class
        StockUpdateNotification.getCustomersWithoutStock();
    }

}