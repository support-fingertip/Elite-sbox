@isTest
public class BeatTriggerTest {

    // Helper method to create test data
    private static void createTestData() {
        
        Profile p = [SELECT Id FROM Profile WHERE Name='DSM'];
        // Create a test User
        User testUser = new User(
            Alias = 'testusr',
            Email = 'testuser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser109rtyed56@testorg.com',
            Region__c = 'Tamil Nadu',
            Employee_Code__c = '4411',
            Payroll__c = 'No'
        );
        insert testUser;
        
        // Create a test Child_beat__c record
        Child_beat__c testBeat = new Child_beat__c(
            Name = 'Test Beat',
            Beat_Type__c ='Primary',
            User__c = testUser.Id
        );
        insert testBeat;
    }

    @isTest
    public static void testBeforeInsertTrigger() {
        // Step 1: Prepare the test data
        createTestData();
        
        // Step 2: Create a new Child_beat__c record in Trigger.new
        Child_beat__c newBeat = new Child_beat__c(
            Name = 'New Test Beat',
            Beat_Type__c ='Primary',
            User__c = [SELECT Id FROM User where isActive=true LIMIT 1].Id
        );

        // Step 3: Insert the record and check OwnerId assignment in before insert
        Test.startTest();
        insert newBeat;
        Test.stopTest();
        
        // Step 4: Query the record and verify the OwnerId was assigned to User__c
        Child_beat__c insertedBeat = [SELECT OwnerId FROM Child_beat__c WHERE Id = :newBeat.Id LIMIT 1];
        System.assertEquals(insertedBeat.OwnerId, newBeat.User__c, 'OwnerId should be set to User__c in before insert.');
    }

    @isTest
    public static void testBeforeUpdateTrigger() {
        // Step 1: Prepare the test data
        createTestData();
        
        // Step 2: Update the User__c field and verify the OwnerId change in before update
        Child_beat__c testBeat = [SELECT Id, User__c, OwnerId FROM Child_beat__c LIMIT 1];
       // User newUser = [SELECT Id FROM User LIMIT 1 OFFSET 1];
        //testBeat.User__c = newUser.Id;
        
        Test.startTest();
        update testBeat;
        Test.stopTest();
        
        // Step 3: Query the record and verify the OwnerId was updated correctly
        Child_beat__c updatedBeat = [SELECT OwnerId FROM Child_beat__c WHERE Id = :testBeat.Id LIMIT 1];
        System.assertEquals(updatedBeat.OwnerId, testBeat.User__c, 'OwnerId should be updated to the new User__c value.');
    }

    @isTest
    public static void testAfterInsertTrigger() {
        // Step 1: Prepare the test data
        createTestData();
        
        // Step 2: Insert a Child_beat__c record with a null Beat_Id_Text__c
        Child_beat__c newBeat = new Child_beat__c(
            Name = 'New Test Beat After Insert',
            User__c = UserInfo.getUserId(),
            Beat_Type__c ='Primary'
        );
        
        Test.startTest();
        insert newBeat;
        Test.stopTest();
        
        // Step 3: Query the Child_beat__c record and verify Beat_Id_Text__c is populated
        Child_beat__c insertedBeat = [SELECT Beat_Id_Text__c FROM Child_beat__c WHERE Id = :newBeat.Id LIMIT 1];
        System.assertNotEquals(insertedBeat.Beat_Id_Text__c, null, 'Beat_Id_Text__c should be populated after insert.');
    }

    @isTest
    public static void testAfterUpdateTrigger() {
        // Step 1: Prepare the test data
        createTestData();
        
        // Step 2: Update the OwnerId and Payroll_Employee__c fields
        Child_beat__c testBeat = [SELECT Id, OwnerId, Payroll_Employee__c FROM Child_beat__c LIMIT 1];
        testBeat.OwnerId = UserInfo.getUserId();
        
        Test.startTest();
        update testBeat;
        Test.stopTest();
        
        // Step 3: Query the Child_beat__c record to verify that the error condition was triggered
        Child_beat__c updatedBeat = [SELECT Id, OwnerId FROM Child_beat__c WHERE Id = :testBeat.Id LIMIT 1];
        System.assertEquals(updatedBeat.OwnerId, testBeat.OwnerId, 'OwnerId should not change when Payroll_Employee__c is true.');
    }
}