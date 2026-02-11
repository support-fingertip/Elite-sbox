@isTest
public class UpdateLastOrderBatchTest {
    
    @isTest
    public static void testUpdateLastOrderBatch() {
        Test.startTest();
        // Create a Product (if required by Order Item)
        Product__c prod = new Product__c(Name='Test Product');
        insert prod;
        
        // Create Account without Last_Order__c
        Account acc = new Account(
            Name = 'Primary Customer',
            Customer_Type__c = 'Secondary Customer',
            Pincode__c = '123456',
            Primary_Phone_Number__c = '9876543210',
            State__c = 'Karnataka',
 
            District__c = 'Kolar'
        );
        insert acc;
        
        
             
        // Create Account without Last_Order__c
        Account acc2 = new Account(
            Name = 'Primary Customer',
            Customer_Type__c = 'Secondary Customer',
            Pincode__c = '123451',
            Primary_Phone_Number__c = '9872543210',
            State__c = 'Karnataka',
 
            District__c = 'Kolar'
        );
        insert acc2;
        
        // Create first Order
        Order__c order1 = new Order__c(
            Order_Type__c = 'Secondary Order',
            Account__c = acc.Id,
            Order_Fulfillment_Status__c = 'Not Fulfilled',
            Order_Date__c = Date.today().addDays(-5)
        );
        insert order1;

        // Order Items for order1
        List<Order_Item__c> items1 = new List<Order_Item__c>();
        for (Integer i = 0; i < 2; i++) {
            items1.add(new Order_Item__c(
                Order__c = order1.Id,
                Product__c = prod.Id,
                Quantity__c = 10,
                Delivered_Quantity__c = 0,
                Unit_Price__c = 100,
                Total_Amount__c = 1000,
                Tax_Amount__c = 100,
                Status__c = 'Not Fulfilled'
            ));
        }
        insert items1;
        
        // Create second Order (latest)
        Order__c order2 = new Order__c(
            Order_Type__c = 'Secondary Order',
            Account__c = acc.Id,
            Order_Fulfillment_Status__c = 'Not Fulfilled',
            Order_Date__c = Date.today()
        );
        insert order2;

        // Order Items for order2
        List<Order_Item__c> items2 = new List<Order_Item__c>();
        for (Integer i = 0; i < 2; i++) {
            items2.add(new Order_Item__c(
                Order__c = order2.Id,
                Product__c = prod.Id,
                Quantity__c = 20,
                Delivered_Quantity__c = 0,
                Unit_Price__c = 200,
                Total_Amount__c = 2000,
                Tax_Amount__c = 200,
                Status__c = 'Not Fulfilled'
            ));
        }
        insert items2;
        acc.Last_Order__c =null;
        update acc;
        
     

        // Run the batch
        Database.executeBatch(new UpdateLastOrderBatch(), 100);
        Test.stopTest();
        
      
    }
}