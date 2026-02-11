@isTest
public class EmployeeDuplicationCheckerTest {
    
    @isTest
    static void testUserNameDuplicate() {
        
        Profile profile = [SELECT Id FROM Profile WHERE Name='TSE'];
        User testUser = new User(
            FirstName = 'Test123',
            LastName = 'User',
            Email = 'testuser@elite.com',
            Username = 'testuser@elitssssseproductmapping.com',
            ProfileId = profile.Id,
            Employee_Code__c = 'EMP12323121122',            
            Alias = 'tuser',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles'
        );
        insert testUser;
        
        Employee__c existing = new Employee__c(
            Payroll__c = 'No',
            Is_Active__c = false,
            Reporting_Manager__c = testUser.Id,
            Approval_Status__c = 'Pending',
            Mail_Id__c = 'mainuser@esssxample.com',
            Aadhar_Number__c = '345456789012',
            Profile__c = 'TSE', // use a valid picklist value if applicable
            Sales_Channel__c = 'CPD', // use a valid picklist or reference value
            User_Name__c = 'mainuserssksskskskkskssaaggg@esssxample.com',
            Working_District__c = 'Kolar',
            Pincode__c = '563101',
            Primary_Phone_Number__c = '9876543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert existing;
        
        Employee__c newEmp = new Employee__c(
            Payroll__c = 'No',
            Is_Active__c = false,
            Reporting_Manager__c = testUser.Id,
            Approval_Status__c = 'Pending',
            Mail_Id__c = 'mainuserksksksk@esssxample.com',
            Aadhar_Number__c = '345456789012',
            Profile__c = 'TSE', // use a valid picklist value if applicable
            Sales_Channel__c = 'CPD', // use a valid picklist or reference value
            User_Name__c = 'mainustttkkkkersskskssskssssaaggg@esssxample.com',
            Working_District__c = 'Kolar',
            Pincode__c = '563101',
            Primary_Phone_Number__c = '9876543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert newEmp;
        
   
        
        Test.startTest();
        EmployeeDuplicationChecker.duplicationCheck(newEmp);
        Test.stopTest();

    }


    @isTest
    static void testNoDuplicates() {
        Employee__c emp = new Employee__c(
            Name = 'Unique Emp',
            User_Name__c = 'uniqueuser',
            Aadhar_Number__c = '999988887777',
            Employee_Code__c = 'UNQ001'
        );
        
        Test.startTest();
        EmployeeDuplicationChecker.DataBox result = EmployeeDuplicationChecker.duplicationCheck(emp);
        Test.stopTest();
        
        System.assertEquals(false, result.duplicateFound, 'Should not detect any duplicates');
        System.assertEquals('', result.duplicateField);
        System.assertEquals('', result.employeeName);
    }

    @isTest
    static void testNullInput() {
        Test.startTest();
        EmployeeDuplicationChecker.DataBox result = EmployeeDuplicationChecker.duplicationCheck(null);
        Test.stopTest();

        System.assertEquals(false, result.duplicateFound, 'Should handle null input gracefully');
        System.assertEquals('', result.duplicateField);
        System.assertEquals('', result.employeeName);
    }
}