@isTest
public class EmployeeUserActivationControllerTest {

    @testSetup
    static void setup() {
        Profile p = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

        // Manager User
        User manager = new User(
            FirstName = 'Manager',
            LastName = 'Test',
            Employee_Code__c  = 'EMP_MANAGER',
            Email = 'manager@example.com',
            Username = 'manager@example.com.test',
            Alias = 'mgr',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_IN',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert manager;

        // Insert dummy Profile record for matching logic
        Profile testProfile = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

        // Insert employees with complete info for user creation
        List<Employee__c> empList = new List<Employee__c>();
        for (Integer i = 0; i < 2; i++) {
            empList.add(new Employee__c(
                Name = 'Test Emp ' + i,
                OwnerId = manager.Id,
                Reporting_Manager__c = manager.Id,
                IsDataUpload__c = true,
                Mail_Id__c = 'testuser' + i + '@email.com',
                Aadhar_Number__c = '99999999999' + i,
                Profile__c = 'ASM',
                Employee_Code__c = 'EMP00' + i,
                Sales_Channel__c = 'TN',
                User_Name__c = 'username' + i + '@example.com'
            ));
        }
        insert empList;
         EmployeeUserActivationController.findEmployeeByUserId(empList,manager.Id);
    }

    @isTest
    static void testActivateUsers_createAndUpdatePath() {
        List<Employee__c> employees = [SELECT Id FROM Employee__c];
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(employees);
        ssc.setSelected(employees); 
        Test.startTest();
        EmployeeUserActivationController controller = new EmployeeUserActivationController(ssc);
        controller.activateUsers();
        Test.stopTest();

    }

    @isTest
    static void testActivateUsers_missingProfile() {
        Employee__c emp = new Employee__c(
            Name = 'Missing Profile Emp',
            Mail_Id__c = 'missing@email.com',
            User_Name__c = 'missing@email.com',
            Profile__c = 'ASM',
            Employee_Code__c = 'MISSING01',
            Is_Active__c = false,
            Aadhar_Number__c = '119977663390',
            Sales_Channel__c = 'TN'
        );
        insert emp;

        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(new List<Employee__c>{emp});
        Test.startTest();
        EmployeeUserActivationController controller = new EmployeeUserActivationController(ssc);
        controller.activateUsers();
        Test.stopTest();

    }

    @isTest
    static void testActivateUsers_missingUsernameOrEmail() {
        Employee__c emp = new Employee__c(
           Name = 'Missing Profile11 Emp',
            Mail_Id__c = 'missing@email.com',
            User_Name__c = 'missi111111111ng@email.com',
            Profile__c = 'ASM',
            Employee_Code__c = 'MISSI2222NG01',
            Is_Active__c = false,
            Aadhar_Number__c = '119977663390',
            Sales_Channel__c = 'TN'
        );
        insert emp;

        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(new List<Employee__c>{emp});
        Test.startTest();
        EmployeeUserActivationController controller = new EmployeeUserActivationController(ssc);
        controller.activateUsers();
        Test.stopTest();

    }

    @isTest
    static void testCancelMethod() {
        List<Employee__c> emps = [SELECT Id FROM Employee__c LIMIT 1];
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(emps);
        EmployeeUserActivationController controller = new EmployeeUserActivationController(ssc);
        PageReference cancelPage = controller.cancel();

    }
    
 
}