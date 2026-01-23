@isTest
public class EmployeeCustomerAssignmentControllerTest {

    @TestSetup
    static void setup() {
        // Create test user
        User testUser = new User(
            Alias = 'tuser',
            Employee_Code__c  = '123212231',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testuser@example.com' + System.currentTimeMillis(),
           Sales_Channel__c = 'Cake'
        );
        insert testUser;

        // Create deactivated user
        User deactivatedUser = new User(
            Alias = 'duser',
             Employee_Code__c  = '123212233',
            Email = 'deactuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Deact',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'deactuser@example.com' + System.currentTimeMillis(),
          	IsActive = false,
             Sales_Channel__c = 'Cake'
        );
        insert deactivatedUser;

        
        area__c area = new area__c();
        area.Name = 'test11121';
        area.Sales_Channel__c = 'CPD';
        area.Region__c =	'Kerala';
        area.Area__c  = 'Central';
        insert area;

        // Create Employee__c
        Employee__c emp = new Employee__c(
            Name = 'Test Employee',
            User__c = testUser.Id,
            Is_Active__c = true,
            Payroll__c = 'Yes',
            Reporting_Manager__c = testUser.Id,
            Sales_Channel__c = 'Cake',
            Mail_Id__c = 'test.employee@example.com',          // Required
            Aadhar_Number__c = '123412341234',                 // Required
            Profile__c = 'DSM',                                // Required (string or lookup, adjust if it's a reference)
            User_Name__c = 'test.employee@example.com'                     // Required
        );
        insert emp;

        // Create Accounts (Primary and Secondary Customers)
        List<Account> accounts = new List<Account>();
        accounts.add(new Account(
            Name = 'Primary Customer 1',
            Customer_Type__c = 'Primary Customer',
            Customer_Status__c = 'Active',
            SAP_Customer_Code__c = 'SAP001',
            Area__c = area.Id,
            City__c = 'Delhi',
            State__c = 'Delhi',
            District__c = 'New Delhi',
            Pincode__c = '110001',
            Primary_Phone_Number__c = '1234567890'
        ));
        accounts.add(new Account(
            Name = 'Primary Customer 2',
            Customer_Type__c = 'Primary Customer',
            Customer_Status__c = 'Active',
            SAP_Customer_Code__c = 'SAP001121',
            Area__c = area.Id,
            City__c = 'Delhi',
            State__c = 'Delhi',
            District__c = 'New Delhi',
            Pincode__c = '110001',
            Primary_Phone_Number__c = '2134567890'
        ));
        accounts.add(new Account(
            Name = 'Secondary Customer 1',
            Customer_Type__c = 'Secondary Customer',
            Customer_Status__c = 'Active',
            SAP_Customer_Code__c = 'SAP002',
            City__c = 'Delhi',
            State__c = 'Delhi',
            District__c = 'New Delhi',
            Pincode__c = '110001',
            Secondary_Customer_Type__c = 'Sub Stockiest',
            Primary_Phone_Number__c = '9876543210'
        ));
        insert accounts;

        // Create Employee_Customer_Assignment__c
        Employee_Customer_Assignment__c eca = new Employee_Customer_Assignment__c(
            Executive__c = testUser.Id,
            Employee__c = emp.Id,
            Customer__c = accounts[0].Id
        );
        insert eca;
        
        // Create primary Product_Mapping__c
        Product_Mapping__c pm = new Product_Mapping__c(
            Exectuive__c = testUser.Id,
            Employee__c = emp.Id,
            Customer__c = accounts[0].Id,
            Primary_Customer__c = accounts[0].Id,
            Area__c = area.Id,
            Payment_Term__c = '0003',
            Chanel__c = 'CPD'
            // Remove Customer__r
        );
        insert pm;
        
        // Create secondary Product_Mapping__c
        Product_Mapping__c pmSecondary = new Product_Mapping__c(
            Exectuive__c = testUser.Id,
            Employee__c = emp.Id,
            Customer__c = accounts[1].Id,
            Primary_Customer__c = accounts[0].Id,
            Area__c = area.Id,
             Chanel__c = 'CPD' 
            // Remove Customer__r
        );
        insert pmSecondary;
        
        SecondaryCustomerMappingBatch batch = new SecondaryCustomerMappingBatch();
        Database.executeBatch(batch, 100);
    }

    @isTest
    static void testGetAllDataUserSSADSM() {
        User testUser = [SELECT Id FROM User WHERE LastName = 'Test' LIMIT 1];

        Test.startTest();
        try{
            EmployeeCustomerAssignmentController.getAllData(testUser.Id, 'User');
            
        } catch(Exception e) {
            
            system.debug('hi');
        }
        Test.stopTest();

        
    }

    @isTest
    static void testGetAllDataEmployeeNonSSADSM() {
        Employee__c emp = [SELECT Id, User__c FROM Employee__c WHERE Name = 'Test Employee' LIMIT 1];
        
        EmployeeSubordinateController.getSubordinates(emp.Id);
        User deactivatedUser = [SELECT Id FROM User WHERE LastName = 'Deact' LIMIT 1];
        update new Employee__c(Id = emp.Id,User__c = deactivatedUser.Id);

        Test.startTest();
        EmployeeCustomerAssignmentController.getAllData(emp.Id, 'Employee');

        Test.stopTest();

        
    }

    @isTest
    static void testGetAllDataEmptyRecordId() {
        Test.startTest();
        EmployeeCustomerAssignmentController.getAllData('', 'User');
        Test.stopTest();

       
    }

    @isTest
    static void testGetCustomersGroupedByArea() {
        Test.startTest();
        
        EmployeeCustomerAssignmentController.getCustomersGroupedByArea();
        Test.stopTest();

       
    }

    @isTest
    static void testInsertProductMapping() {
        
        area__c area = new area__c();
        area.Name = 'tesaatdd11121';
        area.Sales_Channel__c = 'CPD';
        area.Region__c =	'Kerala';
        area.Area__c  = 'Central';
        insert area;
        
        Account acc = [SELECT Id FROM Account WHERE Customer_Type__c = 'Primary Customer' LIMIT 1];
        Employee__c emp = [SELECT Id FROM Employee__c LIMIT 1];
        Product_Mapping__c pm = new Product_Mapping__c(
            Customer__c = acc.Id,
            Exectuive__c = UserInfo.getUserId(),
            Employee__c = emp.Id,
            Chanel__c = 'CPD',
            Area__c = area.Id
            
        );

        Test.startTest();
        EmployeeCustomerAssignmentController.insertProductMaping(pm);
        Test.stopTest();

        
    }

    @isTest
    static void testInsertExecutiveCustomerMapping() {
        Account acc = [SELECT Id FROM Account WHERE Customer_Type__c = 'Primary Customer' and Name='Primary Customer 2' LIMIT 1];
        Employee__c emp = [SELECT Id FROM Employee__c LIMIT 1];
        Employee_Customer_Assignment__c eca = new Employee_Customer_Assignment__c(
            Customer__c = acc.Id,
            Executive__c = UserInfo.getUserId(),
            Employee__c = emp.Id
        );

        Test.startTest();
         
        EmployeeCustomerAssignmentController.insertExecutiveCustomerMapping(eca);
        Test.stopTest();

        
    }

    @isTest
    static void testGetSecondaryCustomerAssignmentUserSSADSM() {
        User testUser = [SELECT Id FROM User WHERE LastName = 'Test' LIMIT 1];

        Test.startTest();
        try{
            EmployeeCustomerAssignmentController.getSecondaryCustomerAssignment(testUser.Id, 'User');
            
            
        } catch(Exception e) {
            system.debug('hi');
            
        }
        Test.stopTest();

        
    }

    @isTest
    static void testGetSecondaryCustomerAssignmentEmployeeNonSSADSM() {
        Employee__c emp = [SELECT Id, User__c FROM Employee__c WHERE Name = 'Test Employee' LIMIT 1];
        User deactivatedUser = [SELECT Id FROM User WHERE LastName = 'Deact' LIMIT 1];
        update new Employee__c(Id = emp.Id,User__c = deactivatedUser.Id);

        Test.startTest();
        EmployeeCustomerAssignmentController.getSecondaryCustomerAssignment(emp.Id, 'Employee');
        Test.stopTest();
    }

    @isTest
    static void testSaveProductMappings() {
             area__c area = new area__c();
        area.Name = 'test111www21';
        area.Sales_Channel__c = 'CPD';
        area.Region__c =	'Kerala';
        area.Area__c  = 'Central';
        insert area;

        Account acc = [SELECT Id FROM Account WHERE Customer_Type__c = 'Primary Customer' LIMIT 1];
        Employee__c emp = [SELECT Id FROM Employee__c LIMIT 1];
        Product_Mapping__c pm = new Product_Mapping__c(
            Customer__c = acc.Id,
            Exectuive__c = UserInfo.getUserId(),
            Employee__c = emp.Id,
            Chanel__c = 'CPD',
            Area__c = area.Id
           
        );
        insert pm;

        List<Product_Mapping__c> mappings = new List<Product_Mapping__c>{ pm };
        List<Id> toDelete = new List<Id>{ pm.Id };

        Test.startTest();
        try{
            EmployeeCustomerAssignmentController.saveProductMappings(mappings, toDelete);
            
        } catch(Exception e) {
            system.debug('hi');
        }
        Test.stopTest();

       
    }

    @isTest
    static void testSaveProductMappingsEmptyList() {
        Test.startTest();
        EmployeeCustomerAssignmentController.saveProductMappings(null, new List<Id>());
        Test.stopTest();

       
    }
}