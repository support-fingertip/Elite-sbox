@isTest
public class VisitFormTriggerTest {
    @testSetup
    static void setup() {
        Daily_Log__c log = new Daily_Log__c();
        insert log;
    }

    @isTest
    static void testAfterInsertTrigger() {
        Daily_Log__c log = [SELECT Id FROM Daily_Log__c LIMIT 1];
        Visit_Form__c visitForm = new Visit_Form__c(
            Daily_Log__c = log.Id,
            Geo_Location__Latitude__s = 28.6139,
            Geo_Location__Longitude__s = 77.2090
        );
        insert visitForm;
        // Assert trigger effect
        log = [SELECT Total_Visit_form_Calls__c FROM Daily_Log__c WHERE Id = :log.Id];
        System.assertEquals(1, log.Total_Visit_form_Calls__c);
    }

    @isTest
    static void testAfterDeleteTrigger() {
        Daily_Log__c log = [SELECT Id FROM Daily_Log__c LIMIT 1];
        Visit_Form__c visitForm = new Visit_Form__c(
            Daily_Log__c = log.Id,
            Geo_Location__Latitude__s = 28.6139,
            Geo_Location__Longitude__s = 77.2090
        );
        insert visitForm;
        delete visitForm;
        // Assert trigger effect
        log = [SELECT Total_Visit_form_Calls__c FROM Daily_Log__c WHERE Id = :log.Id];
        System.assertEquals(0, log.Total_Visit_form_Calls__c);
    }

    @isTest
    static void testAfterUndeleteTrigger() {
        Daily_Log__c log = [SELECT Id FROM Daily_Log__c LIMIT 1];
        Visit_Form__c visitForm = new Visit_Form__c(
            Daily_Log__c = log.Id,
            Geo_Location__Latitude__s = 28.6139,
            Geo_Location__Longitude__s = 77.2090
        );
        insert visitForm;
        delete visitForm;
        undelete visitForm;
        // Assert trigger effect
        log = [SELECT Total_Visit_form_Calls__c FROM Daily_Log__c WHERE Id = :log.Id];
        System.assertEquals(1, log.Total_Visit_form_Calls__c);
    }
}