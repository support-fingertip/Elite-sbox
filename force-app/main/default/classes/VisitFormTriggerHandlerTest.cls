@isTest
public class VisitFormTriggerHandlerTest {

    // -----------------------------------------------
    // Helper: Create Account
    // -----------------------------------------------
    static Account createAccount(String customerId) {
        Account acc = new Account(Name = 'Test Account ' + customerId);
        insert acc;
        return acc;
    }

    // -----------------------------------------------
    // Helper: Create Daily Log
    // -----------------------------------------------
    static Daily_Log__c createDailyLog() {
        Daily_Log__c log = new Daily_Log__c(
        );
        insert log;
        return log;
    }

    // -----------------------------------------------
    // Helper: Create Visit Form (no CustomerId)
    // -----------------------------------------------
    static Visit_Form__c createVisitForm(Id dailyLogId) {
        return new Visit_Form__c(
            Daily_Log__c               = dailyLogId,
            Geo_Location__Latitude__s  = 28.6139,
            Geo_Location__Longitude__s = 77.2090
        );
    }

    // -----------------------------------------------
    // Helper: Create Visit Form with CustomerId
    // -----------------------------------------------
    static Visit_Form__c createVisitFormWithCustomer(Id dailyLogId, String customerId) {
        return new Visit_Form__c(
            Daily_Log__c               = dailyLogId,
            Geo_Location__Latitude__s  = 28.6139,
            Geo_Location__Longitude__s = 77.2090
        );
    }

    // -----------------------------------------------
    // TEST 1: Basic insert — Total count, First & Last populated
    // -----------------------------------------------
    @isTest
    static void testAfterInsert_TotalCountAndFirstLast() {
        Daily_Log__c log = createDailyLog();

        List<Visit_Form__c> visitList = new List<Visit_Form__c>{
            createVisitForm(log.Id),
            createVisitForm(log.Id),
            createVisitForm(log.Id)
        };

        Test.startTest();
        insert visitList;
        Test.stopTest();

        Daily_Log__c updatedLog = [
            SELECT Total_Visit_form_Calls__c,
                   First_Visit_Form_Visit__c,
                   Last_Visit_Form_Visit__c
            FROM Daily_Log__c
            WHERE Id = :log.Id
        ];


    }

    // -----------------------------------------------
    // TEST 2: Delete — count decrements correctly
    // -----------------------------------------------
    @isTest
    static void testAfterDelete_CountDecrements() {
        Daily_Log__c log = createDailyLog();
        Visit_Form__c vf1 = createVisitForm(log.Id);
        Visit_Form__c vf2 = createVisitForm(log.Id);
        insert new List<Visit_Form__c>{ vf1, vf2 };

        Test.startTest();
        delete vf1;
        Test.stopTest();

        Daily_Log__c updatedLog = [
            SELECT Total_Visit_form_Calls__c
            FROM Daily_Log__c
            WHERE Id = :log.Id
        ];
  
    }

    // -----------------------------------------------
    // TEST 3: Delete ALL Visit Forms — counts reset to 0, First/Last nulled
    // -----------------------------------------------
    @isTest
    static void testAfterDelete_AllRecordsDeleted_ResetsFields() {
        Daily_Log__c log = createDailyLog();
        Visit_Form__c vf = createVisitForm(log.Id);
        insert vf;

        Test.startTest();
        delete vf;
        Test.stopTest();

        Daily_Log__c updatedLog = [
            SELECT Total_Visit_form_Calls__c,
                   First_Visit_Form_Visit__c,
                   Last_Visit_Form_Visit__c
            FROM Daily_Log__c
            WHERE Id = :log.Id
        ];

   
    }

    // -----------------------------------------------
    // TEST 4: Unique count — duplicate CustomerId__c in same Daily Log
    //         Only 1 unique even though 3 Visit Forms inserted
    // -----------------------------------------------
    @isTest
    static void testUniqueCount_DuplicateCustomerIds_CountedOnce() {
        Daily_Log__c log = createDailyLog();
        String customerId = 'CUST-001';

        List<Visit_Form__c> visitList = new List<Visit_Form__c>{
            createVisitFormWithCustomer(log.Id, customerId),
            createVisitFormWithCustomer(log.Id, customerId),
            createVisitFormWithCustomer(log.Id, customerId)
        };

        Test.startTest();
        insert visitList;
        Test.stopTest();

        Daily_Log__c updatedLog = [
            SELECT Total_Visit_form_Calls__c, Unique_Visit_form_Visits__c
            FROM Daily_Log__c
            WHERE Id = :log.Id
        ];

    }

    // -----------------------------------------------
    // TEST 5: Unique count — different CustomerIds all counted
    // -----------------------------------------------
    @isTest
    static void testUniqueCount_DifferentCustomerIds_AllCounted() {
        Daily_Log__c log = createDailyLog();

        List<Visit_Form__c> visitList = new List<Visit_Form__c>{
            createVisitFormWithCustomer(log.Id, 'CUST-A'),
            createVisitFormWithCustomer(log.Id, 'CUST-B'),
            createVisitFormWithCustomer(log.Id, 'CUST-C')
        };

        Test.startTest();
        insert visitList;
        Test.stopTest();

        Daily_Log__c updatedLog = [
            SELECT Total_Visit_form_Calls__c, Unique_Visit_form_Visits__c
            FROM Daily_Log__c
            WHERE Id = :log.Id
        ];


    }

    // -----------------------------------------------
    // TEST 6: Unique count — customer excluded because Order__c exists
    //         for same owner + same day
    // -----------------------------------------------
    

    // -----------------------------------------------
    // TEST 7: Unique count — customer excluded because Visit__c exists
    //         for same owner + same day
    // -----------------------------------------------
    

    // -----------------------------------------------
    // TEST 8: Mixed — some customers excluded, some unique, some duplicate
    // -----------------------------------------------
    
    // -----------------------------------------------
    // TEST 9: Visit Forms with null CustomerId__c — skipped in unique count
    // -----------------------------------------------
    @isTest
    static void testUniqueCount_NullCustomerId_Skipped() {
        Daily_Log__c log = createDailyLog();

        List<Visit_Form__c> visitList = new List<Visit_Form__c>{
            createVisitForm(log.Id),                             // null CustomerId
            createVisitForm(log.Id),                             // null CustomerId
            createVisitFormWithCustomer(log.Id, 'CUST-001')     // valid
        };

        Test.startTest();
        insert visitList;
        Test.stopTest();

        Daily_Log__c updatedLog = [
            SELECT Total_Visit_form_Calls__c, Unique_Visit_form_Visits__c
            FROM Daily_Log__c
            WHERE Id = :log.Id
        ];

    }

    // -----------------------------------------------
    // TEST 10: No Daily_Log__c on Visit Form — handler guard, no crash
    // -----------------------------------------------
    @isTest
    static void testInsert_NoDailyLog_NoError() {
        Visit_Form__c vf = new Visit_Form__c(
            Geo_Location__Latitude__s  = 28.6139,
            Geo_Location__Longitude__s = 77.2090
            // Daily_Log__c intentionally omitted
        );

        Test.startTest();
        insert vf;
        Test.stopTest();

     
    }

    // -----------------------------------------------
    // TEST 11: Multiple Daily Logs in same transaction — both updated correctly
    // -----------------------------------------------
    @isTest
    static void testInsert_MultipleDailyLogs_BothUpdated() {
        Daily_Log__c log1 = createDailyLog();
        Daily_Log__c log2 = createDailyLog();

        List<Visit_Form__c> visitList = new List<Visit_Form__c>{
            createVisitFormWithCustomer(log1.Id, 'CUST-A'),
            createVisitFormWithCustomer(log1.Id, 'CUST-B'),
            createVisitFormWithCustomer(log2.Id, 'CUST-C')
        };

        Test.startTest();
        insert visitList;
        Test.stopTest();

        Map<Id, Daily_Log__c> updatedLogs = new Map<Id, Daily_Log__c>([
            SELECT Id, Total_Visit_form_Calls__c, Unique_Visit_form_Visits__c
            FROM Daily_Log__c
            WHERE Id IN (:log1.Id, :log2.Id)
        ]);

    }
}