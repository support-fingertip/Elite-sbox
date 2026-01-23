@isTest
public class EmployeeCustomerAssignmentTriggerTest {
    
    @TestSetup
    static void setup() {
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        UserRole testRole = [SELECT Id FROM UserRole LIMIT 1];
        // Create test users
        User testUser1 = new User(
            Alias = 'tuser',
            Employee_Code__c  = '123212231',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            userroleId = testRole.Id,
            LastName = 'Test',
            isActive=true,
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'TSE' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testuser@example.com' + System.currentTimeMillis(),
            Sales_Channel__c = 'Cake'
        );
        insert testUser1;
        User testUser2 = new User(
            Alias = 'tuser12',
            Employee_Code__c  = '1232122343',
            Email = 'testuser@example.com',
            userroleId = testRole.Id,
            ManagerId = testUser1.Id,
            isActive=true,
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'TSE' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testuser@example.com' + System.currentTimeMillis(),
            Sales_Channel__c = 'Cake'
        );
        insert testUser2 ;
        
        
        
    }
    
    @isTest
    static void testAfterInsert() {
        // Create test accounts
        Account acc1 = new Account(Name = 'Primary Customer 1',
                                   Customer_Type__c = 'Primary Customer',
                                   Customer_Status__c = 'Active',
                                   SAP_Customer_Code__c = 'SAP0012233',
                                   
                                   City__c = 'Delhi',
                                   State__c = 'Delhi',
                                   District__c = 'New Delhi',
                                   Pincode__c = '110001',
                                   Primary_Phone_Number__c = '1234567890');
        insert acc1;
        // Prepare test data
        User user = [SELECT Id FROM User WHERE LastName = 'Test' and isActive= true LIMIT 1];
        Employee_Customer_Assignment__c eca = new Employee_Customer_Assignment__c(
            Customer__c = acc1.Id,
            Executive__c = user.Id
        );
        
        Test.startTest();
        insert eca;
        Test.stopTest();
        
        
    }
    
    
    @isTest
    static void testAfterInsertBulk() {
        // Prepare bulk test data
        
        
        Account acc1 = new Account(Name = 'Primary Customer 1',
                                   Customer_Type__c = 'Primary Customer',
                                   Customer_Status__c = 'Active',
                                   SAP_Customer_Code__c = 'SAP0012ssa233',
                                   
                                   City__c = 'Delhi',
                                   State__c = 'Delhi',
                                   District__c = 'New Delhi',
                                   Pincode__c = '110001',
                                   Primary_Phone_Number__c = '1234567890');
        insert acc1;
                
        // Create test accounts
        Account newAcc = new Account(Name = 'Psecc',
                                     Customer_Type__c = 'Secondary Customer',
                                     Customer_Status__c = 'Active',
                                     SAP_Customer_Code__c = 'SAP001222211233',
                                     City__c = 'Delhi',
                                     State__c = 'Delhi',
                                     District__c = 'New Delhi',
                                     Pincode__c = '110001',
                                     Primary_Phone_Number__c = '1234567890');
        insert newAcc;
        
        user exe = [select Id,Name from User where Employee_Code__C = '1232122343' and isActive = true limit 1];   
        
        
        User user = [SELECT Id FROM User WHERE LastName = 'Test' and isActive = true LIMIT 1];
        List<Employee_Customer_Assignment__c> ecas = new List<Employee_Customer_Assignment__c>();
        for (Integer i = 0; i < 50; i++) {
            ecas.add(new Employee_Customer_Assignment__c(
                Customer__c = acc1.Id,
                Executive__c = user.Id
            ));
        }
        
        area__c tr = new area__c();
        tr.Name = '2211sjsjs';
        tr.Sales_Channel__c = 'CPD';
        tr.Region__c =	'Kerala';
        tr.Area__c  = 'Central';
        insert tr;
        
        Test.startTest(); 
        
        
        Product_Mapping__c pm4 = new   Product_Mapping__c();
        pm4.Customer__c = acc1.Id;
        pm4.Chanel__c = 'CPD';
        pm4.Parent_Depot__c ='1100';
        pm4.Area__c = tr.Id;
        pm4.Child_Depot__c ='1100';
        pm4.Payment_Term__c = '0003';
        pm4.Exectuive__c = exe.Id;
        insert pm4;
        
        Product_Mapping__c pm5 = new Product_Mapping__c(
            Customer__c = newAcc.Id,
            Payment_Term__c = '0003',
            Chanel__c = 'CPD',
            Exectuive__c = exe.Id,
            Area__c = tr.Id,
            Primary_Customer__c = acc1.Id
        );
        insert pm5;
        
        
        Employee_Customer_Assignment__c emp = new Employee_Customer_Assignment__c(
            Customer__c = acc1.Id,
            Executive__c = user.Id
        );
        insert emp;
        
 
        insert ecas;
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testAfterUpdateChangeCustomer() {
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        UserRole testRole = [SELECT Id FROM UserRole LIMIT 1];
        
        user managerUser = [select Id,Name from User where Employee_Code__C = '123212231' limit 1];   
        
        user exe = [select Id,Name from User where Employee_Code__C = '1232122343' limit 1];   
        
        
        // Create employee record
        Employee__c emp1 = new Employee__c(
            Name = 'Test Employee',
            OwnerId = managerUser.Id,
            Reporting_Manager__c = managerUser.Id,
            IsDataUpload__c = true,
            Mail_Id__c = 'test@gmail.com',
            Aadhar_Number__c = '119977663390',
            Profile__c = 'ASM',
            Sales_Channel__c = 'TN',
            User_Name__c = 'my@tstasm.com'
        );
        insert emp1;
        
        // Create test accounts
        Account newAcc = new Account(Name = 'Primary Customer 1',
                                     Customer_Type__c = 'Secondary Customer',
                                     Customer_Status__c = 'Active',
                                     SAP_Customer_Code__c = 'SAP0012233',
                                     City__c = 'Delhi',
                                     State__c = 'Delhi',
                                     District__c = 'New Delhi',
                                     Pincode__c = '110001',
                                     Primary_Phone_Number__c = '1234567890');
        insert newAcc;
        
        // Create test accounts
        Account newAcc1 = new Account(Name = 'Primary Customer 1',
                                      Customer_Type__c = 'Primary Customer',
                                      Customer_Status__c = 'Active',
                                      SAP_Customer_Code__c = 'SAP001221233',
                                      
                                      City__c = 'Delhi',
                                      State__c = 'Delhi',
                                      District__c = 'New Delhi',
                                      Pincode__c = '110001',
                                      Primary_Phone_Number__c = '2344567890');
        insert newAcc1;
        
        // Create test accounts
        Account newAcc3 = new Account(Name = 'Primary Customer 1',
                                      Customer_Type__c = 'Primary Customer',
                                      Customer_Status__c = 'Active',
                                      SAP_Customer_Code__c = 'SAe1111121P0012233',
                                      
                                      City__c = 'Delhi',
                                      State__c = 'Delhi',
                                      District__c = 'New Delhi',
                                      Pincode__c = '110001',
                                      Primary_Phone_Number__c = '1234567890');
        insert newAcc3;
        
        
        Test.startTest();
        area__c tr = new area__c();
        tr.Name = 'test11121';
        tr.Sales_Channel__c = 'CPD';
        tr.Region__c =	'Kerala';
        tr.Area__c  = 'Central';
        insert tr;
        
        Product_Mapping__c pm1 = new Product_Mapping__c(
            Customer__c = newAcc1.Id,
            Area__c = tr.Id,
            Chanel__c = 'CPD',
            Payment_Term__c = '0003',
            Exectuive__c = exe.Id
        );
        insert pm1;
        Product_Mapping__c pm11 = new Product_Mapping__c(
            Customer__c = newAcc1.Id,
            Area__c = tr.Id,
            Chanel__c = 'CPD',
            Payment_Term__c = '0003',
            Exectuive__c = managerUser.Id
        );
        insert pm11;
        
        
        Product_Mapping__c pm7 = new Product_Mapping__c(
            Customer__c = newAcc3.Id,
            Payment_Term__c = '0003',
            Chanel__c = 'CPD',
            Area__c = tr.Id,
            Exectuive__c = managerUser.Id
        );
        insert pm7;
        
        Product_Mapping__c pm = new Product_Mapping__c(
            Customer__c = newAcc.Id,
            Payment_Term__c = '0003',
            Chanel__c = 'CPD',
            Exectuive__c = exe.Id,
            Area__c = tr.Id,
            Primary_Customer__c = newAcc1.Id
        );
        insert pm;
        

        
        
        Employee_Customer_Assignment__c emp = new Employee_Customer_Assignment__c(
            Customer__c = newAcc3.Id,
            Employee__c = emp1.Id,
            Executive__c = exe.Id
        );
        insert emp;
        
        emp = [SELECT Id, Customer__c, Employee__c, Executive__c FROM Employee_Customer_Assignment__c WHERE Id = :emp.Id];
        emp.Customer__c = newAcc1.Id;
        emp.Executive__c = exe.Id;
        update emp;
        
        
        Test.stopTest();
        
    }
    
    
    @isTest
    static void testAfterDelete() {
        user testUser2 = [select Id,Name from User where Employee_Code__C = '123212231' limit 1];   
        
        user testUser1 = [select Id,Name from User where Employee_Code__C = '1232122343' limit 1];   
        
        
        // Create test accounts
        Account newAcc1 = new Account(Name = 'Primary Customer 1',
                                      Customer_Type__c = 'Primary Customer',
                                      Customer_Status__c = 'Active',
                                      SAP_Customer_Code__c = 'SAP0012222221233',
                                      
                                      City__c = 'Delhi',
                                      State__c = 'Delhi',
                                      District__c = 'New Delhi',
                                      Pincode__c = '110001',
                                      Primary_Phone_Number__c = '9344567890');
        insert newAcc1;
        
        // Create test accounts
        Account newAcc3 = new Account(Name = 'Primary Customer 1',
                                      Customer_Type__c = 'Primary Customer',
                                      Customer_Status__c = 'Active',
                                      SAP_Customer_Code__c = 'S111Ae1111121P0012233',
                                      
                                      City__c = 'Delhi',
                                      State__c = 'Delhi',
                                      District__c = 'New Delhi',
                                      Pincode__c = '110001',
                                      Primary_Phone_Number__c = '7234567890');
        insert newAcc3;
        
        
        // Create Employee_Customer_Assignment__c records
        Employee_Customer_Assignment__c eca1 = new Employee_Customer_Assignment__c(
            Customer__c = newAcc1.Id,
            Executive__c = testUser1.Id
        );
        Employee_Customer_Assignment__c eca2 = new Employee_Customer_Assignment__c(
            Customer__c = newAcc3.Id,
            Executive__c = testUser2.Id
        );
        insert new List<Employee_Customer_Assignment__c>{ eca1, eca2 };
            // Prepare test data
            Employee_Customer_Assignment__c eca = [SELECT Id, Customer__c, Executive__c 
                                                   FROM Employee_Customer_Assignment__c 
                                                   WHERE Customer__r.Name = 'Primary Customer 1' LIMIT 1];
        
        
        Test.startTest();
        delete eca;
        Test.stopTest();
        
        
    }
    

}