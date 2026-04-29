@isTest
private class UserFreezeStatusControllerTest {

    @TestSetup
    static void setup() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            FirstName         = 'Test',
            LastName          = 'FreezeUser',
            Email             = 'freezetest@example.com',
            Username          = 'freezetest_' + System.now().getTime() + '@example.com',
            Alias             = 'frztst',
            TimeZoneSidKey    = 'America/Los_Angeles',
            LocaleSidKey      = 'en_US',
            EmailEncodingKey  = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId         = p.Id,
            Employee_Code__c  ='teetssslsls'
        );
        insert testUser;

        Employee__c emp = new Employee__c(
            Name                    = 'Test FreezeUser',
            Mail_Id__c              = 'freezetest@example.com',
            User_Name__c            = 'freezetest@example.com.testuser',
            Primary_Phone_Number__c = '9999999999',
            Employee_Code__c        = 'EMP9999901',
            Designation__c          = 'Sales Exec',
            Profile__c              = 'Admin',
            Is_Active__c            = true,
            Basic_Pay__c            = 25000,
            Aadhar_Number__c        = '123456789012',
            Gross_Salary__c         = 35000,
            DA__c                   = 5000,
            TA_limit__c             = 2000,
            Area__c                 = 'Central',
            Region__c               = 'West',
            User__c                 = testUser.Id,
            Sales_Channel__c        = 'Cake',
            State__c                = 'Uttar Pradesh',
            District__c             = 'Lucknow',
            Pincode__c              = '226001',
            Cloning_is_Completed__c = false
        );
        insert emp;
    }

    // Helper: freeze a user by updating UserLogin directly (valid in test context)
    static void freezeUser(Id userId) {
        UserLogin ul = [SELECT Id, IsFrozen FROM UserLogin WHERE UserId = :userId LIMIT 1];
        ul.IsFrozen = true;
        update ul;
    }

    // ── Test 1: User exists but is NOT frozen ────────────────────────────────
    @isTest
    static void testGetFreezeStatus_NotFrozen() {
        Employee__c emp = [
            SELECT Id FROM Employee__c
            WHERE Mail_Id__c = 'freezetest@example.com' LIMIT 1
        ];

        Test.startTest();
        UserFreezeStatusController.FreezeStatusResult result =
            UserFreezeStatusController.getUserFreezeStatus(emp.Id);
        Test.stopTest();

        System.assertEquals(false, result.isFrozen, 'User should not be frozen');
    }

    // ── Test 2: User IS frozen — covers result.isFrozen = true branch ────────
    @isTest
    static void testGetFreezeStatus_IsFrozen() {
        User testUser = [
            SELECT Id FROM User WHERE Email = 'freezetest@example.com' LIMIT 1
        ];
        Employee__c emp = [
            SELECT Id FROM Employee__c WHERE User__c = :testUser.Id LIMIT 1
        ];

        freezeUser(testUser.Id); // update UserLogin.IsFrozen = true directly

        Test.startTest();
        UserFreezeStatusController.FreezeStatusResult result =
            UserFreezeStatusController.getUserFreezeStatus(emp.Id);
        Test.stopTest();

        System.assertEquals(true,     result.isFrozen,     'User should be frozen');
        System.assertNotEquals(null,   result.freezeReason, 'Freeze reason should be set');
        System.assertNotEquals(null,   result.userName,     'User name should be populated');
        // LoginHistory is not writable in tests, so reason defaults to 'Unknown'
        System.assertEquals('Unknown', result.freezeReason);
    }

    // ── Test 3: Employee has no User__c lookup ───────────────────────────────
    @isTest
    static void testGetFreezeStatus_NoUserLinked() {
        Employee__c emp = new Employee__c(
            Name                    = 'No User Employee',
            Mail_Id__c              = 'nouser@example.com',
            User_Name__c            = 'nouser@example.com.testuser',
            Primary_Phone_Number__c = '8888888888',
            Employee_Code__c        = 'EMP0000099',
            Designation__c          = 'Sales Exec',
            Profile__c              = 'Admin',
            Is_Active__c            = false,
            Basic_Pay__c            = 25000,
            Aadhar_Number__c        = '999999999999',
            Gross_Salary__c         = 35000,
            DA__c                   = 5000,
            TA_limit__c             = 2000,
            Area__c                 = 'Central',
            Region__c               = 'West',
            Sales_Channel__c        = 'Cake',
            State__c                = 'Uttar Pradesh',
            District__c             = 'Lucknow',
            Pincode__c              = '226001',
            Cloning_is_Completed__c = false
            // User__c intentionally omitted
        );
        insert emp;

        Test.startTest();
        UserFreezeStatusController.FreezeStatusResult result =
            UserFreezeStatusController.getUserFreezeStatus(emp.Id);
        Test.stopTest();

        System.assertEquals(false, result.isFrozen, 'Should return false when no user linked');
    }

    // ── Test 4: Unfreeze — happy path ────────────────────────────────────────
    @isTest
    static void testUnfreezeUser_Success() {
        User testUser = [
            SELECT Id FROM User WHERE Email = 'freezetest@example.com' LIMIT 1
        ];
        Employee__c emp = [
            SELECT Id FROM Employee__c WHERE User__c = :testUser.Id LIMIT 1
        ];

        freezeUser(testUser.Id);

        Test.startTest();
        UserFreezeStatusController.unfreezeUser(emp.Id);
        Test.stopTest();

        UserLogin ul = [SELECT IsFrozen FROM UserLogin WHERE UserId = :testUser.Id LIMIT 1];
        System.assertEquals(false, ul.IsFrozen, 'User should be unfrozen after calling unfreezeUser');
    }

    // ── Test 5: Unfreeze — no user linked should throw ───────────────────────
    @isTest
    static void testUnfreezeUser_NoUserLinked() {
        Employee__c emp = new Employee__c(
            Name                    = 'No User Emp2',
            Mail_Id__c              = 'nouser2@example.com',
            User_Name__c            = 'nouser2@example.com.testuser',
            Primary_Phone_Number__c = '7777777777',
            Employee_Code__c        = 'EMP0000098',
            Designation__c          = 'Sales Exec',
            Profile__c              = 'Admin',
            Is_Active__c            = false,
            Basic_Pay__c            = 25000,
            Aadhar_Number__c        = '888888888888',
            Gross_Salary__c         = 35000,
            DA__c                   = 5000,
            TA_limit__c             = 2000,
            Area__c                 = 'Central',
            Region__c               = 'West',
            Sales_Channel__c        = 'Cake',
            State__c                = 'Uttar Pradesh',
            District__c             = 'Lucknow',
            Pincode__c              = '226001',
            Cloning_is_Completed__c = false
        );
        insert emp;

        Test.startTest();
        try {
            UserFreezeStatusController.unfreezeUser(emp.Id);
            System.assert(false, 'Expected AuraHandledException was not thrown');
        } catch (AuraHandledException e) {
     
        }
        Test.stopTest();
    }
}