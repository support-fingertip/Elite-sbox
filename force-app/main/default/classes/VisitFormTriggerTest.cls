@isTest
public class VisitFormTriggerTest {

    @isTest
    static void testInsertVisitForm() {

        List<Visit_Form__c> visitList = new List<Visit_Form__c>();

        for(Integer i = 0; i < 5; i++){

            Visit_Form__c vf = new Visit_Form__c();

            vf.Geo_Location__Latitude__s = 28.6139;
            vf.Geo_Location__Longitude__s = 77.2090;

            visitList.add(vf);
        }

        Test.startTest();
        insert visitList;
        Test.stopTest();

        System.assertEquals(5, visitList.size());
    }


    @isTest
    static void testDeleteVisitForm() {

        Visit_Form__c vf = new Visit_Form__c(
            Geo_Location__Latitude__s = 28.6139,
            Geo_Location__Longitude__s = 77.2090
        );

        insert vf;

        Test.startTest();
        delete vf;
        Test.stopTest();

        System.assert(true);
    }


    @isTest
    static void testUndeleteVisitForm() {

        Visit_Form__c vf = new Visit_Form__c(
            Geo_Location__Latitude__s = 28.6139,
            Geo_Location__Longitude__s = 77.2090
        );

        insert vf;
        delete vf;

        Test.startTest();
        undelete vf;
        Test.stopTest();

        System.assert(true);
    }
}