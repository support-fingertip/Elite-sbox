public class DistanceCalculationQueueable implements Queueable, Database.AllowsCallouts {

    private Id dailyLogId;

    public DistanceCalculationQueueable(Id dailyLogId) {
        this.dailyLogId = dailyLogId;
    }

    public void execute(QueueableContext context) {
        DistanceMatrixControllerForVisit.distanceCalculationForDailyRoute(dailyLogId);
    }
}