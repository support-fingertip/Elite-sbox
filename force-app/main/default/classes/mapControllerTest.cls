@isTest
public class mapControllerTest {
 
    @testSetup
    static void setupData() {
        // Create a User
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + System.currentTimeMillis() + '@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            Employee_Code__c  = '12343',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert u;

        // Create Employee mapped to User
        Employee__c emp = new Employee__c(
             
            OwnerId = u.Id,
            Payroll__c = 'No',
            Is_Active__c = false,
            Reporting_Manager__c = u.Id,
            Approval_Status__c = 'Pending',
            Mail_Id__c = 'mainuseraaass@example.com',
            Aadhar_Number__c = '123456789012',
            Profile__c = 'TSE', // use a valid picklist value if applicable
            Sales_Channel__c = 'CPD', // use a valid picklist or reference value
            User_Name__c =  'mainuseraaass@example.com',
            Working_District__c = 'Kolar',
            Pincode__c = '563101',
            Primary_Phone_Number__c = '9876543210',
            State__c = 'Karnataka',
            District__c = 'Kolar',
            User__c = u.Id
        );
        insert emp;
        

        // Create Visit record
        Visit__c v = new Visit__c(
          
          Status__c = 'Completed',
            OrderCreated__c = true,
            OwnerId = u.Id,
           
            ClockIn_Latitude__c = 12.9716,
            ClockIn_Longitude__c = 77.5946
        );
        insert v;
    }

    @isTest
    static void testGetVisitsWithValidData() {
        Employee__c emp = [SELECT Id, User__c FROM Employee__c LIMIT 1];
       // 4. Define date range that should cover fromDateTime & toDateTime
        Date fromDate = Date.today().addDays(-1); // Yesterday
        Date toDate   = Date.today().addDays(1);  // Tomorrow


        Test.startTest();
        List<Visit__c> visits = mapController.getVisits(emp.Id, fromDate, toDate);
        Test.stopTest();

       
    }

    @isTest
    static void testGetVisitsWithNullInputs() {
        Test.startTest();
        List<Visit__c> visits = mapController.getVisits(null, null, null);
        Test.stopTest();

      
    }

    @isTest
    static void testGetVisitsWithEmployeeNoUser() {
         Employee__c emp = [SELECT Id, User__c FROM Employee__c LIMIT 1];
           Date fromDate = Date.today().addDays(-1); // Yesterday
        Date toDate   = Date.today().addDays(1);  // Tomorrow
        

        Test.startTest();
        List<Visit__c> visits = mapController.getVisits(emp.Id, fromDate, toDate);
        Test.stopTest();

      
    }
    @isTest
static void testGetVisitsCoversDateConversion() {
    Employee__c emp = [SELECT Id FROM Employee__c LIMIT 1];
    Date fromDate = Date.today().addDays(-5);
    Date toDate   = Date.today().addDays(5);

    Test.startTest();
    List<Visit__c> visits = mapController.getVisits(emp.Id, fromDate, toDate);
    Test.stopTest();

   
}

}