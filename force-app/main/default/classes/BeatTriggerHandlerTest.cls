@isTest
public class BeatTriggerHandlerTest {

    
    @TestSetup
    static void setup() {
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        UserRole testRole = [SELECT Id FROM UserRole LIMIT 1];
        // Create test users
        User testUser1 = new User(
            Alias = 'tuser',
            Employee_Code__c  = '123sfgg212231',
            Email = 'testusersss@example.com',
            EmailEncodingKey = 'UTF-8',
            userroleId = testRole.Id,
            LastName = 'Test',
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
            Employee_Code__c  = '1232122DDD343',
            Email = 'testuser@example.com',
            userroleId = testRole.Id,
            ManagerId = testUser1.Id,
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
    
    // Helper method to create test data
    private static void createTestData() {
         Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
         UserRole testRole = [SELECT Id FROM UserRole LIMIT 1];
        // Create a test User
        User testUser = new User(
            Alias = 'testusr',
            Email = 'testuser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            userroleId = testRole.Id,
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser109rtyed56@testorg.com',
            Region__c = 'Tamil Nadu',
            Employee_Code__c = '441112',
            Payroll__c = 'No',
            ManagerId = UserInfo.getUserId()
        );
        insert testUser;
        
        // Create a second test User (Subordinate)
        User subUser = new User(
            Username = 'subuser@example.com',
            Email = 'subuser@example.com',
            Alias = 'subuser',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Region__c = 'Tamil Nadu',
            Employee_Code__c = '4411',
            Payroll__c = 'No',
            userroleId = testRole.Id,
             ManagerId = testUser.Id
        );
        insert subUser;
        
        system.runAs(testUser){
              Account acc = new Account(
            Name = 'Secondary Customer',
            OwnerId = testUser.Id,
            Customer_Type__c = 'Secondary Customer',
            Pincode__c = '123456',
            Primary_Phone_Number__c = '9876543210',
            State__c = 'Karnataka',
            District__c = 'Kolar',
               Outlet_Id__c = '123123'
        );
        insert acc;
        
        Account acc1 = new Account(
            Name = 'Primary Customer',
            OwnerId = testUser.Id,
            Customer_Type__c = 'Primary Customer',
            Pincode__c = '123456',
            Primary_Phone_Number__c = '9876543210',
            State__c = 'Karnataka',
            District__c = 'Kolar',
            SAP_Customer_Code__c = '2234'
        );
        insert acc1;
        
            area__c tr = new area__c();
        tr.Name = 'test11121';
        tr.Sales_Channel__c = 'CPD';
        tr.Region__c =	'Kerala';
        tr.Area__c  = 'Central';
        insert tr;
        
        Product_Mapping__c pm = new   Product_Mapping__c();
        pm.Customer__c = acc1.Id;
        pm.Payment_Term__c = '0003';
        pm.Chanel__c = 'CPD';
        pm.Exectuive__c = testUser.Id;
        pm.Area__c = tr.Id;
        //pm.Primary_Customer__c = acc1.Id;
        insert pm;
            
              Product_Mapping__c pm2 = new   Product_Mapping__c();
        pm2.Customer__c = acc.Id;
        pm2.Payment_Term__c = '0003';
        pm2.Chanel__c = 'CPD';
        pm2.Exectuive__c = testUser.Id;
        pm2.Area__c = tr.Id;
        pm2.Primary_Customer__c = acc1.Id;
        insert pm2;
        
        
        // Create test Child_beat__c records
        Child_beat__c testBeat1 = new Child_beat__c(
            Beat_Id_Text__c = '213223',
            Name = 'Test Beat 1',
            User__c = testUser.Id,
            Beat_Type__c = 'Secondary',
            Primary_Customer__c = acc1.Id,  // Sample Customer ID
            Sub_Stockist__c = null // Sample Customer ID
        );
        try {
                insert testBeat1;
            } catch (DmlException e) {
                //system.debug('Error:' + e.getMessage());
                System.assert(e.getMessage().contains('Primary Customer is not yet mapped'), 'The validation error should have been triggered.');
            }
       
        }
        
         
    }

    @isTest
    public static void testHandleValidations() {
        // Step 1: Create the necessary test data
        createTestData();
        
        User subUser = [SELECT Id FROM User WHERE Username = 'subuser@example.com'];
        Account prim = [select Id from Account where Sap_Customer_Code__c='2234' limit 1];
        
        system.runAs(subUser){
            
            // Step 2: Create a Child_beat__c record to trigger the handleValidations method
            Child_beat__c newBeat = new Child_beat__c(
                Beat_Id_Text__c = '111444',
                Name = 'Test Beat for Validation',
                OwnerId = subUser.id,
                User__c = subUser.Id,
                Beat_Type__c = 'Secondary',
                Primary_Customer__c = prim.Id,  // Sample Customer ID
                Sub_Stockist__c = null // Sample Customer ID
            );
            
            // Step 3: Simulate inserting the new beat record
            Test.startTest();
            insert newBeat;
            Test.stopTest();
            
            // Step 4: Query the created Product_Mapping__c and Employee_Customer_Assignment__c records
            List<Product_Mapping__c> productMappings = [SELECT Id, Customer__c, Exectuive__c, Primary_Customer__c FROM Product_Mapping__c];
            List<Employee_Customer_Assignment__c> employeeAssignments = [SELECT Id, Executive__c, Customer__c FROM Employee_Customer_Assignment__c where Executive__c =:subUser.id ];
            
            // Step 5: Assert that the mappings were created successfully
            // System.assertEquals(1, productMappings.size(), 'One Product Mapping record should have been created.');
            //System.assertEquals('001xx0000035P3zAA', productMappings[0].Customer__c, 'The Sub Stockist should be mapped.');
            
           // System.assertEquals(1, employeeAssignments.size(), 'One Employee Customer Assignment record should have been created.');
            //System.assertEquals(prim.Id, employeeAssignments[0].Customer__c, 'The Primary Customer should be assigned.');
        }
    }
    
    @isTest
    static void testBeforeInsert11() {
        
           Test.startTest();
        user testUser = [select Id,Name from User where Employee_Code__C = '123sfgg212231' limit 1];   
        
        user testUser2 = [select Id,Name from User where Employee_Code__C = '1232122DDD343' limit 1];   
        Employee__c emp = new Employee__c(
            Name = 'Test Employee',
            OwnerId = testUser.Id,
            Reporting_Manager__c = testUser2.Id,
            user__C = testUser.Id,
            IsDataUpload__c = true,
            Mail_Id__c = 'test@gmail.com', Aadhar_Number__c = '119977663390', Profile__c = 'ASM', Sales_Channel__c = 'TN', User_Name__c = 'my@tstasm.com'
        );
        
        Account acc = new Account(
            Name = 'Primary Customer',
            OwnerId = testUser.Id,
            Customer_Type__c = 'Secondary Customer',
            Pincode__c = '123456',
            Primary_Phone_Number__c = '9876543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert acc;
        
        Account acc1 = new Account(
            Name = 'Primary Customer',
            OwnerId = testUser.Id,
            Customer_Type__c = 'Primary Customer',
            Pincode__c = '123456',
            Primary_Phone_Number__c = '9876543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert acc1;
        
        Account acc2 = new Account(
            Name = 'Primary Customer',
            OwnerId = testUser.Id,
            Customer_Type__c = 'Primary Customer',
            Pincode__c = '123456',
            Primary_Phone_Number__c = '2276543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert acc2;
        
        
        // Create test accounts
        Account newAcc = new Account(Name = 'Secondary Customer',
                                     Customer_Type__c = 'Secondary Customer',
                                     Customer_Status__c = 'Active',
                                     Secondary_Customer_Type__c = 'Sub Stockiest',
                                     SAP_Customer_Code__c = 'SAP0012233',
                                     City__c = 'Delhi',
                                     State__c = 'Delhi',
                                     District__c = 'New Delhi',
                                     Pincode__c = '110001',
                                     Primary_Phone_Number__c = '1234567890');
        insert newAcc;
        
        Profile p = [SELECT Id, Name FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        UserRole ur = [SELECT Id FROM UserRole LIMIT 1];
        
        area__c tr = new area__c();
        tr.Name = 'test';
        tr.Sales_Channel__c = 'CPD';
        tr.Region__c =	'Kerala';
        tr.Area__c  = 'Central';
        insert tr;
        
        Product_Mapping__c pm3 = new   Product_Mapping__c();
        pm3.Customer__c = acc1.Id;
        pm3.Chanel__c = 'CPD';
        pm3.Parent_Depot__c ='1100';
        pm3.Child_Depot__c ='1100';
        pm3.Payment_Term__c = '0003';
        pm3.Area__c = tr.Id;
        pm3.Exectuive__c = testUser.Id;
        insert pm3;
        
        Product_Mapping__c pm4 = new   Product_Mapping__c();
        pm4.Customer__c = acc2.Id;
        pm4.Chanel__c = 'CPD';
        pm4.Parent_Depot__c ='1100';
        pm4.Area__c = tr.Id;
        pm4.Child_Depot__c ='1100';
        pm4.Payment_Term__c = '0003';
        pm4.Exectuive__c = testUser2.Id;
        insert pm4;
        
        // Create Employee_Customer_Assignment__c
        Employee_Customer_Assignment__c eca = new Employee_Customer_Assignment__c(
            Executive__c = testUser.Id,
            Employee__c = emp.Id,
            Customer__c = acc2.Id
        );
        insert eca;
        
        
        
        
        Product_Mapping__c pm = new   Product_Mapping__c();
        pm.Customer__c = acc.Id;
        pm.Payment_Term__c = '0003';
        pm.Area__c = tr.Id;
        pm.Exectuive__c = testUser.Id;
        pm.Primary_Customer__c = acc1.Id;
        insert pm;
        
        
        Product_Mapping__c pm1 = new Product_Mapping__c(
            Customer__c = newAcc.Id,
            Payment_Term__c = '0003',
            Area__c = tr.Id,
            Exectuive__c = testUser.Id,
            Primary_Customer__c = acc1.Id
        );
        insert pm1;
        
        pm1.Primary_Customer__c = acc2.Id;
        update pm1;
        
     
        // Step 2: Create a Child_beat__c record to trigger the handleValidations method
        Child_beat__c newBeat = new Child_beat__c(
            Beat_Id_Text__c = '111444',
            Name = 'Test Beat for Validation',
            OwnerId = testUser.id,
            User__c = testUser.Id,
            Cloned_From_Customer_Deactivation__c = false,
            Cloned_From_Employee_Replacement__c = false,
            Beat_Type__c = 'Primary'
            //Primary_Customer__c = prim.Id,  // Sample Customer ID
            // Sub_Stockist__c = null // Sample Customer ID
        );
        insert newBeat;
        // Step 3: Simulate inserting the new beat record
        
        
        
        Junction_Beat__c duplicateRecord = new Junction_Beat__c(
            Account__c = acc1.Id,
            Child_beat__c = newBeat.Id
        );
          Junction_Beat__c duplicateRecord1 = new Junction_Beat__c(
            Account__c = acc2.Id,
            Child_beat__c = newBeat.Id
        );
        insert duplicateRecord1;
        Child_beat__c bt = [select Id ,name,OwnerId,Beat_Type__c,Cloned_From_Employee_Replacement__c,
                            Cloned_From_Customer_Deactivation__c from Child_beat__c where Beat_Id_Text__c ='111444'];
        BeatTriggerHandler.handleValidations(new List<Child_beat__c>{bt});
        Test.stopTest();
        
    }
       @isTest
    public static void testCreateSecMappings() {
        // Step 1: Prepare the test data
        createTestData();
        
        User testUser = [SELECT Id FROM User WHERE Username = 'testuser109rtyed56@testorg.com'];
        Account prim = [select Id from Account where Sap_Customer_Code__c='2234' limit 1];
        Account sec = [select id from Account where Outlet_Id__c ='123123' limit 1];
        
        system.runAs(testUser){
              // Create test Child_beat__c records
        Child_beat__c testBeat1 = new Child_beat__c(
            Beat_Id_Text__c = '2131223',
            Name = 'Test Beat 1',
            User__c = testUser.Id,
            Beat_Type__c = 'Secondary',
            Primary_Customer__c = prim.Id,  // Sample Customer ID
            Sub_Stockist__c = null // Sample Customer ID
        );
         insert testBeat1;
            
            Child_beat__c testBeat2 = new Child_beat__c(
            Beat_Id_Text__c = '3213123',
            Name = 'Test Beat 2',
            User__c = testUser.Id,
            Beat_Type__c = 'Primary'
        );
         insert testBeat2;
            
              // Step 2: Create Junction_Beat__c record for linking Child_Beat__c to Product_Mapping__c
        Junction_Beat__c junctionBeat2 = new Junction_Beat__c(
            Child_Beat__c = testBeat2.Id,
            Account__c = prim.Id
        );
        insert junctionBeat2;
           
       
        List<Employee_Customer_Assignment__c> employeeAssignments = [SELECT Id, Executive__c, Customer__c 
                                                                     FROM Employee_Customer_Assignment__c where Executive__c=:testUser.Id ];
        system.debug('employeeAssignments:'+ employeeAssignments);
        
        // Step 2: Create Junction_Beat__c record for linking Child_Beat__c to Product_Mapping__c
        Junction_Beat__c junctionBeat = new Junction_Beat__c(
            Child_Beat__c = testBeat1.Id,
            Account__c = sec.Id
        );
        insert junctionBeat;
            
           
        
        // Step 3: Simulate calling the createSecMappings method
        Test.startTest();
        BeatTriggerHandler.createSecMappings(new List<Child_beat__c>{testBeat1,testBeat2});
        Test.stopTest();
        
        // Step 4: Verify that the Product_Mapping__c records were created
        List<Product_Mapping__c> productMappings = [SELECT Id, Customer__c, Exectuive__c, Primary_Customer__c, Sub_Stockiest__c 
                                                    FROM Product_Mapping__c  where Exectuive__c =:testUser.id];
        
        // Step 5: Assert that the mappings were created successfully
        //System.assertEquals(1, productMappings.size(), 'One Product Mapping record should have been created.');
       // System.assertEquals(sec.Id, productMappings[0].Customer__c, 'The Account/Customer should be mapped.');
       // System.assertEquals(prim.Id, productMappings[0].Primary_Customer__c, 'The Primary Customer should be mapped.');
        //System.assertEquals('001xx0000035P3zAA', productMappings[0].Sub_Stockiest__c, 'The Sub Stockist should be mapped.');
        }
        
       
    }

    @isTest
    public static void testHandleValidationsWithError() {
        // Step 1: Create the necessary test data
        createTestData();
        
        User u = [select Id from User where Id =:UserInfo.getUserId()];
        
        system.runAs(u){
            
            // Step 2: Create a Child_beat__c record with invalid mappings that should trigger an error
            Child_beat__c newBeat = new Child_beat__c(
                Name = 'Invalid Test Beat',
                OwnerId =UserInfo.getUserId(),
                User__c = UserInfo.getUserId(),
                Beat_Type__c = 'Secondary',
                Primary_Customer__c = [select Id from Account where Sap_Customer_Code__c='2234' limit 1].Id, // Sample Customer ID
                Sub_Stockist__c = null // Sample Customer ID
            );
            
            // Step 3: Simulate inserting the new beat record and check for validation errors
            Test.startTest();
            try {
                insert newBeat;
            } catch (DmlException e) {
                //system.debug('Error:' + e.getMessage());
                System.assert(e.getMessage().contains('Primary Customer is not yet mapped'), 'The validation error should have been triggered.');
            }
            Test.stopTest();
        }
       
    }
}