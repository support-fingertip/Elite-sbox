@isTest
private class postHandler_TestClass 
{
    private class FakeHttpResponseGenerator implements HttpCalloutMock {
        private String responseBody;
        private Integer statusCode;
        private String endPoint;
        
        public FakeHttpResponseGenerator(String responseBody, Integer statusCode, string endPoint) {
            this.responseBody = responseBody;
            this.statusCode = statusCode;
            this.endPoint = endPoint;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setBody(responseBody);
            req.setEndpoint(endPoint);
            res.setStatusCode(statusCode);
            return res;
        }
    }
    
    static testMethod void testmeth(){
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'HR' LIMIT 1];
        
        User newUser = new User();
        newUser.FirstName = 'Test';
        newUser.LastName = 'User005';
        newUser.Email = 'testuswqer@example.com';
        newUser.Username = 'tesqwtww203424@example.com';
        newUser.Alias = 'tuser';
        newUser.CommunityNickname = 'testuser';
        newUser.TimeZoneSidKey = 'America/Los_Angeles';
        newUser.LocaleSidKey = 'en_US';
        newUser.EmailEncodingKey = 'UTF-8';
        newUser.ProfileId = testProfile.Id;
        newUser.LanguageLocaleKey = 'en_US';
        newUser.Employee_Code__c ='1aa21';
        insert newUser;
        
        
        Account acc= new Account();
        acc.Name='Test Account';
        acc.Customer_Type__c = 'Primary Customer';
        acc.Primary_Phone_Number__c ='3121212112';
        acc.State__c='Kerala';
        acc.District__c='Kozhikode';
        insert acc;
        
        Product__c prd=new Product__c();
        prd.Name='sample Product';
        prd.ProductCode__c='test1';
        prd.SKU_Code__c='2ds';
        insert prd;
        
        Order__c ord=new Order__c();
        ord.Order_Date__c= system.today();
      //  ord.Store__c = acc.id;
        ord.account__c = acc.id;
        ord.ownerId=newUser.id;
        insert ord;
        
        Order_Item__c orditem = new Order_Item__c();
        orditem.Product__c=prd.id;
        orditem.Order__c=ord.id;
        orditem.Total_Amount__c=12;
        insert orditem;
        
        Order__c ords=new Order__c();
        ords.Order_Date__c= system.today();
        ords.Store__c = acc.id;
        ords.ownerId=newUser.id;
        insert ords;
        system.debug('ords '+ords);
        list<string>abc= new list<string>();
        String expectedAccessToken1 = '{"access_token":"sampleAccessToken"}';
        
        // String expectedAccessToken2 = '{"access_token":"null"}';
        
        Test.setMock(HttpCalloutMock.class, new FakeHttpResponseGenerator(expectedAccessToken1, 200,'Test'));
        
        Test.startTest();
       // SAPIntegrationController.getAccounts(acc.id);
        postHandler.sendOrder(ord.Id);
     //   postHandler.checkOrderSAP_Status(ord.Id);
        Test.StopTest();
    }
       static testMethod void testmeth01(){
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'HR' LIMIT 1];
        
        User newUser = new User();
        newUser.FirstName = 'Test';
        newUser.LastName = 'User005';
        newUser.Email = 'testuswqer@example.com';
        newUser.Username = 'tesdqwtww203424@example.com';
        newUser.Alias = 'tuser';
        newUser.CommunityNickname = 'testuser';
        newUser.TimeZoneSidKey = 'America/Los_Angeles';
        newUser.LocaleSidKey = 'en_US';
        newUser.EmailEncodingKey = 'UTF-8';
        newUser.ProfileId = testProfile.Id;
        newUser.LanguageLocaleKey = 'en_US';
        newUser.Employee_Code__c ='1aad21';
        insert newUser;
        
        
        Account acc= new Account();
        acc.Name='Test Account';
        acc.Primary_Phone_Number__c ='3121212112';
        acc.State__c='Kerala';
        acc.District__c='Kozhikode';
        insert acc;
        
       
        list<string>abc= new list<string>();
        String expectedAccessToken1 = '{"access_token":"sampleAccessToken"}';
        
        // String expectedAccessToken2 = '{"access_token":"null"}';
        
        Test.setMock(HttpCalloutMock.class, new FakeHttpResponseGenerator(expectedAccessToken1, 200,'Test'));
        
        Test.startTest();
       // SAPIntegrationController.getAccounts(acc.id);	
        postHandler.accPost(acc,true);
     //   postHandler.checkOrderSAP_Status(ord.Id);
        Test.StopTest();
    }
   /* static testMethod void testmeth1(){
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'HR' LIMIT 1];
        
        User newUser = new User();
        newUser.FirstName = 'Test';
        newUser.LastName = 'User005';
        newUser.Email = 'testuser@example.com';
        newUser.Username = 'testww203424@example.com';
        newUser.Alias = 'tuser';
        newUser.CommunityNickname = 'testuser';
        newUser.TimeZoneSidKey = 'America/Los_Angeles';
        newUser.LocaleSidKey = 'en_US';
        newUser.EmailEncodingKey = 'UTF-8';
        newUser.ProfileId = testProfile.Id;
        newUser.LanguageLocaleKey = 'en_US';
        insert newUser;
        
        
        Account acc= new Account();
        acc.Name='Test Account';
        //  acc.Mobile__c='9876578756';
   //     acc.Email__c='sample@asd.com';
        insert acc;
        
        Product__c prd=new Product__c();
        prd.Name='sample Product';
        prd.ProductCode__c='test1';
        insert prd;
        
        Order__c ord=new Order__c();
        ord.Order_Date__c= system.today();
        ord.Store__c = acc.id;
        ord.ownerId=newUser.id;
        insert ord;
        
        Order_Item__c orditem = new Order_Item__c();
        orditem.Product__c=prd.id;
        orditem.Order__c=ord.id;
        insert orditem;
        
        Order__c ords=new Order__c();
        ords.Order_Date__c= system.today();
        ords.Store__c = acc.id;
        ords.ownerId=newUser.id;
        insert ords;
        system.debug('ords '+ords);
        list<string>abc= new list<string>();
        String expectedAccessToken1 = '{"access_token":"sampleAccessToken"}';
        
        Test.setMock(HttpCalloutMock.class, new FakeHttpResponseGenerator(expectedAccessToken1, 0,'trst'));
        Test.startTest();
        postHandler.sendOrder(ord.Id);
        Test.StopTest();
    }
    
    static testMethod void testmeth2(){
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'HR' LIMIT 1];
        
        User newUser = new User();
        newUser.FirstName = 'Test';
        newUser.LastName = 'User005';
        newUser.Email = 'testuser@example.com';
        newUser.Username = 'testww203424@example.com';
        newUser.Alias = 'tuser';
        newUser.CommunityNickname = 'testuser';
        newUser.TimeZoneSidKey = 'America/Los_Angeles';
        newUser.LocaleSidKey = 'en_US';
        newUser.EmailEncodingKey = 'UTF-8';
        newUser.ProfileId = testProfile.Id;
        newUser.LanguageLocaleKey = 'en_US';
        insert newUser;
        
        
        Account acc= new Account();
        acc.Name='Test Account';
   //     acc.Email__c='sample@asd.com';
        insert acc;
        
        Product__c prd=new Product__c();
        prd.Name='sample Product';
        prd.ProductCode__c='test1';
        insert prd;
        
        Order__c ord=new Order__c();
        ord.Order_Date__c= system.today();
        ord.Store__c = acc.id;
        ord.ownerId=newUser.id;
        insert ord;
        
        Order_Item__c orditem = new Order_Item__c();
        orditem.Product__c=prd.id;
        orditem.Order__c=ord.id;
        insert orditem;
        
        Order__c ords=new Order__c();
        
        ords.Store__c = acc.id;
        ords.ownerId=newUser.id;
        insert ords;
        system.debug('ords '+ords);
        list<string>abc= new list<string>();
        String expectedAccessToken1 = '{"access_token":"sampleAccessToken"}';
        String username = 'your_username';
        String password = 'your_password';
        Test.setMock(HttpCalloutMock.class, new FakeHttpResponseGenerator(expectedAccessToken1, 2000,'test'));
       
      postHandler.sendOrder(ord.Id);
  
       //  SAPIntegrationController.testMeth();
      
    }    */
}