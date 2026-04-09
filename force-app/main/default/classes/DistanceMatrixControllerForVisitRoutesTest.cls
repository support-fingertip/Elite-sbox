@isTest
public class DistanceMatrixControllerForVisitRoutesTest implements HttpCalloutMock {
    // Mock the Routes API computeRoutes response
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type','application/json');
        res.setBody('{"routes":[{"legs":[{"distanceMeters":1200,"durationSeconds":180},{"distanceMeters":3000,"durationSeconds":600}]}]}');
        res.setStatusCode(200);
        return res;
    }

    @isTest static void testComputeRoutesMock() {
        // Prepare daily log and a single visit
        Daily_Log__c dl = new Daily_Log__c(Name='DL Test');
        dl.Clock_In_Location__Latitude__s = 12.9716;
        dl.Clock_In_Location__Longitude__s = 77.5946;
        dl.Clock_Out_Location__Latitude__s = 12.9352;
        dl.Clock_Out_Location__Longitude__s = 77.6245;
        insert dl;

        Visit__c v = new Visit__c(Name='V1', Daily_Log__c = dl.Id, ClockIn_Latitude__c = 12.9611, Clockin_Longitude__c = 77.6010, Actual_Start_Time__c = System.now());
        insert v;

        Test.setMock(HttpCalloutMock.class, new DistanceMatrixControllerForVisitRoutesTest());

        Test.startTest();
        // call future method; it will execute on Test.stopTest()
        DistanceMatrixControllerForVisit.distanceCalculationForDailyRoute(dl.Id);
        Test.stopTest();

        Daily_Log__c dlUpd = [SELECT KMs_Travelled__c, Today_Day_Travelled_Distance_KM__c FROM Daily_Log__c WHERE Id=:dl.Id];
        // expected meters = 1200 + 3000 = 4200 => 4.2 km
        System.assertEquals(Decimal.valueOf(4.2), dlUpd.KMs_Travelled__c.setScale(1));
    }
}
