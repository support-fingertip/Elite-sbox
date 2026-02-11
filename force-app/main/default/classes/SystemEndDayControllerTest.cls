@isTest
private class SystemEndDayControllerTest {
    @isTest
    static void testAutoEndDailyLogs() {
        // Create test User
        User u = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

        // Create Daily_Log__c with required conditions
        Daily_Log__c log = new Daily_Log__c(
            OwnerId = u.Id,
            Clock_In_Location__Latitude__s = 17.3850,
            Clock_In_Location__Longitude__s = 78.4867
        );
        insert log;

        Test.startTest();
        SystemEndDayController.autoEndDailyLogs();
        Test.stopTest();

        // Verify
        Daily_Log__c updatedLog = [SELECT Day_ended_time__c, Is_System_Ended__c FROM Daily_Log__c WHERE Id = :log.Id];
        System.assertNotEquals(null, updatedLog.Day_ended_time__c);
        System.assertEquals(true, updatedLog.Is_System_Ended__c);
    }
}