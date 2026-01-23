@isTest
public class EmployeeeControllerTest {

    @testSetup
    static void setupData() {
        // Create a dummy Area__c
        
        area__c testArea = new area__c();
        testArea.Name = 'test11121';
        testArea.Sales_Channel__c = 'CPD';
        testArea.Region__c =	'Kerala';
        testArea.Area__c  = 'Central';
        insert testArea;
        
          User testUser1 = new User(
            Alias = 'tuser',
            Employee_Code__c  = '123212231',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'TSE' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testuser@ekskslsslxample.com' + System.currentTimeMillis(),
           Sales_Channel__c = 'Cake'
        );
        
        User hr = new User(
            Alias = 'tuser',
            Employee_Code__c  = 'TestSSISOOSO',
            Email = 'testuser@esksksksxample.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'TestSSISOOSO',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'HR' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testuseskskskksr@example.com' + System.currentTimeMillis(),
            Sales_Channel__c = 'Cake'
        );
        insert hr;
        User testUser2 = new User(
             Alias = 'tuser12',
            Employee_Code__c  = '1232122343',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            Primary_Customer_Approver_2__c = testUser1.Id,
            Employee_Approver_3_HR__c = testUser1.Id,
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'TSE' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testuser@example.com' + System.currentTimeMillis(),
           Sales_Channel__c = 'Cake'
        );
        insert new List<User>{ testUser1, testUser2 };

      

        // Get existing Profile
        Profile p = [SELECT Id, Name FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        // Just query an existing UserRole to avoid Mixed DML issues
        UserRole ur = [SELECT Id FROM UserRole LIMIT 1];

        // Create mock Employee__c record
        Employee__c emp = new Employee__c(
            Name = 'John Doe',
            Mail_Id__c = 'john.doe@example.com',
            User_Name__c = 'john.doe@example.com.testuser',
            Primary_Phone_Number__c = '1234567890',
            Employee_Code__c = 'EMP123',
            Designation__c = 'Sales Exec',
            Profile__c = 'Admin',
            Role_Id__c = ur.Id,
            Is_Active__c = false,
            // Required fields
            Basic_Pay__c = 25000,
            Aadhar_Number__c = '123456789012',
            Gross_Salary__c = 35000,
            DA__c = 5000,
            TA_limit__c = 2000,
            Area__c = 'Central',
            Region__c = 'West',
            ASM_TSM__c = testUser1.Id,
            RSM__c = testUser1.Id,
            Employee_Approver_3_HR__c = testUser1.Id,
            
            Secondary_Customer_Approver_1__c = testUser1.Id,
            Secondary_Customer_Approver_2__c = testUser1.Id,
            
            Primary_Customer_Approver_1__c = testUser1.Id,
            Primary_Customer_Approver_2__c = testUser1.Id,
            Primary_Customer_Approver_3_CD__c = testUser1.Id,
            
            PJP_Approver_1__c = testUser1.Id,
            PJP_Approver_2__c = testUser1.Id,
            
            Expense_Approver_1__c = testUser1.Id,
            Expense_Approver_2_Finance_Department__c = testUser1.Id,
            Sales_Channel__c = 'Cake',
            State__c = 'Uttar Pradesh',
            District__c = 'Lucknow',
            Pincode__c = '226001',
            User__c = testUser2.Id,
            Cloning_is_Completed__c = false
        );
        insert emp;
        
        
        Employee__c emp2 = new Employee__c(
            Name = 'John Doe',
            Mail_Id__c = 'john.doe@example.com',
            User_Name__c = 'john.doe7734526@example.com.testuser',
            Primary_Phone_Number__c = '1234513890',
            Employee_Code__c = 'EMP554123',
            Designation__c = 'Sales Exec',
            Profile__c = 'Admin',
            Role_Id__c = ur.Id,
            Is_Active__c = false,
            ASM_TSM__c = testUser1.Id,
            RSM__c = testUser1.Id,
            Employee_Approver_3_HR__c = testUser1.Id,
            
            Secondary_Customer_Approver_1__c = testUser1.Id,
            Secondary_Customer_Approver_2__c = testUser1.Id,
            
            Primary_Customer_Approver_1__c = testUser1.Id,
            Primary_Customer_Approver_2__c = testUser1.Id,
            Primary_Customer_Approver_3_CD__c = testUser1.Id,
            
            PJP_Approver_1__c = testUser1.Id,
            PJP_Approver_2__c = testUser1.Id,
            
            Expense_Approver_1__c = testUser1.Id,
            Expense_Approver_2_Finance_Department__c = testUser1.Id,
            // Required fields
            Basic_Pay__c = 25000,
            Aadhar_Number__c = '123006789012',
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
        insert emp2;
        try {
            EmployeeeController.deactivateUser(emp.Id);
          
        } catch (Exception e) {
            System.debug('Error while deactivating user: ' + e.getMessage());
        }

            
      
     
    }

    static testMethod void testCreateUser() {
        Employee__c emp = [SELECT Id FROM Employee__c where user__c != null LIMIT 1];
         Employee__c emp2 = [SELECT Id FROM Employee__c where user__c = null LIMIT 1];

        Test.startTest();
        EmployeeeController.createUser(emp.Id);
        EmployeeeController.createUser(emp2.Id);
        Test.stopTest();
    }

    static testMethod void testDeactivateUser() {
        User user = [SELECT Id FROM User WHERE LastName = 'Test' LIMIT 1];
        Employee__c emp = [SELECT Id FROM Employee__c LIMIT 1];
        EmployeeeController.createUser(emp.Id);
        emp = [SELECT Id, User__c FROM Employee__c WHERE Id = :emp.Id];
        User testUser1 = new User(
            Alias = 'tuser',
            Employee_Code__c  = '123212231',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            Primary_Customer_Approver_2__c = emp.User__c,
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testuser@example.com' + System.currentTimeMillis(),
            Sales_Channel__c = 'Cake'
        );
        Test.startTest();
        EmployeeeController.deactivateUser(emp.Id);
        Test.stopTest();
    }

    static testMethod void testGetAllData() {
        Employee__c emp = [SELECT Id FROM Employee__c LIMIT 1];
        User user1 =[SELECT Id FROM User WHERE Employee_code__c = '123212231' LIMIT 1];
        emp.User__c = user1.Id;
 
        update emp;
        
      
        

        Test.startTest();
        EmployeeeController.DataBox db = EmployeeeController.getAllData(emp.Id);
          EmployeeeController.deactivateEmployeeAsync(emp.Id,user1.Id);
        Test.stopTest();
    }
    
    static testMethod void testGetAllData1() {
        // Get a sample Employee record
       
          User testUser1 = [SELECT Id FROM User WHERE LastName = 'Test' LIMIT 1];
        Test.startTest();
        System.runAs(testUser1) {
           
            
            // Create mock Employee__c record
            Employee__c emp = new Employee__c(
                Name = 'John Doe',
                Mail_Id__c = 'john.doe@exlslsllswwwample.com',
                User_Name__c = 'rameshdurgamaheshramesh@gmail.com',
                Primary_Phone_Number__c = '9909567890',
                Employee_Code__c = 'EMPssskskssksks123',
                Designation__c = 'Sales Exec',
                Profile__c = 'TSE',
                Is_Active__c = false,
                // Required fields
                Basic_Pay__c = 25000,
                Aadhar_Number__c = '123456789012',
                Gross_Salary__c = 35000,
                DA__c = 5000,
                TA_limit__c = 2000,
                Area__c = 'Central',
                Region__c = 'West',
                ASM_TSM__c = testUser1.Id,
                RSM__c = testUser1.Id,
                Employee_Approver_3_HR__c = testUser1.Id,
                
                Secondary_Customer_Approver_1__c = testUser1.Id,
                Secondary_Customer_Approver_2__c = testUser1.Id,
                
                Primary_Customer_Approver_1__c = testUser1.Id,
                Primary_Customer_Approver_2__c = testUser1.Id,
                Primary_Customer_Approver_3_CD__c = testUser1.Id,
                
                PJP_Approver_1__c = testUser1.Id,
                PJP_Approver_2__c = testUser1.Id,
                
                Expense_Approver_1__c = testUser1.Id,
                Expense_Approver_2_Finance_Department__c = testUser1.Id,
                Sales_Channel__c = 'Cake',
                State__c = 'Uttar Pradesh',
                District__c = 'Lucknow',
                Pincode__c = '226001',
                Cloning_is_Completed__c = false
            );
            insert emp;
            
            
            // Code inside this block runs as user1
            EmployeeeController.DataBox db = EmployeeeController.getAllData(emp.Id);
        }
        Test.stopTest();
    }

    static testMethod void testGetAllData2() {
        // Get a sample Employee record
       
          User testUser1 = [SELECT Id FROM User WHERE Employee_Code__c = 'TestSSISOOSO' LIMIT 1];
        Test.startTest();
        System.runAs(testUser1) {
           
            
            // Create mock Employee__c record
            Employee__c emp = new Employee__c(
                Name = 'John Doe',
                Mail_Id__c = 'john.doe@ekskksksxlslsllswwwample.com',
                User_Name__c = 'rameshdurgamahekskskskskshramesh@gmail.com',
                Primary_Phone_Number__c = '9909567890',
                Employee_Code__c = 'EMBskskssksks123',
                Designation__c = 'Sales Exec',
                Profile__c = 'TSE',
                Is_Active__c = false,
                // Required fields
                Basic_Pay__c = 25000,
                Aadhar_Number__c = '123456789012',
                Gross_Salary__c = 35000,
                DA__c = 5000,
                TA_limit__c = 2000,
                Area__c = 'Central',
                Region__c = 'West',
                ASM_TSM__c = testUser1.Id,
                RSM__c = testUser1.Id,
                Employee_Approver_3_HR__c = testUser1.Id,
                
                Secondary_Customer_Approver_1__c = testUser1.Id,
                Secondary_Customer_Approver_2__c = testUser1.Id,
                
                Primary_Customer_Approver_1__c = testUser1.Id,
                Primary_Customer_Approver_2__c = testUser1.Id,
                Primary_Customer_Approver_3_CD__c = testUser1.Id,
                
                PJP_Approver_1__c = testUser1.Id,
                PJP_Approver_2__c = testUser1.Id,
                
                Expense_Approver_1__c = testUser1.Id,
                Expense_Approver_2_Finance_Department__c = testUser1.Id,
                Sales_Channel__c = 'Cake',
                State__c = 'Uttar Pradesh',
                District__c = 'Lucknow',
                Pincode__c = '226001',
                Cloning_is_Completed__c = false
            );
            insert emp;
            
            
            // Code inside this block runs as user1
            EmployeeeController.DataBox db = EmployeeeController.getAllData(emp.Id);
        }
        Test.stopTest();
    }

    //
    
    
    static testMethod void testDuplicationCheck_AllCases() {
        
         User user = [SELECT Id FROM User WHERE LastName = 'Test' LIMIT 1];
        Employee__c emp1 = new Employee__c(
            Name = 'John Test',
            User_Name__c = 'john@test.com',
            Aadhar_Number__c = '111122223333',
            Employee_Code__c = 'EMP001',
              Profile__c = 'Admin',
             Mail_Id__c = 'john.doe@example.com',
            Sales_Channel__c = 'Cake',
            Reporting_Manager__c = user.Id
            
        );
        insert emp1;
        
        // Check duplicate User_Name__c
        Employee__c dup1 = new Employee__c(
            Name = 'UserDup',
            User_Name__c = 'john@test.com'
        );
        EmployeeeController.DataBox db1 = EmployeeeController.duplicationCheck(dup1);
        System.assertEquals(true, db1.duplicateFound);
        System.assertEquals('User_Name__c', db1.duplicateField);
        
        // Check duplicate Aadhar_Number__c
        Employee__c dup2 = new Employee__c(
            Name = 'AadharDup',
            Aadhar_Number__c = '111122223333'
        );
        EmployeeeController.DataBox db2 = EmployeeeController.duplicationCheck(dup2);
        System.assertEquals(true, db2.duplicateFound);
        System.assertEquals('Aadhar_Number__c', db2.duplicateField);
        
        // Check duplicate Employee_Code__c
        Employee__c dup3 = new Employee__c(
            Name = 'CodeDup',
            Employee_Code__c = 'EMP001'
        );
        EmployeeeController.DataBox db3 = EmployeeeController.duplicationCheck(dup3);
        //System.assertEquals(true, db3.duplicateFound);
        //System.assertEquals('Employee_Code__c', db3.duplicateField);
        
        // Check no duplicate case
        Employee__c empUnique = new Employee__c(
            Name = 'Unique Emp',
            User_Name__c = 'unique@test.com',
            Aadhar_Number__c = '999988887777',
            Employee_Code__c = 'EMP999'
        );
        EmployeeeController.DataBox dbNoDup = EmployeeeController.duplicationCheck(empUnique);
        System.assertEquals(false, dbNoDup.duplicateFound);
    }
    
    static testMethod void testSaveData_InsertAndUpdate() {
        
           User user = [SELECT Id FROM User WHERE LastName = 'Test' LIMIT 1];
        // Insert case
        
        Employee__c newEmp = new Employee__c(
            Name = 'Insert Emp',
            User_Name__c = 'insert@test.com',
            Aadhar_Number__c = '222233334444',
            Employee_Code__c = 'EMP100',
              Profile__c = 'Admin',
             Mail_Id__c = 'john.doe@example.com',
            Sales_Channel__c = 'Cake',
             Reporting_Manager__c = user.Id,
            OwnerId = user.Id
        );
        insert newEmp;
        Test.startTest();
        EmployeeeController.DataBox dbInsert = EmployeeeController.saveData(newEmp);
      
        
        
        // Simulate approval conditions
        Employee__c insertedEmp = [SELECT Id, Name FROM Employee__c WHERE Id = :dbInsert.recordId LIMIT 1];
        insertedEmp.Payroll__c = 'No';
        
        insertedEmp.Is_Active__c = false;
        insertedEmp.Approval_Status__c = '';
        update insertedEmp;
        
        
        User adminUser = [SELECT Id FROM User WHERE Profile.Name != 'System Administrator' LIMIT 1];
        System.runAs(user) {
            
            EmployeeeController.DataBox dbUpdate = EmployeeeController.saveData(insertedEmp);
            Test.stopTest();
            
        }
    }
    
    
    static testMethod void testSaveData_InsertAndUpdate12345() {
        
           User user = [SELECT Id FROM User WHERE LastName = 'Test' LIMIT 1];
        // Insert case
        
        Employee__c newEmp = new Employee__c(
            Name = 'Insert Emp',
            User_Name__c = 'insert@test.com',
            Aadhar_Number__c = '222233334444',
            Employee_Code__c = 'EMP100',
              Profile__c = 'Admin',
             Mail_Id__c = 'john.doe@example.com',
            Sales_Channel__c = 'Cake',
             Reporting_Manager__c = user.Id,
            OwnerId = user.Id
        );
        insert newEmp;
        Test.startTest();
        EmployeeeController.DataBox dbInsert = EmployeeeController.saveData(newEmp);
      
        
        
        // Simulate approval conditions
        Employee__c insertedEmp = [SELECT Id, Name FROM Employee__c WHERE Id = :dbInsert.recordId LIMIT 1];
        insertedEmp.Payroll__c = 'No';
        
        insertedEmp.Is_Active__c = true;
        insertedEmp.Approval_Status__c = 'Level 2 Approved';
        update insertedEmp;
        
        
        User adminUser = [SELECT Id FROM User WHERE Profile.Name != 'System Administrator' LIMIT 1];
        System.runAs(user) {
            
            EmployeeeController.DataBox dbUpdate = EmployeeeController.saveData(insertedEmp);
            Test.stopTest();
            
        }
    }
    
    
    static testMethod void testSaveData_InsertAndUpdate123() {
        
        User user = [SELECT Id FROM User WHERE LastName = 'Test' LIMIT 1];
        // Insert case
        System.runAs(user) {
        Employee__c newEmp = new Employee__c(
            Name = 'Insert Emp',
            User_Name__c = 'insert109091@test.com',
            Aadhar_Number__c = '222233334444',
            Employee_Code__c = 'EMP100',
            Profile__c = 'Admin',
            Mail_Id__c = 'john.doe@example.com',
            Sales_Channel__c = 'Cake',
            Reporting_Manager__c = user.Id
        );
        Test.startTest();
        EmployeeeController.saveData(newEmp);
        Test.stopTest();
        
        }
    }

    @isTest
    static void testGetRecordViewFormData_EmployeeCase() {
        
           User user = [SELECT Id FROM User WHERE LastName = 'Test' LIMIT 1];
        // Setup Employee__c record
       Employee__c emp = new Employee__c(
            Name = 'Insert Emp',
            User_Name__c = 'insert@test.com',
            Aadhar_Number__c = '222233334444',
            Employee_Code__c = 'EMP100',
              Profile__c = 'Admin',
             Mail_Id__c = 'john.doe@example.com',
            Sales_Channel__c = 'Cake',
             Reporting_Manager__c = user.Id
        );
        insert emp;

        Test.startTest();
        EmployeeeController.DataBox db = EmployeeeController.getRecordViewFormData(emp.Id, 'Employee');
        Test.stopTest();

       
    }

    @isTest
    static void testGetRecordViewFormData_UserCase() {
        // Create user and employee record
        Profile prof = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

           User user = [SELECT Id FROM User WHERE LastName = 'Test' LIMIT 1];

        // Link employee to user
        Employee__c emp = new Employee__c(
            Name = 'Insert Emp',
            User_Name__c = 'insert@test.com',
            Aadhar_Number__c = '222233334444',
            Employee_Code__c = 'EMP100',
              Profile__c = 'Admin',
             Mail_Id__c = 'john.doe@example.com',
            Sales_Channel__c = 'Cake',
             Reporting_Manager__c = user.Id
        );
        insert emp;

        Test.startTest();
        try{
        EmployeeeController.getRecordViewFormData(user.Id, 'User');
        }catch(exception e){
            system.debug('failed');
        }
        Test.stopTest();

       
    }

    @isTest
    static void testGetRecordViewFormData_NullOrInvalidCases() {
        // Case 1: Null recordId
        Test.startTest();
        EmployeeeController.DataBox db1 = EmployeeeController.getRecordViewFormData(null, 'Employee');
        EmployeeeController.DataBox db2 = EmployeeeController.getRecordViewFormData('someId', '');
        EmployeeeController.DataBox db3 = EmployeeeController.getRecordViewFormData('someId', null);
        Test.stopTest();

        
    }
    
    
    @isTest
    static void testEmployeeReplacementSuccess() {
        // Old employee's user
        User u1 = [SELECT Id FROM User WHERE Employee_Code__c = '123212231' LIMIT 1];
        
        // Manager user (different from u1)
        User u2 = [SELECT Id FROM User WHERE Id != :u1.Id LIMIT 1];
        
        // Old employee (to be replaced)
        Employee__c oldEmp = new Employee__c(
            Name = 'Old Emp',
            User__c = u1.Id,
            User_Name__c = 'oldemp@test.com',
            Aadhar_Number__c = '111122223333',
            Employee_Code__c = 'EMP001',
            Profile__c = 'TSE',
            Mail_Id__c = 'old@example.com',
            Sales_Channel__c = 'Cake',
            Is_Employee_Replaced__c = false,
            Cloning_is_Completed__c = false
        );
        insert oldEmp;
        
        // New employee (replacement)
        Employee__c newEmp = new Employee__c(
            Name = 'New Emp',
            User__c = UserInfo.getUserId(),
            User_Name__c = 'newemp@test.com',
            Aadhar_Number__c = '444455556666',
            Employee_Code__c = 'EMP002',
            Profile__c = 'TSE',
            Mail_Id__c = 'new@example.com',
            Sales_Channel__c = 'Cake',
            Reporting_Manager__c = u2.Id, // use different user here
            Is_Employee_Replaced__c = false,
            Cloning_is_Completed__c = false,
            //ReplacedForUserId__c = u1.Id,
            Replaced_For__c = oldEmp.Id
        );
        insert newEmp;
        
        Test.startTest();
        String result = EmployeeeController.employeeReplacement(newEmp.Id);
        Test.stopTest();
        
      //  System.assert(result.startsWith('Success'), 'Expected success but got: ' + result);
    }
    
    @isTest
    static void testErrorRecordNotFound() {
        Test.startTest();
        String result = EmployeeeController.employeeReplacement(null);
        Test.stopTest();

      
    }

    @isTest
    static void testErrorMissingFields() {
        User user = [SELECT Id FROM User WHERE LastName = 'Test' LIMIT 1];
        // Create employee missing User__c and ReplacedForUserId__c
        Employee__c emp = new Employee__c(
           Name = 'Insert Emp',
            User_Name__c = 'insert@test.com',
            Aadhar_Number__c = '222233334444',
            Employee_Code__c = 'EMP100',
              Profile__c = 'Admin',
             Mail_Id__c = 'john.doe@example.com',
            Sales_Channel__c = 'Cake',
              Cloning_is_Completed__c = false,
             Reporting_Manager__c = user.Id
        
        );
        insert emp;

        Test.startTest();
        String result = EmployeeeController.employeeReplacement(emp.Id);
        Test.stopTest();

        
    }

    @isTest
    static void testErrorAlreadyReplaced() {
        // Set old employee as already replaced
        Employee__c oldEmp = [SELECT Id FROM Employee__c WHERE Name = 'John Doe' LIMIT 1];
        oldEmp.Is_Employee_Replaced__c = true;
        oldEmp.Employee_Replaced_With_Name__c = 'New Emp';
        update oldEmp;

        Employee__c replacingEmp = [SELECT Id FROM Employee__c WHERE Name = 'John Doe' LIMIT 1];

        Test.startTest();
        String result = EmployeeeController.employeeReplacement(replacingEmp.Id);
        Test.stopTest();

       
    }

    @isTest
    static void testErrorCloningAlreadyDone() {
        // Update New Emp to already cloned
        Employee__c emp = [SELECT Id FROM Employee__c WHERE Name = 'John Doe' LIMIT 1];
        emp.Cloning_is_Completed__c = true;
        update emp;

        Test.startTest();
        String result = EmployeeeController.employeeReplacement(emp.Id);
        Test.stopTest();

        
    }
   
}