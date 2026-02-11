public class PushToLogisticsBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    public Integer successCount = 0;
    public Integer errorCount = 0;
    public List<String> errorMessages = new List<String>();
    
    // Parameterless constructor required for scheduling
    public PushToLogisticsBatch() {
        // Constructor can be empty or initialize variables
    }
    
    // Start method to query orders where Push_to_Logistics__c is null
    public Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, Name, Push_to_Logistics__c, Status__c, Delivery_Plant__c ' +
               'FROM Order__c ' +
               'WHERE Order_Type__c = \'Primary Order\' and Push_to_Logistics__c = null';
        return Database.getQueryLocator(query);
    }
    
    // Execute method to process each batch of records
    public void execute(Database.BatchableContext BC, List<Order__c> scope) {
        List<Order__c> ordersToUpdate = new List<Order__c>();
        List<Database.SaveResult> saveResults = new List<Database.SaveResult>();
        
        // Update Push_to_Logistics__c to 'Yes' for each order
        for (Order__c order : scope) {
            order.Push_to_Logistics__c = 'Yes';
            if(order.Status__c == 'New'){
                order.Status__c = 'Push to Logistics';
                order.Pushed_by_System__c = true;
            }
            ordersToUpdate.add(order);
        }
        
        // Update the records and handle errors
        if (!ordersToUpdate.isEmpty()) {
            saveResults = Database.update(ordersToUpdate, false);
            
            // Process the save results
            for (Integer i = 0; i < saveResults.size(); i++) {
                Database.SaveResult sr = saveResults[i];
                if (!sr.isSuccess()) {
                    errorCount++;
                    String errorMsg = 'Order: ' + ordersToUpdate[i].Name + ' - ';
                    for (Database.Error err : sr.getErrors()) {
                        errorMsg += err.getMessage() + ' ';
                    }
                    errorMessages.add(errorMsg);
                } else {
                    successCount++;
                }
            }
        }
    }
    
    // Finish method to send notification or log results
    public void finish(Database.BatchableContext BC) {
        // You can add email notifications or logging here
        System.debug('Batch completed: ' + successCount + ' successes, ' + errorCount + ' errors');
        
        if (!errorMessages.isEmpty()) {
            System.debug('Error messages: ' + errorMessages);
        }
    }
}