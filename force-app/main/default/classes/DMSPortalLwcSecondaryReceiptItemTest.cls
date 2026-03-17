@isTest
public class DMSPortalLwcSecondaryReceiptItemTest {

    @testSetup
    static void setupTestData() {
        Account customer = new Account(
            Name = 'Test Customer',
            City__c = 'Delhi',
            State__c = 'Delhi',
            District__c = 'New Delhi',
            Primary_Phone_Number__c = '9999999999',
            Aadhaar_No__c = '123412341234',
            Pincode__c = '110001',
            Customer_Type__c = 'Secondary Customer',
            Customer_Status__c = 'Active',
            Email_ID__c = 'test@gmail.com',
            SAP_Customer_Code__c = '19810199'
        );
        insert customer;

        Secondary_Invoice__c invoice = new Secondary_Invoice__c(
            Customer__c = customer.Id,
            Invoice_Date__c = Date.today(),
            Status__c = 'Open'
        );
        insert invoice;

        Secondary_Receipt__c receipt = new Secondary_Receipt__c(
            Customer__c = customer.Id,
            Payment_Date__c = Date.today(),
            Payment_Mode__c = 'Cash',
            Reference_Number__c = 'REF-001',
            Remarks__c = 'Test Receipt',
            Total_Amount__c = 5000
        );
        insert receipt;

        List<Secondary_Receipt_Item__c> items = new List<Secondary_Receipt_Item__c>{
            new Secondary_Receipt_Item__c(
                Secondary_Receipt__c = receipt.Id,
                Secondary_Invoice__c = invoice.Id,
                Amount__c = 3000
            ),
            new Secondary_Receipt_Item__c(
                Secondary_Receipt__c = receipt.Id,
                Secondary_Invoice__c = invoice.Id,
                Amount__c = 2000
            )
        };
        insert items;
    }

    @isTest
    static void testGetSecondaryReceiptItemsByReceiptId() {
        Secondary_Receipt__c receipt = [SELECT Id FROM Secondary_Receipt__c LIMIT 1];

        Test.startTest();
        List<Secondary_Receipt_Item__c> items = DMSPortalLwc.getSecondaryReceiptItemsByReceiptId(receipt.Id);
        Test.stopTest();

        System.assertEquals(2, items.size(), 'Should return 2 receipt items');
        for (Secondary_Receipt_Item__c item : items) {
            System.assertEquals(receipt.Id, item.Secondary_Receipt__c, 'Item should belong to the correct receipt');
            System.assertNotEquals(null, item.Amount__c, 'Amount should not be null');
            System.assertNotEquals(null, item.Secondary_Invoice__c, 'Secondary Invoice should not be null');
            System.assertNotEquals(null, item.Secondary_Invoice__r.Name, 'Secondary Invoice Name should be queried');
        }
    }

    @isTest
    static void testGetSecondaryReceiptItemsByReceiptIdNoItems() {
        Account customer = [SELECT Id FROM Account LIMIT 1];
        Secondary_Invoice__c invoice = [SELECT Id FROM Secondary_Invoice__c LIMIT 1];

        Secondary_Receipt__c emptyReceipt = new Secondary_Receipt__c(
            Customer__c = customer.Id,
            Payment_Date__c = Date.today(),
            Payment_Mode__c = 'Cheque',
            Total_Amount__c = 0
        );
        insert emptyReceipt;

        Test.startTest();
        List<Secondary_Receipt_Item__c> items = DMSPortalLwc.getSecondaryReceiptItemsByReceiptId(emptyReceipt.Id);
        Test.stopTest();

        System.assertEquals(0, items.size(), 'Should return 0 receipt items for a receipt with no items');
    }
}
