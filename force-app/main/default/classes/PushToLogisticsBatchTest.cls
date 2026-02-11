@isTest
public class PushToLogisticsBatchTest {
    
    @testSetup
    static void setupTestData() {
        // Create test Order__c records with different statuses
        List<Order__c> testOrders = new List<Order__c>();
        
        // Orders with Status__c = 'New' (should be updated to 'Push to Logistics')
        for (Integer i = 0; i < 5; i++) {
            Order__c order = new Order__c(
                Push_to_Logistics__c = null,
                Status__c = 'New',
                Order_Type__c = 'Primary Order'
            );
            testOrders.add(order);
        }
        
        // Orders with other statuses (Status__c should remain unchanged)
        for (Integer i = 5; i < 10; i++) {
            Order__c order = new Order__c(
                Push_to_Logistics__c = null,
                Status__c = 'New',
                 Order_Type__c = 'Primary Order'
            );
            testOrders.add(order);
        }
        
        insert testOrders;
    }
    
    @isTest
    static void testBatchStartMethod() {
        // Verify initial data setup
        List<Order__c> ordersBefore = [SELECT Id, Push_to_Logistics__c, Status__c FROM Order__c WHERE Push_to_Logistics__c = null];
        
        Test.startTest();
        PushToLogisticsBatch batch = new PushToLogisticsBatch();
		database.executeBatch(batch,100);    
       
        Test.stopTest();
        
    }
    
   
}