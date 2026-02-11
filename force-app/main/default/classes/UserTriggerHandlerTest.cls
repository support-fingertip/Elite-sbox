@isTest
public class UserTriggerHandlerTest {

    @isTest
    public static void setupData() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
              
        
        User approver1 = new User(
            FirstName = 'Approver1',
            LastName = 'User',
            Email = 'approver1@example.com',
            Username = 'approver1@example.com' + System.currentTimeMillis(),
            ProfileId = profile.Id,
            Alias = 'aprv1',
            Employee_Code__c = 'EMP001',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles'
        );
        insert approver1;
        
          
        User mainUser = new User(
            FirstName = 'Main',
            LastName = 'User',
            Email = 'mainuser@example.com',
            Username = 'mainuser@example.com' + System.currentTimeMillis(),
            ProfileId = profile.Id,
            Alias = 'mainu',
            Employee_Code__c = 'EMP002',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            RSM__c = approver1.Id,
            ASM_TSM__c = approver1.Id,
            Employee_Approver_3_HR__c = approver1.Id,
            Primary_Customer_Approver_1__c = approver1.Id,
            Primary_Customer_Approver_2__c = approver1.Id,
            Primary_Customer_Approver_3_Credit_Dept__c = approver1.Id,
            Secondary_Customer_Approver_1__c = approver1.Id,
            Secondary_Customer_Approver_2__c = approver1.Id,
            Expense_Approver_1__c = approver1.Id,
            Expense_Approver_2_Finance_Dept__c = approver1.Id,
            PJP_Approver_1__c = approver1.Id
        );
        insert mainUser;
        
        
        // Create mock Employee__c record
        Employee__c emp1 = new Employee__c(
            Name = 'John Doe',
            Mail_Id__c = 'john.doe@example.com',
            User_Name__c = 'john.doe@example.com.testuser',
            Primary_Phone_Number__c = '1234567890',
            Employee_Code__c = 'EMP123',
            Designation__c = 'Sales Exec',
            Profile__c = 'Admin',
            Is_Active__c = false,
            // Required fields
            Basic_Pay__c = 25000,
            Aadhar_Number__c = '123456789012',
            Gross_Salary__c = 35000,
            DA__c = 5000,
            TA_limit__c = 2000,
            Area__c = 'Central',
            Region__c = 'West',
            Sales_Channel__c = 'Cake',
            State__c = 'Uttar Pradesh',
            District__c = 'Lucknow',
            Pincode__c = '226001',
            User__c = mainUser.Id,
            Cloning_is_Completed__c = false
        );
        insert emp1;
        
  
      
        
        Employee__c emp = new Employee__c(
            OwnerId = mainUser.Id,
            Payroll__c = 'No',
            Is_Active__c = false,
            Reporting_Manager__c = mainUser.Id,
            Approval_Status__c = 'Pending',
            Mail_Id__c = 'mainuser@example.com',
            Aadhar_Number__c = '123456789012',
            Profile__c = 'TSE', // use a valid picklist value if applicable
            Sales_Channel__c = 'CPD', // use a valid picklist or reference value
            User_Name__c = mainUser.Username,
            Working_District__c = 'Kolar',
            Pincode__c = '563101',
            Primary_Phone_Number__c = '9876543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert emp;
        
        Account primaryAcc = new Account(
            Name = 'Primary Customer',
            OwnerId = mainUser.Id,
            Customer_Type__c = 'Primary Customer',
            Pincode__c = '123456',
            Primary_Phone_Number__c = '2876543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert primaryAcc;
        
        Account secondaryAcc = new Account(
            Customer_Type__c = 'Secondary Customer',
            Name = 'Primary Customer',
            OwnerId = mainUser.Id,
            Pincode__c = '123456',
            Primary_Phone_Number__c = '9846543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert secondaryAcc;
        

        
        Calendar_beat__c pjp = new Calendar_beat__c(
            OwnerId = mainUser.Id,
            User__c = mainUser.Id
        );
        insert pjp;
        
        
        
        mainUser.RSM__c = null;
        mainUser.ASM_TSM__c = null;
        mainUser.Employee_Approver_3_HR__c = null;
        mainUser.Primary_Customer_Approver_1__c = null;
        mainUser.Primary_Customer_Approver_2__c = null;
        mainUser.Primary_Customer_Approver_3_Credit_Dept__c = null;
        mainUser.Secondary_Customer_Approver_1__c = null;
        mainUser.Secondary_Customer_Approver_2__c = null;
        mainUser.Expense_Approver_1__c = null;
        mainUser.Expense_Approver_2_Finance_Dept__c = null;
        mainUser.PJP_Approver_1__c = null;
        update mainUser;
        
        SyncApprovers.syncApprovers(emp1.Id);

    }
    
}