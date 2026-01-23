@isTest
private class PJPItemHandlerTest {

    @isTest
    static void testUpdatePjpItemsAfterApproval() {
        // Step 1: Create a user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'pjptestuser@example.com',
            Username = 'pjptestuser' + System.currentTimeMillis() + '@example.com',
            Alias = 'pjptu',
            ProfileId = p.Id,
            Employee_Code__c = 'EMP002111121166',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;

              
        Calendar_beat__c pjp = new Calendar_beat__c(
            OwnerId = testUser.Id,
            User__c = testUser.Id
        );
        insert pjp;
        // Step 3: Create PJP Items with various statuses
        List<PJP_Item__c> items = new List<PJP_Item__c>{
            new PJP_Item__c( PJP__c = pjp.Id,Date__c=Date.today(), Status__c = 'Submitted'),
            new PJP_Item__c( PJP__c = pjp.Id,Date__c=Date.today().addDays(1), Status__c = 'Not Submitted'),
            new PJP_Item__c(PJP__c = pjp.Id,Date__c=Date.today().addDays(2), Status__c = 'Approved'), // Should be skipped
            new PJP_Item__c(PJP__c = pjp.Id,Date__c=Date.today().addDays(3), Status__c = 'Rejected')  // Should be skipped
        };
        insert items;

        // Step 4: Call the method to test
        Test.startTest();
        PJPItemHandler.updatePjpItemsAfterApproval(pjp.Id);
        Test.stopTest();

        // Done - no assertions as per request
    }
     @isTest
    static void testDeactivateBeats() {
          // Step 1: Create a user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'pjptestuser@example.com',
            Username = 'pjptestuser' + System.currentTimeMillis() + '@example.com',
            Alias = 'pjptu',
            ProfileId = p.Id,
            Employee_Code__c = 'EMP002HSHER111121166',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        // Step 1: Create sample accounts
        Account acc1 = new Account(
            Customer_Type__c = 'Secondary Customer',
            Name = 'Primary Customer',
            OwnerId = testUser.Id,
            Pincode__c = '123456',
            Primary_Phone_Number__c = '6646543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        Account acc2 = new Account(
            Customer_Type__c = 'Secondary Customer',
            Name = 'Primary Customer',
            OwnerId = testUser.Id,
            Pincode__c = '123456',
            Primary_Phone_Number__c = '7746543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert new List<Account>{ acc1, acc2 };

        // Step 2: Create Child Beats with Active__c = true
        List<Child_beat__c> beats = new List<Child_beat__c>{
            new Child_beat__c(Name = 'Beat A', Primary_Customer__c = acc1.Id, Active__c = true),
            new Child_beat__c(Name = 'Beat B', Sub_Stockist__c = acc2.Id, Active__c = true)
        };
        insert beats;

        // Step 3: Create Junction Beats
        List<Junction_Beat__c> junctions = new List<Junction_Beat__c>{
            new Junction_Beat__c( Account__c = acc1.Id,Child_beat__c =beats[0].Id,Active__c = true),
            new Junction_Beat__c( Account__c = acc2.Id, Child_beat__c =beats[0].Id,Active__c = true)
        };
        insert junctions;

        // Step 4: Call method
        Set<Id> accIds = new Set<Id>{ acc1.Id, acc2.Id };
        Test.startTest();
        PJPItemHandler.deactivateBeats(accIds);
        Test.stopTest();

        // No assertions needed per your instruction
    }
     @isTest
    static void testHandleValidations() {
        // Prepare test data
        Account acc = new Account(
            Customer_Type__c = 'Secondary Customer',
            Name = 'Primary Customer',
            OwnerId = UserInfo.getUserId(),
            Pincode__c = '123456',
            Primary_Phone_Number__c = '6646543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert acc;

         Calendar_beat__c pjp = new Calendar_beat__c(
            OwnerId = UserInfo.getUserId(),
            User__c = UserInfo.getUserId()
        );
        insert pjp;
      
        PJP_Item__c pjpItem1 = new PJP_Item__c(PJP__c = pjp.Id, Beat__c = null, Date__c = Date.today(), Status__c = 'Approved');
         insert pjpItem1;
        PJP_Item__c pjpItem2 = new PJP_Item__c(PJP__c = pjp.Id, Beat__c = null, Date__c = Date.today(), Status__c = 'Approved');
           Test.startTest();
        try {
            insert pjpItem2;
            // If we reach here, the validation did not fire as expected
            System.assert(false, 'Expected a FIELD_CUSTOM_VALIDATION_EXCEPTION due to duplicate PJP Item.');
        } catch (DmlException e) {
            // Verify if the expected error message is in the exception
            System.assert(e.getMessage().contains('A PJP Item for this PJP and Date already exists. Please update the existing item instead of creating a new one.'), 'Expected validation error not found.');
        }
        
        Test.stopTest();
    }
}