global class EODReportBatchScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        // Call your main logic class
        EODReportBatch bt = new EODReportBatch();
        database.executeBatch(bt,1);
    }
}