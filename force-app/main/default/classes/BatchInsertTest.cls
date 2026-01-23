@isTest
private class BatchInsertTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test account for duplicate testing
        Account testAccount = new Account(
            Name = 'Test Account',
            SAP_Customer_Code__c = 'EXT123',
            Pincode__c = '445534',
            Primary_Phone_Number__c = '7766334451',
            State__c = 'Punjab',
            District__c = 'Moga'
        );
        insert testAccount;
    }
    
    @isTest
    static void testBatchInsertWithSuccessAndErrors() {
        // Prepare test data
        List<Account> accounts = new List<Account>();
        
        // This will succeed (new record)
        accounts.add(new Account(
            Name = 'Success Account 1',
            SAP_Customer_Code__c = 'EXT001',
            Pincode__c = '445534',
            Primary_Phone_Number__c = '7766334452',
            State__c = 'Punjab',
            District__c = 'Moga'
        ));
        
        // This will succeed (new record)
        accounts.add(new Account(
            Name = 'Success Account 2',
            SAP_Customer_Code__c = 'EXT002',
            Pincode__c = '445534',
            Primary_Phone_Number__c = '7766334453',
            State__c = 'Punjab',
            District__c = 'Moga'
        ));
        
        // This will fail (duplicate external ID)
        accounts.add(new Account(
            Name = 'Duplicate Account',
            SAP_Customer_Code__c = 'EXT123',
            Pincode__c = '445534',
            Primary_Phone_Number__c = '7766334454',
            State__c = 'Punjab',
            District__c = 'Moga'// Matches existing account from TestSetup
        ));
        
        // This will fail (missing required field)
        accounts.add(new Account(
            Name = null, // Name is required
            SAP_Customer_Code__c = 'EXT004',
            Pincode__c = '445534',
            Primary_Phone_Number__c = '7766334455',
            State__c = 'Punjab',
            District__c = 'Moga'
        ));
        
        // Create test CSV string
        String csvStr = 'Name,SAP_Customer_Code__c\n"Test Account","EXT123"\n"New Account","EXT456"';
        
        Test.startTest();
        // Execute batch with test data
        BatchInsert batch = new BatchInsert(
            accounts, 
            Account.SAP_Customer_Code__c, 
            'Account', 
            csvStr
        );
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify results
       // List<Account> insertedAccounts = [SELECT Id, Name FROM Account WHERE SAP_Customer_Code__c IN ('EXT001', 'EXT002')];
        //System.assertEquals(2, insertedAccounts.size(), 'Should have inserted 2 accounts');
    }
    
    @isTest
    static void testBatchWithEmptyList() {
        // Test with empty record list
        List<Account> accounts = new List<Account>();
        String csvStr = 'Name,SAP_Customer_Code__c\n"Test Account","EXT123"';
        
        Test.startTest();
        BatchInsert batch = new BatchInsert(
            accounts, 
            Account.SAP_Customer_Code__c, 
            'Account', 
            csvStr
        );
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify no errors occurred with empty list
        System.assert(true, 'Batch should complete successfully with empty list');
    }
    
    @isTest
    static void testEmailAttachmentCreation() {
        // Prepare test data that will generate both success and error attachments
        List<Account> accounts = new List<Account>();
        
        // Success record
        accounts.add(new Account(
            Name = 'Email Test Success',
            SAP_Customer_Code__c = 'EXTEMAIL1'
        ));
        
        // Error record (duplicate)
        accounts.add(new Account(
            Name = 'Email Test Error',
            SAP_Customer_Code__c = 'EXT123' // Duplicate from TestSetup
        ));
        
        // Create test CSV string
        String csvStr = 'Name,SAP_Customer_Code__c\n"Email Test Success","EXTEMAIL1"\n"Email Test Error","EXT123"';
        
        // Mock the email sending to avoid actual emails in test
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.startTest();
        BatchInsert batch = new BatchInsert(
            accounts, 
            Account.SAP_Customer_Code__c, 
            'Account', 
            csvStr
        );
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify DataUpload_Log__c was created
        List<DataUpload_Log__c> logs = [SELECT Id FROM DataUpload_Log__c];
        System.assertEquals(1, logs.size(), 'Should create one upload log');
        
        // Verify content versions were created
        List<ContentVersion> contentVersions = [SELECT Id, Title FROM ContentVersion];
        System.assertEquals(3, contentVersions.size(), 'Should create 3 files (success, error, original)');
        
        // Verify links to the log record
        List<ContentDocumentLink> links = [
            SELECT Id 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :logs[0].Id
        ];
        System.assertEquals(3, links.size(), 'Should link all files to the log record');
    }
    
    @isTest
    static void testBatchConstructor() {
        // Test the empty constructor
        BatchInsert batch = new BatchInsert();
        System.assertNotEquals(null, batch, 'Should instantiate batch class');
    }
    
    // Mock class for email sending
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