public class UpdateCustomerChannelsAndPlantsBatch implements Database.Batchable<SObject>, Database.Stateful {

    // Persist across batch scopes
    private Map<Id, Set<String>> customerToChannels = new Map<Id, Set<String>>();
    private Map<Id, Set<String>> customerToPlants = new Map<Id, Set<String>>();

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Customer__c, Chanel__c, Child_Depot__c
            FROM Product_Mapping__c
            WHERE Customer_Type__c = 'Primary Customer'
                AND Customer__c != null
                AND (Chanel__c != null OR Child_Depot__c != null)
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Product_Mapping__c> scope) {
        for (Product_Mapping__c pm : scope) {
            Id custId = pm.Customer__c;

            if (pm.Chanel__c != null) {
                if (!customerToChannels.containsKey(custId)) {
                    customerToChannels.put(custId, new Set<String>());
                }
                customerToChannels.get(custId).add(pm.Chanel__c);
            }

            if (pm.Child_Depot__c != null) {
                if (!customerToPlants.containsKey(custId)) {
                    customerToPlants.put(custId, new Set<String>());
                }
                customerToPlants.get(custId).add(pm.Child_Depot__c);
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        List<Account> accountsToUpdate = new List<Account>();
        Set<Id> allCustomerIds = new Set<Id>();
        allCustomerIds.addAll(customerToChannels.keySet());
        allCustomerIds.addAll(customerToPlants.keySet());

        for (Id custId : allCustomerIds) {
            String channels = customerToChannels.containsKey(custId)
                ? String.join(new List<String>(customerToChannels.get(custId)), ',') + ','
                : null;

            String plants = customerToPlants.containsKey(custId)
                ? String.join(new List<String>(customerToPlants.get(custId)), ',') + ','
                : null;

            Account acc = new Account(Id = custId);
            if (channels != null) acc.Sales_Channel__c = channels;
            if (plants != null) acc.Delivery_Plant__c = plants;
            accountsToUpdate.add(acc);
        }

        if (!accountsToUpdate.isEmpty()) {
            Database.update(accountsToUpdate, false);
        }

        System.debug('Batch execution finished. Updated ' + accountsToUpdate.size() + ' accounts.');
    }
}