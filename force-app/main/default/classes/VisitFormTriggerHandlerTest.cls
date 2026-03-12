@isTest
public class VisitFormTriggerHandlerTest {
    @testSetup
    static void setup() {
        // Create Daily_Log__c records (only required fields)
        List<Daily_Log__c> logs = new List<Daily_Log__c>();
        for (Integer i = 0; i < 2; i++) {
            logs.add(new Daily_Log__c());
        }
        insert logs;

        // Create Visit_Form__c records linked to Daily_Log__c (required fields)
        List<Visit_Form__c> visitForms = new List<Visit_Form__c>();
        for (Daily_Log__c log : logs) {
            visitForms.add(new Visit_Form__c(
                Daily_Log__c = log.Id,
                Geo_Location__Latitude__s = 28.6139,
                Geo_Location__Longitude__s = 77.2090
            ));
        }
        insert visitForms;
    }

    @isTest
    static void testAfterInsert() {
        // Create a single Daily_Log__c and Visit_Form__c to avoid multiple batch jobs
        Daily_Log__c log = new Daily_Log__c();
        insert log;
        Visit_Form__c visitForm = new Visit_Form__c(
            Daily_Log__c = log.Id,
            Geo_Location__Latitude__s = 28.6139,
            Geo_Location__Longitude__s = 77.2090
        );
        insert visitForm;
        Test.startTest();
        VisitFormTriggerHandler.afterInsert(new List<Visit_Form__c>{visitForm});
        Test.stopTest();
        // Assert Daily_Log__c fields updated
        log = [SELECT Total_Visit_form_Calls__c FROM Daily_Log__c WHERE Id = :log.Id];
        System.assertEquals(1, log.Total_Visit_form_Calls__c);
    }

    @isTest
    static void testAfterDelete() {
        // Create a single Daily_Log__c and Visit_Form__c to avoid multiple batch jobs
        Daily_Log__c log = new Daily_Log__c();
        insert log;
        Visit_Form__c visitForm = new Visit_Form__c(
            Daily_Log__c = log.Id,
            Geo_Location__Latitude__s = 28.6139,
            Geo_Location__Longitude__s = 77.2090
        );
        insert visitForm;
        delete visitForm;
        Test.startTest();
        VisitFormTriggerHandler.afterDelete(new List<Visit_Form__c>{visitForm});
        Test.stopTest();
        // Assert Daily_Log__c fields reset
        log = [SELECT Total_Visit_form_Calls__c FROM Daily_Log__c WHERE Id = :log.Id];
        System.assertEquals(0, log.Total_Visit_form_Calls__c);
    }

    @isTest
    static void testCoverageForPrivateMethod() {
        // Create a single Daily_Log__c and Visit_Form__c to avoid multiple batch jobs
        Daily_Log__c log = new Daily_Log__c();
        insert log;
        Visit_Form__c visitForm = new Visit_Form__c(
            Daily_Log__c = log.Id,
            Geo_Location__Latitude__s = 28.6139,
            Geo_Location__Longitude__s = 77.2090
        );
        insert visitForm;
        Test.startTest();
        VisitFormTriggerHandler.afterInsert(new List<Visit_Form__c>{visitForm});
        Test.stopTest();
        // No assertion needed, just coverage
    }
}