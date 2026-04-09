@isTest
public class CustomerReplacementControllerTest {

    // @testSetup runs in its own transaction, so User DML done here does NOT
    // cause Mixed DML errors when test methods later insert non-setup objects
    // like Account, Product_Mapping__c, etc.
    @testSetup
    static void setupUsers() {
        UserRole testRole = [SELECT Id FROM UserRole LIMIT 1];
        Profile tseProfile = [SELECT Id FROM Profile WHERE Name = 'TSE' LIMIT 1];

        User testUser1 = new User(
            Alias = 'tuser',
            Employee_Code__c = '123212231',
            Email = 'testus12er@example.com',
            EmailEncodingKey = 'UTF-8',
            userroleId = testRole.Id,
            LastName = 'Test',
            isActive = true,
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = tseProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testus1212er@example.com' + System.currentTimeMillis(),
            Sales_Channel__c = 'Cake'
        );
        insert testUser1;

        User testUser2 = new User(
            Alias = 'tuser12',
            Employee_Code__c = '1232122343',
            Email = 'testuse12r@example.com',
            userroleId = testRole.Id,
            ManagerId = testUser1.Id,
            isActive = true,
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = tseProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testu212ser@example.com' + System.currentTimeMillis(),
            Sales_Channel__c = 'Cake'
        );
        insert testUser2;
    }

    @isTest
    static void testPrimaryCustomerReplacement() {
        // Users were inserted in @testSetup, so querying is safe - no Mixed DML.
        User testUser2 = [SELECT Id FROM User WHERE Employee_Code__c = '1232122343' LIMIT 1];

        // Create primary customer
        Account primaryAcc = new Account(
            Name = 'Primary Customer',
            Customer_Type__c = 'Primary Customer',
            Approval_Status__c = 'Credit Dept. Approved',
            Payment_Type__c = 'Credit',
            Credit_Limit__c = 10000,
            Customer_Status__c = 'Active',
            SAP_Customer_Code__c = '1211',
            Pincode__c = '123456',
            Primary_Phone_Number__c = '9876543210',
            State__c = 'Karnataka',
            District__c = 'Kolar',
            Is_Transfer_Completed__c = false
        );
        insert primaryAcc;

        // Create new primary customer to transfer to
        Account newPrimaryAcc = new Account(
            Name = 'New Primary Customer',
            Customer_Type__c = 'Primary Customer',
            Approval_Status__c = 'Credit Dept. Approved',
            Payment_Type__c = 'Credit',
            Credit_Limit__c = 15000,
            Customer_Status__c = 'Active',
            SAP_Customer_Code__c = '1211211',
            Pincode__c = '123456',
            Primary_Phone_Number__c = '9876543111',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert newPrimaryAcc;

        area__c tr = new area__c();
        tr.Name = '2211sjsjs';
        tr.Sales_Channel__c = 'CPD';
        tr.Region__c = 'Kerala';
        tr.Area__c = 'Central';
        insert tr;

        // Create product mapping
        Product_Mapping__c pm = new Product_Mapping__c(
            Customer__c = primaryAcc.Id,
            Payment_Type__c = 'Credit',
            Chanel__c = 'CPD',
            Area__c = tr.Id,
            Payment_Term__c = 'Z045',
            Inco_Terms__c = 'FOB',
            Exectuive__c = testUser2.Id
        );
        insert pm;

        // Update to inactive with transfer
        primaryAcc.Customer_Status__c = 'Inactive';
        primaryAcc.Deactivate_Reason2__c = 'Replacement';
        primaryAcc.Transferred_To__c = newPrimaryAcc.Id;

        Test.startTest();
        update primaryAcc;

        String result = CustomerReplacementController.customerReplacement(primaryAcc.Id);
        Test.stopTest();
    }


    @isTest
    static void testCustomerNotFound() {
        Test.startTest();
        String result = CustomerReplacementController.customerReplacement(Id.valueOf('001000000000000AAA'));
        Test.stopTest();

        System.assertEquals('Error: CUSTOMER_NOT_FOUND', result);
    }

    @isTest
    static void testTransferredToMissing() {
        // Account has no Transferred_To__c set - should return TRANSFERRED_TO_MISSING
        Account acc = new Account(
            Name = 'No Transfer Target',
            Customer_Type__c = 'Primary Customer',
            Customer_Status__c = 'Active',
            SAP_Customer_Code__c = 'SAPNOTRF',
            Pincode__c = '560001',
            Primary_Phone_Number__c = '1112223333',
            State__c = 'Karnataka',
            District__c = 'Kolar',
            Is_Transfer_Completed__c = false
        );
        insert acc;

        Test.startTest();
        String result = CustomerReplacementController.customerReplacement(acc.Id);
        Test.stopTest();

        System.assertEquals('Error: TRANSFERRED_TO_MISSING', result);
    }

    @isTest
    static void testTransferAlreadyCompleted() {
        // Account already has Is_Transfer_Completed__c = true - should return TRANSFER_COMPLETED
        Account newAcc = new Account(
            Name = 'New Target Account',
            Customer_Type__c = 'Primary Customer',
            Customer_Status__c = 'Active',
            SAP_Customer_Code__c = 'SAPNEWTRGT',
            Pincode__c = '560001',
            Primary_Phone_Number__c = '2223334444',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert newAcc;

        Account acc = new Account(
            Name = 'Already Transferred Account',
            Customer_Type__c = 'Primary Customer',
            Customer_Status__c = 'Inactive',
            Deactivate_Reason2__c = 'Replacement',
            SAP_Customer_Code__c = 'SAPCOMPLETED',
            Pincode__c = '560001',
            Primary_Phone_Number__c = '3334445555',
            State__c = 'Karnataka',
            District__c = 'Kolar',
            Transferred_To__c = newAcc.Id,
            Is_Transfer_Completed__c = true
        );
        insert acc;

        Test.startTest();
        String result = CustomerReplacementController.customerReplacement(acc.Id);
        Test.stopTest();

        System.assertEquals('Error: TRANSFER_COMPLETED', result);
    }

    @isTest
    static void testSubStockiestReplacement() {
        // Create new target sub stockiest
        Account newSub = new Account(
            Name = 'New Sub Stockiest',
            Customer_Type__c = 'Secondary Customer',
            Secondary_Customer_Type__c = 'Sub Stockiest',
            Customer_Status__c = 'Active',
            SAP_Customer_Code__c = 'SAPNEWSUB',
            Pincode__c = '560001',
            Primary_Phone_Number__c = '4445556666',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert newSub;

        // Create old sub stockiest to be replaced
        Account oldSub = new Account(
            Name = 'Old Sub Stockiest',
            Customer_Type__c = 'Secondary Customer',
            Secondary_Customer_Type__c = 'Sub Stockiest',
            Customer_Status__c = 'Active',
            SAP_Customer_Code__c = 'SAPOLDSUB',
            Pincode__c = '560001',
            Primary_Phone_Number__c = '5556667777',
            State__c = 'Karnataka',
            District__c = 'Kolar',
            Is_Transfer_Completed__c = false
        );
        insert oldSub;

        // Flip to inactive with replacement
        oldSub.Customer_Status__c = 'Inactive';
        oldSub.Deactivate_Reason2__c = 'Replacement';
        oldSub.Transferred_To__c = newSub.Id;

        Test.startTest();
        update oldSub;
        String result = CustomerReplacementController.customerReplacement(oldSub.Id);
        Test.stopTest();

        System.assert(result.startsWith('Success'), 'Expected success for sub stockiest replacement, got: ' + result);

        Account updated = [SELECT Is_Transfer_Completed__c FROM Account WHERE Id = :oldSub.Id];
        System.assertEquals(true, updated.Is_Transfer_Completed__c,
            'Is_Transfer_Completed__c should be true after replacement');
    }

    @isTest
    static void testActiveCustomerNoMapsPopulated() {
        // Customer is Active (not Inactive) - neither map will be populated,
        // so no CustomSharingService call, but method still returns Success.
        Account newAcc = new Account(
            Name = 'Active Target',
            Customer_Type__c = 'Primary Customer',
            Customer_Status__c = 'Active',
            SAP_Customer_Code__c = 'SAPACTIVETRGT',
            Pincode__c = '560001',
            Primary_Phone_Number__c = '6667778888',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert newAcc;

        Account acc = new Account(
            Name = 'Active Source',
            Customer_Type__c = 'Primary Customer',
            Customer_Status__c = 'Active',
            SAP_Customer_Code__c = 'SAPACTIVESRC',
            Pincode__c = '560001',
            Primary_Phone_Number__c = '7778889999',
            State__c = 'Karnataka',
            District__c = 'Kolar',
            Transferred_To__c = newAcc.Id,
            Is_Transfer_Completed__c = false
        );
        insert acc;

        Test.startTest();
        String result = CustomerReplacementController.customerReplacement(acc.Id);
        Test.stopTest();

        System.assert(result.startsWith('Success'),
            'Should return success even when no maps populated, got: ' + result);

        Account reloaded = [SELECT Is_Transfer_Completed__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(false, reloaded.Is_Transfer_Completed__c,
            'Is_Transfer_Completed__c should remain false when no maps are populated');
    }

    @isTest
    static void testExceptionHandling() {
        // Passing null recordId throws - exercises the catch block
        Test.startTest();
        String result = CustomerReplacementController.customerReplacement(null);
        Test.stopTest();

        System.assert(result.startsWith('Error:'),
            'Expected error message, got: ' + result);
    }
}
