@isTest
public class ReturnControllerLwcTest {
    @testSetup
    static void setupTestData() {
        // Create Account
        Account acc = new Account(
            Name = 'Test Account',
            Pincode__c = '123456',
            Primary_Phone_Number__c = '9876543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert acc;

        // Create User
        User u = [SELECT Id FROM User WHERE profile.Name ='System Administrator'  LIMIT 1];

        // Create Product
        Product__c product = new Product__c(
            Name = 'Test Product',
            Channel__c = 'Institutional',
            List_Price__c = 200,
            MRP__c = 250,
            SKU_Code__c = '112SSAA',
            Tax_Percent__c = 5,
            UOM__c = 'Unit',
            Is_Active__c = true
        );
        insert product;

        // Create Product Mapping
        Product_Mapping__c pm = new Product_Mapping__c(
            Exectuive__c = u.Id,
            Customer__c = acc.Id,
            Chanel__c = product.Channel__c
        );
        insert pm;

        // Create Price Book Entry
        Price_Book__c pb = new Price_Book__c(
            Product__c = product.Id,
            Unit_Price__c = 180,
            MRP__c = 250,
            UOM__c = 'KGS',
            Customer__c = acc.Id,
            Region__c = acc.Region__c,
            Customer_Type__c = acc.Customer_Type__c,
            Secondary_Customer_Category__c = acc.Secondary_Customer_Category__c
        );
        insert pb;
    }

    @isTest
    static void testGetData() {
        // Get test Account
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        ReturnControllerLwc.getData(acc.Id);
        Test.stopTest();

       
    }

    @isTest
    static void testSaveReturn() {
        // Create Return__c record
        Return__c ret = new Return__c(
           
           
        );

        // Create Return_Item__c list
        List<Return_Item__c> items = new List<Return_Item__c>();
        items.add(new Return_Item__c(
            Quantity__c = 2,
             UOM__c = 'Unit'
           // Reason_For_Return__c = 'Damaged'
        ));

        Test.startTest();
        ReturnControllerLwc.saveReturn(ret, items);
        Test.stopTest();

       
    }
   
}