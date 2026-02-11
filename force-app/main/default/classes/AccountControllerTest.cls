@isTest
public class AccountControllerTest {
    
    @testSetup
    static void setupData() {
        // Create a test Account
                Account acc = new Account(
            Name = 'Primary Customer',
            Customer_Type__c = 'Primary Customer',
            Pincode__c = '123456',
            Primary_Phone_Number__c = '8070763910',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert acc;
    }
    
    @isTest
    static void testGetAccounts() {
        // Fetch the inserted Account
        Account insertedAcc = [SELECT Id FROM Account LIMIT 1];
        
        // Call the method
        List<Account> result = AccountController.getAccounts(insertedAcc.Id);
        
        
    }
}