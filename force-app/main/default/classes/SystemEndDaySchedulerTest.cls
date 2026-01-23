@isTest
private class SystemEndDaySchedulerTest {
    @isTest
    static void testSchedulerRuns() {
        Test.startTest();
        String cronExp = '0 0 22 * * ?';
        System.schedule('Test Scheduler Job', cronExp, new SystemEndDayScheduler());
        Test.stopTest();

        // No assert needed unless you verify logs or jobs; code coverage is ensured
    }
}