@isTest
public class dailylogTriggerHandlerTest {
    
    @isTest
    static void testTriggerLogic() {
        Daily_Log__c daily = new Daily_Log__c();
        insert daily;
        
        Visit__c vs = new Visit__c(Daily_Log__c = daily.Id);
        insert vs;
        
        vs.ClockIn_Latitude__c = 37.7749;
        vs.Clockin_Longitude__c = 78.4194;
        vs.Actual_Start_Time__c = DateTime.now();
        update vs;
        
        vs.Distance__c = 12;
        update vs;
        
        daily.Day_ended_time__c = DateTime.now();
        daily.Clock_Out_Location__Longitude__s = 37.7749;
        daily.Clock_Out_Location__Latitude__s = 78.4194;
        update daily;
    }
    
    @isTest
    static void testEODReportBatch() {
        // Create minimum data so batch runs once
        Daily_Log__c daily = new Daily_Log__c();
        insert daily;
        
        Test.startTest();
        Database.executeBatch(new EODReport(), 1); // force single execution
        Test.stopTest();
    }
}