@isTest
public class EmployeeCustomerTriggerHandlerTest {
    @TestSetup
    static void setup() {
        // Create test users
        User testUser1 = new User(
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
        User testUser2 = new User(
           Alias = 'tuser12',
            Employee_Code__c  = '1232122343',
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
        insert new List<User>{ testUser1, testUser2 };
            
             // Create Area__c
        Area__c area = new Area__c(Name = 'Test Area', Sales_Channel__c = 'Cake',Region__c ='Kerala');
        insert area;

        // Create test accounts
        Account acc1 = new Account( Name = 'Primary Customer 1',
            Customer_Type__c = 'Primary Customer',
            Customer_Status__c = 'Active',
            SAP_Customer_Code__c = 'SAP001',
            Area__c = area.Id,
            City__c = 'Delhi',
            State__c = 'Delhi',
            District__c = 'New Delhi',
            Pincode__c = '110001',
            Primary_Phone_Number__c = '1234567890');
        Account acc2 = new Account(   Name = 'Secondary Customer 1',
            Customer_Type__c = 'Secondary Customer',
            Customer_Status__c = 'Active',
            SAP_Customer_Code__c = 'SAP002',
            City__c = 'Delhi',
            State__c = 'Delhi',
            District__c = 'New Delhi',
            Pincode__c = '110001',
            Secondary_Customer_Type__c = 'Sub Stockiest',
            Primary_Phone_Number__c = '9876543210');
        insert new List<Account>{ acc1, acc2 };

        // Create Employee_Customer_Assignment__c records
        Employee_Customer_Assignment__c eca1 = new Employee_Customer_Assignment__c(
            Customer__c = acc1.Id,
            Executive__c = testUser1.Id
        );
        
     
        
        Employee_Customer_Assignment__c eca2 = new Employee_Customer_Assignment__c(
            Customer__c = acc2.Id,
            Executive__c = testUser2.Id
        );
        insert new List<Employee_Customer_Assignment__c>{ eca1, eca2 };
            
            Product_Mapping__c pm = new   Product_Mapping__c();
        pm.Customer__c = acc2.Id;
        pm.Payment_Term__c = '0003';
        pm.Chanel__c = 'CPD';
        pm.Exectuive__c = testUser1.Id;
        pm.Area__c = area.Id;
        pm.Primary_Customer__c = acc1.Id;
        insert pm;
    }

    @isTest
    static void testAfterInsertValidAssignments() {
        // Prepare test data
        Account acc = [SELECT Id FROM Account WHERE Name = 'Primary Customer 1' LIMIT 1];
        User user = [SELECT Id FROM User WHERE LastName = 'Test' LIMIT 1];
        Employee_Customer_Assignment__c eca = new Employee_Customer_Assignment__c(
            Customer__c = acc.Id,
            Executive__c = user.Id
        );

        Test.startTest();
        EmployeeCustomerAssignmentTriggerHandler.afterInsert(new List<Employee_Customer_Assignment__c>{ eca });
        Test.stopTest();

       
    }

    @isTest
    static void testAfterInsertNullFields() {
        // Prepare test data with null fields
        Employee_Customer_Assignment__c eca = new Employee_Customer_Assignment__c(
            Customer__c = null,
            Executive__c = null
        );

        Test.startTest();
        EmployeeCustomerAssignmentTriggerHandler.afterInsert(new List<Employee_Customer_Assignment__c>{ eca });
        Test.stopTest();

        
    }

    @isTest
    static void testAfterInsertEmptyList() {
        Test.startTest();
        EmployeeCustomerAssignmentTriggerHandler.afterInsert(new List<Employee_Customer_Assignment__c>());
        Test.stopTest();

       
    }

    @isTest
    static void testAfterUpdateChangeCustomer() {
        // Prepare test data
        Employee_Customer_Assignment__c eca = [SELECT Id, Customer__c, Executive__c 
                                              FROM Employee_Customer_Assignment__c 
                                              WHERE Customer__r.Name = 'Primary Customer 1' LIMIT 1];
        Account newAcc = [SELECT Id FROM Account WHERE Name = 'Secondary Customer 1' LIMIT 1];
        Map<Id, Employee_Customer_Assignment__c> oldMap = new Map<Id, Employee_Customer_Assignment__c>{
            eca.Id => new Employee_Customer_Assignment__c(
                Id = eca.Id,
                Customer__c = eca.Customer__c,
                Executive__c = eca.Executive__c
            )
        };
        eca.Customer__c = newAcc.Id;

        Test.startTest();
        EmployeeCustomerAssignmentTriggerHandler.afterUpdate(new List<Employee_Customer_Assignment__c>{ eca }, oldMap);
        Test.stopTest();

        
    }

    @isTest
    static void testAfterUpdateNoChanges() {
        // Prepare test data
        Employee_Customer_Assignment__c eca = [SELECT Id, Customer__c, Executive__c 
                                              FROM Employee_Customer_Assignment__c 
                                              WHERE Customer__r.Name = 'Primary Customer 1' LIMIT 1];
        list<Account> lstacc=  [select Id from account limit 1];
        Employee_Customer_Assignment__c emp = new Employee_Customer_Assignment__c(
            Id = eca.Id,
            Customer__c =  lstacc[0].Id
        );

		update emp;

       
    }

    @isTest
    static void testAfterDelete() {
        // Prepare test data
        Employee_Customer_Assignment__c eca = [SELECT Id, Customer__c, Executive__c 
                                              FROM Employee_Customer_Assignment__c 
                                              WHERE Customer__r.Name = 'Primary Customer 1' LIMIT 1];
        

        Test.startTest();
       // EmployeeCustomerAssignmentTriggerHandler.afterDelete(new List<Employee_Customer_Assignment__c>{ eca });
        Test.stopTest();

       
    }

    @isTest
    static void testAfterDeleteNullFields() {
        // Prepare test data with null fields
        Employee_Customer_Assignment__c eca = new Employee_Customer_Assignment__c(
            Customer__c = null,
            Executive__c = null
        );

        Test.startTest();
      //  EmployeeCustomerAssignmentTriggerHandler.afterDelete(new List<Employee_Customer_Assignment__c>{ eca });
        Test.stopTest();

       
    }

    @isTest
    static void testAfterDeleteEmptyList() {
        Test.startTest();
       // EmployeeCustomerAssignmentTriggerHandler.afterDelete(new List<Employee_Customer_Assignment__c>());
        Test.stopTest();

        
    }
}