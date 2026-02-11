@isTest
public class CustomDuplicationServiceTest {

    @isTest
    static void testDuplicationCheck_NoDuplicateFound() {
        // Create a unique account
        Account acc = new Account(
            Name = 'Unique Account',
            Primary_Phone_Number__c = '9999911111',
            Customer_Type__c = 'Retail',
             Pincode__c = '123456',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert acc;

        // Create test input data with different phone number
        Account testAcc = new Account(
            Primary_Phone_Number__c = '8888822222',
            Customer_Type__c = 'Retail',
             Pincode__c = '123456',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );

        Test.startTest();
        CustomDuplicationService.DataBox result = CustomDuplicationService.dupicationCheck(testAcc);
        Test.stopTest();

        System.assertEquals(false, result.duplicateFound, 'Expected no duplicate to be found');
        System.assertEquals('', result.accountName, 'Expected account name to be blank');
    }

    @isTest
    static void testDuplicationCheck_DuplicateFound() {
        // Create an account that will act as the duplicate
        Account acc = new Account(
            Name = 'Duplicate Account',
            Primary_Phone_Number__c = '7777733333',
            Customer_Type__c = 'Retail',
             Pincode__c = '123456',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert acc;

        // Create test input with same phone number and customer type
        Account testAcc = new Account(
            Primary_Phone_Number__c = '7777733333',
            Customer_Type__c = 'Retail',
             Pincode__c = '123456',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );

        Test.startTest();
        CustomDuplicationService.DataBox result = CustomDuplicationService.dupicationCheck(testAcc);
        Test.stopTest();

    }
}