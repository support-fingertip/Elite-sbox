@isTest
private class GRNPdfControllerTest {

    @testSetup
    static void setupData() {
        Account customer = new Account(
            Name = 'GRN Test Customer',
            Customer_Type__c = 'Primary Customer',
            Pincode__c = '123456',
            Primary_Phone_Number__c = '9876543210',
            State__c = 'Karnataka',
            District__c = 'Kolar',
            SAP_Customer_Code__c = 'CUST-GRN-1',
            GST_Number__c = '29ABCDE1234F1Z5',
            Land_Mark__c = 'Near Park',
            Street__c = '1st Main'
        );
        insert customer;

        Invoice__c inv = new Invoice__c(
            Invoice_No__c = 'INV-GRN-001',
            Store__c = customer.Id,
            Customer_SAP_Code__c = 'CUST-GRN-1',
            Status__c = 'Raised',
            Customer_Name__c = 'GRN Test Customer',
            Delivery_Plant__c = '1480'
        );
        insert inv;

        Product__c prod = new Product__c(
            Name = 'GRN Test Product',
            List_Price__c = 100,
            SKU_Code__c = 'SKU-GRN-1'
        );
        insert prod;

        Goods_Received_Note__c grn = new Goods_Received_Note__c(
            Invoice__c = inv.Id,
            GRN_Date__c = Date.today()
        );
        insert grn;

        Goods_Received_Note_Item__c grnItem = new Goods_Received_Note_Item__c(
            Goods_Received_Note__c = grn.Id,
            Product__c = prod.Id,
            Invoiced_Quantity__c = 10,
            Received_Saleable_Quantity__c = 8,
            Received_Nonsaleable_Quantity__c = 2
        );
        insert grnItem;
    }

    @isTest
    static void testControllerWithValidGrnAndCustomer() {
        Goods_Received_Note__c grn = [SELECT Id FROM Goods_Received_Note__c LIMIT 1];
        Account customer = [SELECT Id FROM Account LIMIT 1];

        PageReference pageRef = Page.GRNPdf;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', grn.Id);
        ApexPages.currentPage().getParameters().put('customerId', customer.Id);

        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(grn);
        GRNPdfController controller = new GRNPdfController(stdController);
        Test.stopTest();

        System.assertNotEquals(null, controller.grn, 'GRN should be populated');
        System.assertEquals(grn.Id, controller.grn.Id, 'GRN Id should match');
        System.assertEquals(1, controller.items.size(), 'Should load 1 GRN item');
        System.assertNotEquals(null, controller.customer, 'Customer should be populated');
        System.assertEquals(customer.Id, controller.customer.Id, 'Customer Id should match');
    }

    @isTest
    static void testControllerWithoutCustomerId() {
        Goods_Received_Note__c grn = [SELECT Id FROM Goods_Received_Note__c LIMIT 1];

        PageReference pageRef = Page.GRNPdf;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', grn.Id);

        Test.startTest();
        GRNPdfController controller = new GRNPdfController(new ApexPages.StandardController(grn));
        Test.stopTest();

        System.assertNotEquals(null, controller.grn, 'GRN should be populated');
        System.assertEquals(1, controller.items.size(), 'Items should be loaded');
        System.assertEquals(null, controller.customer, 'Customer should be null when customerId not provided');
    }

    @isTest
    static void testControllerWithoutIdParameter() {
        PageReference pageRef = Page.GRNPdf;
        Test.setCurrentPage(pageRef);

        Test.startTest();
        GRNPdfController controller = new GRNPdfController(
            new ApexPages.StandardController(new Goods_Received_Note__c())
        );
        Test.stopTest();

        System.assertEquals(null, controller.grn, 'GRN should be null when id is missing');
        System.assertEquals(0, controller.items.size(), 'Items list should be empty');
        System.assertEquals(null, controller.customer, 'Customer should be null');
    }

    @isTest
    static void testControllerWithNonExistentGrn() {
        Goods_Received_Note__c placeholder = new Goods_Received_Note__c(
            GRN_Date__c = Date.today()
        );
        insert placeholder;
        Id tempId = placeholder.Id;
        delete placeholder;

        PageReference pageRef = Page.GRNPdf;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', tempId);

        Test.startTest();
        GRNPdfController controller = new GRNPdfController(
            new ApexPages.StandardController(new Goods_Received_Note__c())
        );
        Test.stopTest();

        System.assertEquals(null, controller.grn, 'GRN should be null when record not found');
        System.assertEquals(0, controller.items.size(), 'Items should be empty when GRN not found');
    }

    @isTest
    static void testControllerWithNonExistentCustomer() {
        Goods_Received_Note__c grn = [SELECT Id FROM Goods_Received_Note__c LIMIT 1];

        Account placeholder = new Account(
            Name = 'Temp',
            Pincode__c = '123456',
            Primary_Phone_Number__c = '9999999999',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert placeholder;
        Id deletedCustomerId = placeholder.Id;
        delete placeholder;

        PageReference pageRef = Page.GRNPdf;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', grn.Id);
        ApexPages.currentPage().getParameters().put('customerId', deletedCustomerId);

        Test.startTest();
        GRNPdfController controller = new GRNPdfController(new ApexPages.StandardController(grn));
        Test.stopTest();

        System.assertNotEquals(null, controller.grn, 'GRN should be populated');
        System.assertEquals(null, controller.customer, 'Customer should be null when account not found');
    }
}
