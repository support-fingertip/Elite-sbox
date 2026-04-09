@isTest
public class DistanceCalculationQueueableTest {

    @TestSetup
    static void setupTestData() {
        // Create necessary test data - adjust object/field API names to match your org
        // Assuming Daily_Log__c is the object - update as needed
        SObject dailyLog = (SObject) Type.forName('Daily_Log__c').newInstance();
        insert dailyLog;
    }

    @isTest
    static void testQueueableConstructorAndExecute() {
        // Get the daily log created in setup
        // Update the SOQL query to match your actual object API name
        SObject dailyLog = Database.query('SELECT Id FROM Daily_Log__c LIMIT 1');
        Id dailyLogId = dailyLog.Id;

        Test.startTest();
        DistanceCalculationQueueable queueable = new DistanceCalculationQueueable(dailyLogId);
        System.enqueueJob(queueable);
        Test.stopTest();


    }

    @isTest
    static void testQueueableWithValidId() {
        SObject dailyLog = Database.query('SELECT Id FROM Daily_Log__c LIMIT 1');
        Id dailyLogId = dailyLog.Id;

        DistanceCalculationQueueable queueable = new DistanceCalculationQueueable(dailyLogId);



        Test.startTest();
        System.enqueueJob(queueable);
        Test.stopTest();
    }

    @isTest
    static void testQueueableWithNullId() {
        DistanceCalculationQueueable queueable = new DistanceCalculationQueueable(null);



        Test.startTest();
        try {
            System.enqueueJob(queueable);
            Test.stopTest();
        } catch (Exception e) {

        }
    }

    @isTest
    static void testQueueableJobIsEnqueued() {
        SObject dailyLog = Database.query('SELECT Id FROM Daily_Log__c LIMIT 1');
        Id dailyLogId = dailyLog.Id;

        Test.startTest();
        Id jobId = System.enqueueJob(new DistanceCalculationQueueable(dailyLogId));
        Test.stopTest();



        // Optionally query AsyncApexJob to verify
        AsyncApexJob job = [
            SELECT Id, Status, JobType
            FROM AsyncApexJob
            WHERE Id = :jobId
        ];

    }
}