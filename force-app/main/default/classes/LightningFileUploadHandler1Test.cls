@isTest
public class LightningFileUploadHandler1Test{
    public static testmethod void filemethod(){
        // Create a test lead
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            phone='9977447133',
            leadsource ='Website',
            Email = 'test@example.com',	
            Status = 'Open'
        );
        insert testLead;

        // Create a test ContentVersion
        ContentVersion contentVersion = new ContentVersion(
            VersionData = Blob.valueOf('Test attachment content'),
            Title = 'Test Content',
            PathOnClient = 'TestFile.txt'
        );
        insert contentVersion;

        // Create a ContentDocumentLink to attach the ContentVersion to the Lead
        ContentDocumentLink contentLink = new ContentDocumentLink(
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId,
            LinkedEntityId = testLead.Id,
            ShareType = 'V'
        );
        insert contentLink;
        List<ContentDocumentLink> contentLinks = [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId = :testLead.Id];
        List<String> stringIds = new List<String>();
        stringIds.add(contentLinks[0].Id);
        test.starttest();
        LightningFileUploadHandler1.getFiles(testLead.Id,'yryryryryyryr','OnUpload');
        LightningFileUploadHandler1.deleteFile(contentLinks[0].ContentDocumentId);
        test.stoptest();
    
    }

}