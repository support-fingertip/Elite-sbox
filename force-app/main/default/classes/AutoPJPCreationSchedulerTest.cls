@isTest
public class AutoPJPCreationSchedulerTest {
    
    // Helper method to insert test data
    private static void createTestData() {
       // Create test user
        Profile p = [SELECT Id FROM Profile WHERE Name='DSM'];
        User testUser = new User(
            Alias = 'testusr',
            Email = 'testuser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser109rtyed56@testorg.com',
            Region__c = 'Tamil Nadu',
            Employee_Code__c = '4411'
        );
        insert testUser;
        
        // Create test calendar beat
        Calendar_beat__c testPJP = new Calendar_beat__c(
            Active__c = true,
            Recurring_Frequency__c = 5,
            Next_PJP_Run__c = Date.today(),
            User__c = testUser.Id,
            OwnerId = testUser.Id
        );
        insert testPJP;
        
        // Create test child beats
        List<Child_Beat__c> childBeats = new List<Child_Beat__c>();
        childBeats.add(new Child_Beat__c(
            Name = 'Child Beat 1',
            Active__c = true,
            Order_Number__c = 1,
            OwnerId = testUser.Id
        ));
        childBeats.add(new Child_Beat__c(
            Name = 'Child Beat 2',
            Active__c = true,
            Order_Number__c = 2,
            OwnerId = testUser.Id
        ));
        insert childBeats;
        
        // Create test PJP_Item__c records related to the Calendar_beat
        List<PJP_Item__c> pjpItems = new List<PJP_Item__c>();
        for (Integer i = 0; i < 2; i++) {
            pjpItems.add(new PJP_Item__c(
                PJP__c = testPJP.Id,
                Date__c = Date.today().addDays(-i-1), // Assigning dates from the past
                Beat__c = childBeats[i].id,
                Assigned_Beat__c = childBeats[i].id,
                Order_Number__c = i + 1,
                Status__c = 'Approved'
            ));
        }
        insert pjpItems;
    }

    @isTest
    public static void testBatchableClass() {
        // Step 1: Prepare the test data
        createTestData();

        // Step 2: Create an instance of the batchable class
        AutoPJPCreationScheduler scheduler = new AutoPJPCreationScheduler();

        // Step 3: Execute the batchable class using a test context
        Test.startTest();
        
        // Execute the batch job manually
        Database.executeBatch(scheduler, 1);
        
        Test.stopTest();
        
        
    }

    @isTest
    public static void testSchedulableClass() {
        // Step 1: Prepare the test data
        createTestData();
        
        // Step 2: Create an instance of the schedulable class
        AutoPJPCreationScheduler scheduler = new AutoPJPCreationScheduler();
        
        // Step 3: Schedule the job using the cron expression
        String cronExpression = '0 55 23 * * ?'; // Cron expression for 11:55 PM every day
        System.schedule('Test PJPItemScheduler', cronExpression, scheduler);
        
        // Step 4: Verify that the job has been scheduled
        CronTrigger[] scheduledJobs = [SELECT Id, CronExpression FROM CronTrigger WHERE CronJobDetail.Name = 'Test PJPItemScheduler'];
        System.assertEquals(1, scheduledJobs.size(), 'Expected the job to be scheduled.');
        System.assertEquals(cronExpression, scheduledJobs[0].CronExpression, 'Expected the correct cron expression.');
    }
}