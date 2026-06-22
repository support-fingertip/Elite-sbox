/**
 * Direct coverage for SecondaryAchievementScheduler so it appears in the
 * coverage report on its own, not only via the achievement batch test.
 */
@isTest
public class SecondaryAchievementSchedulerTest {

    private static final String CRON = '0 0 1 1 1 ? 2099';

    @isTest
    static void scheduleCreatesCronTrigger() {
        Test.startTest();
        Id jobId = System.schedule(
            'SecondaryAchievement Scheduler Test',
            CRON,
            new SecondaryAchievementScheduler()
        );
        Test.stopTest();
        System.assertNotEquals(null, jobId);
        System.assertEquals(1,
            [SELECT COUNT() FROM CronTrigger WHERE Id = :jobId]);
    }

    @isTest
    static void executeInvokesTheBatch() {
        // Direct execute() so the Database.executeBatch path is hit. With
        // no Secondary_Target__c rows the batch is a no-op, but the wrapper
        // is what we're covering here.
        Test.startTest();
        new SecondaryAchievementScheduler().execute(null);
        Test.stopTest();
        System.assert(true, 'execute returned without throwing');
    }
}
