@isTest
public class UpdateCustomerChannelsAndPlantsBatchTest {

    @isTest
    static void testBatchExecution() {
        // Step 1: Create a test Account (Customer)
        Account acc = new Account(
            Name = 'Test Primary Customer',
            Customer_Type__c = 'Primary Customer',
            Pincode__c = '123456',
            Primary_Phone_Number__c = '9876543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert acc;
        


        // Step 2: Create Product_Mapping__c records with Chanel__c and Child_Depot__c
        List<Product_Mapping__c> pmList = new List<Product_Mapping__c>();
        
        Product_Mapping__c pm = new   Product_Mapping__c();
        pm.Customer__c = acc.Id;
        pm.Payment_Term__c = '0003';
        pm.Primary_Customer__c = acc.Id;
        pm.Chanel__c = 'TN';
        insert pm;

        // Step 3: Run the batch
        Test.startTest();
        //Database.executeBatch(new UpdateCustomerChannelsAndPlantsBatch(), 200);
        SecondaryCustomerMappingBatch batch = new SecondaryCustomerMappingBatch();
        Database.executeBatch(batch, 100);
        Test.stopTest();

    }
}