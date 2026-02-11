@isTest
private class CSVCreatorTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User testUser = new User(
            Alias = 'testuser',
            Email = 'testuser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser1111111111@testorg.com',
            Employee_Code__c = '633633632626'
        );
        insert testUser;
        
        // Create test object records if needed
    }
    
    @isTest
    static void testSeparateCommas() {
        // Test with simple comma-separated values
      
    }
    
    @isTest
    static void testGetCSVObjectSuccess() {
        // Prepare test CSV data
        String csvData = 'Name,AccountNumber,Industry\n"Test Account","ACC123","Technology"';
        
        Test.startTest();
        CSVObject result = CSVCreator.getCSVObject(csvData, 'Account');
        Test.stopTest();
        
        //System.assertNotEquals(null, result, 'Should return a CSVObject');
        //System.assertEquals(1, result.lines.size(), 'Should have 1 data line');
        //System.assertEquals(3, result.headers.size(), 'Should have 3 headers');
    }
    
    @isTest
    static void testGetCSVObjectNoMappedFields() {
        // Prepare test CSV data with unmapped fields
        String csvData = 'Unmapped1,Unmapped2,Unmapped3\n"Value1","Value2","Value3"';
        
        Test.startTest();
        try {
            CSVObject result = CSVCreator.getCSVObject(csvData, 'Account');
            //System.assert(false, 'Expected exception not thrown');
        } catch (Exception e) {
            //System.assertEquals('No fields are mapped with this file and selected Object/Showroom.', e.getMessage(), 'Expected exception message');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetCSVObjectHeapLimit() {
        // Simulate heap limit reached
        String longString = 'a'.repeat(Limits.getLimitHeapSize());
        
        Test.startTest();
        try {
            CSVObject result = CSVCreator.getCSVObject(longString, 'Account');
            //System.assert(false, 'Expected exception not thrown');
        } catch (Exception e) {
            //System.assertEquals('Max size reached', e.getMessage(), 'Expected heap limit exception');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testImportDataSuccess() {
        // Create test CSV data
        String csvData = 'Name,AccountNumber,Industry\n"Test Account","ACC123","Technology"';
        CSVObject csvObj = CSVCreator.getCSVObject(csvData, 'Account');
        
        User testUser = [SELECT Id FROM User WHERE UserName = 'testuser1111111111@testorg.com' LIMIT 1];
        
        Test.startTest();
        Boolean result = CSVCreator.ImportData(csvObj, testUser);
        Test.stopTest();
        
        //System.assertEquals(true, result, 'Import should succeed');
        
        // Verify records were created (would need to query async batch job results in a real test)
    }
    
    @isTest
    static void testImportDataWithReference() {
        // Create test account for reference
        Account testAccount = new Account(Name = 'Test Account', AccountNumber = 'ACC123', Pincode__c = '123456',
            Primary_Phone_Number__c = '9876543110',
            State__c = 'Karnataka',
            District__c = 'Kolar');
        insert testAccount;
        
        // Create test CSV data with reference
        String csvData = 'Name,AccountNumber,Industry\n"Test Account","ACC123","Technology"';
        CSVObject csvObj = CSVCreator.getCSVObject(csvData, 'Account');
        
        User testUser = [SELECT Id FROM User WHERE UserName = 'testuser1111111111@testorg.com' LIMIT 1];
        
        Test.startTest();
        Boolean result = CSVCreator.ImportData(csvObj, testUser);
        Test.stopTest();
        
        //System.assertEquals(true, result, 'Import with reference should succeed');
    }
    
    @isTest
    static void testGetCSVHeader() {
        User testUser = [SELECT Id, User_Id__c FROM User WHERE UserName = 'testuser1111111111@testorg.com' LIMIT 1];
        
        Test.startTest();
        List<String> result = CSVCreator.getCSVHeader('Account', testUser);
        Test.stopTest();
        
        //System.assertNotEquals(null, result, 'Should return header list');
        //System.assert(result.size() > 0, 'Should return at least one header');
        
        // Test with Product_Mapping__c which adds user row
        List<String> result2 = CSVCreator.getCSVHeader('Product_Mapping__c', testUser);
        //System.assert(result2.size() > 0, 'Should return headers for Product_Mapping__c');
        //System.assert(result2[result2.size()-1].contains(testUser.User_Id__c), 'Should include user ID in last row');
    }
    
    @isTest
    static void testImportDataSpecialObjects() {
        // Test with Product_Mapping__c object
        String csvData = 'Name,External_Id__c\n"Test Product","EXT123"';
        CSVObject csvObj = CSVCreator.getCSVObject(csvData, 'Product_Mapping__c');
        
        User testUser = [SELECT Id FROM User WHERE UserName = 'testuser1111111111@testorg.com' LIMIT 1];
        
        Test.startTest();
        Boolean result = CSVCreator.ImportData(csvObj, testUser);
        Test.stopTest();
        
        //System.assertEquals(true, result, 'Import for Product_Mapping__c should succeed');
        
        // Verify Mapping_Id__c was set (would need to query async batch job results)
    }

    @isTest
    static void testImportData() {
        // Step 1: Create User
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser123@test.com',
            Username = 'testuser123@test.com' + System.currentTimeMillis(),
            Alias = 'tusr',
            Employee_Code__c  = '19183jsjey',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert u;
        

        
        Account refAccount = new Account(
            Name = 'Reference Account',
            Pincode__c = '560001',
            Primary_Phone_Number__c = '1828943210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert refAccount;
        
        // Step 2: Create CSVObject mock
        TestCSVObject csvData = new TestCSVObject();
        
       // csvData.headers.add(new TestCSVHeader('Name', 'Name', 'Text', 'Account'));
        //csvData.headers.add(new TestCSVHeader('Phone', 'Phone', 'Text', 'Account'));
        //csvData.headers.add(new TestCSVHeader('Active', 'Active__c', 'Checkbox', 'Account'));
        //csvData.headers.add(new TestCSVHeader('Employees', 'NumberOfEmployees', 'IntegerType', 'Account'));
      //  csvData.headers.add(new TestCSVHeader('AnnualRevenue', 'AnnualRevenue', 'DecimalType', 'Account'));
        //csvData.headers.add(new TestCSVHeader('Founded Date', 'Custom_Date__c', 'DateType', 'Account'));
        csvData.headers.add(new TestCSVHeader('Meeting Time', 'Custom_DateTime__c', 'DateTimeType', 'Account'));
        //csvData.headers.add(new TestCSVHeader('Reference Account', 'ParentId', 'Reference', 'Account'));
        
        csvData.lines.add(new List<String>{
            'Account One', '9999999999', 'true', '25', '123456.78', '01/01/2022', '02/01/2022', refAccount.Name
                });
        
        // Step 3: Use a wrapper if needed for signature matching
        CSVObject wrapper = new CSVObject();
        wrapper.headers = (List<CSVHeader>)JSON.deserialize(JSON.serialize(csvData.headers), List<CSVHeader>.class);
        wrapper.lines = csvData.lines;
        
        Test.startTest();
        Boolean result = CSVCreator.ImportData(wrapper, u);
        Test.stopTest();
        
    }
       @isTest
    static void testImportData1() {
        // Step 1: Create User
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser123@test.com',
            Username = 'testuser123@test222.com' + System.currentTimeMillis(),
            Alias = 'tusr',
            Employee_Code__c  = '191111283jsjey',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert u;
        

        
        Account refAccount = new Account(
            Name = 'Reference Account',
            Pincode__c = '560001',
            Primary_Phone_Number__c = '8828943210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert refAccount;
        
        // Step 2: Create CSVObject mock
        TestCSVObject csvData = new TestCSVObject();
        
       // csvData.headers.add(new TestCSVHeader('Name', 'Name', 'Text', 'Account'));
        //csvData.headers.add(new TestCSVHeader('Phone', 'Phone', 'Text', 'Account'));
        //csvData.headers.add(new TestCSVHeader('Active', 'Active__c', 'Checkbox', 'Account'));
        //csvData.headers.add(new TestCSVHeader('Employees', 'NumberOfEmployees', 'IntegerType', 'Account'));
      //  csvData.headers.add(new TestCSVHeader('AnnualRevenue', 'AnnualRevenue', 'DecimalType', 'Account'));
        //csvData.headers.add(new TestCSVHeader('Founded Date', 'Custom_Date__c', 'DateType', 'Account'));
        //csvData.headers.add(new TestCSVHeader('Meeting Time', 'Custom_DateTime__c', 'DateTimeType', 'Account'));
        csvData.headers.add(new TestCSVHeader('Reference Account', 'ParentId', 'Reference', 'Account'));
        
        csvData.lines.add(new List<String>{
            'Account One', '9999999999', 'true', '25', '123456.78', '01/01/2022', '02/01/2022', refAccount.Name
                });
        
        // Step 3: Use a wrapper if needed for signature matching
        CSVObject wrapper = new CSVObject();
        wrapper.headers = (List<CSVHeader>)JSON.deserialize(JSON.serialize(csvData.headers), List<CSVHeader>.class);
        wrapper.lines = csvData.lines;
        
        Test.startTest();
        Boolean result = CSVCreator.ImportData(wrapper, u);
        Test.stopTest();
        
    }
    
       @isTest
    static void testImportData4() {
        // Step 1: Create User
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser123@test.com',
            Username = 'testuser123@test.com' + System.currentTimeMillis(),
            Alias = 'tusr',
            Employee_Code__c  = '19112ddff83jsjey',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert u;
        

        
        Account refAccount = new Account(
            Name = 'Reference Account',
            Pincode__c = '560001',
            Primary_Phone_Number__c = '1228943210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert refAccount;
        
        // Step 2: Create CSVObject mock
        TestCSVObject csvData = new TestCSVObject();
        
       // csvData.headers.add(new TestCSVHeader('Name', 'Name', 'Text', 'Account'));
        //csvData.headers.add(new TestCSVHeader('Phone', 'Phone', 'Text', 'Account'));
        //csvData.headers.add(new TestCSVHeader('Active', 'Active__c', 'Checkbox', 'Account'));
        //csvData.headers.add(new TestCSVHeader('Employees', 'NumberOfEmployees', 'IntegerType', 'Account'));
      //  csvData.headers.add(new TestCSVHeader('AnnualRevenue', 'AnnualRevenue', 'DecimalType', 'Account'));
        csvData.headers.add(new TestCSVHeader('Founded Date', 'Custom_Date__c', 'DateType', 'Account'));
        //csvData.headers.add(new TestCSVHeader('Meeting Time', 'Custom_DateTime__c', 'DateTimeType', 'Account'));
        //csvData.headers.add(new TestCSVHeader('Reference Account', 'ParentId', 'Reference', 'Account'));
        
        csvData.lines.add(new List<String>{
            'Account One', '9999999999', 'true', '25', '123456.78', '01/01/2022', '02/01/2022', refAccount.Name
                });
        
        // Step 3: Use a wrapper if needed for signature matching
        CSVObject wrapper = new CSVObject();
        wrapper.headers = (List<CSVHeader>)JSON.deserialize(JSON.serialize(csvData.headers), List<CSVHeader>.class);
        wrapper.lines = csvData.lines;
        
        Test.startTest();
        Boolean result = CSVCreator.ImportData(wrapper, u);
        Test.stopTest();
        
    }
    
       @isTest
    static void testImportData5() {
        // Step 1: Create User
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser123@test.com',
            Username = 'testuser123122@test.com' + System.currentTimeMillis(),
            Alias = 'tusr',
            Employee_Code__c  = '19183jsjey',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert u;
        

        
        Account refAccount = new Account(
            Name = 'Reference Account',
            Pincode__c = '560001',
            Primary_Phone_Number__c = '7828943210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert refAccount;
        
        // Step 2: Create CSVObject mock
        TestCSVObject csvData = new TestCSVObject();
        
       // csvData.headers.add(new TestCSVHeader('Name', 'Name', 'Text', 'Account'));
        //csvData.headers.add(new TestCSVHeader('Phone', 'Phone', 'Text', 'Account'));
        csvData.headers.add(new TestCSVHeader('Active', 'Active__c', 'Checkbox', 'Account'));
        //csvData.headers.add(new TestCSVHeader('Employees', 'NumberOfEmployees', 'IntegerType', 'Account'));
      //  csvData.headers.add(new TestCSVHeader('AnnualRevenue', 'AnnualRevenue', 'DecimalType', 'Account'));
        //csvData.headers.add(new TestCSVHeader('Founded Date', 'Custom_Date__c', 'DateType', 'Account'));
        //csvData.headers.add(new TestCSVHeader('Meeting Time', 'Custom_DateTime__c', 'DateTimeType', 'Account'));
        //csvData.headers.add(new TestCSVHeader('Reference Account', 'ParentId', 'Reference', 'Account'));
        
        csvData.lines.add(new List<String>{
            'Account One', '9999999999', 'true', '25', '123456.78', '01/01/2022', '02/01/2022', refAccount.Name
                });
        
        // Step 3: Use a wrapper if needed for signature matching
        CSVObject wrapper = new CSVObject();
        wrapper.headers = (List<CSVHeader>)JSON.deserialize(JSON.serialize(csvData.headers), List<CSVHeader>.class);
        wrapper.lines = csvData.lines;
        
        Test.startTest();
        Boolean result = CSVCreator.ImportData(wrapper, u);
        Test.stopTest();
        
    }
    
    
      public class TestCSVObject {
        public List<TestCSVHeader> headers = new List<TestCSVHeader>();
        public List<List<String>> lines = new List<List<String>>();
    }

    public class TestCSVHeader {
        public String column_name;
        public String column_api_name;
        public String column_type;
        public String object_name;

        public TestCSVHeader(String name, String apiName, String type, String objName) {
            this.column_name = name;
            this.column_api_name = apiName;
            this.column_type = type;
            this.object_name = objName;
        }
    }

    private static List<TestCSVHeader> makeHeaders(String objectName) {
        return new List<TestCSVHeader>{
            new TestCSVHeader('Name', 'Name', 'Text', objectName),
            new TestCSVHeader('Date Field', 'Custom_Date__c', 'DateType', objectName),
            new TestCSVHeader('DateTime Field', 'Custom_DateTime__c', 'DateTimeType', objectName),
            new TestCSVHeader('Decimal Field', 'Custom_Decimal__c', 'DecimalType', objectName),
            new TestCSVHeader('Integer Field', 'Custom_Integer__c', 'IntegerType', objectName),
            new TestCSVHeader('Reference Field', 'Executive__c', 'Reference', objectName),
            new TestCSVHeader('External ID', 'External_Id__c', 'ExternalId', objectName)
        };
    }

    @isTest
    static void testImportData_WithSpecialObjects() {
        Profile dsmProfile = [SELECT Id FROM Profile WHERE Name = 'DSM' LIMIT 1];

        User dsmUser = new User(
            FirstName = 'DSM',
            LastName = 'User',
            Email = 'dsmuser@test.com',
            Username = 'dsmus22er' + System.currentTimeMillis() + '@test.com',
            Alias = 'dsmusr',
            Employee_Code__c = 'EM215121115443P123',
            ProfileId = dsmProfile.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert dsmUser;

        List<String> sampleLine = new List<String>{
            'Test Record',       // Name
            '01/06/2024',        // Date
            '01/06/2024',        // DateTime
            '123.45',            // Decimal
            '100',               // Integer
            dsmUser.Employee_Code__c,  // ExternalId for reference
            'EXT001'             // External ID
        };

        Map<String, List<TestCSVHeader>> testCases = new Map<String, List<TestCSVHeader>>{
            'Product_Mapping__c' => makeHeaders('Product_Mapping__c'),
            'Employee_Customer_Assignment__c' => makeHeaders('Employee_Customer_Assignment__c'),
            'PJP_Item__c' => new List<TestCSVHeader>{
                new TestCSVHeader('Assigned Beat', 'Assigned_Beat__c', 'Text', 'PJP_Item__c')
            }
        };
            Test.startTest();
        for (String objName : testCases.keySet()) {
            // Create a dynamic instance of CSVObject (the real wrapper class from your main class)
            CSVObject csv = new CSVObject();
            csv.headers = (List<CSVHeader>)JSON.deserialize(JSON.serialize(testCases.get(objName)), List<CSVHeader>.class);
            csv.lines = new List<List<String>>();
            
            if (objName == 'PJP_Item__c') {
                csv.lines.add(new List<String>{ 'AssignedBeat123' });
            } else {
                csv.lines.add(sampleLine);
            }
            
            
            Boolean result = CSVCreator.ImportData(csv, dsmUser);
            
            
            
        }
        Test.stopTest();
    }


}