public class PushOrderToSAQueueable implements Queueable, Database.AllowsCallouts {

    private Id orderId;

    public PushOrderToSAQueueable(Id orderId) {
        this.orderId = orderId;
    }

    public void execute(QueueableContext qc) {
        PostHandler.sendOrder(orderId);
        
    }
}