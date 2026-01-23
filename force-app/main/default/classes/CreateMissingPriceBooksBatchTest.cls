@isTest
private class CreateMissingPriceBooksBatchTest {
    
    @testSetup
    static void setupTestData() {
        // Create test accounts
       List<Account> testAccounts = new List<Account>{
            new Account(
                Name = 'Primary Cust',
                City__c = 'Delhi',
                State__c = 'Delhi',
                District__c = 'New Delhi',
                Primary_Phone_Number__c = '9999999999',
                Aadhaar_No__c = '123412341234',
                Pincode__c = '110001',
                Customer_Type__c = 'Primary Customer',
                Customer_Status__c = 'Active',
                GeoLocation__Latitude__s =  28.6139,
                GeoLocation__Longitude__s = 77.2090,
                Secondary_Customer_Category__c = 'TN_Elite Club',
                Secondary_Customer_Type__c = 'Retailer',
                Approval_Status__c = 'Credit Dept. Approved',
                Email_ID__c = 'test@gmail.com',
                 SAP_Customer_Code__c ='19810121',
                Sales_Channel__c = 'TS'
              
                
            ),
            new Account(
                Name = 'Secondary Cust',
                City__c = 'Mumbai',
                State__c = 'Andhra Pradesh',
                District__c = 'East Godavari',
                Primary_Phone_Number__c = '8888888888',
                Aadhaar_No__c = '567856785678',
                Pincode__c = '575444',
                Customer_Type__c = 'Secondary Customer',
                Customer_Status__c = 'Active',
                Email_ID__c = 'test@gmail.com',
                SAP_Customer_Code__c ='198101',
                Sales_Channel__c = 'TS'
            )
        };
        insert testAccounts;
        
        // Create test products (SKUs)
        List<Product__c> testProducts = new List<Product__c>();
        for(Integer i = 0; i < 3; i++) {
            testProducts.add(new Product__c(
                Name = 'Test SKU ' + i,
                List_Price__c = 100 + (i * 50),
                MRP__c = 120 + (i * 60),
                SKU_Code__c = 'TEYED899933333333'+i
            ));
        }
        insert testProducts;
        
        // Create Sales Channel to SKU mappings
        List<Sales_Channel_To_SKU__c> channelSKUs = new List<Sales_Channel_To_SKU__c>();
        for(Product__c prod : testProducts) {
            channelSKUs.add(new Sales_Channel_To_SKU__c(
                Sales_Channel__c = 'TS',
                SKU__c = prod.Id
            ));
        }
        insert channelSKUs;
        
        // Create some existing Price Books for first account
        List<Price_Book__c> existingPriceBooks = new List<Price_Book__c>();
        existingPriceBooks.add(new Price_Book__c(
            Customer__c = testAccounts[0].Id,
            Product__c = testProducts[0].Id,
            Customer_Type__c = 'Primary Customer',
            Unit_Price__c = testProducts[0].List_Price__c,
            MRP__c = testProducts[0].MRP__c
        ));
        insert existingPriceBooks;
    }
    
    @isTest
    static void testBatchStartMethod() {
        Test.startTest();
        CreateMissingPriceBooksBatch batch = new CreateMissingPriceBooksBatch();
        Database.QueryLocator ql = batch.start(null);
        Test.stopTest();
        
    }
    
    @isTest
    static void testBatchExecuteMethod() {
        List<Account> testAccounts = [SELECT Id FROM Account WHERE Sales_Channel__c LIKE '%TS%'];
        List<Product2> testProducts = [SELECT Id FROM Product2];
        List<Price_Book__c> existingPriceBooks = [SELECT Id FROM Price_Book__c];
        
        Test.startTest();
        CreateMissingPriceBooksBatch batch = new CreateMissingPriceBooksBatch();
        Database.executeBatch(batch, 10);
        Test.stopTest();
        
    }
    
    @isTest
    static void testBatchExecuteWithEmptyScope() {
        // Delete all TN accounts to test empty scope
        delete [SELECT Id FROM Account WHERE Sales_Channel__c LIKE '%TN%'];
        
        Test.startTest();
        CreateMissingPriceBooksBatch batch = new CreateMissingPriceBooksBatch();
        Database.executeBatch(batch, 10);
        Test.stopTest();
      
    }
    
    @isTest
    static void testBatchExecuteWithNoChannelSKUs() {
        // Delete all channel SKUs
        delete [SELECT Id FROM Sales_Channel_To_SKU__c];
        
        Test.startTest();
        CreateMissingPriceBooksBatch batch = new CreateMissingPriceBooksBatch();
        Database.executeBatch(batch, 10);
        Test.stopTest();
       
    }
    
    @isTest
    static void testBatchFinishMethod() {
        // Mock the email sending
        Test.startTest();
        CreateMissingPriceBooksBatch batch = new CreateMissingPriceBooksBatch();
        batch.totalRecordsProcessed = 5;
        batch.totalRecordsCreated = 14;
        batch.totalErrors = 0;
        batch.finish(null);
        Test.stopTest();
       
    }
    
   
}