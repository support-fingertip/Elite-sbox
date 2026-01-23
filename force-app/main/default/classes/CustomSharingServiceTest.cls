@isTest
public class CustomSharingServiceTest {
   
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
    

    @isTest
    static void testLinkFilesToRecords() {
        Account primaryOld = new Account(
            Name = 'Primary Old',
            Pincode__c = '560001',
            Primary_Phone_Number__c = '0876542210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert primaryOld;
        
        // Create ContentVersion -> ContentDocument
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.pdf',
            VersionData = Blob.valueOf('Test Content'),
            Description = 'UNIQUE_TEST_FILE'
        );
        insert cv;

        Id docId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = docId,
            LinkedEntityId = primaryOld.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;
  
        Set<String> fileIds = new Set<String>{ 'UNIQUE_TEST_FILE' };
        Map<String, Id> recordMap = new Map<String, Id>{ 'UNIQUE_TEST_FILE' => primaryOld.Id };

        Test.startTest();
        CustomSharingService.linkFilesToRecords(fileIds, recordMap);
        Test.stopTest();

    }



   @isTest
    static void testEmployeeReplacement() {
            
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
        insert emp;
        
           Employee__c emp1 = new Employee__c(
            Name = 'Test Employee11',
            OwnerId = testUser2.Id,
            user__C = testUser2.Id,
            IsDataUpload__c = true,
            Mail_Id__c = 'test@gmail1111.com', Aadhar_Number__c = '111977663390', Profile__c = 'ASM', Sales_Channel__c = 'TN', User_Name__c = 'my@tstasm.com'
        );
         insert emp1;
        
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
        pm4.Exectuive__c = testUser.Id;
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
        
        Test.startTest();
        // Step 2: Create a Child_beat__c record to trigger the handleValidations method
        Child_beat__c newBeat = new Child_beat__c(
            Beat_Id_Text__c = '111444',
            Name = 'Test Beat for Validation',
            OwnerId = testUser2.id,
            User__c = testUser2.Id,
            Beat_Type__c = 'Primary'
            //Primary_Customer__c = prim.Id,  // Sample Customer ID
            // Sub_Stockist__c = null // Sample Customer ID
        );
        insert newBeat;
        // Step 3: Simulate inserting the new beat record
   
    
        
        Junction_Beat__c duplicateRecord = new Junction_Beat__c(
            Account__c = acc.Id,
            Child_beat__c = newBeat.Id
        );
        
        
        // Execute method
        Map<String, String> oldToNewMap = new Map<String, String>();
        Map<String, String> oldToNewMap2 = new Map<String, String>();
        oldToNewMap.put(testUser.Id, testUser2.Id);
        oldToNewMap2.put(testUser2.Id, testUser.Id);
        
        CustomSharingService.employeeReplacement(oldToNewMap);
        Database.executeBatch(new BeatCloneBatch(oldToNewMap2), 50);
        //Database.executeBatch(new EmployeeReplacementBatch(testUser.Id, testUser2.Id,emp1.Id,emp.Id,'TEST','TEST'), 50);
        
        Test.stopTest();
        
    }
    
    
    @isTest
    static void testCustomerReplacement() {
        Account primaryOld = new Account(
            Name = 'Primary Old',
            Pincode__c = '560001',
            Primary_Phone_Number__c = '2876543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert primaryOld;
        Account primaryNew = new Account(
            Name = 'Primary New',
            Pincode__c = '560001',
            Primary_Phone_Number__c = '2976543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert primaryNew;
        
        Account subOld = new Account(
            Name = 'Sub Old',
            Pincode__c = '560001',
            Primary_Phone_Number__c = '0876543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert subOld;
        Account subNew = new Account(
            Name = 'Sub New',
            Pincode__c = '560001',
            Primary_Phone_Number__c = '0826543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert subNew;
        
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User u = new User(
            FirstName = 'Approver1',
            LastName = 'User',
            Email = 'approver1@example11.com',
            Username = 'approver1@example22.com' + System.currentTimeMillis(),
            ProfileId = p.Id,
            Alias = 'aprv1',
            Employee_Code__c = 'EMP02198212RTQ201',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles'
        );
        insert u;
        set<Id> userids = new set<Id>();
        userids.add(u.Id);
        
        
        
        // Create Product Mapping for old primary customer
        Product_Mapping__c pmPrimary = new Product_Mapping__c(
            Exectuive__c = u.Id,
            Customer__c = primaryOld.Id,
            Primary_Customer__c = primaryOld.Id,
            Payment_Term__c = '0003'
        );
        
        // Create Product Mapping for sub stockist
        Product_Mapping__c pmSub = new Product_Mapping__c(
            Exectuive__c = u.Id,
            Customer__c = subOld.Id,
            Sub_Stockiest__c = subOld.Id,
            Primary_Customer__c = primaryOld.Id,
            Payment_Term__c = '0003'
        );
        
        insert new List<Product_Mapping__c>{pmPrimary, pmSub};
            
            // Create Child Beat with both primary and sub stockist
            Child_beat__c beatPrimary = new Child_beat__c(
                Name = 'Beat P',
                Primary_Customer__c = primaryOld.Id,
                OwnerId = u.Id,
                Beat_Type__c ='Primary'
            );
        
        Child_beat__c beatSub = new Child_beat__c(
            Name = 'Beat S',
            Sub_Stockist__c = subOld.Id,
            Primary_Customer__c = primaryOld.Id,
            OwnerId = u.Id,
            Beat_Type__c ='Primary'
        );
        
        insert new List<Child_beat__c>{beatPrimary, beatSub};
            
 
            
            // Prepare the replacement maps
            Map<String, String> primaryMap = new Map<String, String>{
                primaryOld.Id => primaryNew.Id
                    };
                        
                        Map<String, String> subStockistMap = new Map<String, String>{
                            subOld.Id => subNew.Id
                                };
                                    
                                    Test.startTest();
        CustomSharingService.customerReplacement(primaryMap, subStockistMap);
        
        Test.stopTest();
        
        // Validate cloned records exist
        List<Product_Mapping__c> clonedPMs = [
            SELECT Id, Cloning_From_Customer_Deactivation__c FROM Product_Mapping__c
            WHERE Cloning_From_Customer_Deactivation__c = true
        ];
        System.debug('Cloned Product Mappings: ' + clonedPMs);
        
        List<Child_beat__c> clonedBeats = [
            SELECT Id FROM Child_beat__c
            WHERE Cloned_From_Customer_Deactivation__c = true
        ];
        System.debug('Cloned Beats: ' + clonedBeats);
        
        List<Junction_Beat__c> clonedJBs = [
            SELECT Id FROM Junction_Beat__c
            WHERE Cloned_From_Customer_Deactivation__c = true
        ];
        System.debug('Cloned Junction Beats: ' + clonedJBs);
    }

    @IsTest
    static void testRemoveAccountSharesWithMap() {
        // Setup data
        Account acc = new Account(
            Name = 'Primary Old',
            Pincode__c = '560001',
            Primary_Phone_Number__c = '2876543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert acc;
        
        user u1 = [select Id,Name from User where Employee_Code__C = '123sfgg212231' limit 1];   
        
        user u2 = [select Id,Name from User where Employee_Code__C = '1232122DDD343' limit 1];   

        
        // Insert shares
        AccountShare s1 = new AccountShare(AccountId = acc.Id, UserOrGroupId = u1.Id, AccountAccessLevel='Read', RowCause='Manual',OpportunityAccessLevel='Read');
        AccountShare s2 = new AccountShare(AccountId = acc.Id, UserOrGroupId = u2.Id, AccountAccessLevel='Edit', RowCause='Manual',OpportunityAccessLevel='Read');
        insert new List<AccountShare>{ s1, s2 };
        
        Test.startTest();
        // Prepare map: Account -> Users
        Map<Id, List<Id>> accToUsers = new Map<Id, List<Id>>();
        accToUsers.put(acc.Id, new List<Id>{ u1.Id, u2.Id });
        
        // Call method
        CustomSharingService.removeAccountSharesWithMap(accToUsers);
        Test.stopTest();

    }
    
    @IsTest
    static void testRemoveAccountWithPairShares() {
        // Setup data
          // Setup data
        Account acc = new Account(
            Name = 'Primary Old',
            Pincode__c = '560001',
            Primary_Phone_Number__c = '1876543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert acc;
        
        user u3 = [select Id,Name from User where Employee_Code__C = '123sfgg212231' limit 1];   
        
        user u4 = [select Id,Name from User where Employee_Code__C = '1232122DDD343' limit 1];   

        
        // Insert shares
        AccountShare s3 = new AccountShare(AccountId = acc.Id, UserOrGroupId = u3.Id, AccountAccessLevel='Read', RowCause='Manual',OpportunityAccessLevel='Read');
        AccountShare s4 = new AccountShare(AccountId = acc.Id, UserOrGroupId = u4.Id, AccountAccessLevel='Read', RowCause='Manual',OpportunityAccessLevel='Read');
        insert new List<AccountShare>{ s3, s4 };
        
        // Prepare sets
        Set<Id> accountIds = new Set<Id>{ acc.Id };
        Set<Id> userIds = new Set<Id>{ u3.Id, u4.Id };
        
        // Pair key = AccountId_UserId
        Set<String> pairsToRemove = new Set<String>();
        pairsToRemove.add(acc.Id + '_' + u3.Id);
        
        Test.startTest();
        CustomSharingService.removeAccountWithPairShares(accountIds, userIds, pairsToRemove);
        Test.stopTest();

    }
    
    @IsTest
    static void testAccountShareRecords() {
        // Setup data
        Account acc = new Account(
            Name = 'Primary Old',
            Pincode__c = '560001',
            Primary_Phone_Number__c = '1876543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert acc;
        
        user u1 = [select Id,Name from User where Employee_Code__C = '123sfgg212231' limit 1];   
        
        user u2 = [select Id,Name from User where Employee_Code__C = '1232122DDD343' limit 1];   

        
        // Map of record -> users
        Map<Id, List<Id>> recordToUserMap = new Map<Id, List<Id>>();
        recordToUserMap.put(acc.Id, new List<Id>{ u1.Id, u2.Id });
        
        Test.startTest();
        CustomSharingService.shareRecords('AccountShare', recordToUserMap, 'Read');
        Test.stopTest();

    }

    
    @IsTest
    static void testApproverReplacementQueue() {

        
        user oldUser = [select Id,Name from User where Employee_Code__C = '123sfgg212231' limit 1];   
        
        user newUser = [select Id,Name from User where Employee_Code__C = '1232122DDD343' limit 1];   

        
        // Insert employee with old approvers set
        Employee__c emp = new Employee__c(
            Name = 'Test Employee',
            RSM__c = oldUser.Id,
            ASM_TSM__c = oldUser.Id,
            Employee_Approver_3_HR__c = oldUser.Id,
            Secondary_Customer_Approver_1__c = oldUser.Id,
            Secondary_Customer_Approver_2__c = oldUser.Id,
            Primary_Customer_Approver_1__c = oldUser.Id,
            Primary_Customer_Approver_2__c = oldUser.Id,
            Primary_Customer_Approver_3_CD__c = oldUser.Id,
            PJP_Approver_1__c = oldUser.Id,
            PJP_Approver_2__c = oldUser.Id,
            Expense_Approver_1__c = oldUser.Id,
            Expense_Approver_2_Finance_Department__c = oldUser.Id,
            Reporting_Manager__c = oldUser.Id,
            IsDataUpload__c = true,
            Mail_Id__c = 'test@gmail.com', Aadhar_Number__c = '119977663390', Profile__c = 'ASM', Sales_Channel__c = 'TN', User_Name__c = 'my@tstasm.com'
        );
        insert emp;
        
        // Prepare replacement map
        Map<String, String> oldToNew = new Map<String, String>{
            oldUser.Id => newUser.Id
                };
                    Set<String> oldIds = new Set<String>{ oldUser.Id };
                        
                        Test.startTest();
        System.enqueueJob(new ApproverReplacementQueue(oldToNew, oldIds));
        Test.stopTest();
        
        // Reload employee
        Employee__c updatedEmp = [
            SELECT RSM__c, ASM_TSM__c, Employee_Approver_3_HR__c,
            Secondary_Customer_Approver_1__c, Secondary_Customer_Approver_2__c,
            Primary_Customer_Approver_1__c, Primary_Customer_Approver_2__c, Primary_Customer_Approver_3_CD__c,
            PJP_Approver_1__c, PJP_Approver_2__c,
            Expense_Approver_1__c, Expense_Approver_2_Finance_Department__c, Reporting_Manager__c
            FROM Employee__c
            WHERE Id = :emp.Id
        ];
        
    }

    

    
    
}