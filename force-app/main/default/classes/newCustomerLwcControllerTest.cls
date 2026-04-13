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
    static void testGetInitialData() {
        Account testAccount = new Account(
            Name = 'Initial Data Account',
            SAP_Customer_Code__c = '88112233',
            Customer_Status__c = 'Active',
            Primary_Phone_Number__c = '9988776655',
            Customer_Type__c = 'Primary Customer',
            District__c = 'Kolar',
            State__c = 'Karnataka',
            Pincode__c = '60001'
        );
        insert testAccount;

        Test.startTest();
        newCustomerLwcController.DataBox db = newCustomerLwcController.getInitialData(testAccount.Id);
        Test.stopTest();

        // Heavy collections that the new method should NOT populate
        System.assertEquals(null, db.userList, 'userList should not be preloaded by getInitialData');
        System.assertEquals(null, db.primaryCustomerList, 'primaryCustomerList should not be preloaded by getInitialData');
        System.assert(db.executiveWiseAccounts == null || db.executiveWiseAccounts.isEmpty(), 'executiveWiseAccounts should be empty');
        System.assert(db.primaryToSubStockiestMap == null || db.primaryToSubStockiestMap.isEmpty(), 'primaryToSubStockiestMap should be empty');
        System.assert(db.executiveToSubStockiestIds == null || db.executiveToSubStockiestIds.isEmpty(), 'executiveToSubStockiestIds should be empty');

        // Lookups that should still come back
        System.assertNotEquals(null, db.parentDeportList);
        System.assertNotEquals(null, db.areaList);
        System.assertNotEquals(null, db.currentAccount);
    }

    @isTest
    static void testSearchExecutives() {
        User existing = [SELECT Id, Name, Employee_Code__c FROM User WHERE Employee_Code__c = '123sfgg212231' LIMIT 1];

        Test.startTest();
        // Match by employee code
        List<User> byCode = newCustomerLwcController.searchExecutives('123sfgg212231', false);
        // Match by name
        List<User> byName = newCustomerLwcController.searchExecutives(existing.Name, false);
        // Empty term short-circuits
        List<User> emptyTerm = newCustomerLwcController.searchExecutives('', false);
        // Primary flag excludes SSA/DSM users (existing test users have Is_SSA_DSM__c = false so still included)
        List<User> byCodePrimary = newCustomerLwcController.searchExecutives('123sfgg212231', true);
        Test.stopTest();

        System.assert(byCode != null, 'byCode result should not be null');
        System.assert(byName != null, 'byName result should not be null');
        System.assertEquals(0, emptyTerm.size(), 'Empty search term should return no users');
        System.assert(byCodePrimary != null, 'isPrimary search should run');
    }

    @isTest
    static void testSearchPrimaryCustomers() {
        User testUser = [SELECT Id FROM User WHERE Employee_Code__c = '123sfgg212231' LIMIT 1];

        Account primaryAcc = new Account(
            Name = 'Searchable Super Stockist',
            SAP_Customer_Code__c = 'SAP-9999',
            Customer_Status__c = 'Active',
            Customer_Type__c = 'Primary Customer',
            Primary_Customer_Type__c = 'Superstockiest',
            Primary_Phone_Number__c = '7000000001',
            District__c = 'Kolar',
            State__c = 'Karnataka',
            Pincode__c = '60001'
        );
        insert primaryAcc;

        Product_Mapping__c pm = new Product_Mapping__c(
            Customer__c = primaryAcc.Id,
            Exectuive__c = testUser.Id,
            Chanel__c = 'CPD',
            Parent_Depot__c = '1100',
            Child_Depot__c = '1100'
        );
        insert pm;

        Test.startTest();
        // Match by name
        List<Account> byName = newCustomerLwcController.searchPrimaryCustomers('Searchable', testUser.Id, false);
        // Match by SAP code
        List<Account> byCode = newCustomerLwcController.searchPrimaryCustomers('SAP-9999', testUser.Id, false);
        // Substockiest mode keeps it because the account is a Superstockiest
        List<Account> subMode = newCustomerLwcController.searchPrimaryCustomers('Searchable', testUser.Id, true);
        // Empty term and missing executive short-circuit
        List<Account> emptyTerm = newCustomerLwcController.searchPrimaryCustomers('', testUser.Id, false);
        List<Account> noExec = newCustomerLwcController.searchPrimaryCustomers('Searchable', null, false);
        Test.stopTest();

        System.assertEquals(1, byName.size(), 'Should find primary customer by name');
        System.assertEquals(1, byCode.size(), 'Should find primary customer by SAP code');
        System.assertEquals(1, subMode.size(), 'Superstockiest should still be found in sub-stockiest mode');
        System.assertEquals(0, emptyTerm.size(), 'Empty term returns empty list');
        System.assertEquals(0, noExec.size(), 'Null executive returns empty list');
    }

    @isTest
    static void testSearchSubstockiests() {
        User testUser = [SELECT Id FROM User WHERE Employee_Code__c = '123sfgg212231' LIMIT 1];

        Account primaryAcc = new Account(
            Name = 'Primary For Sub Search',
            Customer_Status__c = 'Active',
            Customer_Type__c = 'Primary Customer',
            Primary_Customer_Type__c = 'Superstockiest',
            Primary_Phone_Number__c = '7000000002',
            District__c = 'Kolar',
            State__c = 'Karnataka',
            Pincode__c = '60001'
        );
        insert primaryAcc;

        Account subAcc = new Account(
            Name = 'Searchable Sub Stockist',
            Customer_Code__c = 'SUB-001',
            Customer_Status__c = 'Active',
            Customer_Type__c = 'Secondary Customer',
            Secondary_Customer_Type__c = 'Sub Stockiest',
            Primary_Phone_Number__c = '7000000003',
            District__c = 'Kolar',
            State__c = 'Karnataka',
            Pincode__c = '60001'
        );
        insert subAcc;

        Product_Mapping__c subMapping = new Product_Mapping__c(
            Customer__c = subAcc.Id,
            Primary_Customer__c = primaryAcc.Id,
            Exectuive__c = testUser.Id,
            Chanel__c = 'CPD',
            Parent_Depot__c = '1100',
            Child_Depot__c = '1100'
        );
        insert subMapping;

        Test.startTest();
        List<Account> byName = newCustomerLwcController.searchSubstockiests('Searchable', primaryAcc.Id, testUser.Id);
        List<Account> byCode = newCustomerLwcController.searchSubstockiests('SUB-001', primaryAcc.Id, testUser.Id);
        List<Account> emptyTerm = newCustomerLwcController.searchSubstockiests('', primaryAcc.Id, testUser.Id);
        List<Account> noPrimary = newCustomerLwcController.searchSubstockiests('Searchable', null, testUser.Id);
        List<Account> noExec = newCustomerLwcController.searchSubstockiests('Searchable', primaryAcc.Id, null);
        Test.stopTest();

        System.assertEquals(1, byName.size(), 'Should find sub-stockiest by name');
        System.assertEquals(1, byCode.size(), 'Should find sub-stockiest by customer code');
        System.assertEquals(0, emptyTerm.size(), 'Empty term returns empty list');
        System.assertEquals(0, noPrimary.size(), 'Null primary returns empty list');
        System.assertEquals(0, noExec.size(), 'Null executive returns empty list');
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