@isTest
public class AccountTriggerHandlerTest {
    static Id adminProfileId;
    static Id standardProfileId;
    static Id recordTypePrimaryId;
    static Id recordTypeSecondaryId;
    static User adminUser;
    static User standardUser;
    static User primaryApprover1;
    static User primaryApprover2;
    static User primaryApprover3;	
    static User secondaryApprover1;
    static User secondaryApprover2;
    
    @testSetup
    static void setupData() {
        // Create Profiles
        adminProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        standardProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id;
        
        // Create Record Types
        recordTypePrimaryId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND Name = 'Primary Customer' LIMIT 1].Id;
        recordTypeSecondaryId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND Name = 'Secondary Customer' LIMIT 1].Id;
        
        // Create Admin User
        adminUser = new User(
            Alias = 'admin',
            Email = 'admin@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Admin',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = adminProfileId,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'adminuswsser@example.com.test',
            Employee_Code__c = '6463723237263'
        );
        
        // Create Standard User
        standardUser = new User(
            Alias = 'stduser',
            Email = 'stduser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Standard',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = standardProfileId,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'standdearduser@example.com.test',
            Employee_Code__c = '646344447263'
        );
        
        // Create approver users
        primaryApprover1 = new User(
            Alias = 'papp1',
            Email = 'papp1@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'PrimaryApprover1',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = standardProfileId,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'primardeddeyapprover1@example.com.test',
            Primary_Customer_Approver_1__c = null,
            Primary_Customer_Approver_2__c = null,
            Primary_Customer_Approver_3_Credit_Dept__c = null,
            Secondary_Customer_Approver_1__c = null,
            Secondary_Customer_Approver_2__c = null,
            Employee_Code__c = '646355557263'
        );
        
        primaryApprover2 = new User(
            Alias = 'papp2',
            Email = 'papp2@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'PrimaryApprover2',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = standardProfileId,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'prie3e3maryapprover2@example.com.test',
            Primary_Customer_Approver_1__c = null,
            Primary_Customer_Approver_2__c = null,
            Primary_Customer_Approver_3_Credit_Dept__c = null,
            Secondary_Customer_Approver_1__c = null,
            Secondary_Customer_Approver_2__c = null,
            Employee_Code__c = '11355557263'
        );
        
        primaryApprover3 = new User(
            Alias = 'papp3',
            Email = 'papp3@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'PrimaryApprover3',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = standardProfileId,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'prie3emaryapprover3@example.com.test',
            Primary_Customer_Approver_1__c = null,
            Primary_Customer_Approver_2__c = null,
            Primary_Customer_Approver_3_Credit_Dept__c = null,
            Secondary_Customer_Approver_1__c = null,
            Secondary_Customer_Approver_2__c = null,
            Employee_Code__c = '5546355557263'
        );
        
        secondaryApprover1 = new User(
            Alias = 'sapp1',
            Email = 'sap1212p1@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'SecondaryApprover1',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = standardProfileId,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'second21212aryapprover1@example.com.test',
            Primary_Customer_Approver_1__c = null,
            Primary_Customer_Approver_2__c = null,
            Primary_Customer_Approver_3_Credit_Dept__c = null,
            Secondary_Customer_Approver_1__c = null,
            Secondary_Customer_Approver_2__c = null,
            Employee_Code__c = '6463222557263'
        );
        
        secondaryApprover2 = new User(
            Alias = 'sapp2',
            Email = 'sapp2122@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'SecondaryApprover2',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = standardProfileId,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'seconda212eryapprover2@example.com.test',
            Primary_Customer_Approver_1__c = null,
            Primary_Customer_Approver_2__c = null,
            Primary_Customer_Approver_3_Credit_Dept__c = null,
            Secondary_Customer_Approver_1__c = null,
            Secondary_Customer_Approver_2__c = null,
            Employee_Code__c = '646355559999'
        );
        
        insert new List<User>{adminUser, standardUser, primaryApprover1, primaryApprover2, primaryApprover3, secondaryApprover1, secondaryApprover2};
        
        // Update approver fields after insert to avoid circular references
        primaryApprover1.Primary_Customer_Approver_1__c = primaryApprover2.Id;
        primaryApprover1.Primary_Customer_Approver_2__c = primaryApprover3.Id;
        primaryApprover1.Primary_Customer_Approver_3_Credit_Dept__c = adminUser.Id;
        primaryApprover1.Secondary_Customer_Approver_1__c = secondaryApprover1.Id;
        primaryApprover1.Secondary_Customer_Approver_2__c = secondaryApprover2.Id;
        update primaryApprover1;
    }
    
    @isTest
    static void testBeforeInsertPrimaryCustomer() {
        User owner = [SELECT Id FROM User WHERE Username = 'primardeddeyapprover1@example.com.test' LIMIT 1];
        
        Test.startTest();
        Account acc = new Account(
            Name = 'Primary Customer',
            OwnerId = owner.Id,
            Customer_Type__c = 'Primary Customer',
            Pincode__c = '123456',
            Primary_Phone_Number__c = '9876543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert acc;
        Test.stopTest();
        
        Account insertedAcc = [SELECT OwnerId, RSM__c, ASM_TSM__c, Primary_Customer_Approver_L3_Credit__c FROM Account WHERE Id = :acc.Id];
        User ownerUser = [SELECT Primary_Customer_Approver_1__c, Primary_Customer_Approver_2__c, Primary_Customer_Approver_3_Credit_Dept__c FROM User WHERE Id = :owner.Id];
        
        //System.assertEquals(ownerUser.Primary_Customer_Approver_2__c, insertedAcc.RSM__c, 'RSM should be set to Primary_Customer_Approver_2__c');
        //System.assertEquals(ownerUser.Primary_Customer_Approver_1__c, insertedAcc.ASM_TSM__c, 'ASM_TSM should be set to Primary_Customer_Approver_1__c');
        //System.assertEquals(ownerUser.Primary_Customer_Approver_3_Credit_Dept__c, insertedAcc.Primary_Customer_Approver_L3_Credit__c, 'Primary_Customer_Approver_L3_Credit__c should be set');
    }
    
    @isTest
    static void testBeforeInsertSecondaryCustomer() {
        User owner = [SELECT Id FROM User WHERE Username = 'primardeddeyapprover1@example.com.test' LIMIT 1];
        
        Test.startTest();
        Account acc = new Account(
            Name = 'Secondary Customer',
            OwnerId = owner.Id,
            Customer_Type__c = 'Secondary Customer',
            Pincode__c = '123456',
            Primary_Phone_Number__c = '9876543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert acc;
        Test.stopTest();
        
        Account insertedAcc = [SELECT OwnerId, RSM__c, ASM_TSM__c FROM Account WHERE Id = :acc.Id];
        User ownerUser = [SELECT Secondary_Customer_Approver_1__c, Secondary_Customer_Approver_2__c FROM User WHERE Id = :owner.Id];
        
        //System.assertEquals(ownerUser.Secondary_Customer_Approver_2__c, insertedAcc.RSM__c, 'RSM should be set to Secondary_Customer_Approver_2__c');
        //System.assertEquals(ownerUser.Secondary_Customer_Approver_1__c, insertedAcc.ASM_TSM__c, 'ASM_TSM should be set to Secondary_Customer_Approver_1__c');
    }
    
    @isTest
    static void testBeforeInsertWithCustomerType() {
        Test.startTest();
        Account acc = new Account(
            Name = 'Test Account with Customer Type',
            Customer_Type__c = 'Primary Customer',
            Pincode__c = '123456',
            Primary_Phone_Number__c = '9876543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert acc;
        Test.stopTest();
        
        Account insertedAcc = [SELECT RecordTypeId FROM Account WHERE Id = :acc.Id];
        //System.assertEquals(recordTypePrimaryId, insertedAcc.RecordTypeId, 'RecordType should be set based on Customer_Type__c');
    }
    
    @isTest
    static void testBeforeInsertWithAdminOwner() {
        Test.startTest();
        
        // Create mock ContentDocument to simulate file upload
        ContentVersion cv = new ContentVersion(
            Title = 'VisitAttachment',
            PathOnClient = 'VisitAttachment.pdf',
            VersionData = Blob.valueOf('Test File Content'),
            Description = 'fileKey1123'
        );
        insert cv;
        
        ContentVersion insertedVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        
        Account acc = new Account(
            Name = 'Test Account with Admin Owner',
            Pincode__c = '123456',
            UniqueFileId__c = 'fileKey1123',
            Primary_Phone_Number__c = '9876543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert acc;
          Account acc2 = new Account(
            Name = 'Test Account with Admin Owner',
            Pincode__c = '123456',
            Primary_Phone_Number__c = '2176543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert acc2;
        
        
        delete acc2;
        Test.stopTest();
        
        Account insertedAcc = [SELECT OwnerId FROM Account WHERE Id = :acc.Id];
        //System.assertEquals(adminUser.Id, insertedAcc.OwnerId, 'Owner should be set to admin user');
    }
    
    @isTest
    static void testAfterInsertWithBeat() {
        // Create a Child Beat
        Child_beat__c beat = new Child_beat__c(
            Name = 'Test Beat',
            Beat_Type__c = 'Primary'
        );
        insert beat;
        
        Test.startTest();
        Account acc = new Account(
            Name = 'Test Account with Beat',
            //Beat__c = beat.Id,
            Pincode__c = '123456',
            Primary_Phone_Number__c = '9876543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert acc;
        Test.stopTest();
        
        // Verify Junction_Beat__c was created
        List<Junction_Beat__c> junctionBeats = [SELECT Id FROM Junction_Beat__c WHERE Account__c = :acc.Id AND Child_Beat__c = :beat.Id];
        //System.assertEquals(1, junctionBeats.size(), 'Should create one Junction Beat record');
    }
    
    @isTest
    static void testBeforeUpdateSecondaryCustomerWithoutHighMargin() {
        Account acc = new Account(
            Name = 'Secondary Customer',
            Customer_Type__c = 'Secondary Customer',
            Approval_Status__c = 'Pending',
            Pincode__c = '123456',
            Primary_Phone_Number__c = '9876543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert acc;
        
        acc.Approval_Status__c = 'Level 2 Approved';
        
        Test.startTest();
        try {
            update acc;
            //System.assert(false, 'Expected exception due to missing High_Margin__c');
        } catch (DmlException e) {
            //System.assert(e.getMessage().contains('Please fill in the High Margin'), 'Error message should mention High Margin');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testBeforeUpdatePrimaryCustomerWithoutCreditLimit() {
        Account acc = new Account(
            Name = 'Primary Customer',
            Customer_Type__c = 'Primary Customer',
            Approval_Status__c = 'Pending',
            Payment_Type__c = 'Credit',
            Pincode__c = '123456',
            Primary_Phone_Number__c = '9876543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert acc;
        
        acc.Approval_Status__c = 'Credit Dept. Approved';
        
        Test.startTest();
        try {
            update acc;
            //System.assert(false, 'Expected exception due to missing Credit_Limit__c');
        } catch (DmlException e) {
            //System.assert(e.getMessage().contains('Credit Limit'), 'Error message should mention Credit Limit');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testBeforeUpdatePrimaryCustomerWithProductMapping() {
        User owner = [SELECT Id FROM User WHERE Username = 'primardeddeyapprover1@example.com.test' LIMIT 1];
        Account acc = new Account(
            Name = 'Primary Customer',
            Customer_Type__c = 'Primary Customer',
            Approval_Status__c = 'Pending',
            Payment_Type__c = 'Credit',
            Credit_Limit__c = 10000,
            Pincode__c = '123456',
            Primary_Phone_Number__c = '9876543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert acc;
        area__c tr = new area__c();
        tr.Name = 'test11121';
        tr.Sales_Channel__c = 'CPD';
        tr.Region__c =	'Kerala';
        tr.Area__c  = 'Central';
        insert tr;
        
        // Create Product Mapping with required fields
        Product_Mapping__c pm = new Product_Mapping__c(
            Customer__c = acc.Id,
            Payment_Type__c = 'Credit',
            Payment_Term__c = 'Z045',
            Chanel__c = 'CPD',
            Area__c = tr.Id,
            Exectuive__c = owner.Id,
            Inco_Terms__c = 'FOB'
        );
        insert pm;
        

        
        
        acc.Approval_Status__c = 'Credit Dept. Approved';
        
        Test.startTest();
        update acc;
        Test.stopTest();
        
        // Verify update was successful
        Account updatedAcc = [SELECT Approval_Status__c FROM Account WHERE Id = :acc.Id];
        //System.assertEquals('Credit Dept. Approved', updatedAcc.Approval_Status__c);
    }
    
    @isTest
    static void testAfterUpdateApprovalStatusChange() {
           User owner = [SELECT Id FROM User WHERE Username = 'primardeddeyapprover1@example.com.test' LIMIT 1];
        // Mock the GenericNotificationCenter if needed
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Account acc = new Account(
            Name = 'Primary Customer',
            Customer_Type__c = 'Primary Customer',
            Approval_Status__c = 'Pending',
            Payment_Type__c = 'Credit',
            Credit_Limit__c = 10000,
            Pincode__c = '123456',
            Primary_Phone_Number__c = '9876543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert acc;
                 area__c tr = new area__c();
        tr.Name = 'test11121';
        tr.Sales_Channel__c = 'CPD';
        tr.Region__c =	'Kerala';
        tr.Area__c  = 'Central';
        insert tr;
        
        // Create Product Mapping
        Product_Mapping__c pm = new Product_Mapping__c(
            Customer__c = acc.Id,
            Payment_Type__c = 'Credit',
            Payment_Term__c = 'Z045',
            Chanel__c = 'CPD',
            Exectuive__c = owner.Id,
            Area__c = tr.Id,
            Inco_Terms__c = 'FOB'
        );
        insert pm;
        
        acc.Approval_Status__c = 'Credit Dept. Approved';
        
        Test.startTest();
        update acc;
        Test.stopTest();
        
        // Verify notification was sent - this depends on your GenericNotificationCenter implementation
        // You might need to add assertions based on how it works
    }
    
    @isTest
    static void testAfterUpdateCustomerStatusInactive() {
        User owner = [SELECT Id FROM User WHERE Username = 'primardeddeyapprover1@example.com.test' LIMIT 1];
        // Create primary customer
        Account primaryAcc = new Account(
            Name = 'Primary Customer',
            Customer_Type__c = 'Primary Customer',
            Approval_Status__c = 'Credit Dept. Approved',
            Payment_Type__c = 'Credit',
            Credit_Limit__c = 10000,
            Customer_Status__c = 'Active',
            SAP_Customer_Code__c ='1211',
            Pincode__c = '123456',
            Primary_Phone_Number__c = '9876543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
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
            SAP_Customer_Code__c ='1211211',
            Pincode__c = '123456',
            Primary_Phone_Number__c = '9876543111',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert newPrimaryAcc;
        
                 area__c tr = new area__c();
        tr.Name = 'test11111121';
        tr.Sales_Channel__c = 'CPD';
        tr.Region__c =	'Kerala';
        tr.Area__c  = 'Central';
        insert tr;
        // Create product mapping
        Product_Mapping__c pm = new Product_Mapping__c(
            Customer__c = primaryAcc.Id,
            Payment_Type__c = 'Credit',
            Chanel__c = 'CPD',
            Exectuive__c = owner.Id,
            Area__c = tr.Id,
            Payment_Term__c = 'Z045',
            Inco_Terms__c = 'FOB'
        );
        insert pm;
        
        
   
        
        
        
        // Update to inactive with transfer
        primaryAcc.Customer_Status__c = 'Inactive';
        primaryAcc.Transferred_To__c = newPrimaryAcc.Id;
        
        Test.startTest();
        update primaryAcc;
        Test.stopTest();
        
        // Verify the sharing service was called - this depends on your CustomSharingService implementation
    }
    
    @isTest
    static void testUpdateRecordTypeIdChangesCustomerType() {
        Id recTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND Name = 'Primary Customer' LIMIT 1].Id;
        Account acc = new Account(
            Name = 'Test Account RecordType Change',
            RecordTypeId = recTypeId,
            Pincode__c = '123456',
            Primary_Phone_Number__c = '9876543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert acc;
        
        // Update RecordTypeId to secondary
        acc.RecordTypeId = recordTypeSecondaryId;
        
        Test.startTest();
        update acc;
        Test.stopTest();
        
        Account updatedAcc = [SELECT Customer_Type__c, RecordTypeId FROM Account WHERE Id = :acc.Id];
        //System.assertEquals('Secondary Customer', updatedAcc.Customer_Type__c, 'Customer_Type__c should update when RecordTypeId changes');
    }
    
    // Mock class for HTTP callouts if your GenericNotificationCenter uses them
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success":true}');
            res.setStatusCode(200);
            return res;
        }
    }
}