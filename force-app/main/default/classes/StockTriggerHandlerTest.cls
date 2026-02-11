@isTest
public class StockTriggerHandlerTest {
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
            Username = 'adminuser@example.com.test',
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
            Username = 'standarduser@example.com.test',
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
            Username = 'primaryapprover1@example.com.test',
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
            Username = 'primaryapprover2@example.com.test',
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
            Username = 'primaryapprover3@example.com.test',
            Primary_Customer_Approver_1__c = null,
            Primary_Customer_Approver_2__c = null,
            Primary_Customer_Approver_3_Credit_Dept__c = null,
            Secondary_Customer_Approver_1__c = null,
            Secondary_Customer_Approver_2__c = null,
            Employee_Code__c = '5546355557263'
        );
        
        secondaryApprover1 = new User(
            Alias = 'sapp1',
            Email = 'sapp1@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'SecondaryApprover1',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = standardProfileId,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'secondaryapprover1@example.com.test',
            Primary_Customer_Approver_1__c = null,
            Primary_Customer_Approver_2__c = null,
            Primary_Customer_Approver_3_Credit_Dept__c = null,
            Secondary_Customer_Approver_1__c = null,
            Secondary_Customer_Approver_2__c = null,
            Employee_Code__c = '6463222557263'
        );
        
        secondaryApprover2 = new User(
            Alias = 'sapp2',
            Email = 'sapp2@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'SecondaryApprover2',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = standardProfileId,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'secondaryapprover2@example.com.test',
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
        User owner = [SELECT Id FROM User WHERE Username = 'primaryapprover1@example.com.test' LIMIT 1];
        
        Test.startTest();
        Account acc = new Account(
            Name = 'Primary Customer',
            Customer_Type__c = 'Primary Customer',
            Pincode__c = '123456',
            Primary_Phone_Number__c = '9876543210',
            State__c = 'Karnataka',
            District__c = 'Kolar',
            OwnerId =  UserInfo.getUserId()
        );
        insert acc;
   
        
        Dealer_Stock__c dl = new Dealer_Stock__c();
        dl.Store__c = acc.Id;
        dl.OwnerId = UserInfo.getUserId();
        insert dl;
        
        Dealer_Stock__c dl1 = new Dealer_Stock__c();
        dl1.Store__c = acc.Id;
        dl1.OwnerId = UserInfo.getUserId();
        insert dl1;
        
        delete dl1;
        
        daily_log__c daily = new Daily_log__c();
        daily.OwnerId = UserInfo.getUserId();
        insert daily;
        Test.stopTest();
        
        //System.assertEquals(ownerUser.Primary_Customer_Approver_2__c, insertedAcc.RSM__c, 'RSM should be set to Primary_Customer_Approver_2__c');
        //System.assertEquals(ownerUser.Primary_Customer_Approver_1__c, insertedAcc.ASM_TSM__c, 'ASM_TSM should be set to Primary_Customer_Approver_1__c');
        //System.assertEquals(ownerUser.Primary_Customer_Approver_3_Credit_Dept__c, insertedAcc.Primary_Customer_Approver_L3_Credit__c, 'Primary_Customer_Approver_L3_Credit__c should be set');
    }

}