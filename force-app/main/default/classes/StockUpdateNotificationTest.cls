@isTest
private class StockUpdateNotificationTest {

    @isTest
    static void testGetCustomersWithoutStock() {
        // Step 1: Query Notification Type (must already exist in org)
        CustomNotificationType notifType = [
            SELECT Id FROM CustomNotificationType 
            WHERE DeveloperName = 'Stock_Update_Notification' 
            LIMIT 1
        ];

        // Step 2: Create a test user (Executive)
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User exec = new User(
            FirstName = 'Test',
            LastName = 'Executive',
            Email = 'exec@test.com',
            Username = 'exec' + System.currentTimeMillis() + '@test.com',
            Alias = 'exec',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = profile.Id,
            IsActive = true,
            Employee_Code__c = 'E123456'
        );
        insert exec;

        // Step 3: Create Primary Customers
        Account acc1 = new Account(Name = 'Customer 1', 
                                   Customer_Type__c = 'Primary Customer',
                                   OwnerId = exec.Id,
                                   Pincode__c = '123456',
                                   Primary_Phone_Number__c = '8546543210',
                                   State__c = 'Karnataka',
                                   District__c = 'Kolar'
                                  );
       

        Account acc2 = new Account(Name = 'Customer 2', Customer_Type__c = 'Primary Customer',
                                   OwnerId = exec.Id,
                                   Pincode__c = '123456',
                                   Primary_Phone_Number__c = '0746543210',
                                   State__c = 'Karnataka',
                                   District__c = 'Kolar');
        insert new List<Account>{ acc1, acc2 };

        // Step 4: Insert Product Mappings
        insert new List<Product_Mapping__c>{
            new Product_Mapping__c(Customer__c = acc1.Id, Exectuive__c = exec.Id),
            new Product_Mapping__c(Customer__c = acc2.Id, Exectuive__c = exec.Id)
        };

        // Step 5: Insert stock for only acc1 — acc2 will be considered pending
        insert new Dealer_Stock__c(Store__c = acc1.Id);

        // Step 6: Call method
        Test.startTest();
        StockUpdateNotification.getCustomersWithoutStock();
        Test.stopTest();
    }
}