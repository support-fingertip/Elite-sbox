@isTest
public class DailyLogNotificationSchedulerTest {
    @isTest
    static void testStockUpdateScheduler() {
        // Schedule the job to run one minute later
        String CRON_EXP = '0 0 0 15 9 ? 2025'; // July 15, 2025 at 12:00 AM
        
        Test.startTest();
        String jobId = System.schedule('Test Stock Update Scheduler Job', CRON_EXP, new EmployeesWithoutAttendenceBatchScheduler());
        Test.stopTest();
        
        // No assertion needed, we just want to ensure the job is schedulable and doesn't error
    }
}