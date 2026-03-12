@isTest
private class SystemEndDayBatchTest {

    // Helper to create a Daily_Log__c record
    private static Daily_Log__c createDailyLog(Boolean setDayEndedTime, Boolean setLocation) {
        Daily_Log__c dl = new Daily_Log__c();
        
        if (setLocation) {
            dl.Clock_In_Location__Latitude__s = 37.7749;
            dl.Clock_In_Location__Longitude__s = -122.4194;
        }
        
        if (setDayEndedTime) {
            dl.Day_ended_time__c = Datetime.now().addHours(-1);
        }
        
        insert dl;
        return dl;
    }

    // ─────────────────────────────────────────────
    // Test 1: Happy path — valid record gets updated
    // ─────────────────────────────────────────────
    @isTest
    static void testBatchUpdatesValidRecord() {
        Daily_Log__c dl = createDailyLog(false, true);

        Test.startTest();
        SystemEndDayBatch batch = new SystemEndDayBatch();
        Database.executeBatch(batch, 1);
        Test.stopTest();

        Daily_Log__c updated = [
            SELECT Id, Day_ended_time__c, Is_System_Ended__c
            FROM Daily_Log__c
            WHERE Id = :dl.Id
        ];

        Assert.isNotNull(updated.Day_ended_time__c, 'Day_ended_time__c should be set');
        Assert.isTrue(updated.Is_System_Ended__c, 'Is_System_Ended__c should be true');
    }

    // ─────────────────────────────────────────────
    // Test 2: Record already has Day_ended_time — should NOT be returned by query
    // ─────────────────────────────────────────────
    @isTest
    static void testBatchSkipsAlreadyEndedRecords() {
        Daily_Log__c dl = createDailyLog(true, true); // Day already ended

        Test.startTest();
        SystemEndDayBatch batch = new SystemEndDayBatch();
        Database.executeBatch(batch, 1);
        Test.stopTest();

        Daily_Log__c unchanged = [
            SELECT Id, Is_System_Ended__c
            FROM Daily_Log__c
            WHERE Id = :dl.Id
        ];

        Assert.isFalse(
            unchanged.Is_System_Ended__c == true,
            'Record with existing Day_ended_time__c should not be batch-updated'
        );
    }

    // ─────────────────────────────────────────────
    // Test 3: Record with null location — should NOT be returned by query
    // ─────────────────────────────────────────────
    @isTest
    static void testBatchSkipsNullLocationRecords() {
        Daily_Log__c dl = createDailyLog(false, false); // No location set

        Test.startTest();
        SystemEndDayBatch batch = new SystemEndDayBatch();
        Database.executeBatch(batch, 1);
        Test.stopTest();

        Daily_Log__c unchanged = [
            SELECT Id, Day_ended_time__c, Is_System_Ended__c
            FROM Daily_Log__c
            WHERE Id = :dl.Id
        ];

        Assert.isNull(unchanged.Day_ended_time__c, 'Record without location should not be updated');
        Assert.isFalse(
            unchanged.Is_System_Ended__c == true,
            'Is_System_Ended__c should remain false for unqualified records'
        );
    }

    // ─────────────────────────────────────────────
    // Test 4: Empty scope — execute should handle gracefully
    // ─────────────────────────────────────────────
    @isTest
    static void testExecuteWithEmptyScope() {
        Test.startTest();
        SystemEndDayBatch batch = new SystemEndDayBatch();
        // Explicitly call execute with empty list to test guard clause
        batch.execute(null, new List<Daily_Log__c>());
        Test.stopTest();

        // No exception = pass
        Assert.isTrue(true, 'Execute should handle empty scope without errors');
    }

    // ─────────────────────────────────────────────
    // Test 5: Verify Queueable is enqueued
    // ─────────────────────────────────────────────
    @isTest
    static void testQueueableIsEnqueued() {
        Daily_Log__c dl = createDailyLog(false, true);

        Test.startTest();
        SystemEndDayBatch batch = new SystemEndDayBatch();
        Database.executeBatch(batch, 1);
        Test.stopTest();

        // If no exception and batch completed, queueable was enqueued successfully
        // Async jobs are flushed within Test.stopTest()
        List<AsyncApexJob> jobs = [
            SELECT Id, JobType, Status
            FROM AsyncApexJob
            WHERE JobType = 'Queueable'
        ];

        Assert.isFalse(jobs.isEmpty(), 'A Queueable job should have been enqueued');
    }

    // ─────────────────────────────────────────────
    // Test 6: Finish method runs without error
    // ─────────────────────────────────────────────
    @isTest
    static void testFinishMethodRuns() {
        Test.startTest();
        SystemEndDayBatch batch = new SystemEndDayBatch();
        batch.finish(null);
        Test.stopTest();

        Assert.isTrue(true, 'Finish method should complete without errors');
    }

   
}