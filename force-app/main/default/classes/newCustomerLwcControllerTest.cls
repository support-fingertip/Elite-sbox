@isTest
public class newCustomerLwcControllerTest {
    
     
    @TestSetup
    static void setup() {
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        UserRole testRole = [SELECT Id FROM UserRole LIMIT 1];
        // Create test users
        User testUser1 = new User(
            Alias = 'tuser',
            Employee_Code__c  = '123sfgg212231',
            Email = 'testusersss@example.com',
            EmailEncodingKey = 'UTF-8',
            userroleId = testRole.Id,
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testuser@example.com' + System.currentTimeMillis(),
            Sales_Channel__c = 'Cake'
        );
        insert testUser1;
        User testUser2 = new User(
            Alias = 'tuser12',
            Employee_Code__c  = '1232122DDD343',
            Email = 'testuser@example.com',
            userroleId = testRole.Id,
            ManagerId = testUser1.Id,
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testuser@example.com' + System.currentTimeMillis(),
            Sales_Channel__c = 'Cake'
        );
        insert testUser2 ;
        
        
        
    }
    
    @isTest
    static void testGetAllData() {
        // Setup test data
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser  = new User(
            Username = 'lalatest@example.com',
            Email = 'lalatest@example.com',
            Alias = 'tuser',
            Employee_Code__c = '112009911',
            ProfileId = profile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LastName = 'lala',
            Sales_Channel__c = 'Cake',
            IsActive = true
        );
        insert testUser ;

        Account testAccount = new Account(Name = 'Test Account',SAP_Customer_Code__c='1919101', Customer_Status__c = 'Active',Primary_Phone_Number__c = '1234567890', Customer_Type__c = 'Primary Customer',District__c = 'Kolar',State__c= 'Karnataka',Pincode__c = '60001');
        insert testAccount;

        RecordType recordType = new RecordType(
            Name = 'Primary Customer',
            SObjectType = 'Account'
          
        );
       

        // Call the method
        Test.startTest();
       	newCustomerLwcController.getAllData(testAccount.Id);
        Test.stopTest();

       
    }

    @isTest
    static void testGetAvailableRecordTypes() {
        Test.startTest();
        newCustomerLwcController.getAvailableRecordTypes();
        Test.stopTest();

        
    }


    @isTest
    static void testSendOtp() {
        Test.startTest();
        newCustomerLwcController.sendOtp('1234567890', '123456');
        Test.stopTest();

        
    }

    @isTest
    static void testValidateFileUpload() {
        Test.startTest();
       newCustomerLwcController.validateFileUpload('uniqueFileId', 'Primary Customer', false);
        Test.stopTest();

       
    }

    @isTest
    static void testDuplicationCheck() {
        // Setup test data
        Account testAccount = new Account(Name = 'Test Account', Primary_Phone_Number__c = '1234567890', Customer_Type__c = 'Primary Customer',District__c = 'Kolar',State__c= 'Karnataka',Pincode__c = '60001');
        insert testAccount;

        // Call the method
        Test.startTest();
        newCustomerLwcController.dupicationCheck(testAccount);
        Test.stopTest();

       
    }

    @isTest
    static void testSaveData() {
        // Setup test data
        Account testAccount = new Account(
            Name = 'Test Account',
            Customer_Status__c = 'Active',
            Primary_Phone_Number__c = '1234567890',
            Customer_Type__c = 'Primary Customer',
            District__c = 'Kolar',
            State__c = 'Karnataka',
            Pincode__c = '60001'
        );
        
        
        
        
        // Assertions to verify the account was saved and product mappings were created
        //  System.assertNotEquals(null, accountId, 'Account ID should not be null');//
        //System.assertEquals(1, [SELECT COUNT() FROM Product_Mapping__c WHERE Customer__c = :accountId]);
    }

    @isTest
    static void testSaveProductData() {
        
        
        user testUser = [select Id,Name from User where Employee_Code__C = '123sfgg212231' limit 1];   
        
        area__c tr = new area__c();
        tr.Name = 'test';
        tr.Sales_Channel__c = 'CPD';
        tr.Region__c =	'Kerala';
        tr.Area__c  = 'Central';
        insert tr; 
        
        Account acc2 = new Account(
            Name = 'Primary Customer',
            OwnerId = testUser.Id,
            Customer_Type__c = 'Primary Customer', 
            Pincode__c = '123456',
            Primary_Phone_Number__c = '2276543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert acc2;
        
                
        Account acc3 = new Account(
            Name = 'Primary Customer',
            OwnerId = testUser.Id,
            Customer_Type__c = 'Secondary Customer',
            Pincode__c = '123456',
            Primary_Phone_Number__c = '2276543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        
        Product_Mapping__c pm = new   Product_Mapping__c();
        pm.Customer__c = acc2.Id;
        pm.Chanel__c = 'CPD';
        pm.Parent_Depot__c ='1100';
        pm.Area__c = tr.Id;
        pm.Child_Depot__c ='1100';
        pm.Payment_Term__c = '0003';
        pm.Exectuive__c = testUser.Id;
        insert pm;   
        
                
        Product_Mapping__c newPm = new   Product_Mapping__c();
        //newPm.Customer__c = acc2.Id;
        newPm.Primary_Customer__c = acc2.Id;
        newPm.Chanel__c = 'CPD';
        newPm.Parent_Depot__c ='1100';
        newPm.Area__c = tr.Id;
        newPm.Child_Depot__c ='1100';
        newPm.Payment_Term__c = '0003';
        newPm.Exectuive__c = testUser.Id;
       // insert newPm;
        
        // Create a new Product_Mapping__c record for insertion
        List<Product_Mapping__c> productMappings = new List<Product_Mapping__c>();
                    productMappings.add(newPm);
                    List<String> deleteProductMappingList = new List<String>{pm.Id};
            
            Test.startTest();
          String accountId = newCustomerLwcController.saveData(acc3, productMappings);
        MappingHelper.saveAutoMappingData(acc3, productMappings);
        //newCustomerLwcController.saveData(, List<Product_Mapping__c>{newPm});
        
        //newCustomerLwcController.saveProductData(new List<Product_Mapping__c>{newPm}, deleteProductMappingList);
        Test.stopTest();
        
        // Verify that the original record has been deleted
        //System.assertEquals(0, [SELECT COUNT() FROM Product_Mapping__c WHERE Id = :pm.Id]);
        
        // Verify that the new record has been inserted
        //System.assertEquals(1, [SELECT COUNT() FROM Product_Mapping__c WHERE Parent_Depot__c = '1400']);
    }

    @isTest
    static void testGetDependentMap() {
        
        
        user testUser = [select Id,Name from User where Employee_Code__C = '123sfgg212231' limit 1];   
        
        area__c tr = new area__c();
        tr.Name = 'test';
        tr.Sales_Channel__c = 'CPD';
        tr.Region__c =	'Kerala';
        tr.Area__c  = 'Central';
        insert tr; 
        
        Account acc2 = new Account(
            Name = 'Primary Customer',
            OwnerId = testUser.Id,
            Customer_Type__c = 'Primary Customer',
            Pincode__c = '123456',
            Primary_Phone_Number__c = '2276543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert acc2;
        
        
        // Setup test data
        Product_Mapping__c newPm = new   Product_Mapping__c();
        newPm.Customer__c = acc2.Id;
        newPm.Chanel__c = 'CPD';
        newPm.Parent_Depot__c ='1100';
        newPm.Area__c = tr.Id;
        newPm.Child_Depot__c ='1100';
        newPm.Payment_Term__c = '0003';
        newPm.Exectuive__c = testUser.Id;
        insert newPm;
        
        
        Test.startTest();
        Map<String, Map<String, String>> result = newCustomerLwcController.getDependentMap(newPm, 'Parent_Depot__c', 'Child_Depot__c');
        Test.stopTest();

        // Assertions
       // System.assertNotEquals(null, result);
    }

    @isTest
    static void testExtractPicklistValues() {
        Test.startTest();
       	List<Map<String, String>> res = newCustomerLwcController.extractPicklistValues('Product_Mapping__c', 'Parent_Depot__c');
        System.assertNotEquals(null, res);
        Test.stopTest();

      
    }
}