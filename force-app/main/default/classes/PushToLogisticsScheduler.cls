// Separate schedulable class
public class PushToLogisticsScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        PushToLogisticsBatch batch = new PushToLogisticsBatch();
        Database.executeBatch(batch);
    }
}