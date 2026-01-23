@isTest
public class CustomerReplacementControllerTest {
    
    @isTest
    static void testPrimaryCustomerReplacement() {
        // Create source and target primary customers
     // Create primary customer
        Account primaryAcc = new Account(
            Name = 'Primary Customer',
            Customer_Type__c = 'Primary Customer',
            Approval_Status__c = 'Credit Dept. Approved',
            Payment_Type__c = 'Credit',
            Credit_Limit__c = 10000,
            Customer_Status__c = 'Active',
            SAP_Customer_Code__c ='1211',
            Pincode__c = '123456',
            Primary_Phone_Number__c = '9876543210',
            State__c = 'Karnataka',
            District__c = 'Kolar',
            Is_Transfer_Completed__c = false
        );
        insert primaryAcc;
        
        // Create new primary customer to transfer to
        Account newPrimaryAcc = new Account(
            Name = 'New Primary Customer',
            Customer_Type__c = 'Primary Customer',
            Approval_Status__c = 'Credit Dept. Approved',
            Payment_Type__c = 'Credit',
            Credit_Limit__c = 15000,
            Customer_Status__c = 'Active',
            SAP_Customer_Code__c ='1211211',
            Pincode__c = '123456',
            Primary_Phone_Number__c = '9876543111',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert newPrimaryAcc;
        
        // Create product mapping
        Product_Mapping__c pm = new Product_Mapping__c(
            Customer__c = primaryAcc.Id,
            Payment_Type__c = 'Credit',
            Payment_Term__c = 'Z045',
            Inco_Terms__c = 'FOB'
        );
        insert pm;
        
        // Update to inactive with transfer
        primaryAcc.Customer_Status__c = 'Inactive';
        primaryAcc.Deactivate_Reason2__c = 'Replacement';
        primaryAcc.Transferred_To__c = newPrimaryAcc.Id;
        
        Test.startTest();
        update primaryAcc;

        String result = CustomerReplacementController.customerReplacement(primaryAcc.Id);
        Test.stopTest();
    }


    @isTest
    static void testCustomerNotFound() {
        Test.startTest();
        String result = CustomerReplacementController.customerReplacement(Id.valueOf('001000000000000AAA'));
        Test.stopTest();

        System.assertEquals('Error: CUSTOMER_NOT_FOUND', result);
    }
}