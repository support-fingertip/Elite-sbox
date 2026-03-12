@isTest
public class VisitFormControllerTest {

    @testSetup
static void setupData(){

    Account primary = new Account(
        Name = 'Primary Customer',
        Type = 'Distributor',
        BillingState = 'Jharkhand',
        BillingCity = 'Ranchi'
    );
    insert primary;

    Account secondary = new Account(
        Name = 'Secondary Customer',
        ParentId = primary.Id,
        BillingState = 'Jharkhand',
        BillingCity = 'Ranchi'
    );
    insert secondary;

    Product_Mapping__c pm = new Product_Mapping__c(
        Customer__c = secondary.Id,
        Primary_Customer__c = primary.Id
    );

    insert pm;
}

    @isTest
    static void testPrimaryCustomer(){

        Test.startTest();
        List<Account> accList = VisitFormController.getPrimaryCustomers();
        Test.stopTest();

        System.assertNotEquals(null, accList);
    }


    @isTest
    static void testSecondaryCustomer(){

        Account primary = [SELECT Id FROM Account WHERE ParentId = null LIMIT 1];

        Test.startTest();
        List<Account> accList =
            VisitFormController.getSecondaryCustomers(primary.Id);
        Test.stopTest();

        System.assertNotEquals(null, accList);
    }


    @isTest
    static void testAutoFill(){

        Account secondary =
            [SELECT Id FROM Account WHERE ParentId != null LIMIT 1];

        Test.startTest();
        Map<String,String> result =
            VisitFormController.getSecondaryCustomerAutoFill(secondary.Id);
        Test.stopTest();

        System.assertNotEquals(null, result);
    }


    @isTest
    static void testAllowedProducts(){

        Test.startTest();
        Map<String,List<String>> products =
            VisitFormController.getAllowedProducts();
        Test.stopTest();

        System.assertNotEquals(null, products);
    }


    @isTest
    static void testSavePrimaryVisit(){

        Account primary =
            [SELECT Id FROM Account WHERE ParentId = null LIMIT 1];

        Test.startTest();

        Id visitId = VisitFormController.savePrimaryVisit(
            primary.Id,
            'Cement',
            'Retail',
            'UltraTech',
            'OPC',
            'Remarks',
            'General',
            null,
            null,
            null,
            null,
            23.5,
            85.3,
            null,
            null
        );

        Test.stopTest();

        System.assertNotEquals(null, visitId);
    }


    @isTest
    static void testSaveSecondaryVisit(){

        Account primary =
            [SELECT Id FROM Account WHERE ParentId = null LIMIT 1];

        Account secondary =
            [SELECT Id FROM Account WHERE ParentId != null LIMIT 1];

        Test.startTest();

        Id visitId = VisitFormController.saveSecondaryVisit(
            primary.Id,
            secondary.Id,
            'Cement',
            'Retail',
            'UltraTech',
            'OPC',
            'Remarks',
            'General',
            null,
            null,
            null,
            null,
            23.5,
            85.3,
            null,
            null
        );

        Test.stopTest();

        System.assertNotEquals(null, visitId);
    }

}