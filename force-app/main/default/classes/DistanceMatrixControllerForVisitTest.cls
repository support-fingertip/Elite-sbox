@istest
public class DistanceMatrixControllerForVisitTest {
    
    public static testMethod void testDistanceCalculation() {
        Daily_Log__c dailyLog = new Daily_Log__c();
        dailyLog.Day_started_time__c = system.now();
        dailyLog.Clock_Out_Location__Latitude__s = 37.7749;
        dailyLog.Clock_Out_Location__Longitude__s = 78.4194;
        insert dailyLog;
        
        
        
        
        visit__c vs = new visit__c();
        vs.Daily_Log__c=dailyLog.id;
        insert vs;
        
        
        vs.ClockIn_Latitude__c = 37.7749;
        vs.Clockin_Longitude__c = 78.4194;
        vs.Actual_Start_Time__c = DateTime.now();
        update vs; 
        
        Visit__c visit1 = new Visit__c();
        visit1.Status__c = 'In Progress';
        visit1.Daily_Log__c = dailyLog.Id ;
        visit1.Actual_Start_Time__c = Datetime.now();
        insert visit1;
        
        
        visit1.ClockIn_Latitude__c = 37.7749;
        visit1.Clockin_Longitude__c = 78.4194;
        update visit1;
        system.debug(visit1.Id);
        
        Test.startTest();
        
        DistanceMatrixControllerForVisit.distanceCalculation(visit1.Id);
        DistanceMatrixControllerForVisit.distanceCalculationForLastVisit(dailyLog.Id,15.832253109813513, 78.03556991478293,15.913763631963366, 77.70113489750705);
        DistanceMatrixControllerForVisit.distanceCalculationinKM(15.832253109813513, 78.03556991478293,15.913763631963366, 77.70113489750705);
        
        Test.stopTest();
        
    }
}