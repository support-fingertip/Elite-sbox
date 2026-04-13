public class UpdateSalesChannelAndDepotQueueable implements Queueable {
    private Set<Id> primaryCustomerIds;

    public UpdateSalesChannelAndDepotQueueable(Set<Id> primaryCustomerIds) {
        this.primaryCustomerIds = primaryCustomerIds;
    }

    public void execute(QueueableContext context) {
        try {
            if (primaryCustomerIds != null && !primaryCustomerIds.isEmpty()) {
                ProductMappingTriggerHandler.updateSaleschannelandParentDeport(primaryCustomerIds);
            }
        } catch (Exception ex) {
            System.debug('UpdateSalesChannelAndDepotQueueable error: ' + ex.getMessage());
        }
    }
}