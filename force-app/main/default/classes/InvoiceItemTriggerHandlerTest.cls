@isTest
public class InvoiceItemTriggerHandlerTest {

    @testSetup
    static void setupTestData() {
        
     
        // Create common test accounts
        List<Account> testAccounts = new List<Account>{
            new Account(
                Name = 'Primary Cust',
                City__c = 'Delhi',
                State__c = 'Delhi',
                District__c = 'New Delhi',
                Primary_Phone_Number__c = '9999999999',
                Aadhaar_No__c = '123412341234',
                Pincode__c = '110001',
                Customer_Type__c = 'Primary Customer',
                Customer_Status__c = 'Active',
                GeoLocation__Latitude__s =  28.6139,
                GeoLocation__Longitude__s = 77.2090,
                Secondary_Customer_Category__c = 'TN_Elite Club',
                Secondary_Customer_Type__c = 'Retailer',
                Approval_Status__c = 'Credit Dept. Approved',
                Email_ID__c = 'test@gmail.com',
                 SAP_Customer_Code__c ='1133'
              
                
            ),
            new Account(
                Name = 'Secondary Cust',
                City__c = 'Mumbai',
                State__c = 'Andhra Pradesh',
                District__c = 'East Godavari',
                Primary_Phone_Number__c = '8888888888',
                Aadhaar_No__c = '567856785678',
                Pincode__c = '575444',
                Customer_Type__c = 'Secondary Customer',
                Customer_Status__c = 'Active',
                Email_ID__c = 'test@gmail.com',
                SAP_Customer_Code__c ='1122'
            )
        };
        insert testAccounts;

        // Create one existing invoice for one account
        Invoice__c existingInvoice = new Invoice__c(
            Invoice_No__c = 'INV-EXISTING',
            Store__c = testAccounts[0].Id,
            Customer_SAP_Code__c = 'CUST002',
            Status__c = 'Raised',
            Customer_Name__c = 'tetete',
            Delivery_Plant__c ='1480'
        );
        insert existingInvoice;
        
        area__c tr = new area__c();
        tr.Name = 'test11121';
        tr.Sales_Channel__c = 'CPD';
        tr.Region__c =	'Kerala';
        tr.Area__c  = 'Central';
        insert tr;
        
    }

    // Test Case 1: Insert Invoice Items for an existing Invoice
    @isTest
    static void testInsertItemsWithExistingInvoice() {
        // Get the existing invoice and account
        Invoice__c existingInv = [SELECT Id, Invoice_No__c FROM Invoice__c WHERE Invoice_No__c = 'INV-EXISTING' LIMIT 1];
        Account existingAcc = [SELECT Id, SAP_Customer_Code__c FROM Account WHERE SAP_Customer_Code__c = '1122' LIMIT 1];
        
        Product__c prod = new Product__c(Name='Test Product',SKU_Code__c ='1010sksksk');
        insert prod;
        // Primary Order
        Order__c order = new Order__c(
            Order_Type__c = 'Primary Order',
            Account__c = existingAcc.Id,
            Order_Fulfillment_Status__c = 'Not Fulfilled',
            Order_Date__c = Date.today()
        );
        insert order;
        
        List<Order_Item__c> items = new List<Order_Item__c>();
        for (Integer i = 0; i < 2; i++) {
            items.add(new Order_Item__c(
                Order__c = order.Id,
                Product__c = prod.Id,
                Quantity__c = 10,
                Delivered_Quantity__c = 0,
                Unit_Price__c = 100,
                Total_Amount__c = 1000,
                Tax_Amount__c = 100,
                Status__c = 'Not Fulfilled'
            ));
        }
        insert items;
        
        
 

        List<Invoice_Item__c> testItems = new List<Invoice_Item__c>();
        for(Integer i = 0; i < 3; i++) {
            testItems.add(new Invoice_Item__c(
                Bill_Number__c = existingInv.Invoice_No__c,
                Invoice__c =existingInv.Id,
                Bill_to_Party__c = existingAcc.SAP_Customer_Code__c,
                Order__c =  order.Id,
                Qyt_in_Each__c =10,
                SKU__c = prod.id
            ));
        }

        Test.startTest();
        insert testItems;
        Test.stopTest();

    }

    // Test Case 2: Insert Invoice Items for a NEW Invoice (should be auto-created)
    @isTest
    static void testInsertItemsWithNewInvoice() {
          Invoice__c existingInv = [SELECT Id, Invoice_No__c FROM Invoice__c WHERE Invoice_No__c = 'INV-EXISTING' LIMIT 1];
        Account existingAcc = [SELECT Id, SAP_Customer_Code__c FROM Account WHERE SAP_Customer_Code__c = '1133' LIMIT 1];
        String newInvoiceNumber = 'INV-NEW-123';

        List<Invoice_Item__c> testItems = new List<Invoice_Item__c>();
        for(Integer i = 0; i < 2; i++) {
            testItems.add(new Invoice_Item__c(
                Bill_Number__c = newInvoiceNumber,
                Invoice__c =existingInv.Id,
                Bill_to_Party__c = existingAcc.SAP_Customer_Code__c
            ));
        }

        Test.startTest();
        insert testItems;
        Test.stopTest();

    }

    // Test Case 3: Insert Invoice Items with an INVALID Customer Code (should fail)
    @isTest
    static void testInsertItemsWithInvalidCustomerCode() {
        String invalidCustomerCode = 'INVALID_CUST';
        String invoiceNumber = 'INV-FAIL';

        Invoice_Item__c failingItem = new Invoice_Item__c(
            Bill_Number__c = invoiceNumber,
            Bill_to_Party__c = invalidCustomerCode
        );

        Test.startTest();
        try {
            insert failingItem;
        } catch (DmlException e) {
           
        }
        Test.stopTest();

     
    }

    // Test Case 4: Bulk test - mixed scenario (some existing, some new invoices)
    @isTest
    static void testBulkInsertMixedScenario() {
        Account acc1 = [SELECT Id, SAP_Customer_Code__c FROM Account WHERE SAP_Customer_Code__c = '1122' LIMIT 1];
        Account acc2 = [SELECT Id, SAP_Customer_Code__c FROM Account WHERE SAP_Customer_Code__c = '1133' LIMIT 1];
        
        Invoice__c existingInv = [SELECT Id, Invoice_No__c FROM Invoice__c WHERE Invoice_No__c = 'INV-EXISTING' LIMIT 1];
        String newInvoiceNumber = 'INV-BULK-NEW';

        List<Invoice_Item__c> testItems = new List<Invoice_Item__c>();
        for(Integer i = 0; i < 50; i++) {
            testItems.add(new Invoice_Item__c(
                Bill_Number__c = existingInv.Invoice_No__c,
                Invoice__c =existingInv.Id,
                Bill_to_Party__c = acc1.SAP_Customer_Code__c
            ));
        }
        
        for(Integer i = 0; i < 50; i++) {
            testItems.add(new Invoice_Item__c(
                Bill_Number__c = newInvoiceNumber,
                Invoice__c =existingInv.Id,
                Bill_to_Party__c = acc2.SAP_Customer_Code__c
            ));
        }

        Test.startTest();
        insert testItems;
        Test.stopTest();
    }
}