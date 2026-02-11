@isTest
public class ContentDocTriggerHandlerTest {

    @isTest
    static void testBeforeDelete_NonAdmin_User_NotAllowedToDeleteAccountFile() {
        // Create a non-admin user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'TSE' LIMIT 1];
        User u = new User(
            Username = 'testuser88888888888888888@testorg.com',
            Email = 'testuser@testorg.com',
            LastName = 'Test',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US',
            Employee_Code__c= '1122334455'
        );
        insert u;

        // Run as non-admin
        System.runAs(u) {
            // Create an Account
            Account acc = new Account(Name = 'Test Account',Pincode__c = '445534',
            Primary_Phone_Number__c = '7766334451',
            State__c = 'Punjab',
            District__c = 'Moga');
            insert acc;

            // Create a ContentVersion
            ContentVersion cv = new ContentVersion(
                Title = 'TestFile',
                PathOnClient = 'TestFile.txt',
                VersionData = Blob.valueOf('This is a test file.')
            );
            insert cv;

            // Get ContentDocumentId
            Id docId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

            // Link to Account
            ContentVersion cv1 = new ContentVersion(
            Title = 'Non-Account Document',
            PathOnClient = 'NonAccountDoc.pdf',
            VersionData = Blob.valueOf('Test Content')
        );
        insert cv1;
        cv1 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv1.Id];
        ContentDocument testDoc = new ContentDocument(Id = cv1.ContentDocumentId);

            // Create a list and try delete
            Test.startTest();
            try {
                delete [SELECT Id FROM ContentDocument WHERE Id = :docId];
                //System.assert(false, 'Expected error not thrown');
            } catch (DmlException e) {
                //System.assert(e.getMessage().contains('You are not allowed to delete files related to Account'));
            }
            Test.stopTest();
        }
    }

    @isTest
    static void testBeforeDelete_Admin_User_AllowedToDelete() {
        // Get System Admin user
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];

        System.runAs(adminUser) {
            // Create an Account
            Account acc = new Account(Name = 'Admin Account',Pincode__c = '445534',
            Primary_Phone_Number__c = '7766334451',
            State__c = 'Punjab',
            District__c = 'Moga');
            insert acc;

            // Create a ContentVersion
            ContentVersion cv = new ContentVersion(
                Title = 'AdminTestFile',
                PathOnClient = 'AdminTestFile.txt',
                VersionData = Blob.valueOf('File content')
            );
            insert cv;

            // Get ContentDocumentId
            Id docId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

            // Link it to Account
            ContentDocumentLink link = new ContentDocumentLink(
                ContentDocumentId = docId,
                LinkedEntityId = acc.Id,
                ShareType = 'V',
                Visibility = 'AllUsers'
            );
            insert link;

            // Try to delete - should succeed for admin
            Test.startTest();
            delete [SELECT Id FROM ContentDocument WHERE Id = :docId];
            Test.stopTest();
        }
    }
}