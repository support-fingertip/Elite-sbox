public class UpdateLastOrderBatch implements Database.Batchable<SObject> {
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id 
            FROM Account 
            WHERE Id IN (
                SELECT Account__c 
                FROM Order__c 
                WHERE Order_Type__c = 'Secondary Order'
                AND Account__c != null
            )
            AND Last_Order__c = null
        ]);
    }


    
    public void execute(Database.BatchableContext bc, List<Account> accounts) {
        Map<Id, Id> accToLatestOrder = new Map<Id, Id>();

        // Query latest orders for these accounts
        List<Order__c> latestOrders = [  SELECT Id, Account__c, CreatedDate  FROM Order__c  WHERE Account__c IN :accounts  ORDER BY Account__c, CreatedDate DESC
        ];
        
        for (Order__c ord : latestOrders) {
            if (!accToLatestOrder.containsKey(ord.Account__c)) { accToLatestOrder.put(ord.Account__c, ord.Id); }
        }

        // Prepare updates
        List<Account> accountsToUpdate = new List<Account>();
        for (Account acc : accounts) {
            if (accToLatestOrder.containsKey(acc.Id)) {
                acc.Last_Order__c = accToLatestOrder.get(acc.Id);
                accountsToUpdate.add(acc);
            }
        }

        if (!accountsToUpdate.isEmpty()) {update accountsToUpdate; }
    }
    
    public void finish(Database.BatchableContext bc) { System.debug('Batch completed. Last Orders updated.');}
}