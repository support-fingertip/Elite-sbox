global class SystemEndDayScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        SystemEndDayBatch batch = new SystemEndDayBatch();
        Database.executeBatch(batch, 1); // Batch size is 1
    }
}