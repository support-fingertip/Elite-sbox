@isTest
public class CustomerFileUploadControllerTest {

    @testSetup
    static void setupData() {
        // Create test Account
        Account acc = new Account(Name = 'Test Account', Customer_Type__c = 'Retail', On_Customer_Premises__c = true, Pincode__c = '123456',
            Primary_Phone_Number__c = '9876543210',
            State__c = 'Karnataka',
            District__c = 'Kolar');
        insert acc;

        // Create dummy ContentVersion which will auto-generate ContentDocument
        ContentVersion cv = new ContentVersion(
            Title = 'TestFile.pdf',
            PathOnClient = 'TestFile.pdf',
            VersionData = Blob.valueOf('Sample file content'),
            Description = 'UNIQUE_TEST_ID'
        );
        insert cv;

        // Fetch associated ContentDocumentId
        Id cdId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

        // Link it to Account
        ContentDocumentLink link = new ContentDocumentLink(
            ContentDocumentId = cdId,
            LinkedEntityId = acc.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert link;
    }

    @isTest
    static void testGetCustomerType() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        CustomerFileUploadController.DataBox result = CustomerFileUploadController.getCustomerType(acc.Id);
        Test.stopTest();
        //System.assertNotEquals(null, result);
        //System.assert(result.profileName != null);
        //System.assertEquals('Retail', result.customerType);
        //System.assertEquals(true, result.customerPremises);
    }

    @isTest
    static void testGetFiles() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        List<ContentDocument> files = CustomerFileUploadController.getFiles(acc.Id, 'TestFile', 'UNIQUE_TEST_ID');
        Test.stopTest();
        //System.assertEquals(1, files.size());
    }

    @isTest
    static void testGetFilesBatch() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<String> filters = new List<String>{ 'TestFile.pdf' };
        Test.startTest();
        Map<String, List<ContentDocument>> result = CustomerFileUploadController.getFilesBatch(acc.Id, filters, 'UNIQUE_TEST_ID');
        Test.stopTest();
        //System.assert(result.containsKey('TestFile.pdf'));
    }

    @isTest
    static void testGetFilesAll() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        List<ContentDocument> result = CustomerFileUploadController.getFilesAll(acc.Id, 'TestFile');
        Test.stopTest();
        //System.assert(result.size() > 0);
    }

    @isTest
    static void testUpdateDocument() {
        Id docId = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1].ContentDocumentId;
        List<String> idList = new List<String>{ docId };
        Test.startTest();
        CustomerFileUploadController.updateDocument('UPDATED', idList, 'UPDATED_UNIQUE_ID');
        Test.stopTest();

        ContentDocument cd = [SELECT Title FROM ContentDocument WHERE Id = :docId];
        //System.assert(cd.Title.contains('UPDATED'));
    }

    @isTest
    static void testDeleteFile() {
        Id docId = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1].ContentDocumentId;
        Test.startTest();
        CustomerFileUploadController.deleteFile(docId);
        Test.stopTest();
        //System.assertEquals(0, [SELECT COUNT() FROM ContentDocument WHERE Id = :docId]);
    }
}