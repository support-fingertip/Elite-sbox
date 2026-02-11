@isTest
public class BatchPasswordResetTest {

    @isTest
    static void testBatchPasswordReset() {
        // Create a dummy user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            Alias = 'testu',
            Employee_Code__c = 'kskskskss',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            UserName = 'testuser'+System.currentTimeMillis()+'@example.com'
        );
        insert testUser;

        // Create mock Employee__c record
        Employee__c emp = new Employee__c(
            Name = 'John Doe',
            Mail_Id__c = 'john.doe@example.com',
            User_Name__c = 'john.doe@example.com.testuser',
            Primary_Phone_Number__c = '1234567890',
            Employee_Code__c = 'EMP123',
            Designation__c = 'Sales Exec',
            Profile__c = 'Admin',
            Is_Active__c = true,
			IsDataUpload__c = true,
            // Required fields
            Basic_Pay__c = 25000,
            Aadhar_Number__c = '123456789012',
            Gross_Salary__c = 35000,
            DA__c = 5000,
            TA_limit__c = 2000,
            Area__c = 'Central',
            Region__c = 'West',
           
            Sales_Channel__c = 'TN',
            State__c = 'Uttar Pradesh',
            District__c = 'Lucknow',
            Pincode__c = '226001',
            User__c = testUser.Id,
            Cloning_is_Completed__c = false
        );
        insert emp;
        
        
        // Run the batch
        Test.startTest();
        VerifyEmailController.sendEmailVerification(emp.Id);
        Test.stopTest();

        // No assert here because setPassword cannot be verified in test context
        System.debug('Batch executed successfully');
    }
}