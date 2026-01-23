@isTest
public class EmployeeSubmitForApprovalControllerTest {
    
   @testSetup
    static void setupData() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        UserRole ur = [SELECT Id FROM UserRole LIMIT 1];

        User u = new User(
            Alias = 'tuser',
            Employee_Code__c  = '123212231',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testuser@example.com' + System.currentTimeMillis(),
            Sales_Channel__c = 'Cake'
        );
        insert u;

        Employee__c emp = new Employee__c(
            Name = 'John Doe',
            Mail_Id__c = 'john.doe@example.com',
            User_Name__c = 'john.doe1@example.com.testuser',
            Primary_Phone_Number__c = '1234567890',
            Employee_Code__c = 'EMP001',
            Designation__c = 'Sales Exec',
            Profile__c = 'Admin',
            Role_Id__c = ur.Id,
            Is_Active__c = false,
            Basic_Pay__c = 25000,
            Aadhar_Number__c = '111122223333',
            Gross_Salary__c = 35000,
            DA__c = 5000,
            TA_limit__c = 2000,
            Area__c = 'Central',
            Region__c = 'West',
            Sales_Channel__c = 'Cake',
            State__c = 'Uttar Pradesh',
            District__c = 'Lucknow',
            Pincode__c = '226001'
        );
        insert emp;

        Employee_Customer_Assignment__c primary = new Employee_Customer_Assignment__c(Employee__c = emp.Id);
        insert primary;

        Area__c area = new Area__c(Name = 'Test Area', Sales_Channel__c = 'Cake');
        insert area;

        Account secondaryCustomer = new Account(
            Name = 'Secondary Cust',
            Customer_Status__c = 'Active',
            SAP_Customer_Code__c = 'SAP001',
            Area__c = area.Id,
            City__c = 'Delhi',
            State__c = 'Delhi',
            District__c = 'New Delhi',
            Pincode__c = '110001',
            Primary_Phone_Number__c = '1234567890',
            Customer_Type__c = 'Secondary Customer'
        );
        insert secondaryCustomer;

        Product_Mapping__c secondary = new Product_Mapping__c(Employee__c = emp.Id, Customer__c = secondaryCustomer.Id);
        insert secondary;
    }

    @isTest
    static void testGetAssignments_Success() {
        Employee__c emp = [SELECT Id FROM Employee__c WHERE Name = 'John Doe' LIMIT 1];
        Test.startTest();
        String result = EmployeeSubmitForApprovalController.getAssignments(emp.Id);
        Test.stopTest();
        
    }

    @isTest
    static void testGetAssignments_MissingPrimaryAndSecondary() {
        UserRole ur = [SELECT Id FROM UserRole LIMIT 1];
        Employee__c emp = new Employee__c(
            Name = 'John Doe1',
            Mail_Id__c = 'john.doe1@example.com',
            User_Name__c = 'john.doe2@example.com.testuser',
            Primary_Phone_Number__c = '1234567991',
            Employee_Code__c = 'EMP002',
            Designation__c = 'Sales Exec',
            Profile__c = 'Admin',
            Role_Id__c = ur.Id,
            Is_Active__c = false,
            Basic_Pay__c = 25000,
            Aadhar_Number__c = '111122223334',
            Gross_Salary__c = 35000,
            DA__c = 5000,
            TA_limit__c = 2000,
            Area__c = 'Central',
            Region__c = 'West',
            Sales_Channel__c = 'Cake',
            State__c = 'Uttar Pradesh',
            District__c = 'Lucknow',
            Pincode__c = '226001'
        );
        insert emp;

        Test.startTest();
        String result = EmployeeSubmitForApprovalController.getAssignments(emp.Id);
        Test.stopTest();
       
    }

    @isTest
    static void testGetAssignments_OnlySecondary() {
        UserRole ur = [SELECT Id FROM UserRole LIMIT 1];
        Employee__c emp = new Employee__c(
            Name = 'John Doe2',
            Mail_Id__c = 'john.doe2@example.com',
            User_Name__c = 'john.doe3@example.com.testuser',
            Primary_Phone_Number__c = '1234567792',
            Employee_Code__c = 'EMP003',
            Designation__c = 'Sales Exec',
            Profile__c = 'Admin',
            Role_Id__c = ur.Id,
            Is_Active__c = false,
            Basic_Pay__c = 25000,
            Aadhar_Number__c = '111122223335',
            Gross_Salary__c = 35000,
            DA__c = 5000,
            TA_limit__c = 2000,
            Area__c = 'Central',
            Region__c = 'West',
            Sales_Channel__c = 'Cake',
            State__c = 'Uttar Pradesh',
            District__c = 'Lucknow',
            Pincode__c = '226001',
            Payroll__c = 'No'
        );
        insert emp;

        Account secondaryCustomer = new Account(Name = 'Secondary Customer 1',
                                   Customer_Type__c = 'Secondary Customer',
                                   Customer_Status__c = 'Active',
                                   SAP_Customer_Code__c = 'SAP004',
                                   City__c = 'Delhi',
                                   State__c = 'Delhi',
                                   District__c = 'New Delhi',
                                   Pincode__c = '110006',
                                   Secondary_Customer_Type__c = 'Sub Stockiest',
                                   Primary_Phone_Number__c = '9876543216');
        try{
        insert secondaryCustomer;
        }catch(exception e){
            system.debug('failed');
        }

        Product_Mapping__c mapping = new Product_Mapping__c(Employee__c = emp.Id, Customer__c = secondaryCustomer.Id);
        insert mapping;

        Test.startTest();
        String result = EmployeeSubmitForApprovalController.getAssignments(emp.Id);
        Test.stopTest();
       
    }

    @isTest
    static void testGetAssignments_OnlyPrimary() {
      User u  = [SELECT Id FROM User  LIMIT 1];
        Employee__c emp = new Employee__c(
            Name = 'John Doe3',
            Mail_Id__c = 'john.doe3@example.com',
            User_Name__c = 'john.doe4@example.com.testuser',
            Primary_Phone_Number__c = '1234667893',
            Employee_Code__c = 'EMP004',
            Designation__c = 'Sales Exec',
            Profile__c = 'Admin',
            Role_Id__c = u.Id,
            Is_Active__c = false,
            Basic_Pay__c = 25000,
            Aadhar_Number__c = '111122223336',
            Gross_Salary__c = 35000,
            DA__c = 5000,
            TA_limit__c = 2000,
            Area__c = 'Central',
            Region__c = 'West',
            Sales_Channel__c = 'Cake',
            State__c = 'Uttar Pradesh',
            District__c = 'Lucknow',
            Pincode__c = '226001',
            Payroll__c = 'No'
        );
        insert emp;

        Employee_Customer_Assignment__c assignment = new Employee_Customer_Assignment__c(Employee__c = emp.Id);
        insert assignment;

        Test.startTest();
        String result = EmployeeSubmitForApprovalController.getAssignments(emp.Id);
        Test.stopTest();
        
    }

    @isTest
    static void testSubmitForApproval() {
        User u  = [SELECT Id FROM User  LIMIT 1];
        Employee__c emp = new Employee__c(
            
            Name = 'Approval Test',
            User_Name__c = 'approval.test@example.com.testuser',
            Aadhar_Number__c = '111122223337',
            Primary_Phone_Number__c = '9999911111',
            Payroll__c = 'No',
            Reporting_Manager__c = u.Id,
            Is_Active__c = false,
            
            //  Required fields
            Mail_Id__c = 'approval.test@example.com',
            Profile__c = 'DSM',             
            Sales_Channel__c = 'Cake'        
            
        );
        insert emp;

        Test.startTest();
        EmployeeSubmitForApprovalController.submitForApproval(emp.Id, 'Testing approval');
        Test.stopTest();
      
    }

    @isTest
    static void testSubmitForApproval_BlankComment() {
             User u  = [SELECT Id FROM User  LIMIT 1];
        Employee__c emp = new Employee__c(
            Name = 'Blank Comment',
        User_Name__c = 'blank.comment@example.com.testuser',
        Aadhar_Number__c = '111122223338',
        Primary_Phone_Number__c = '9999922222',
        Payroll__c = 'No',
        Is_Active__c = false,
        Reporting_Manager__c = u.Id, // required relationship field
        Mail_Id__c = 'blank.comment@example.com',
        Profile__c = 'Admin',
        Sales_Channel__c = 'Cake',
        Employee_Code__c = 'EMP005',
        Designation__c = 'Sales Exec',
       
        Basic_Pay__c = 25000,
        Gross_Salary__c = 35000,
        DA__c = 5000,
        TA_limit__c = 2000,
        Area__c = 'Central',
        Region__c = 'West',
        State__c = 'Uttar Pradesh',
        District__c = 'Lucknow',
        Pincode__c = '226001'
        );
        insert emp;

        Test.startTest();
        EmployeeSubmitForApprovalController.submitForApproval(emp.Id, '');
        Test.stopTest();
      
    }
}