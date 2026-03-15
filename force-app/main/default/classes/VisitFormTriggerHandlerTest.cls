@isTest
public class VisitFormTriggerHandlerTest {

    // Create Daily Log record
    static Daily_Log__c createDailyLog(){
        Daily_Log__c log = new Daily_Log__c();
        insert log;
        return log;
    }

    // Create Visit Form record
    static Visit_Form__c createVisitForm(Id dailyLogId){

        Visit_Form__c vf = new Visit_Form__c(
            Daily_Log__c = dailyLogId,
            Geo_Location__Latitude__s = 28.6139,
            Geo_Location__Longitude__s = 77.2090
        );

        return vf;
    }

    @isTest
    static void testAfterInsert(){

        Daily_Log__c log = createDailyLog();

        List<Visit_Form__c> visitList = new List<Visit_Form__c>();

        visitList.add(createVisitForm(log.Id));
        visitList.add(createVisitForm(log.Id));
        visitList.add(createVisitForm(log.Id));

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

        System.assertEquals(3, updatedLog.Total_Visit_form_Calls__c);
        System.assertNotEquals(null, updatedLog.First_Visit_Form_Visit__c);
        System.assertNotEquals(null, updatedLog.Last_Visit_Form_Visit__c);
    }

    @isTest
    static void testAfterDelete(){

        Daily_Log__c log = createDailyLog();

        Visit_Form__c vf1 = createVisitForm(log.Id);
        Visit_Form__c vf2 = createVisitForm(log.Id);

        insert new List<Visit_Form__c>{vf1, vf2};

        Test.startTest();
        delete vf1;
        Test.stopTest();

        Daily_Log__c updatedLog = [
            SELECT Total_Visit_form_Calls__c
            FROM Daily_Log__c
            WHERE Id = :log.Id
        ];

        System.assertEquals(1, updatedLog.Total_Visit_form_Calls__c);
    }

    @isTest
    static void testAfterUndelete(){

        Daily_Log__c log = createDailyLog();

        Visit_Form__c vf = createVisitForm(log.Id);

        insert vf;
        delete vf;

        Test.startTest();
        undelete vf;
        Test.stopTest();

        Daily_Log__c updatedLog = [
            SELECT Total_Visit_form_Calls__c
            FROM Daily_Log__c
            WHERE Id = :log.Id
        ];

        System.assertEquals(1, updatedLog.Total_Visit_form_Calls__c);
    }

}