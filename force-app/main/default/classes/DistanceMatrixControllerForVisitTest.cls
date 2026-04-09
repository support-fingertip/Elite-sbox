@isTest
public class DistanceMatrixControllerForVisitTest {

    // -------------------------------------------------------
    // Helper: create a Daily_Log__c with clock-in location
    // -------------------------------------------------------
    private static Daily_Log__c createDailyLog(Boolean withClockOut) {
        Daily_Log__c dl = new Daily_Log__c();
        dl.Day_started_time__c            = System.now();
        dl.Clock_In_Location__Latitude__s  = 17.3850;
        dl.Clock_In_Location__Longitude__s = 78.4867;
        if (withClockOut) {
            dl.Clock_Out_Location__Latitude__s  = 17.4400;
            dl.Clock_Out_Location__Longitude__s = 78.3489;
        }
        insert dl;
        return dl;
    }

    // -------------------------------------------------------
    // Helper: create a Visit__c with coordinates
    // -------------------------------------------------------
    private static Visit__c createVisit(Id dlId, Decimal lat, Decimal lon, Datetime startTime) {
        Visit__c v = new Visit__c();
        v.Daily_Log__c        = dlId;
        v.Actual_Start_Time__c = startTime;
        v.ClockIn_Latitude__c  = lat;
        v.Clockin_Longitude__c = lon;
        insert v;
        return v;
    }

    // -------------------------------------------------------
    // TEST 1: distanceCalculation — no previous visit,
    //         daily log has clock-in location  (else branch)
    // -------------------------------------------------------
    @isTest
    static void testDistanceCalculation_NoPreviousVisit_WithDailyLog() {
        Daily_Log__c dl = createDailyLog(false);

        Visit__c v = new Visit__c();
        v.Daily_Log__c         = dl.Id;
        v.Actual_Start_Time__c = System.now();
        v.ClockIn_Latitude__c  = 17.3850;
        v.Clockin_Longitude__c = 78.4867;
        insert v;

        Test.startTest();
        DistanceMatrixControllerForVisit.distanceCalculation(v.Id);
        Test.stopTest();
        // distanceCalculationinKM returns 0 in test context — no DML assert needed
    }

    // -------------------------------------------------------
    // TEST 2: distanceCalculation — previous visit exists
    //         with coordinates  (if-vis2 branch)
    // -------------------------------------------------------
    @isTest
    static void testDistanceCalculation_WithPreviousVisit() {
        Daily_Log__c dl = createDailyLog(false);

        // Earlier visit
        Visit__c v1 = new Visit__c();
        v1.Daily_Log__c         = dl.Id;
        v1.Actual_Start_Time__c = System.now().addMinutes(-30);
        v1.ClockIn_Latitude__c  = 17.3750;
        v1.Clockin_Longitude__c = 78.4767;
        insert v1;

        // Current visit (later timestamp)
        Visit__c v2 = new Visit__c();
        v2.Daily_Log__c         = dl.Id;
        v2.Actual_Start_Time__c = System.now();
        v2.ClockIn_Latitude__c  = 17.3850;
        v2.Clockin_Longitude__c = 78.4867;
        insert v2;

        Test.startTest();
        DistanceMatrixControllerForVisit.distanceCalculation(v2.Id);
        Test.stopTest();
    }

    // -------------------------------------------------------
    // TEST 3: distanceCalculation — previous visit exists
    //         but has NULL coordinates (inner null check)
    // -------------------------------------------------------
    @isTest
    static void testDistanceCalculation_PreviousVisitNullCoords() {
        Daily_Log__c dl = createDailyLog(false);

        // Earlier visit with NO coordinates
        Visit__c v1 = new Visit__c();
        v1.Daily_Log__c         = dl.Id;
        v1.Actual_Start_Time__c = System.now().addMinutes(-30);
        insert v1;

        // Current visit
        Visit__c v2 = new Visit__c();
        v2.Daily_Log__c         = dl.Id;
        v2.Actual_Start_Time__c = System.now();
        v2.ClockIn_Latitude__c  = 17.3850;
        v2.Clockin_Longitude__c = 78.4867;
        insert v2;

        Test.startTest();
        DistanceMatrixControllerForVisit.distanceCalculation(v2.Id);
        Test.stopTest();
    }

    // -------------------------------------------------------
    // TEST 4: distanceCalculation — visit has NULL coords
    //         (outer null guard — skips all distance logic)
    // -------------------------------------------------------
    @isTest
    static void testDistanceCalculation_NullCoords() {
        Daily_Log__c dl = createDailyLog(false);

        Visit__c v = new Visit__c();
        v.Daily_Log__c         = dl.Id;
        v.Actual_Start_Time__c = System.now();
        // No lat/lon — outer if-block is skipped
        insert v;

        Test.startTest();
        DistanceMatrixControllerForVisit.distanceCalculation(v.Id);
        Test.stopTest();
    }

    // -------------------------------------------------------
    // TEST 5: distanceCalculation — no daily log linked
    //         and no previous visit  (dl is empty, else branch)
    // -------------------------------------------------------
    @isTest
    static void testDistanceCalculation_NoDailyLog() {
        Visit__c v = new Visit__c();
        v.Actual_Start_Time__c = System.now();
        v.ClockIn_Latitude__c  = 17.3850;
        v.Clockin_Longitude__c = 78.4867;
        insert v;

        Test.startTest();
        DistanceMatrixControllerForVisit.distanceCalculation(v.Id);
        Test.stopTest();
    }

    // -------------------------------------------------------
    // TEST 6: distanceCalculationForLastVisit
    // -------------------------------------------------------
    @isTest
    static void testDistanceCalculationForLastVisit() {
        Daily_Log__c dl = createDailyLog(false);

        Test.startTest();
        DistanceMatrixControllerForVisit.distanceCalculationForLastVisit(
            dl.Id,
            15.8322, 78.0355,
            15.9137, 77.7011
        );
        Test.stopTest();

        Daily_Log__c updated = [SELECT Last_Visit_Distance_Salesforce__c FROM Daily_Log__c WHERE Id = :dl.Id];
        System.assertNotEquals(null, updated.Last_Visit_Distance_Salesforce__c,
            'Haversine distance should have been written');
    }

    // -------------------------------------------------------
    // TEST 7: calculateHaversineDistance & toRadians (direct)
    // -------------------------------------------------------
    @isTest
    static void testCalculateHaversineDistance() {
        Decimal result = DistanceMatrixControllerForVisit.calculateHaversineDistance(
            17.3850, 78.4867,
            17.4400, 78.3489
        );
        System.assert(result > 0, 'Haversine distance should be positive');
    }

    // -------------------------------------------------------
    // TEST 8: distanceCalculationinKM (test bypass returns 0)
    // -------------------------------------------------------
    @isTest
    static void testDistanceCalculationInKM() {
        Test.startTest();
        Decimal result = DistanceMatrixControllerForVisit.distanceCalculationinKM(
            17.3850, 78.4867,
            17.4400, 78.3489
        );
        Test.stopTest();
        System.assertEquals(0, result, 'Should return 0 in test context');
    }

    // -------------------------------------------------------
    // TEST 9: distanceCalculationForDailyRoute
    //         — with Clock Out, visits AND visit forms
    // -------------------------------------------------------
    @isTest
    static void testDistanceCalculationForDailyRoute_WithClockOut() {
        Daily_Log__c dl = createDailyLog(true); // has clock-out

        // Insert visits linked to daily log
        Visit__c v1 = createVisit(dl.Id, 17.3850, 78.4867, System.now().addMinutes(-60));
        Visit__c v2 = createVisit(dl.Id, 17.4000, 78.4500, System.now().addMinutes(-30));

        // Insert Visit Forms
        Visit_Form__c vf1 = new Visit_Form__c();
        vf1.Daily_Log__c               = dl.Id;
        vf1.Geo_Location__Latitude__s  = 17.4100;
        vf1.Geo_Location__Longitude__s = 78.4300;
        insert vf1;

        Test.startTest();
        DistanceMatrixControllerForVisit.distanceCalculationForDailyRoute(dl.Id);
        Test.stopTest();
    }

    // -------------------------------------------------------
    // TEST 10: distanceCalculationForDailyRoute
    //          — no Clock Out, uses last waypoint as destination
    // -------------------------------------------------------
    @isTest
    static void testDistanceCalculationForDailyRoute_NoClockOut() {
        Daily_Log__c dl = createDailyLog(false); // no clock-out

        createVisit(dl.Id, 17.3850, 78.4867, System.now().addMinutes(-60));
        createVisit(dl.Id, 17.4000, 78.4500, System.now().addMinutes(-30));

        Test.startTest();
        DistanceMatrixControllerForVisit.distanceCalculationForDailyRoute(dl.Id);
        Test.stopTest();
    }

    // -------------------------------------------------------
    // TEST 11: distanceCalculationForDailyRoute
    //          — no Clock Out AND no waypoints (early return)
    // -------------------------------------------------------
    @isTest
    static void testDistanceCalculationForDailyRoute_NoWaypoints() {
        Daily_Log__c dl = createDailyLog(false); // no clock-out, no visits

        Test.startTest();
        DistanceMatrixControllerForVisit.distanceCalculationForDailyRoute(dl.Id);
        Test.stopTest();
    }

    // -------------------------------------------------------
    // TEST 12: distanceCalculationForDailyRoute — null input
    // -------------------------------------------------------
    @isTest
    static void testDistanceCalculationForDailyRoute_NullId() {
        Test.startTest();
        DistanceMatrixControllerForVisit.distanceCalculationForDailyRoute(null);
        Test.stopTest();
    }

    // -------------------------------------------------------
    // TEST 13: distanceCalculationForDailyRoute — no clock-in
    //          (early return when startLat is null)
    // -------------------------------------------------------
    @isTest
    static void testDistanceCalculationForDailyRoute_NoClockIn() {
        Daily_Log__c dl = new Daily_Log__c();
        dl.Day_started_time__c = System.now();
        // No Clock_In_Location set
        insert dl;

        createVisit(dl.Id, 17.3850, 78.4867, System.now());

        Test.startTest();
        DistanceMatrixControllerForVisit.distanceCalculationForDailyRoute(dl.Id);
        Test.stopTest();
    }

    // -------------------------------------------------------
    // TEST 14: distanceCalculationForDailyRouteOld
    //          — with Clock Out and visits
    // -------------------------------------------------------
    @isTest
    static void testDistanceCalculationForDailyRouteOld_WithClockOut() {
        Daily_Log__c dl = createDailyLog(true);

        createVisit(dl.Id, 17.3850, 78.4867, System.now().addMinutes(-60));
        createVisit(dl.Id, 17.4000, 78.4500, System.now().addMinutes(-30));

        Test.startTest();
        DistanceMatrixControllerForVisit.distanceCalculationForDailyRouteOld(dl.Id);
        Test.stopTest();
    }

    // -------------------------------------------------------
    // TEST 15: distanceCalculationForDailyRouteOld
    //          — no Clock Out, last visit used as destination
    // -------------------------------------------------------
    @isTest
    static void testDistanceCalculationForDailyRouteOld_NoClockOut() {
        Daily_Log__c dl = createDailyLog(false);

        createVisit(dl.Id, 17.3850, 78.4867, System.now().addMinutes(-60));
        createVisit(dl.Id, 17.4000, 78.4500, System.now().addMinutes(-30));

        Test.startTest();
        DistanceMatrixControllerForVisit.distanceCalculationForDailyRouteOld(dl.Id);
        Test.stopTest();
    }

    // -------------------------------------------------------
    // TEST 16: distanceCalculationForDailyRouteOld
    //          — no Clock Out AND no visits (early return)
    // -------------------------------------------------------
    @isTest
    static void testDistanceCalculationForDailyRouteOld_NoVisits() {
        Daily_Log__c dl = createDailyLog(false);

        Test.startTest();
        DistanceMatrixControllerForVisit.distanceCalculationForDailyRouteOld(dl.Id);
        Test.stopTest();
    }

    // -------------------------------------------------------
    // TEST 17: distanceCalculationForDailyRouteOld — null input
    // -------------------------------------------------------
    @isTest
    static void testDistanceCalculationForDailyRouteOld_NullId() {
        Test.startTest();
        DistanceMatrixControllerForVisit.distanceCalculationForDailyRouteOld(null);
        Test.stopTest();
    }

    // -------------------------------------------------------
    // TEST 18: WaypointWrapper.compareTo — all 3 branches
    //          (equal, less-than, greater-than)
    // -------------------------------------------------------
    @isTest
    static void testWaypointWrapperCompareTo() {
        Datetime t1 = Datetime.newInstance(2024, 1, 1, 10, 0, 0);
        Datetime t2 = Datetime.newInstance(2024, 1, 1, 11, 0, 0);

        DistanceMatrixControllerForVisit.WaypointWrapper w1 =
            new DistanceMatrixControllerForVisit.WaypointWrapper(17.0, 78.0, t1);
        DistanceMatrixControllerForVisit.WaypointWrapper w2 =
            new DistanceMatrixControllerForVisit.WaypointWrapper(17.1, 78.1, t2);
        DistanceMatrixControllerForVisit.WaypointWrapper w3 =
            new DistanceMatrixControllerForVisit.WaypointWrapper(17.2, 78.2, t1); // same time as w1

        // less-than  → -1
        System.assertEquals(-1, w1.compareTo(w2), 'Earlier date should return -1');
        // greater-than → 1
        System.assertEquals(1,  w2.compareTo(w1), 'Later date should return 1');
        // equal → 0
        System.assertEquals(0,  w1.compareTo(w3), 'Same date should return 0');

        // Also exercise list sort to cover the Comparable path in bulk
        List<DistanceMatrixControllerForVisit.WaypointWrapper> wList =
            new List<DistanceMatrixControllerForVisit.WaypointWrapper>{ w2, w3, w1 };
        wList.sort();
        System.assertEquals(t1, wList[0].createdDate);
        System.assertEquals(t2, wList[2].createdDate);
    }

    // -------------------------------------------------------
    // TEST 19: Inner wrapper / response classes instantiation
    //          (ensures class-level coverage for inner types)
    // -------------------------------------------------------
    @isTest
    static void testInnerClasses() {
        // distancematrix hierarchy
        DistanceMatrixControllerForVisit.distance dist = new DistanceMatrixControllerForVisit.distance();
        dist.text  = '5 km';
        dist.value = 5000;

        DistanceMatrixControllerForVisit.duration dur = new DistanceMatrixControllerForVisit.duration();
        dur.text  = '10 mins';
        dur.value = 600;

        DistanceMatrixControllerForVisit.element elem = new DistanceMatrixControllerForVisit.element();
        elem.distance = dist;
        elem.duration = dur;

        DistanceMatrixControllerForVisit.row r = new DistanceMatrixControllerForVisit.row();
        r.elements = new List<DistanceMatrixControllerForVisit.element>{ elem };

        DistanceMatrixControllerForVisit.distancematrix dm = new DistanceMatrixControllerForVisit.distancematrix();
        dm.rows = new List<DistanceMatrixControllerForVisit.row>{ r };

        System.assertEquals(1, dm.rows.size());
        System.assertEquals(5000, dm.rows[0].elements[0].distance.value);

        // Routes API response hierarchy
        DistanceMatrixControllerForVisit.rleg leg = new DistanceMatrixControllerForVisit.rleg();
        leg.distanceMeters  = 3000L;
        leg.durationSeconds = 180L;

        DistanceMatrixControllerForVisit.rroute route = new DistanceMatrixControllerForVisit.rroute();
        route.legs           = new List<DistanceMatrixControllerForVisit.rleg>{ leg };
        route.distanceMeters = 3000L;

        DistanceMatrixControllerForVisit.routesResponse rr = new DistanceMatrixControllerForVisit.routesResponse();
        rr.routes = new List<DistanceMatrixControllerForVisit.rroute>{ route };

        System.assertEquals(1, rr.routes.size());
        System.assertEquals(3000L, rr.routes[0].legs[0].distanceMeters);
    }

    // -------------------------------------------------------
    // TEST 20: distanceCalculationForDailyRoute
    //          — only Visit Forms (no Visits)
    // -------------------------------------------------------
    @isTest
    static void testDistanceCalculationForDailyRoute_OnlyVisitForms() {
        Daily_Log__c dl = createDailyLog(true);

        Visit_Form__c vf1 = new Visit_Form__c();
        vf1.Daily_Log__c               = dl.Id;
        vf1.Geo_Location__Latitude__s  = 17.3900;
        vf1.Geo_Location__Longitude__s = 78.4700;
        insert vf1;

        Visit_Form__c vf2 = new Visit_Form__c();
        vf2.Daily_Log__c               = dl.Id;
        vf2.Geo_Location__Latitude__s  = 17.4100;
        vf2.Geo_Location__Longitude__s = 78.4300;
        insert vf2;

        Test.startTest();
        DistanceMatrixControllerForVisit.distanceCalculationForDailyRoute(dl.Id);
        Test.stopTest();
    }

    // -------------------------------------------------------
    // TEST 21: distanceCalculationForDailyRoute
    //          — large number of waypoints (> 26) to exercise
    //            the chunking while-loop over multiple iterations
    // -------------------------------------------------------
    @isTest
    static void testDistanceCalculationForDailyRoute_ManyWaypoints() {
        Daily_Log__c dl = createDailyLog(true);

        // Insert 30 visits to trigger multi-chunk logic
        List<Visit__c> visits = new List<Visit__c>();
        for (Integer i = 0; i < 30; i++) {
            Visit__c v = new Visit__c();
            v.Daily_Log__c         = dl.Id;
            v.Actual_Start_Time__c = System.now().addMinutes(-60 + i);
            v.ClockIn_Latitude__c  = 17.3850 + (i * 0.001);
            v.Clockin_Longitude__c = 78.4867 + (i * 0.001);
            visits.add(v);
        }
        insert visits;

        Test.startTest();
        DistanceMatrixControllerForVisit.distanceCalculationForDailyRoute(dl.Id);
        Test.stopTest();
    }
}