@IsTest
private class AzureIntegrationControllerTest {

    private class OrderSuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(201);
            res.setBody('{"status":"completed","successCount":1,"failedCount":0,"message":"Success"}');
            return res;
        }
    }

    private class OrderFailMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setBody('{"status":400,"title":"Error","errors":{"orders":["Invalid"]}}');
            return res;
        }
    }


    private class AccountSuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"success","message":"Customer created"}');
            return res;
        }
    }

    private class AccountFailMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setBody('{"status":400,"title":"Validation error","errors":{"request":["Invalid"]}}');
            return res;
        }
    }

    private static void setupData() {

        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + System.currentTimeMillis() + '@test.com',
            Alias = 'tst',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            Employee_Code__c ='1aa21',
            LanguageLocaleKey = 'en_US'
        );
        insert u;

        Account acc= new Account();
        acc.Name='Test Account';
        acc.Customer_Type__c = 'Primary Customer';
        acc.Primary_Phone_Number__c ='3121212112';
        acc.State__c='Kerala';
        acc.District__c='Kozhikode';
        acc.Email_ID__c='abc@gmail.cm';
        insert acc;
        
        Order__c ord=new Order__c();
        ord.Order_Date__c= system.today();
        ord.Store__c = acc.id;
        ord.account__c=acc.id;
        ord.ownerId=u.id;
     //   ord.Delivery_Plant__c = 'DP01';
        insert ord;

    }
    //
    // TEST ORDER SUCCESS
    //
    @IsTest
    static void testOrderSuccess() {

        setupData();
        Order__c ord = [SELECT Id FROM Order__c LIMIT 1];

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new OrderSuccessMock());

        AzureIntegrationController.sendOrderMaster('{ "test": "order" }', ord.Id);

        Test.stopTest();

        Order__c updatedOrd = [SELECT ERP_Check__c FROM Order__c WHERE Id = :ord.Id];
   //     System.assertEquals(true, updatedOrd.ERP_Check__c, 'Order ERP flag should be true');

        System.assertEquals(1, [SELECT COUNT() FROM Apex_Log__c], 'Log should be inserted');
	    }

    @IsTest
    static void testOrderFailure() {

        setupData();
        Order__c ord = [SELECT Id FROM Order__c LIMIT 1];

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new OrderFailMock());

        AzureIntegrationController.sendOrderMaster('{ "test": "order" }', ord.Id);

        Test.stopTest();

        Order__c updatedOrd = [SELECT ERP_Check__c FROM Order__c WHERE Id = :ord.Id];
     //   System.assertEquals(false, updatedOrd.ERP_Check__c, 'ERP flag must be false on failure');

   //     System.assertEquals(1, [SELECT COUNT() FROM Apex_Log__c], 'Error log must be created');
    }

    @IsTest
    static void testAccountSuccess() {

        setupData();
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AccountSuccessMock());

        AzureIntegrationController.sendAccountMaster('{ "test": "account" }', acc.Id,false);

        Test.stopTest();

        Account updatedAcc = [SELECT ERP_Check__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(true, updatedAcc.ERP_Check__c, 'ERP flag should be true');
    }


    //
    // TEST ACCOUNT FAILURE
    //
    @IsTest
    static void testAccountFailure() {

        setupData();
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AccountFailMock());

        AzureIntegrationController.sendAccountMaster('{ "test": "account" }', acc.Id,true);

        Test.stopTest();

        Account updatedAcc = [SELECT ERP_Check__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(false, updatedAcc.ERP_Check__c, 'ERP flag should be false on failure');
    }

private class ThrowExceptionMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        // Force an exception — this will take execution directly to catch(exception e)
        throw new CalloutException('Simulated callout exception');
    }
}
    @IsTest
static void testAccountCalloutExceptionBlock() {

    setupData();
    Account acc = [SELECT Id FROM Account LIMIT 1];

    Test.startTest();

    // Mock the exception
    Test.setMock(HttpCalloutMock.class, new ThrowExceptionMock());

    // Call method → it will enter the catch(exception e) block
    AzureIntegrationController.sendAccountMaster('{ "test": "account" }', acc.Id,true);
AzureIntegrationController.testmeth();
    Test.stopTest();

    // VALIDATIONS
    Account updatedAcc = [SELECT ERP_Check__c FROM Account WHERE Id = :acc.Id];
    System.assertEquals(false, updatedAcc.ERP_Check__c, 'ERP flag must be false when exception occurs');

    System.assertEquals(1, [SELECT COUNT() FROM Apex_Log__c], 'Exception log must be created');
}
private class OrderExceptionMock implements HttpCalloutMock {
    public HttpResponse respond(HTTPRequest req) {
        // This forces the callout to jump directly to the outer catch block
        throw new CalloutException('Simulated callout exception for order');
    }
}
    
 private class OrderInvalidJsonMock implements HttpCalloutMock {
    public HttpResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(400);

        // Return JSON that causes JSON.deserializeUntyped() to throw exception
          res.setBody('{"status":"completed1","errors2":"error"}');

        return res;
    }
}   
    @IsTest
static void testSendOrderMaster_ExceptionBlock() {

    // --- SETUP REQUIRED DATA ---  
   setupData();
        Order__c ord = [SELECT Id FROM Order__c LIMIT 1];


    Test.startTest();

    // ★ IMPORTANT: This mock throws an exception, causing res == null
    Test.setMock(HttpCalloutMock.class, new OrderExceptionMock());

    AzureIntegrationController.sendOrderMaster('{"x":"y"}', ord.Id);

    Test.stopTest();

  
    Order__c updatedOrd = [SELECT ERP_Check__c FROM Order__c WHERE Id = :ord.Id];
    System.assertEquals(false, updatedOrd.ERP_Check__c, 'ERP_Check__c must be false for exception scenario');

    System.assertEquals(1, [SELECT COUNT() FROM Apex_Log__c], 'Apex log should be inserted');
}
      @IsTest
static void testSendOrderMaster_ExceptionBlock1() {

   setupData();
        Order__c ord = [SELECT Id FROM Order__c LIMIT 1];


    Test.startTest();

    Test.setMock(HttpCalloutMock.class, new OrderInvalidJsonMock());

    AzureIntegrationController.sendOrderMaster('{"x":"y"}', ord.Id);

    Test.stopTest();


    Order__c updatedOrd = [SELECT ERP_Check__c FROM Order__c WHERE Id = :ord.Id];
    System.assertEquals(false, updatedOrd.ERP_Check__c, 'ERP_Check__c must be false for exception scenario');

    // Log must be created
    System.assertEquals(1, [SELECT COUNT() FROM Apex_Log__c], 'Apex log should be inserted');
}
   @IsTest
    static void testaccMaster_ExceptionBlock1() {

   setupData();
        account ord = [SELECT Id FROM account LIMIT 1];


    Test.startTest();

    Test.setMock(HttpCalloutMock.class, new OrderInvalidJsonMock());

    AzureIntegrationController.sendAccountMaster('{"x":"y"}', ord.Id,false);

    Test.stopTest();


}


}