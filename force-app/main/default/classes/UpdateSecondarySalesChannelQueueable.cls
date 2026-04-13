public class UpdateSecondarySalesChannelQueueable implements Queueable {
    private Map<Id, Set<Id>> primaryToSecondaryCustomerIds;

    public UpdateSecondarySalesChannelQueueable(Map<Id, Set<Id>> primaryToSecondaryCustomerIds) {
        this.primaryToSecondaryCustomerIds = primaryToSecondaryCustomerIds;
    }

    public void execute(QueueableContext context) {
        try {
            if (primaryToSecondaryCustomerIds != null && !primaryToSecondaryCustomerIds.isEmpty()) {
                ProductMappingTriggerHandler.updateSecondarySalesChannelFromPrimary(primaryToSecondaryCustomerIds);
            }
        } catch (Exception ex) {
            System.debug('UpdateSecondarySalesChannelQueueable error: ' + ex.getMessage());
        }
    }
}
