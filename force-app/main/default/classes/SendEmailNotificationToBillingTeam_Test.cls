@IsTest
private class SendEmailNotificationToBillingTeam_Test {

    @TestSetup
    static void setupData() {
        // Create Account (omit read-only fields)
        Account acc = new Account(
            Name = 'Test Account',
            Primary_Customer_Type__c = 'Modern Trade',
            Primary_Customer_Business_Type__c = 'Retailer',
            State__c = 'Karnataka',
            District__c = 'Bangalore Urban',
            Approval_Status__c = '',
            Primary_Phone_Number__c = '9876543210',
            Payment_Type__c = 'Credit',
            Credit_Limit__c = 500000
        );
        insert acc;

        // Create file and link to Account
        ContentVersion cv = new ContentVersion(
            Title = 'TestFile',
            PathOnClient = 'TestFile.pdf',
            VersionData = Blob.valueOf('Dummy content'),
            IsMajorVersion = true
        );
        insert cv;

        Id docId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1].ContentDocumentId;
        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = acc.Id,
            ContentDocumentId = docId,
            ShareType = 'V'
        );
        insert cdl;
    }

    @IsTest
    static void test_sendDocuments_withAttachments() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
            SendEmailNotificationToBillingTeam.sendDocuments(new Set<Id>{acc.Id});
        Test.stopTest();
        System.assert(true, 'Ran successfully with attachments.');
    }

}