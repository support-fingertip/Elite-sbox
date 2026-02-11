@isTest
public class UpdateDailyLogBatchTest {
     @isTest
    static void testAfterInsertVisits() {
        // Create a user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'visituser@test.com',
            Username = 'visituser' + System.currentTimeMillis() + '@test.com',
            Alias = 'vusr',
            Employee_Code__c  = 'sjkhjkj18118',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert u;
        
        // Create a Daily Log record
        Daily_Log__c log = new Daily_Log__c();
        log.Day_started_time__c = Date.today().addDays(-1);
        log.Clock_Out_Location__Longitude__s =37.7749;
        log.Clock_Out_Location__Latitude__s = 78.4194;
        insert log;
        
        // Create mock ContentDocument to simulate file upload
        ContentVersion cv = new ContentVersion(
            Title = 'VisitAttachment',
            PathOnClient = 'VisitAttachment.pdf',
            VersionData = Blob.valueOf('Test File Content'),
            Description = 'fileKey123'
        );
        insert cv;
        
        ContentVersion insertedVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        
        // Create a test Child_beat__c record
        Child_beat__c testBeat = new Child_beat__c(
            Name = 'Test Beat',
            Beat_Type__c = 'Primary',
            User__c = u.Id
        );
        insert testBeat;
        // Create Visit record with key fields
        Visit__c visit = new Visit__c(
            OwnerId = u.Id,
            UniqueFileId__c = 'fileKey123',
            Child_Beat__c = testBeat.Id,
            ClockIn_Latitude__c = 12.9716,
            Clockin_Longitude__c = 77.5946,
            Actual_Start_Time__c = System.now(),
            Distance__c = 10,
            Daily_log__c = log.Id
        );
        
        

        
        Test.startTest();
        insert visit;  // This should trigger the VisitTriggerHandler logic
        visit.ClockIn_Latitude__c = 37.7749;
        visit.Clockin_Longitude__c = 78.4194;
        visit.Actual_End_Time__c = DateTime.now();
        
        visit.Actual_Start_Time__c = DateTime.now();
        update visit; 
        
     
        
        UpdateDailyLogBatchForAccountCount bt = new UpdateDailyLogBatchForAccountCount();
        database.executeBatch(bt,200);
        Test.stopTest();
        
        // No assertions as requested
    }
    @isTest
    static void testAfterInsertVisits2() {
        // Create a user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'visituser@te112st.com',
            Username = 'visitu121ser' + System.currentTimeMillis() + '@test.com',
            Alias = 'vusr',
            Employee_Code__c  = 'sjkhjdd2kj18118',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert u;
        
        // Create a Daily Log record
        Daily_Log__c log = new Daily_Log__c();
        log.Clock_Out_Location__Longitude__s =37.7749;
        log.Clock_Out_Location__Latitude__s = 78.4194;
        insert log;
        
        // Create mock ContentDocument to simulate file upload
        ContentVersion cv = new ContentVersion(
            Title = 'VisitAttachment',
            PathOnClient = 'VisitAttachment.pdf',
            VersionData = Blob.valueOf('Test File Content'),
            Description = 'fileKey1123'
        );
        insert cv;
        
        ContentVersion insertedVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        
        // Create Visit record with key fields
        Visit__c visit = new Visit__c(
            OwnerId = u.Id,
            UniqueFileId__c = 'fileKey1123',
            Actual_Start_Time__c = System.now(),
            Distance__c = 10,
            Daily_log__c = log.Id
        );
        
          insert visit;
        
        Test.startTest();
        // This should trigger the VisitTriggerHandler logic
        try{
            delete visit;
        }
        catch(exception e)
        {
            
        }
        
        Test.stopTest();
        
        // No assertions as requested
    }

}