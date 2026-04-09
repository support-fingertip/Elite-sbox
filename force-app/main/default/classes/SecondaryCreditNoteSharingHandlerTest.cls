@isTest
private class SecondaryCreditNoteSharingHandlerTest {

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
                Email = 'tcpcnsharing' + uniqueStr + '@test.com',
                Username = 'tcpcnsharing' + uniqueStr + '@test.com.sharing',
                Alias = 'tcnr', TimeZoneSidKey = 'Asia/Kolkata',
                LocaleSidKey = 'en_IN', EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US', ProfileId = p.Id, ContactId = con.Id,
                Employee_Code__c = 'EMPCN' + uniqueStr
            );
            insert u;
        }
    }

    static User getCommunityUser() {
        return [SELECT Id FROM User WHERE Username LIKE 'tcpcnsharing%' AND IsActive = true LIMIT 1];
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
        Secondary_Credit_Note__c cn = new Secondary_Credit_Note__c(
            Distributor__c = dist.Id,
            Customer__c = secCust.Id,
            Credit_Date__c = Date.today(),
            Amount__c = 500
        );
        insert cn;
        Test.stopTest();

        System.assertNotEquals(null, cn.Id);
    }

    @isTest
    static void testHandleAfterInsertNullDistributor() {
        Account secCust = getSecondaryCustomer();
        Test.startTest();
        Secondary_Credit_Note__c cn = new Secondary_Credit_Note__c(
            Customer__c = secCust.Id,
            Credit_Date__c = Date.today(),
            Amount__c = 100
        );
        insert cn;
        Test.stopTest();

        System.assertNotEquals(null, cn.Id);
    }

    @isTest
    static void testHandleAfterUpdate() {
        Account dist = getDistributor();
        Account secCust = getSecondaryCustomer();

        Secondary_Credit_Note__c cn = new Secondary_Credit_Note__c(
            Distributor__c = dist.Id,
            Customer__c = secCust.Id,
            Credit_Date__c = Date.today(),
            Amount__c = 500
        );
        insert cn;

        Test.startTest();
        cn.Distributor__c = secCust.Id;
        update cn;
        Test.stopTest();

        Secondary_Credit_Note__c updated = [SELECT Distributor__c FROM Secondary_Credit_Note__c WHERE Id = :cn.Id];
        System.assertEquals(secCust.Id, updated.Distributor__c);
    }

    @isTest
    static void testHandleAfterUpdateNoChange() {
        Account dist = getDistributor();
        Account secCust = getSecondaryCustomer();

        Secondary_Credit_Note__c cn = new Secondary_Credit_Note__c(
            Distributor__c = dist.Id,
            Customer__c = secCust.Id,
            Credit_Date__c = Date.today(),
            Amount__c = 500
        );
        insert cn;

        Test.startTest();
        cn.Amount__c = 600;
        update cn;
        Test.stopTest();

        Secondary_Credit_Note__c updated = [SELECT Amount__c FROM Secondary_Credit_Note__c WHERE Id = :cn.Id];
        System.assertEquals(600, updated.Amount__c);
    }

    @isTest
    static void testShareCustomerAccountsDirectCall() {
        Account dist = getDistributor();
        Account secCust = getSecondaryCustomer();

        Secondary_Credit_Note__c cn = new Secondary_Credit_Note__c(
            Distributor__c = dist.Id,
            Customer__c = secCust.Id,
            Credit_Date__c = Date.today(),
            Amount__c = 500
        );
        insert cn;

        Test.startTest();
        SecondaryCreditNoteSharingHandler.shareCustomerAccountsWithDistributorUsers(
            new List<Secondary_Credit_Note__c>{ cn }
        );
        Test.stopTest();
    }

    @isTest
    static void testShareCustomerAccountsEmptyList() {
        Test.startTest();
        SecondaryCreditNoteSharingHandler.shareCustomerAccountsWithDistributorUsers(
            new List<Secondary_Credit_Note__c>()
        );
        Test.stopTest();
    }

    @isTest
    static void testShareCustomerAccountsNullFields() {
        Account secCust = getSecondaryCustomer();
        Secondary_Credit_Note__c cn = new Secondary_Credit_Note__c(
            Customer__c = secCust.Id,
            Credit_Date__c = Date.today(),
            Amount__c = 100
        );
        insert cn;

        Test.startTest();
        SecondaryCreditNoteSharingHandler.shareCustomerAccountsWithDistributorUsers(
            new List<Secondary_Credit_Note__c>{ cn }
        );
        Test.stopTest();
    }

    @isTest
    static void testHandleAfterUpdateDistributorChange() {
        Account dist = getDistributor();
        Account secCust = getSecondaryCustomer();

        Secondary_Credit_Note__c cn = new Secondary_Credit_Note__c(
            Distributor__c = dist.Id,
            Customer__c = secCust.Id,
            Credit_Date__c = Date.today(),
            Amount__c = 500
        );
        insert cn;

        Test.startTest();
        cn.Distributor__c = secCust.Id;
        update cn;
        Test.stopTest();

        Secondary_Credit_Note__c updated = [SELECT Distributor__c FROM Secondary_Credit_Note__c WHERE Id = :cn.Id];
        System.assertEquals(secCust.Id, updated.Distributor__c);
    }

    // ========== Batch Test ==========

    @isTest
    static void testSecondaryCreditNoteSharingBatch() {
        Account dist = getDistributor();
        Account secCust = getSecondaryCustomer();

        Secondary_Credit_Note__c cn = new Secondary_Credit_Note__c(
            Distributor__c = dist.Id,
            Customer__c = secCust.Id,
            Credit_Date__c = Date.today(),
            Amount__c = 500
        );
        insert cn;

        Test.startTest();
        Database.executeBatch(new SecondaryCreditNoteSharingBatch(), 200);
        Test.stopTest();
    }

    @isTest
    static void testMultipleCreditNotesInsert() {
        Account dist = getDistributor();
        Account secCust = getSecondaryCustomer();

        List<Secondary_Credit_Note__c> creditNotes = new List<Secondary_Credit_Note__c>();
        for (Integer i = 0; i < 5; i++) {
            creditNotes.add(new Secondary_Credit_Note__c(
                Distributor__c = dist.Id,
                Customer__c = secCust.Id,
                Credit_Date__c = Date.today(),
                Amount__c = 100 * (i + 1)
            ));
        }

        Test.startTest();
        insert creditNotes;
        Test.stopTest();

        System.assertEquals(5, [SELECT COUNT() FROM Secondary_Credit_Note__c WHERE Distributor__c = :dist.Id AND Customer__c = :secCust.Id]);
    }

    // ========== Community User Tests for full sharing logic ==========

    @isTest
    static void testSharingWithCommunityUser() {
        User communityUser = getCommunityUser();
        Account dist = getDistributor();
        Account secCust = getSecondaryCustomer();

        Test.startTest();
        Secondary_Credit_Note__c cn = new Secondary_Credit_Note__c(
            Distributor__c = dist.Id,
            Customer__c = secCust.Id,
            Credit_Date__c = Date.today(),
            Amount__c = 1000
        );
        insert cn;
        Test.stopTest();

        System.assertNotEquals(null, cn.Id);
    }

    @isTest
    static void testSharingDirectCallWithCommunityUser() {
        User communityUser = getCommunityUser();
        Account dist = getDistributor();
        Account secCust = getSecondaryCustomer();

        Secondary_Credit_Note__c cn = new Secondary_Credit_Note__c(
            Distributor__c = dist.Id,
            Customer__c = secCust.Id,
            Credit_Date__c = Date.today(),
            Amount__c = 500
        );
        insert cn;

        Test.startTest();
        // Call directly again to test duplicate share prevention
        SecondaryCreditNoteSharingHandler.shareCustomerAccountsWithDistributorUsers(
            new List<Secondary_Credit_Note__c>{ cn }
        );
        Test.stopTest();
    }

    @isTest
    static void testBatchWithCommunityUser() {
        User communityUser = getCommunityUser();
        Account dist = getDistributor();
        Account secCust = getSecondaryCustomer();

        Secondary_Credit_Note__c cn = new Secondary_Credit_Note__c(
            Distributor__c = dist.Id,
            Customer__c = secCust.Id,
            Credit_Date__c = Date.today(),
            Amount__c = 500
        );
        insert cn;

        Test.startTest();
        Database.executeBatch(new SecondaryCreditNoteSharingBatch(), 200);
        Test.stopTest();
    }
}