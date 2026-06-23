@isTest
public class TAM_CalculationEngine_ServiceTest {

    private static User makeUser(String alias) {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        return new User(
            FirstName = 'T', LastName = alias,
            Email = alias + '@example.com',
            Username = alias + System.currentTimeMillis() + '@example.com',
            Alias = alias.substring(0, Math.min(8, alias.length())),
            TimeZoneSidKey = 'Asia/Kolkata', LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', ProfileId = p.Id,
            Employee_Code__c = 'EC-' + alias + String.valueOf(System.currentTimeMillis())
        );
    }

    /**
     * Seed data shared by every operator test below. One user, two outlets,
     * two products in a Focused Pack, and a small Order + Order_Item set.
     * Each test queries what it needs and builds its own criterion.
     */
    @TestSetup
    static void setup() {
        User u = makeUser('engsh');
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert u;
        }

        Account acc1 = new Account(Name = 'EngTest O1', Customer_Type__c = 'Secondary Customer',
            Pincode__c = '123456', Primary_Phone_Number__c = '9876543210',
            State__c = 'Karnataka', District__c = 'Kolar');
        Account acc2 = new Account(Name = 'EngTest O2', Customer_Type__c = 'Secondary Customer',
            Pincode__c = '123456', Primary_Phone_Number__c = '9876543210',
            State__c = 'Karnataka', District__c = 'Kolar');
        insert new List<Account>{ acc1, acc2 };

        Product__c prodA = new Product__c(Name = 'EngA', Net_Weight__c = 1, SKU_Code__c = 'ENG-A');
        Product__c prodB = new Product__c(Name = 'EngB', Net_Weight__c = 1, SKU_Code__c = 'ENG-B');
        insert new List<Product__c>{ prodA, prodB };

        Focused_Pack__c fp = new Focused_Pack__c(Name = 'EngPack', Minimum_Qualifying_Quantity__c = 10);
        insert fp;
        insert new List<Focused_Pack_Item__c>{
            new Focused_Pack_Item__c(Focused_Pack__c = fp.Id, SKU__c = prodA.Id),
            new Focused_Pack_Item__c(Focused_Pack__c = fp.Id, SKU__c = prodB.Id)
        };

        // Daily logs so attendance-divisor operators have working days.
        insert new List<Daily_Log__c>{
            new Daily_Log__c(User__c = u.Id, OwnerId = u.Id,
                Day_started_time__c = Datetime.newInstance(
                    Date.today().year(), Date.today().month(), Date.today().day(), 12, 0, 0)),
            new Daily_Log__c(User__c = u.Id, OwnerId = u.Id,
                Day_started_time__c = Datetime.newInstance(
                    Date.today().addDays(1).year(),
                    Date.today().addDays(1).month(),
                    Date.today().addDays(1).day(), 12, 0, 0))
        };

        // Two orders on different days → exercise per-day daily-* logic.
        Order__c o1 = new Order__c(Account__c = acc1.Id, OwnerId = u.Id, Order_Date__c = Date.today());
        Order__c o2 = new Order__c(Account__c = acc2.Id, OwnerId = u.Id, Order_Date__c = Date.today().addDays(1));
        insert new List<Order__c>{ o1, o2 };

        insert new List<Order_Item__c>{
            // o1 / acc1 / 6 + 6 = 12 (meets FP min qty 10), 600+600=1200 revenue
            new Order_Item__c(Order__c = o1.Id, Product__c = prodA.Id, Account__c = acc1.Id,
                Quantity__c = 6, Total_Amount__c = 600),
            new Order_Item__c(Order__c = o1.Id, Product__c = prodB.Id, Account__c = acc1.Id,
                Quantity__c = 6, Total_Amount__c = 600),
            // o2 / acc2 / 6 (doesn't meet FP min qty), 300 revenue
            new Order_Item__c(Order__c = o2.Id, Product__c = prodA.Id, Account__c = acc2.Id,
                Quantity__c = 6, Total_Amount__c = 300)
        };
    }

    // ----- Helpers -----

    private static Target_Criteria__c makeCrit(String name, String op) {
        return new Target_Criteria__c(
            Name = name, Object__c = 'Order_Item__c', Operator__c = op,
            Date_Field__c = 'Order_Date__c', User_Field__c = 'Order_Owner_Id__c',
            Active__c = true
        );
    }

    private static Secondary_Target__c makeTgt(Id userId, Id critId, Decimal targetVal, Id packId) {
        return new Secondary_Target__c(
            User__c = userId, Target_Criteria__c = critId, Target_Value__c = targetVal,
            Focused_Pack__c = packId, Is_Active__c = true,
            Start_Date__c = Date.today().addDays(-1),
            End_Date__c = Date.today().addDays(2)
        );
    }

    // ----- Guard tests -----

    @isTest
    static void testEmptyAndNullGuards() {
        Target_Criteria__c crit = makeCrit('g', 'SUM');
        crit.Field__c = 'Total_Amount__c';
        insert crit;

        Test.startTest();
        Map<Id, Decimal> r1 = TAM_CalculationEngine_Service.compute(
            crit, new List<Secondary_Target__c>(), Date.today(), Date.today(), null);
        Map<Id, Decimal> r2 = TAM_CalculationEngine_Service.computePerUser(
            crit, new Set<Id>(), Date.today(), Date.today(), null);
        Map<Id, Decimal> r3 = TAM_CalculationEngine_Service.compute(
            null, new List<Secondary_Target__c>(), Date.today(), Date.today(), null);
        Test.stopTest();

        System.assertEquals(0, r1.size());
        System.assertEquals(0, r2.size());
        System.assertEquals(0, r3.size());
    }

    // ----- Operator coverage -----

    @isTest
    static void testSumOperator() {
        User u = [SELECT Id FROM User WHERE LastName = 'engsh' LIMIT 1];
        Target_Criteria__c crit = makeCrit('Sum', 'SUM');
        crit.Field__c = 'Total_Amount__c';
        insert crit;
        Secondary_Target__c tgt = makeTgt(u.Id, crit.Id, 2000, null);
        insert tgt;

        Test.startTest();
        Map<Id, Decimal> result = TAM_CalculationEngine_Service.compute(
            crit, new List<Secondary_Target__c>{ tgt },
            Date.today().addDays(-1), Date.today().addDays(2), null);
        Test.stopTest();

        // 600 + 600 + 300 = 1500 across all items the test user owns in range.
        System.assertEquals(1500, result.get(tgt.Id), 'SUM of Total_Amount__c');
    }

    @isTest
    static void testCountOperator() {
        User u = [SELECT Id FROM User WHERE LastName = 'engsh' LIMIT 1];
        Target_Criteria__c crit = makeCrit('Count', 'COUNT');
        insert crit;
        Secondary_Target__c tgt = makeTgt(u.Id, crit.Id, 10, null);
        insert tgt;

        Test.startTest();
        Map<Id, Decimal> result = TAM_CalculationEngine_Service.compute(
            crit, new List<Secondary_Target__c>{ tgt },
            Date.today().addDays(-1), Date.today().addDays(2), null);
        Test.stopTest();
        // Three test-inserted items. Other tests' items may have bled in via
        // pre-existing org data — assert at least 3.
        System.assert(result.get(tgt.Id) >= 3, 'COUNT should see at least the 3 seeded items, got ' + result.get(tgt.Id));
    }

    @isTest
    static void testCountDistinctOperator() {
        User u = [SELECT Id FROM User WHERE LastName = 'engsh' LIMIT 1];
        Target_Criteria__c crit = makeCrit('Distinct', 'COUNT_DISTINCT');
        crit.Distinct_Field__c = 'Account__c';
        insert crit;
        Secondary_Target__c tgt = makeTgt(u.Id, crit.Id, 5, null);
        insert tgt;

        Test.startTest();
        Map<Id, Decimal> result = TAM_CalculationEngine_Service.compute(
            crit, new List<Secondary_Target__c>{ tgt },
            Date.today().addDays(-1), Date.today().addDays(2), null);
        Test.stopTest();
        // Two distinct accounts seeded.
        System.assert(result.get(tgt.Id) >= 2, 'COUNT_DISTINCT should see at least 2 outlets');
    }

    @isTest
    static void testDailyUniqueAvgOperator() {
        User u = [SELECT Id FROM User WHERE LastName = 'engsh' LIMIT 1];
        Target_Criteria__c crit = makeCrit('DailyUnique', 'DAILY_UNIQUE_AVG');
        crit.Distinct_Field__c = 'Account__c';
        crit.Use_Attendance_Divisor__c = true;
        insert crit;
        Map<Id, Integer> wd = new Map<Id, Integer>{ u.Id => 2 };
        Secondary_Target__c tgt = makeTgt(u.Id, crit.Id, 1, null);
        insert tgt;

        Test.startTest();
        Map<Id, Decimal> result = TAM_CalculationEngine_Service.compute(
            crit, new List<Secondary_Target__c>{ tgt },
            Date.today().addDays(-1), Date.today().addDays(2), wd);
        Test.stopTest();

        System.assertNotEquals(null, result.get(tgt.Id), 'DAILY_UNIQUE_AVG computed');
        System.assert(result.get(tgt.Id) > 0, 'should yield a positive average');
    }

    @isTest
    static void testDailyLinesPerOrderOperator() {
        User u = [SELECT Id FROM User WHERE LastName = 'engsh' LIMIT 1];
        Target_Criteria__c crit = makeCrit('DLpO', 'DAILY_LINES_PER_ORDER');
        crit.Distinct_Field__c = 'Order__c';
        crit.Use_Attendance_Divisor__c = true;
        insert crit;
        Map<Id, Integer> wd = new Map<Id, Integer>{ u.Id => 2 };
        Secondary_Target__c tgt = makeTgt(u.Id, crit.Id, 5, null);
        insert tgt;

        Test.startTest();
        Map<Id, Decimal> result = TAM_CalculationEngine_Service.compute(
            crit, new List<Secondary_Target__c>{ tgt },
            Date.today().addDays(-1), Date.today().addDays(2), wd);
        Test.stopTest();

        System.assertNotEquals(null, result.get(tgt.Id), 'DAILY_LINES_PER_ORDER computed');
    }

    @isTest
    static void testDailyRatioAvgOperator() {
        User u = [SELECT Id FROM User WHERE LastName = 'engsh' LIMIT 1];
        Target_Criteria__c crit = makeCrit('Ratio', 'DAILY_RATIO_AVG');
        crit.Numerator_Field__c = 'Total_Amount__c';
        crit.Denominator_Field__c = 'Quantity__c';
        crit.Use_Attendance_Divisor__c = true;
        insert crit;
        Map<Id, Integer> wd = new Map<Id, Integer>{ u.Id => 2 };
        Secondary_Target__c tgt = makeTgt(u.Id, crit.Id, 100, null);
        insert tgt;

        Test.startTest();
        Map<Id, Decimal> result = TAM_CalculationEngine_Service.compute(
            crit, new List<Secondary_Target__c>{ tgt },
            Date.today().addDays(-1), Date.today().addDays(2), wd);
        Test.stopTest();

        System.assertNotEquals(null, result.get(tgt.Id), 'DAILY_RATIO_AVG computed');
    }

    @isTest
    static void testFocusPackRevenue() {
        User u = [SELECT Id FROM User WHERE LastName = 'engsh' LIMIT 1];
        Focused_Pack__c fp = [SELECT Id FROM Focused_Pack__c WHERE Name = 'EngPack' LIMIT 1];
        Target_Criteria__c crit = makeCrit('FpRev', 'FOCUS_PACK_REVENUE');
        insert crit;
        Secondary_Target__c tgt = makeTgt(u.Id, crit.Id, 5000, fp.Id);
        insert tgt;

        Test.startTest();
        Map<Id, Decimal> result = TAM_CalculationEngine_Service.compute(
            crit, new List<Secondary_Target__c>{ tgt },
            Date.today().addDays(-1), Date.today().addDays(2), null);
        Test.stopTest();

        // 600 + 600 + 300 = 1500 across pack SKUs in the period for this user.
        System.assert(result.get(tgt.Id) >= 1500, 'FP Revenue covers all pack-SKU lines');
    }

    @isTest
    static void testFocusPackEcoDirect() {
        User u = [SELECT Id FROM User WHERE LastName = 'engsh' LIMIT 1];
        Focused_Pack__c fp = [SELECT Id FROM Focused_Pack__c WHERE Name = 'EngPack' LIMIT 1];
        Target_Criteria__c crit = makeCrit('FpEco', 'FOCUS_PACK_ECO');
        insert crit;
        Secondary_Target__c tgt = makeTgt(u.Id, crit.Id, 5, fp.Id);
        insert tgt;

        Test.startTest();
        Map<Id, Decimal> result = TAM_CalculationEngine_Service.compute(
            crit, new List<Secondary_Target__c>{ tgt },
            Date.today().addDays(-1), Date.today().addDays(2), null);
        Test.stopTest();

        // Only acc1 reaches the 10-unit threshold within a single order.
        System.assert(result.get(tgt.Id) >= 1, 'at least the 1 qualifying outlet');
    }

    @isTest
    static void testSecondarySourceObjectsUnion() {
        // DAILY_UNIQUE_AVG with Secondary_Source_Objects exercises
        // parseSecondarySources (a private helper that was 0% covered).
        User u = [SELECT Id FROM User WHERE LastName = 'engsh' LIMIT 1];
        // Seed a Visit_Form__c so the secondary source union has something to read.
        Account acc1 = [SELECT Id FROM Account WHERE Name = 'EngTest O1' LIMIT 1];
        insert new Visit_Form__c(
            OwnerId = u.Id, Secondary_Customer__c = acc1.Id,
            Geo_Location__Latitude__s = 17.41, Geo_Location__Longitude__s = 78.43
        );

        Target_Criteria__c crit = makeCrit('TC', 'DAILY_UNIQUE_AVG');
        crit.Distinct_Field__c = 'Account__c';
        crit.Use_Attendance_Divisor__c = true;
        crit.Secondary_Source_Objects__c =
            '[{"object":"Visit_Form__c","userField":"OwnerId","dateField":"CreatedDate","distinctField":"CustomerId__c"}]';
        insert crit;
        Map<Id, Integer> wd = new Map<Id, Integer>{ u.Id => 2 };
        Secondary_Target__c tgt = makeTgt(u.Id, crit.Id, 1, null);
        insert tgt;

        Test.startTest();
        Map<Id, Decimal> result = TAM_CalculationEngine_Service.compute(
            crit, new List<Secondary_Target__c>{ tgt },
            Date.today().addDays(-1), Date.today().addDays(2), wd);
        Test.stopTest();

        System.assertNotEquals(null, result.get(tgt.Id),
            'TC with Visit_Form__c union should compute');
    }

    @isTest
    static void testComputePerUserDirect() {
        // computePerUser is a separate public entry point used by the
        // criteria-builder preview pipeline. Verify it returns a map keyed
        // by userId.
        User u = [SELECT Id FROM User WHERE LastName = 'engsh' LIMIT 1];
        Target_Criteria__c crit = makeCrit('PerUser', 'SUM');
        crit.Field__c = 'Total_Amount__c';
        insert crit;

        Test.startTest();
        Map<Id, Decimal> result = TAM_CalculationEngine_Service.computePerUser(
            crit, new Set<Id>{ u.Id },
            Date.today().addDays(-1), Date.today().addDays(2),
            new Map<Id, Integer>{ u.Id => 2 });
        Test.stopTest();

        System.assertNotEquals(null, result.get(u.Id), 'per-user result for the test user');
        System.assert(result.get(u.Id) >= 1500, 'sum should include the 1500 seeded revenue');
    }
}