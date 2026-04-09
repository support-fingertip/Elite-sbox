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

    @isTest
    static void testHandleValidationsIntraBatchDuplicate() {
        // Covers the intra-batch duplicate detection branch of handleValidations
        Calendar_beat__c pjp = new Calendar_beat__c(
            OwnerId = UserInfo.getUserId(),
            User__c = UserInfo.getUserId()
        );
        insert pjp;

        // Two items in the same batch with same PJP and Date
        List<PJP_Item__c> items = new List<PJP_Item__c>{
            new PJP_Item__c(PJP__c = pjp.Id, Date__c = Date.today(), Status__c = 'Submitted'),
            new PJP_Item__c(PJP__c = pjp.Id, Date__c = Date.today(), Status__c = 'Submitted')
        };

        Test.startTest();
        try {
            insert items;
            System.assert(false, 'Expected an error for intra-batch duplicate PJP items');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Duplicate PJP Item'),
                'Expected intra-batch duplicate error, got: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testHandleValidationsBeatUserMismatch() {
        // Covers the "Beat is not assigned to the same user as the PJP" branch
        Id adminUserId = UserInfo.getUserId();
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User otherUser = new User(
            FirstName = 'Beat',
            LastName = 'Owner',
            Email = 'beatowner@example.com',
            Username = 'beatowner' + System.currentTimeMillis() + '@example.com',
            Alias = 'bowns',
            ProfileId = p.Id,
            Employee_Code__c = 'BOWNEREMP001',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert otherUser;

        // Use runAs to avoid Mixed DML after the User insert above
        Calendar_beat__c pjp;
        Child_beat__c beat;
        System.runAs(otherUser) {
            pjp = new Calendar_beat__c(
                OwnerId = adminUserId,
                User__c = adminUserId
            );
            insert pjp;

            beat = new Child_beat__c(
                Name = 'Other User Beat',
                OwnerId = otherUser.Id,
                Beat_Type__c = 'Primary',
                Active__c = true
            );
            insert beat;
        }

        PJP_Item__c pjpItem = new PJP_Item__c(
            PJP__c = pjp.Id,
            Beat__c = beat.Id,
            Date__c = Date.today().addDays(5),
            Status__c = 'Submitted'
        );

        Test.startTest();
        try {
            insert pjpItem;
            System.assert(false, 'Expected an error for beat/user mismatch');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Beat is not assigned to the same user'),
                'Expected beat/user mismatch error, got: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testAutoApprovePJPForAdminOrManager() {
        // Covers autoApprovePJPForAdminOrManager - admin path approves items
        // for PJPs owned by other users.
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User pjpUser = new User(
            FirstName = 'PJP',
            LastName = 'Owner',
            Email = 'pjpowner@example.com',
            Username = 'pjpowner' + System.currentTimeMillis() + '@example.com',
            Alias = 'pown',
            ProfileId = p.Id,
            Employee_Code__c = 'PJPOWNEREMP001',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert pjpUser;

        // Wrap non-setup DML in runAs to avoid Mixed DML after User insert
        PJP_Item__c item;
        System.runAs(pjpUser) {
            Calendar_beat__c pjp = new Calendar_beat__c(
                OwnerId = pjpUser.Id,
                User__c = pjpUser.Id
            );
            insert pjp;

            Child_beat__c beat = new Child_beat__c(
                Name = 'Auto Approve Beat',
                OwnerId = pjpUser.Id,
                Beat_Type__c = 'Primary',
                Active__c = true
            );
            insert beat;

            item = new PJP_Item__c(
                PJP__c = pjp.Id,
                Beat__c = beat.Id,
                Assigned_Beat__c = beat.Id,
                Date__c = Date.today().addDays(10),
                Status__c = 'Submitted'
            );
            insert item;
        }

        // Reload to get the formula OwnerId__c populated
        PJP_Item__c reloaded = [
            SELECT Id, OwnerId__c, Status__c, Beat__c, Assigned_Beat__c
            FROM PJP_Item__c
            WHERE Id = :item.Id
        ];

        Test.startTest();
        // Running as the default test user (System Administrator) - should auto approve
        PJPItemHandler.autoApprovePJPForAdminOrManager(new List<PJP_Item__c>{ reloaded });
        Test.stopTest();

        System.assertEquals('Approved', reloaded.Status__c,
            'Admin should auto-approve PJP items owned by other users');
    }

    @isTest
    static void testAutoApprovePJPForAdminOrManager_SelfOwned() {
        // Covers the branch where item.OwnerId__c == currentUserId - should NOT be approved
        Calendar_beat__c pjp = new Calendar_beat__c(
            OwnerId = UserInfo.getUserId(),
            User__c = UserInfo.getUserId()
        );
        insert pjp;

        PJP_Item__c item = new PJP_Item__c(
            PJP__c = pjp.Id,
            Date__c = Date.today().addDays(20),
            Status__c = 'Submitted'
        );
        insert item;

        PJP_Item__c reloaded = [
            SELECT Id, OwnerId__c, Status__c
            FROM PJP_Item__c
            WHERE Id = :item.Id
        ];

        Test.startTest();
        PJPItemHandler.autoApprovePJPForAdminOrManager(new List<PJP_Item__c>{ reloaded });
        Test.stopTest();

        // Status should remain unchanged when owner is the current user
        System.assertEquals('Submitted', reloaded.Status__c,
            'Items owned by current user should not be auto-approved');
    }

    @isTest
    static void testUpdatePjpItemsAfterApproval_NoItems() {
        // Covers early-return path when there are no matching items to update
        Calendar_beat__c pjp = new Calendar_beat__c(
            OwnerId = UserInfo.getUserId(),
            User__c = UserInfo.getUserId()
        );
        insert pjp;

        Test.startTest();
        PJPItemHandler.updatePjpItemsAfterApproval(pjp.Id);
        Test.stopTest();
    }
}