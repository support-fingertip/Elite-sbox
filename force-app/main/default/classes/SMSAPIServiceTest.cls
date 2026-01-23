@isTest
private class SMSAPIServiceTest {

    // Helper method to create test metadata
    private static void createTestMetadata() {
        // Create mock custom metadata
        External_API_Configuration__mdt mockConfig = new External_API_Configuration__mdt(
            DeveloperName = 'SMS_API',
            Sender_ID__c = 'TESTID',
            Endpoint_URL__c = 'https://api.example.com/send',
            API_Key__c = 'test-api-key-123',
            Method__c = 'POST'
        );
        
        // Use Metadata.Operations to insert mock metadata in test context
        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
        customMetadata.fullName = 'External_API_Configuration__mdt.SMS_API';
        customMetadata.label = 'SMS_API';
        
        customMetadata.values.add(createCustomMetadataField('Sender_ID__c', mockConfig.Sender_ID__c));
        customMetadata.values.add(createCustomMetadataField('Endpoint_URL__c', mockConfig.Endpoint_URL__c));
        customMetadata.values.add(createCustomMetadataField('API_Key__c', mockConfig.API_Key__c));
        customMetadata.values.add(createCustomMetadataField('Method__c', mockConfig.Method__c));
        
        mdContainer.addMetadata(customMetadata);
        Test.enableChangeDataCapture();
        Metadata.Operations.enqueueDeployment(mdContainer, null);
    }
    
    // Helper method to create custom metadata field
    private static Metadata.CustomMetadataValue createCustomMetadataField(String fieldName, Object value) {
        Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
        customField.field = fieldName;
        customField.value = value;
        return customField;
    }
    
   
    
    
    
    @isTest
    static void testSendSMSMetadataMissing() {
        // Don't create metadata to test missing metadata scenario
        
        Test.startTest();
        Boolean result = SMSAPIService.sendSMS('9876543210', '123456');
        Test.stopTest();
        
        System.assertEquals(false, result, 'SMS should fail when metadata is missing');
    }
    
   
    
    // Mock HTTP response generator
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        private Integer statusCode;
        private String body;
        
        public MockHttpResponseGenerator(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body = body;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(this.body);
            res.setStatusCode(this.statusCode);
            return res;
        }
    }
}