public class SecondaryCustomerTransferBatchProcessor implements Queueable, Database.AllowsCallouts {
    private Map<Id, Id> distributorTransferredToMap;

    public SecondaryCustomerTransferBatchProcessor(Map<Id, Id> distributorTransferredToMap) {
        this.distributorTransferredToMap = distributorTransferredToMap;
    }

    public void execute(QueueableContext context) {
        // List to collect all updated secondary customers
        List<Account> customersToUpdate = new List<Account>();

        // Query secondary customers related to the original distributors
        List<Account> relatedSecondaryCustomers = [
            SELECT Id, Distributor__c 
            FROM Account 
            WHERE Customer_Type__c ='Secondary Customer' and Distributor__c IN :distributorTransferredToMap.keySet()
        ];
        system.debug('relatedSecondaryCustomers'+relatedSecondaryCustomers);

        for (Account customer : relatedSecondaryCustomers) {
            Id newDistributorId = distributorTransferredToMap.get(customer.Distributor__c);
            if (newDistributorId != null && customer.Distributor__c != newDistributorId) {
                customer.Distributor__c = newDistributorId;
                customersToUpdate.add(customer);
            }
        }

        // Single DML update outside the loop
        if (!customersToUpdate.isEmpty()) {
              system.debug('customersToUpdate'+customersToUpdate);
            update customersToUpdate;
        }
    }
}