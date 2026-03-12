@isTest
private class EODReportQueueableMailTest {

    // ─────────────────────────────────────────────
    // Helper: Create Manager + Employee User
    // ─────────────────────────────────────────────
    private static User createTestUserWithManager() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        Long uniqueKey = DateTime.now().getTime();

        User manager = new User(
            FirstName         = 'Manager',
            LastName          = 'User',
            Email             = 'manager' + uniqueKey + '@elitefoods.test.com',
            Username          = 'mgr_eod_' + uniqueKey + '@elitefoods.test.com',
            Alias             = 'mgrusr',
            TimeZoneSidKey    = 'America/Los_Angeles',
            LocaleSidKey      = 'en_US',
            EmailEncodingKey  = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId         = p.Id,
            Employee_Code__c  = 'MGR-' + uniqueKey
        );
        insert manager;

        User employee = new User(
            FirstName         = 'Test',
            LastName          = 'Employee',
            Email             = 'employee' + uniqueKey + '@elitefoods.test.com',
            Username          = 'emp_eod_' + uniqueKey + '@elitefoods.test.com',
            Alias             = 'empl',
            TimeZoneSidKey    = 'America/Los_Angeles',
            LocaleSidKey      = 'en_US',
            EmailEncodingKey  = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId         = p.Id,
            ManagerId         = manager.Id,
            Employee_Code__c  = 'EMP-' + uniqueKey
        );
        insert employee;

        return employee;
    }

    // ─────────────────────────────────────────────
    // Helper: Create Employee User without Manager
    // ─────────────────────────────────────────────
    private static User createTestUserWithoutManager() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        Long uniqueKey = DateTime.now().getTime();

        User employee = new User(
            FirstName         = 'Solo',
            LastName          = 'User',
            Email             = 'solo' + uniqueKey + '@elitefoods.test.com',
            Username          = 'solo_eod_' + uniqueKey + '@elitefoods.test.com',
            Alias             = 'solo',
            TimeZoneSidKey    = 'America/Los_Angeles',
            LocaleSidKey      = 'en_US',
            EmailEncodingKey  = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId         = p.Id,
            Employee_Code__c  = 'SOLO-' + uniqueKey
        );
        insert employee;

        return employee;
    }

    // ─────────────────────────────────────────────
    // Helper: Create Daily Log owned by given user
    // Formula fields resolve automatically from OwnerId
    // ─────────────────────────────────────────────
    private static Daily_Log__c createDailyLog(Id ownerId) {
        Daily_Log__c dl = new Daily_Log__c(
            OwnerId                         = ownerId,
            Clock_In_Location__Latitude__s  = 37.7749,
            Clock_In_Location__Longitude__s = -122.4194
        );
        insert dl;
        return dl;
    }

    // ─────────────────────────────────────────────
    // Test 1: Happy path — owner has email + manager
    // ─────────────────────────────────────────────
    @isTest
    static void testExecuteWithBothEmails() {
        User emp = createTestUserWithManager();
        Daily_Log__c dl;

        System.runAs(emp) {
            dl = createDailyLog(emp.Id);
        }

        Test.startTest();
        Id jobId = System.enqueueJob(new EODReportQueueableMail(dl.Id));
        Test.stopTest();

        AsyncApexJob job = [
            SELECT Id, Status, NumberOfErrors
            FROM AsyncApexJob
            WHERE Id = :jobId
        ];
        Assert.areEqual('Completed', job.Status, 'Job should complete successfully');
        Assert.areEqual(0, job.NumberOfErrors, 'Job should have zero errors');
    }

    // ─────────────────────────────────────────────
    // Test 2: Owner has no manager — manager email null
    // ─────────────────────────────────────────────
    @isTest
    static void testExecuteWithOwnerEmailOnly() {
        User emp = createTestUserWithoutManager();
        Daily_Log__c dl;

        System.runAs(emp) {
            dl = createDailyLog(emp.Id);
        }

        Test.startTest();
        Id jobId = System.enqueueJob(new EODReportQueueableMail(dl.Id));
        Test.stopTest();

        AsyncApexJob job = [
            SELECT Id, Status, NumberOfErrors
            FROM AsyncApexJob
            WHERE Id = :jobId
        ];
        Assert.areEqual('Completed', job.Status, 'Job should complete with only owner email');
        Assert.areEqual(0, job.NumberOfErrors, 'Job should have zero errors');
    }

    // ─────────────────────────────────────────────
    // Test 3: Verify PDF blob fallback in test context
    // Test.isRunningTest() triggers Blob.valueOf('Test PDF content')
    // ─────────────────────────────────────────────
    @isTest
    static void testPdfBlobFallbackInTestContext() {
        User emp = createTestUserWithManager();
        Daily_Log__c dl;

        System.runAs(emp) {
            dl = createDailyLog(emp.Id);
        }

        Test.startTest();
        Id jobId = System.enqueueJob(new EODReportQueueableMail(dl.Id));
        Test.stopTest();

        AsyncApexJob job = [
            SELECT Id, Status, NumberOfErrors
            FROM AsyncApexJob
            WHERE Id = :jobId
        ];
        Assert.areEqual('Completed', job.Status, 'PDF blob fallback should not cause errors');
        Assert.areEqual(0, job.NumberOfErrors, 'No errors expected with blob fallback');
    }

    // ─────────────────────────────────────────────
    // Test 4: Null Day_Started_Date__c — date format fallback
    // If Day_Started_Date__c is a regular field (not formula), set it null explicitly
    // If formula, this is handled automatically — test verifies no crash
    // ─────────────────────────────────────────────
    @isTest
    static void testExecuteWithNullDayStartedDate() {
        User emp = createTestUserWithManager();
        Daily_Log__c dl;

        System.runAs(emp) {
            dl = new Daily_Log__c(
                OwnerId                         = emp.Id,
                Clock_In_Location__Latitude__s  = 37.7749,
                Clock_In_Location__Longitude__s = -122.4194
            );
            insert dl;
        }

        Test.startTest();
        Id jobId = System.enqueueJob(new EODReportQueueableMail(dl.Id));
        Test.stopTest();

        AsyncApexJob job = [
            SELECT Id, Status, NumberOfErrors
            FROM AsyncApexJob
            WHERE Id = :jobId
        ];
        Assert.areEqual('Completed', job.Status, 'Null date should be handled by ternary fallback');
        Assert.areEqual(0, job.NumberOfErrors, 'No errors expected with null date');
    }

    // ─────────────────────────────────────────────
    // Test 5: Constructor instantiates correctly
    // ─────────────────────────────────────────────
    @isTest
    static void testConstructorSetsId() {
        User emp = createTestUserWithManager();
        Daily_Log__c dl;

        System.runAs(emp) {
            dl = createDailyLog(emp.Id);
        }

        EODReportQueueableMail queueable = new EODReportQueueableMail(dl.Id);
        Assert.isNotNull(queueable, 'Queueable instance should be created successfully');
    }

    // ─────────────────────────────────────────────
    // Test 6: Verify job is enqueued and returns a job Id
    // ─────────────────────────────────────────────
    @isTest
    static void testJobIsEnqueued() {
        User emp = createTestUserWithManager();
        Daily_Log__c dl;

        System.runAs(emp) {
            dl = createDailyLog(emp.Id);
        }

        Test.startTest();
        Id jobId = System.enqueueJob(new EODReportQueueableMail(dl.Id));
        Test.stopTest();

        Assert.isNotNull(jobId, 'enqueueJob should return a valid job Id');

        AsyncApexJob job = [
            SELECT Id, JobType, Status
            FROM AsyncApexJob
            WHERE Id = :jobId
        ];
        Assert.areEqual('Queueable', job.JobType, 'Job type should be Queueable');
        Assert.areEqual('Completed', job.Status, 'Job should reach Completed status');
    }

    // ─────────────────────────────────────────────
    // Test 7: Multiple Daily Logs — each processes independently
    // ─────────────────────────────────────────────
    @isTest
    static void testMultipleDailyLogsEnqueuedSeparately() {
        User emp1 = createTestUserWithManager();
        User emp2 = createTestUserWithoutManager();

        Daily_Log__c dl1, dl2;
        System.runAs(emp1) { dl1 = createDailyLog(emp1.Id); }
        System.runAs(emp2) { dl2 = createDailyLog(emp2.Id); }

        Test.startTest();
        Id jobId1 = System.enqueueJob(new EODReportQueueableMail(dl1.Id));
        Id jobId2 = System.enqueueJob(new EODReportQueueableMail(dl2.Id));
        Test.stopTest();

        List<AsyncApexJob> jobs = [
            SELECT Id, Status, NumberOfErrors
            FROM AsyncApexJob
            WHERE Id IN :new List<Id>{ jobId1, jobId2 }
        ];
        Assert.areEqual(2, jobs.size(), 'Both jobs should be tracked');
        for (AsyncApexJob job : jobs) {
            Assert.areEqual('Completed', job.Status, 'Each job should complete successfully');
            Assert.areEqual(0, job.NumberOfErrors, 'No errors expected');
        }
    }
}