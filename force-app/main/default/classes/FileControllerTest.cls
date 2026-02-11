@isTest
public class FileControllerTest {
    
    @isTest
    static void testSaveFile() {
        // Create and insert a test Account record
        Account acc = new Account(
            Name = 'Test Account',
            Pincode__c = '123456',
            Primary_Phone_Number__c = '9876543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert acc; // Insert the account to get the Id

        // Prepare parameters for the saveFile method
        String parentId = acc.Id; // Now this will have a valid Id
        String fileName = 'TestFile';
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Test file content'));
        String uniqueId = 'UniqueIdentifier123';

        // Call the saveFile method
        Test.startTest();
        String contentDocumentId;
        try {
            contentDocumentId = FileController.saveFile(parentId, fileName, base64Data, uniqueId);
        } catch (AuraHandledException e) {
            System.debug('Error while saving file: ' + e.getMessage());
            System.assert(false, 'Exception should not be thrown');
        }
        Test.stopTest();

        // Verify that the ContentVersion was created
        ContentVersion cv = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Title = :fileName + '-Store-Image' LIMIT 1];
        System.assertNotEquals(null, cv, 'ContentVersion should be created.');

        // Verify that the ContentDocumentLink was created
        ContentDocumentLink cdl = [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId = :cv.ContentDocumentId AND LinkedEntityId = :parentId LIMIT 1];
        System.assertNotEquals(null, cdl, 'ContentDocumentLink should be created.');
    }
}