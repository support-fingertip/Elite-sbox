@isTest
private class PJPItemHandlerTest {
    
     @testSetup
    static void setup() {
        Profile tseProfile = [SELECT Id FROM Profile WHERE Name = 'TSE' LIMIT 1];
        UserRole testRole = [SELECT Id FROM UserRole LIMIT 1];

        // Manager user (this user receives Product_Mapping__c to satisfy the
        // reporting-manager validation in the handler)
        User managerUser = new User(
            Alias = 'ecah0',
            Employee_Code__c = 'ECAHMGR001',
            Email = 'ecah.mgr@example.com',
            EmailEncodingKey = 'UTF-8',
            UserRoleId = testRole.Id,
            LastName = 'EcahManager',
            IsActive = true,
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = tseProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'ecah.mgr@example.com' + System.currentTimeMillis(),
            Sales_Channel__c = 'Cake'
        );
        insert managerUser;

        // Executive user with ManagerId set - so Reporting_Manager_Employee_Id__c
        // formula evaluates to manager's Id.
        User executiveUser = new User(
            Alias = 'ecah1',
            Employee_Code__c = 'ECAHEXEC001',
            Email = 'eca1h.exec@example.com',
            EmailEncodingKey = 'UTF-8',
            UserRoleId = testRole.Id,
            ManagerId = managerUser.Id,
            LastName = 'EcahExecutive',
            IsActive = true,
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = tseProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'ec1eah.exec@example.com' + System.currentTimeMillis(),
            Sales_Channel__c = 'Cake'
        );
        insert executiveUser;

        // Inactive user - used to exercise the "activeUserIds does not contain"
        // branch of afterInsert, no AccountShare created.
        User inactiveUser = new User(
            Alias = 'ecah2',
            Employee_Code__c = 'ECAHINAC001',
            Email = 'ec2ah.inac@example.com',
            EmailEncodingKey = 'UTF-8',
            UserRoleId = testRole.Id,
            LastName = 'EcahInactive',
            IsActive = true,
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = tseProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'eca2h.inac@example.com' + System.currentTimeMillis(),
            Sales_Channel__c = 'Cake'
        );
        insert inactiveUser;
    }

    
   private static Map<String, SObject> buildBaseData() {
        Map<String, SObject> data = new Map<String, SObject>();

        User managerUser = [SELECT Id FROM User WHERE Employee_Code__c = 'ECAHMGR001' LIMIT 1];
        User executiveUser = [SELECT Id, ManagerId FROM User WHERE Employee_Code__c = 'ECAHEXEC001' LIMIT 1];

        data.put('managerUser', managerUser);
        data.put('executiveUser', executiveUser);

        // Employee for the executive user
        Employee__c exeEmp = new Employee__c(
            Name = 'Ecah Exe Emp',
            User__c = executiveUser.Id,
            Is_Active__c = true,
            Payroll__c = 'Yes',
            Reporting_Manager__c = managerUser.Id,
            Sales_Channel__c = 'Cake',
            Mail_Id__c = 'ecah.exe.emp@example.com',
            Aadhar_Number__c = '555566667788',
            Profile__c = 'DSM',
            IsDataUpload__c = true,
            User_Name__c = 'ecah.exe.emp@example.com'
        );
        insert exeEmp;
        data.put('exeEmp', exeEmp);

        area__c area = new area__c(
            Name = 'ecah area',
            Sales_Channel__c = 'CPD',
            Region__c = 'Kerala',
            Area__c = 'Central'
        );
        insert area;
        data.put('area', area);

        // Accounts
        Account primary1 = new Account(
            Name = 'Ecah Primary 1',
            Customer_Type__c = 'Primary Customer',
            Customer_Status__c = 'Active',
            SAP_Customer_Code__c = 'ECAHSAP001',
            Area__c = area.Id,
            State__c = 'Karnataka',
            District__c = 'Kolar',
            Pincode__c = '560001',
            Primary_Phone_Number__c = '9100000001'
        );
        Account primary2 = new Account(
            Name = 'Ecah Primary 2',
            Customer_Type__c = 'Primary Customer',
            Customer_Status__c = 'Active',
            SAP_Customer_Code__c = 'ECAHSAP002',
            Area__c = area.Id,
            State__c = 'Karnataka',
            District__c = 'Kolar',
            Pincode__c = '560001',
            Primary_Phone_Number__c = '9100000002'
        );
        insert new List<Account>{ primary1, primary2 };
        data.put('primary1', primary1);
        data.put('primary2', primary2);

        // Manager user has Product_Mapping__c for primary1 - so the reporting
        // manager validation passes when ECA.Customer__c = primary1.Id
        Product_Mapping__c managerPm = new Product_Mapping__c(
            Exectuive__c = managerUser.Id,
            Customer__c = primary1.Id,
      //      Customer_Type__c = 'Primary Customer',
            Primary_Customer__c = primary1.Id,
            Area__c = area.Id,
            Payment_Term__c = '0003',
            Chanel__c = 'CPD'
        );
        insert managerPm;
        data.put('managerPm', managerPm);

        return data;
    }

    @isTest
    static void testUpdatePjpItemsAfterApproval() {
        // Step 1: Create a user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'pjptestuser@example.com',
            Username = 'pjptestuser' + System.currentTimeMillis() + '@example.com',
            Alias = 'pjptu',
            ProfileId = p.Id,
            Employee_Code__c = 'EMP002111121166',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;

              
        Calendar_beat__c pjp = new Calendar_beat__c(
            OwnerId = testUser.Id,
            User__c = testUser.Id
        );
        insert pjp;
        // Step 3: Create PJP Items with various statuses
        List<PJP_Item__c> items = new List<PJP_Item__c>{
            new PJP_Item__c( PJP__c = pjp.Id,Date__c=Date.today(), Status__c = 'Submitted'),
            new PJP_Item__c( PJP__c = pjp.Id,Date__c=Date.today().addDays(1), Status__c = 'Not Submitted'),
            new PJP_Item__c(PJP__c = pjp.Id,Date__c=Date.today().addDays(2), Status__c = 'Approved'), // Should be skipped
            new PJP_Item__c(PJP__c = pjp.Id,Date__c=Date.today().addDays(3), Status__c = 'Rejected')  // Should be skipped
        };
        insert items;

        // Step 4: Call the method to test
        Test.startTest();
        PJPItemHandler.updatePjpItemsAfterApproval(pjp.Id);
        Test.stopTest();

        // Done - no assertions as per request
    }
     @isTest
    static void testDeactivateBeats() {
          // Step 1: Create a user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'pjptestuser@example.com',
            Username = 'pjptestuser' + System.currentTimeMillis() + '@example.com',
            Alias = 'pjptu',
            ProfileId = p.Id,
            Employee_Code__c = 'EMP002HSHER111121166',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        // Step 1: Create sample accounts
/*        Account acc1 = new Account(
            Customer_Type__c = 'Secondary Customer',
            Name = 'Primary Customer',
            OwnerId = testUser.Id,
            Pincode__c = '123456',
            Primary_Phone_Number__c = '6646543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        Account acc2 = new Account(
            Customer_Type__c = 'Secondary Customer',
            Name = 'Primary Customer',
            OwnerId = testUser.Id,
            Pincode__c = '123456',
            Primary_Phone_Number__c = '7746543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert new List<Account>{ acc1, acc2 };
*/
        Map<String, SObject> data = buildBaseData();
        User executiveUser = (User) data.get('executiveUser');
        Employee__c exeEmp = (Employee__c) data.get('exeEmp');
        Account primary1 = (Account) data.get('primary1');
        area__c area = (area__c) data.get('area');

        // Secondary account
        Account subStockist = new Account(
            Name = 'Ecah Sub Stockist',
            Customer_Type__c = 'Primary Customer',
            Secondary_Customer_Type__c = 'Sub Stockiest',
            Customer_Status__c = 'Active',
            SAP_Customer_Code__c = 'ECAHSAPSUB',
            State__c = 'Karnataka',
            District__c = 'Kolar',
            Pincode__c = '560001',
            Primary_Phone_Number__c = '9100000003'
        );
        insert subStockist;

        // A product mapping that links subStockist to primary1 - afterInsert
        // will find this via the `Primary_Customer__c IN :primaryCustomerIds`
        // query and create an auto-mapping for our new executive.
        Product_Mapping__c secondaryPm = new Product_Mapping__c(
            Exectuive__c = executiveUser.Id,
            Customer__c = subStockist.Id,
            Primary_Customer__c = primary1.Id,
       //     Secondary_Customer_Type__c = 'Sub Stockiest',
            Area__c = area.Id,
            Payment_Term__c = '0003',
            Chanel__c = 'CPD'
        );
        insert secondaryPm;
        
        // Step 2: Create Child Beats with Active__c = true
        List<Child_beat__c> beats = new List<Child_beat__c>{
            new Child_beat__c(Name = 'Beat A', Primary_Customer__c = subStockist.Id, Active__c = true,Beat_Type__c ='Primary')
      //      new Child_beat__c(Name = 'Beat B', Sub_Stockist__c = secondary.Id, Active__c = true,Beat_Type__c ='Primary')
        };
        insert beats;

        // Step 3: Create Junction Beats
        List<Junction_Beat__c> junctions = new List<Junction_Beat__c>{
            new Junction_Beat__c( Account__c = subStockist.Id,Child_beat__c =beats[0].Id,Active__c = true)
  //          new Junction_Beat__c( Account__c = secondary.Id, Child_beat__c =beats[0].Id,Active__c = true)
        };
        insert junctions;

        // Step 4: Call method
        Set<Id> accIds = new Set<Id>{  subStockist.Id };
        Test.startTest();
        PJPItemHandler.deactivateBeats(accIds);
        Test.stopTest();

        // No assertions needed per your instruction
    }
     @isTest
    static void testHandleValidations() {
        // Prepare test data
        Account acc = new Account(
            Customer_Type__c = 'Secondary Customer',
            Name = 'Primary Customer',
            OwnerId = UserInfo.getUserId(),
            Pincode__c = '123456',
            Primary_Phone_Number__c = '6646543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert acc;

         Calendar_beat__c pjp = new Calendar_beat__c(
            OwnerId = UserInfo.getUserId(),
            User__c = UserInfo.getUserId()
        );
        insert pjp;
      
        PJP_Item__c pjpItem1 = new PJP_Item__c(PJP__c = pjp.Id, Beat__c = null, Date__c = Date.today(), Status__c = 'Approved');
         insert pjpItem1;
        PJP_Item__c pjpItem2 = new PJP_Item__c(PJP__c = pjp.Id, Beat__c = null, Date__c = Date.today(), Status__c = 'Approved');
           Test.startTest();
        try {
            insert pjpItem2;
            // If we reach here, the validation did not fire as expected
            System.assert(false, 'Expected a FIELD_CUSTOM_VALIDATION_EXCEPTION due to duplicate PJP Item.');
        } catch (DmlException e) {
            // Verify if the expected error message is in the exception
            System.assert(e.getMessage().contains('A PJP Item for this PJP and Date already exists. Please update the existing item instead of creating a new one.'), 'Expected validation error not found.');
        }
        
        Test.stopTest();
    }
}