@isTest
public class RejectOrderTest {
    
    @testSetup
    static void setupData() {
        // Create a sample Order__c record
        Order__c ord = new Order__c(
            Status__c = 'New'
        );
        insert ord;
    }

    @isTest
    static void testRejectOrder_Success() {
        // Get the order created in @testSetup
        Order__c ord = [SELECT Id, Status__c FROM Order__c LIMIT 1];
        
        // Call method
        String result = RejectOrder.rejectOrder(ord.Id);
        

    }
    
    @isTest
    static void testRejectOrder_AlreadyRejected() {
        // Create an already rejected order
        Order__c ord = new Order__c(
            Status__c = 'Rejected'
        );
        insert ord;
        
        // Call method
        String result = RejectOrder.rejectOrder(ord.Id);
        
        // Assert proper error
        System.assertEquals('Error: REJECTION_COMPLETED', result);
    }
    

}