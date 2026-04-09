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
        
        // Validate records were transferred (updated in place) to new customers
        List<Product_Mapping__c> transferredPMs = [
            SELECT Id, Customer__c, Primary_Customer__c, Sub_Stockiest__c FROM Product_Mapping__c
            WHERE Customer__c = :primaryNew.Id OR Customer__c = :subNew.Id
        ];
        System.debug('Transferred Product Mappings: ' + transferredPMs);

        List<Child_beat__c> transferredBeats = [
            SELECT Id, Primary_Customer__c, Sub_Stockist__c FROM Child_beat__c
            WHERE Primary_Customer__c = :primaryNew.Id
        ];
        System.debug('Transferred Beats: ' + transferredBeats);
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

    @IsTest
    static void testShareRecordsEmptyInputs() {
        // Covers early-return branches of shareRecords
        Map<Id, List<Id>> emptyMap = new Map<Id, List<Id>>();
        Map<Id, List<Id>> nonEmptyMap = new Map<Id, List<Id>>{
            UserInfo.getUserId() => new List<Id>{ UserInfo.getUserId() }
        };

        Test.startTest();
        // Empty map - should return early
        CustomSharingService.shareRecords('AccountShare', emptyMap, 'Read');
        // Empty objectType - should return early
        CustomSharingService.shareRecords('', nonEmptyMap, 'Read');
        // Empty accessLevel - should return early
        CustomSharingService.shareRecords('AccountShare', nonEmptyMap, '');
        Test.stopTest();
    }

    @IsTest
    static void testShareRecordsChildBeatShare() {
        // Covers the non-AccountShare (else) branch of shareRecords
        User u1 = [SELECT Id FROM User WHERE Employee_Code__C = '123sfgg212231' LIMIT 1];
        User u2 = [SELECT Id FROM User WHERE Employee_Code__C = '1232122DDD343' LIMIT 1];

        Child_beat__c beat = new Child_beat__c(
            Name = 'Share Test Beat',
            OwnerId = u1.Id,
            Beat_Type__c = 'Primary'
        );
        insert beat;

        Map<Id, List<Id>> recordToUserMap = new Map<Id, List<Id>>();
        recordToUserMap.put(beat.Id, new List<Id>{ u2.Id });

        Test.startTest();
        CustomSharingService.shareRecords('Child_beat__Share', recordToUserMap, 'Read');
        Test.stopTest();
    }

    @IsTest
    static void testLinkFilesToRecordsEmptyInputs() {
        // Covers null/empty input early returns of linkFilesToRecords
        Map<String, Id> emptyMap = new Map<String, Id>();

        Test.startTest();
        CustomSharingService.linkFilesToRecords(null, emptyMap);
        CustomSharingService.linkFilesToRecords(new Set<String>(), emptyMap);
        // Non-existing file identifier - files query will return empty
        CustomSharingService.linkFilesToRecords(new Set<String>{ 'NON_EXISTING_FILE_IDENTIFIER' }, emptyMap);
        Test.stopTest();
    }

    @IsTest
    static void testBuildAccountShare() {
        Account acc = new Account(
            Name = 'Build Share Account',
            Pincode__c = '560001',
            Primary_Phone_Number__c = '3876543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert acc;

        User u = [SELECT Id FROM User WHERE Employee_Code__C = '123sfgg212231' LIMIT 1];

        Test.startTest();
        AccountShare share = CustomSharingService.buildAccountShare(acc.Id, u.Id);
        Test.stopTest();

        System.assertEquals(acc.Id, share.AccountId, 'AccountId should match');
        System.assertEquals(u.Id, share.UserOrGroupId, 'UserOrGroupId should match');
        System.assertEquals('Edit', share.AccountAccessLevel, 'AccountAccessLevel should be Edit');
        System.assertEquals('Read', share.OpportunityAccessLevel, 'OpportunityAccessLevel should be Read');
        System.assertEquals('Read', share.CaseAccessLevel, 'CaseAccessLevel should be Read');
    }

    @IsTest
    static void testShareAccounts() {
        Account acc = new Account(
            Name = 'Share Accounts',
            Pincode__c = '560001',
            Primary_Phone_Number__c = '4876543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert acc;

        User u = [SELECT Id FROM User WHERE Employee_Code__C = '123sfgg212231' LIMIT 1];

        List<AccountShare> shares = new List<AccountShare>{
            CustomSharingService.buildAccountShare(acc.Id, u.Id)
        };

        // Also test the empty list path (no-op)
        List<AccountShare> emptyShares = new List<AccountShare>();

        Test.startTest();
        CustomSharingService.shareAccounts(emptyShares);
        CustomSharingService.shareAccounts(shares);

        // Second call triggers error path - duplicate share insert failures
        List<AccountShare> duplicateShares = new List<AccountShare>{
            CustomSharingService.buildAccountShare(acc.Id, u.Id)
        };
        CustomSharingService.shareAccounts(duplicateShares);
        Test.stopTest();
    }

    @IsTest
    static void testCloneMapping() {
        Account acc = new Account(
            Name = 'Clone Mapping Account',
            Pincode__c = '560001',
            Primary_Phone_Number__c = '5876543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert acc;

        area__c tr = new area__c(
            Name = 'clone test',
            Sales_Channel__c = 'CPD',
            Region__c = 'Kerala',
            Area__c = 'Central'
        );
        insert tr;

        User u = [SELECT Id FROM User WHERE Employee_Code__C = '123sfgg212231' LIMIT 1];

        Product_Mapping__c original = new Product_Mapping__c(
            Customer__c = acc.Id,
            Chanel__c = 'CPD',
            Parent_Depot__c = '1100',
            Child_Depot__c = '1100',
            Payment_Term__c = '0003',
            Area__c = tr.Id,
            Exectuive__c = u.Id
        );
        insert original;

        Product_Mapping__c loaded = [
            SELECT Exectuive__c, Primary_Customer__c, Sub_Stockiest__c, Customer__c, Chanel__c,
                   Area__c, PDP_Name__c, PDP_Day__c, Parent_Depot__c, Child_Depot__c,
                   Payment_Term__c, Credit_Description__c, Inco_Terms__c, Order_Type__c,
                   Distribution_Channel__c, Sales_Office__c, Division__c
            FROM Product_Mapping__c
            WHERE Id = :original.Id
        ];

        Test.startTest();
        Product_Mapping__c cloned = CustomSharingService.cloneMapping(loaded);
        Test.stopTest();

        System.assertEquals(loaded.Customer__c, cloned.Customer__c, 'Customer should be copied');
        System.assertEquals(loaded.Exectuive__c, cloned.Exectuive__c, 'Executive should be copied');
        System.assertEquals(loaded.Chanel__c, cloned.Chanel__c, 'Chanel should be copied');
        System.assertEquals(loaded.Parent_Depot__c, cloned.Parent_Depot__c, 'Parent Depot should be copied');
        System.assertEquals(loaded.Child_Depot__c, cloned.Child_Depot__c, 'Child Depot should be copied');
        System.assertEquals(loaded.Payment_Term__c, cloned.Payment_Term__c, 'Payment Term should be copied');
        System.assertEquals(loaded.Area__c, cloned.Area__c, 'Area should be copied');
        System.assertEquals(null, cloned.Id, 'Clone should not have an Id');
    }

    @IsTest
    static void testShareCustomerAccessToHierarchy() {
        User deactivatedUser = [SELECT Id FROM User WHERE Employee_Code__C = '123sfgg212231' LIMIT 1];
        User managerUser = [SELECT Id FROM User WHERE Employee_Code__C = '1232122DDD343' LIMIT 1];

        // Create Employee with reporting manager
        Employee__c emp = new Employee__c(
            Name = 'Hierarchy Emp',
            OwnerId = managerUser.Id,
            Reporting_Manager__c = managerUser.Id,
            User__c = deactivatedUser.Id,
            IsDataUpload__c = true,
            Mail_Id__c = 'hierarchy@gmail.com',
            Aadhar_Number__c = '999977663390',
            Profile__c = 'ASM',
            Sales_Channel__c = 'TN',
            User_Name__c = 'hierarchy@tstasm.com'
        );
        insert emp;

        Account acc1 = new Account(
            Name = 'Hierarchy Account 1',
            Pincode__c = '560001',
            Primary_Phone_Number__c = '6876543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        Account acc2 = new Account(
            Name = 'Hierarchy Account 2',
            Pincode__c = '560001',
            Primary_Phone_Number__c = '6976543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        Account acc3 = new Account(
            Name = 'Hierarchy Account 3',
            Pincode__c = '560001',
            Primary_Phone_Number__c = '7076543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert new List<Account>{ acc1, acc2, acc3 };

        // Share acc1 with deactivated user via manual AccountShare
        AccountShare manualShare = new AccountShare(
            AccountId = acc1.Id,
            UserOrGroupId = deactivatedUser.Id,
            AccountAccessLevel = 'Read',
            OpportunityAccessLevel = 'Read',
            RowCause = 'Manual'
        );
        insert manualShare;

        // Employee Customer Assignment pointing to acc2
        Employee_Customer_Assignment__c eca = new Employee_Customer_Assignment__c(
            Executive__c = deactivatedUser.Id,
            Employee__c = emp.Id,
            Customer__c = acc2.Id
        );
        insert eca;

        // Product Mapping pointing to acc3
        area__c tr = new area__c(
            Name = 'hierarchy area',
            Sales_Channel__c = 'CPD',
            Region__c = 'Kerala',
            Area__c = 'Central'
        );
        insert tr;

        Product_Mapping__c pm = new Product_Mapping__c(
            Customer__c = acc3.Id,
            Payment_Term__c = '0003',
            Area__c = tr.Id,
            Exectuive__c = deactivatedUser.Id
        );
        insert pm;

        Test.startTest();
        CustomSharingService.shareCustomerAccessToHierarchy(deactivatedUser.Id);
        Test.stopTest();
    }

    @IsTest
    static void testShareCustomerAccessToHierarchyEmptyBranches() {
        // Covers the early-return branches when employee is missing / no accounts found
        User someUser = [SELECT Id FROM User WHERE Employee_Code__C = '123sfgg212231' LIMIT 1];
        User managerUser = [SELECT Id FROM User WHERE Employee_Code__C = '1232122DDD343' LIMIT 1];

        // No employee exists for this user - should early return
        Test.startTest();
        CustomSharingService.shareCustomerAccessToHierarchy(someUser.Id);

        // Create an employee with a manager but no accounts - should early return on empty accountIds
        Employee__c emp = new Employee__c(
            Name = 'Empty Accounts Emp',
            OwnerId = managerUser.Id,
            Reporting_Manager__c = managerUser.Id,
            User__c = someUser.Id,
            IsDataUpload__c = true,
            Mail_Id__c = 'empty@gmail.com',
            Aadhar_Number__c = '888877663390',
            Profile__c = 'ASM',
            Sales_Channel__c = 'TN',
            User_Name__c = 'empty@tstasm.com'
        );
        insert emp;
        CustomSharingService.shareCustomerAccessToHierarchy(someUser.Id);
        Test.stopTest();
    }

    @IsTest
    static void testDeleteEmployeeOldClonedAssignments() {
        User u = [SELECT Id FROM User WHERE Employee_Code__C = '123sfgg212231' LIMIT 1];

        Account acc = new Account(
            Name = 'Delete Cloned Account',
            Pincode__c = '560001',
            Primary_Phone_Number__c = '7176543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert acc;

        area__c tr = new area__c(
            Name = 'delete cloned area',
            Sales_Channel__c = 'CPD',
            Region__c = 'Kerala',
            Area__c = 'Central'
        );
        insert tr;

        Product_Mapping__c pm = new Product_Mapping__c(
            Customer__c = acc.Id,
            Payment_Term__c = '0003',
            Area__c = tr.Id,
            Exectuive__c = u.Id,
            Cloned_From_Employee_Replacement__c = true
        );
        insert pm;

        Child_beat__c beat = new Child_beat__c(
            Name = 'Cloned Beat',
            OwnerId = u.Id,
            Beat_Type__c = 'Primary',
            Cloned_From_Employee_Replacement__c = true
        );
        insert beat;

        Junction_Beat__c jb = new Junction_Beat__c(
            Account__c = acc.Id,
            Child_beat__c = beat.Id,
            Cloned_From_Employee_Replacement__c = true
        );
        insert jb;

        Calendar_beat__c cb = new Calendar_beat__c(
            User__c = u.Id,
            Active__c = true,
            Cloned_From_Employee_Replacement__c = true
        );
        insert cb;

        Set<Id> userIds = new Set<Id>{ u.Id };

        Test.startTest();
        CustomSharingService.deleteEmployeeOldClonedAssignments(userIds);
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Product_Mapping__c WHERE Id = :pm.Id],
            'Cloned product mapping should be deleted');
        System.assertEquals(0, [SELECT COUNT() FROM Child_beat__c WHERE Id = :beat.Id],
            'Cloned child beat should be deleted');
        System.assertEquals(0, [SELECT COUNT() FROM Calendar_beat__c WHERE Id = :cb.Id],
            'Cloned calendar beat should be deleted');
    }

    @IsTest
    static void testRemoveAccountSharesWithMapEmptyInputs() {
        // Covers null/empty branches of removeAccountSharesWithMap
        Test.startTest();
        CustomSharingService.removeAccountSharesWithMap(null);
        CustomSharingService.removeAccountSharesWithMap(new Map<Id, List<Id>>());
        Test.stopTest();
    }

    @IsTest
    static void testEmployeeReplacementEmptyMap() {
        // Covers null/empty branches of employeeReplacement
        Test.startTest();
        CustomSharingService.employeeReplacement(null);
        CustomSharingService.employeeReplacement(new Map<String, String>());
        Test.stopTest();
    }

    @IsTest
    static void testCustomerReplacementEmptyMaps() {
        // Covers the path where both maps are empty - beats query still runs
        Test.startTest();
        CustomSharingService.customerReplacement(
            new Map<String, String>(),
            new Map<String, String>()
        );
        Test.stopTest();
    }

    @IsTest
    static void testEmployeeTransferEmptyInputs() {
        // Covers null / empty early-return branches of employeeTransfer
        Test.startTest();
        CustomSharingService.employeeTransfer(null);
        CustomSharingService.employeeTransfer(new Map<String, String>());
        Test.stopTest();
    }

    @IsTest
    static void testEmployeeTransferFullFlow() {
        // Covers all 6 steps of employeeTransfer:
        // Product_Mapping, Employee_Customer_Assignment, Child_beat, Calendar_beat,
        // ApproverReplacementQueue enqueue, and updateUserRoleHierarchy (@future).
        User oldUser = [SELECT Id FROM User WHERE Employee_Code__C = '123sfgg212231' LIMIT 1];
        User newUser = [SELECT Id FROM User WHERE Employee_Code__C = '1232122DDD343' LIMIT 1];

        Account acc = new Account(
            Name = 'Transfer Account',
            Pincode__c = '560001',
            Primary_Phone_Number__c = '8176543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert acc;

        area__c tr = new area__c(
            Name = 'transfer area',
            Sales_Channel__c = 'CPD',
            Region__c = 'Kerala',
            Area__c = 'Central'
        );
        insert tr;

        // Step 1 target: Product_Mapping__c with Exectuive__c = oldUser
        Product_Mapping__c pm = new Product_Mapping__c(
            Customer__c = acc.Id,
            Payment_Term__c = '0003',
            Area__c = tr.Id,
            Exectuive__c = oldUser.Id
        );
        insert pm;

        // Step 2 target: Employee_Customer_Assignment__c with Executive__c = oldUser
        Employee__c emp = new Employee__c(
            Name = 'Transfer Emp',
            OwnerId = oldUser.Id,
            User__c = oldUser.Id,
            IsDataUpload__c = true,
            Mail_Id__c = 'transfer@gmail.com',
            Aadhar_Number__c = '555577663390',
            Profile__c = 'ASM',
            Sales_Channel__c = 'TN',
            User_Name__c = 'transfer@tstasm.com'
        );
        insert emp;

        Employee_Customer_Assignment__c eca = new Employee_Customer_Assignment__c(
            Executive__c = oldUser.Id,
            Employee__c = emp.Id,
            Customer__c = acc.Id
        );
        insert eca;

        // Step 3 target: Child_beat__c with OwnerId = oldUser
        Child_beat__c beatOwner = new Child_beat__c(
            Name = 'Transfer Beat Owner',
            OwnerId = oldUser.Id,
            User__c = oldUser.Id,
            Beat_Type__c = 'Primary',
            Active__c = true,
            Cloned_From_Customer_Deactivation__c = true,
            Cloned_From_Employee_Replacement__c = true
        );
        insert beatOwner;

        // Step 4 target: Calendar_beat__c with User__c = oldUser
        Calendar_beat__c pjp = new Calendar_beat__c(
            OwnerId = oldUser.Id,
            User__c = oldUser.Id,
            Active__c = true
        );
        insert pjp;

        Map<String, String> oldToNewMap = new Map<String, String>{
            oldUser.Id => newUser.Id
        };

        Test.startTest();
        CustomSharingService.employeeTransfer(oldToNewMap);
        Test.stopTest();

        // Verify Product Mapping was transferred
        Product_Mapping__c updatedPm = [SELECT Id, Exectuive__c FROM Product_Mapping__c WHERE Id = :pm.Id];
        System.assertEquals(newUser.Id, updatedPm.Exectuive__c,
            'Product Mapping executive should be transferred to new user');

        // Verify Employee Customer Assignment was transferred
        Employee_Customer_Assignment__c updatedEca = [SELECT Id, Executive__c FROM Employee_Customer_Assignment__c WHERE Id = :eca.Id];
        System.assertEquals(newUser.Id, updatedEca.Executive__c,
            'Employee Customer Assignment executive should be transferred to new user');

        // Verify Child Beat owner/user was transferred
        Child_beat__c updatedBeat = [SELECT Id, OwnerId, User__c FROM Child_beat__c WHERE Id = :beatOwner.Id];
        System.assertEquals(newUser.Id, updatedBeat.OwnerId,
            'Beat owner should be transferred to new user');
        System.assertEquals(newUser.Id, updatedBeat.User__c,
            'Beat user should be transferred to new user');

        // Verify Calendar Beat was transferred
        Calendar_beat__c updatedPjp = [SELECT Id, User__c FROM Calendar_beat__c WHERE Id = :pjp.Id];
        System.assertEquals(newUser.Id, updatedPjp.User__c,
            'Calendar Beat user should be transferred to new user');
    }

    @IsTest
    static void testEmployeeTransferBeatUserOnlyMatch() {
        // Covers the else-if branch in Step 3 where beat.OwnerId is NOT in the map
        // but beat.User__c is - the beat is still transferred.
        User oldUser = [SELECT Id FROM User WHERE Employee_Code__C = '123sfgg212231' LIMIT 1];
        User newUser = [SELECT Id FROM User WHERE Employee_Code__C = '1232122DDD343' LIMIT 1];

        // Beat owned by newUser but User__c points to oldUser
        Child_beat__c beat = new Child_beat__c(
            Name = 'User Only Match Beat',
            OwnerId = newUser.Id,
            User__c = oldUser.Id,
            Beat_Type__c = 'Primary',
            Active__c = true,
            Cloned_From_Customer_Deactivation__c = true,
            Cloned_From_Employee_Replacement__c = true
        );
        insert beat;

        Map<String, String> oldToNewMap = new Map<String, String>{
            oldUser.Id => newUser.Id
        };

        Test.startTest();
        CustomSharingService.employeeTransfer(oldToNewMap);
        Test.stopTest();

        Child_beat__c updated = [SELECT Id, User__c, OwnerId FROM Child_beat__c WHERE Id = :beat.Id];
        System.assertEquals(newUser.Id, updated.User__c,
            'Beat User__c should be transferred via the else-if branch');
    }

}