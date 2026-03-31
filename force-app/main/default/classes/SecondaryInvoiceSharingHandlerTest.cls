@isTest
private class SecondaryInvoiceSharingHandlerTest {

    @TestSetup
    static void setupTestData() {
        Account distributor = new Account(
            Name = 'Test Distributor',
            Customer_Type__c = 'Secondary Customer',
            State__c = 'Bihar',
            District__c = 'Patna'
        );
        insert distributor;

        Account secondaryCustomer = new Account(
            Name = 'Test Secondary Customer',
            Customer_Type__c = 'Secondary Customer',
            State__c = 'Bihar',
            District__c = 'Patna'
        );
        insert secondaryCustomer;

        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'Partner',
            AccountId = distributor.Id
        );
        insert con;

        // Create Community User in separate context to avoid MIXED_DML_OPERATION
        User adminUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(adminUser) {
            Profile p = [SELECT Id FROM Profile WHERE Name = 'Partner Community User' LIMIT 1];
            String uniqueStr = String.valueOf(DateTime.now().getTime());
            User u = new User(
                FirstName = 'Test', LastName = 'CommunityPartner',
                Email = 'tcpsharing' + uniqueStr + '@test.com',
                Username = 'tcpsharing' + uniqueStr + '@test.com.sharing',
                Alias = 'tcpr', TimeZoneSidKey = 'Asia/Kolkata',
                LocaleSidKey = 'en_IN', EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US', ProfileId = p.Id, ContactId = con.Id,
                Employee_Code__c = 'EMPS' + uniqueStr
            );
            insert u;
        }
    }

    static User getCommunityUser() {
        return [SELECT Id FROM User WHERE Username LIKE 'tcpsharing%' AND IsActive = true LIMIT 1];
    }

    static Account getDistributor() {
        return [SELECT Id FROM Account WHERE Name = 'Test Distributor' LIMIT 1];
    }

    static Account getSecondaryCustomer() {
        return [SELECT Id FROM Account WHERE Name = 'Test Secondary Customer' LIMIT 1];
    }

    @isTest
    static void testHandleAfterInsert() {
        Account dist = getDistributor();
        Account secCust = getSecondaryCustomer();

        Test.startTest();
        Secondary_Invoice__c inv = new Secondary_Invoice__c(
            Store__c = dist.Id,
            Customer__c = secCust.Id,
            Invoice_Date__c = Date.today(),
            Status__c = 'Raised',
            Grand_Total__c = 500
        );
        insert inv;
        Test.stopTest();

        // Verify the handler ran without errors
        System.assertNotEquals(null, inv.Id);
    }

    @isTest
    static void testHandleAfterInsertNullStore() {
        Account secCust = getSecondaryCustomer();
        Test.startTest();
        Secondary_Invoice__c inv = new Secondary_Invoice__c(
            Customer__c = secCust.Id,
            Invoice_Date__c = Date.today(),
            Status__c = 'Raised',
            Grand_Total__c = 100
        );
        insert inv;
        Test.stopTest();

        System.assertNotEquals(null, inv.Id);
    }

    @isTest
    static void testHandleAfterUpdate() {
        Account dist = getDistributor();
        Account secCust = getSecondaryCustomer();

        Secondary_Invoice__c inv = new Secondary_Invoice__c(
            Store__c = dist.Id,
            Customer__c = secCust.Id,
            Invoice_Date__c = Date.today(),
            Status__c = 'Raised',
            Grand_Total__c = 500
        );
        insert inv;

        Test.startTest();
        // Change Store to trigger the update path (Customer__c is not writeable after insert)
        inv.Store__c = secCust.Id;
        update inv;
        Test.stopTest();

        Secondary_Invoice__c updated = [SELECT Store__c FROM Secondary_Invoice__c WHERE Id = :inv.Id];
        System.assertEquals(secCust.Id, updated.Store__c);
    }

    @isTest
    static void testHandleAfterUpdateNoChange() {
        Account dist = getDistributor();
        Account secCust = getSecondaryCustomer();

        Secondary_Invoice__c inv = new Secondary_Invoice__c(
            Store__c = dist.Id,
            Customer__c = secCust.Id,
            Invoice_Date__c = Date.today(),
            Status__c = 'Raised',
            Grand_Total__c = 500
        );
        insert inv;

        Test.startTest();
        // Update a field that doesn't trigger sharing recalculation
        inv.Grand_Total__c = 600;
        update inv;
        Test.stopTest();

        Secondary_Invoice__c updated = [SELECT Grand_Total__c FROM Secondary_Invoice__c WHERE Id = :inv.Id];
        System.assertEquals(600, updated.Grand_Total__c);
    }

    @isTest
    static void testShareCustomerAccountsDirectCall() {
        Account dist = getDistributor();
        Account secCust = getSecondaryCustomer();

        Secondary_Invoice__c inv = new Secondary_Invoice__c(
            Store__c = dist.Id,
            Customer__c = secCust.Id,
            Invoice_Date__c = Date.today(),
            Status__c = 'Raised',
            Grand_Total__c = 500
        );
        insert inv;

        Test.startTest();
        SecondaryInvoiceSharingHandler.shareCustomerAccountsWithDistributorUsers(
            new List<Secondary_Invoice__c>{ inv }
        );
        Test.stopTest();
    }

    @isTest
    static void testShareCustomerAccountsEmptyList() {
        Test.startTest();
        SecondaryInvoiceSharingHandler.shareCustomerAccountsWithDistributorUsers(
            new List<Secondary_Invoice__c>()
        );
        Test.stopTest();
    }

    @isTest
    static void testShareCustomerAccountsNullFields() {
        // Call directly with an in-memory record (no Store__c set) to hit the null check path
        Account secCust = getSecondaryCustomer();
        Secondary_Invoice__c inv = new Secondary_Invoice__c(
            Customer__c = secCust.Id,
            Invoice_Date__c = Date.today(),
            Status__c = 'Raised',
            Grand_Total__c = 100
        );
        insert inv;

        Test.startTest();
        SecondaryInvoiceSharingHandler.shareCustomerAccountsWithDistributorUsers(
            new List<Secondary_Invoice__c>{ inv }
        );
        Test.stopTest();
    }

    @isTest
    static void testHandleAfterUpdateStoreChange() {
        Account dist = getDistributor();
        Account secCust = getSecondaryCustomer();

        Secondary_Invoice__c inv = new Secondary_Invoice__c(
            Store__c = dist.Id,
            Customer__c = secCust.Id,
            Invoice_Date__c = Date.today(),
            Status__c = 'Raised',
            Grand_Total__c = 500
        );
        insert inv;

        Test.startTest();
        // Use the secondary customer as the new store to trigger store change path
        inv.Store__c = secCust.Id;
        update inv;
        Test.stopTest();

        Secondary_Invoice__c updated = [SELECT Store__c FROM Secondary_Invoice__c WHERE Id = :inv.Id];
        System.assertEquals(secCust.Id, updated.Store__c);
    }

    // ========== Batch Test ==========

    @isTest
    static void testSecondaryInvoiceSharingBatch() {
        Account dist = getDistributor();
        Account secCust = getSecondaryCustomer();

        Secondary_Invoice__c inv = new Secondary_Invoice__c(
            Store__c = dist.Id,
            Customer__c = secCust.Id,
            Invoice_Date__c = Date.today(),
            Status__c = 'Raised',
            Grand_Total__c = 500
        );
        insert inv;

        Test.startTest();
        Database.executeBatch(new SecondaryInvoiceSharingBatch(), 200);
        Test.stopTest();
    }

    @isTest
    static void testMultipleInvoicesInsert() {
        Account dist = getDistributor();
        Account secCust = getSecondaryCustomer();

        List<Secondary_Invoice__c> invoices = new List<Secondary_Invoice__c>();
        for (Integer i = 0; i < 5; i++) {
            invoices.add(new Secondary_Invoice__c(
                Store__c = dist.Id,
                Customer__c = secCust.Id,
                Invoice_Date__c = Date.today(),
                Status__c = 'Raised',
                Grand_Total__c = 100 * (i + 1)
            ));
        }

        Test.startTest();
        insert invoices;
        Test.stopTest();

        System.assertEquals(5, [SELECT COUNT() FROM Secondary_Invoice__c WHERE Store__c = :dist.Id AND Customer__c = :secCust.Id]);
    }

    // ========== Community User Tests for full sharing logic ==========

    @isTest
    static void testSharingWithCommunityUser() {
        User communityUser = getCommunityUser();
        Account dist = getDistributor();
        Account secCust = getSecondaryCustomer();

        // Insert invoice - the trigger will call the handler which should now find the community user
        Test.startTest();
        Secondary_Invoice__c inv = new Secondary_Invoice__c(
            Store__c = dist.Id,
            Customer__c = secCust.Id,
            Invoice_Date__c = Date.today(),
            Status__c = 'Raised',
            Grand_Total__c = 1000
        );
        insert inv;
        Test.stopTest();

        System.assertNotEquals(null, inv.Id);
    }

    @isTest
    static void testSharingDirectCallWithCommunityUser() {
        User communityUser = getCommunityUser();
        Account dist = getDistributor();
        Account secCust = getSecondaryCustomer();

        Secondary_Invoice__c inv = new Secondary_Invoice__c(
            Store__c = dist.Id,
            Customer__c = secCust.Id,
            Invoice_Date__c = Date.today(),
            Status__c = 'Raised',
            Grand_Total__c = 500
        );
        insert inv;

        Test.startTest();
        // Call directly again to test duplicate share prevention
        SecondaryInvoiceSharingHandler.shareCustomerAccountsWithDistributorUsers(
            new List<Secondary_Invoice__c>{ inv }
        );
        Test.stopTest();
    }

    @isTest
    static void testBatchWithCommunityUser() {
        User communityUser = getCommunityUser();
        Account dist = getDistributor();
        Account secCust = getSecondaryCustomer();

        Secondary_Invoice__c inv = new Secondary_Invoice__c(
            Store__c = dist.Id,
            Customer__c = secCust.Id,
            Invoice_Date__c = Date.today(),
            Status__c = 'Raised',
            Grand_Total__c = 500
        );
        insert inv;

        Test.startTest();
        Database.executeBatch(new SecondaryInvoiceSharingBatch(), 200);
        Test.stopTest();
    }
}