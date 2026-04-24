@isTest
private class GTInvoiceControllerTest {

    @TestSetup
    static void setupTestData() {
        Account distributor = new Account(
            Name = 'Test Distributor',
            Customer_Type__c = 'Secondary Customer',
            State__c = 'Bihar',
            District__c = 'Patna'
        );
        insert distributor;

        Account sameStateCustomer = new Account(
            Name = 'Test Same State Customer',
            Customer_Type__c = 'Secondary Customer',
            State__c = 'Bihar',
            District__c = 'Patna'
        );
        insert sameStateCustomer;

        Account differentStateCustomer = new Account(
            Name = 'Test Different State Customer',
            Customer_Type__c = 'Secondary Customer',
            State__c = 'Kerala',
            District__c = 'Ernakulam'
        );
        insert differentStateCustomer;

        Order__c ord = new Order__c(
            Account__c = distributor.Id,
            Order_Date__c = Date.today(),
            Beat_Name__c = 'Test Beat',
            Executive_Employee_Code__c = 'EMP001'
        );
        insert ord;

        Secondary_Invoice__c sameStateInv = new Secondary_Invoice__c(
            Store__c = distributor.Id,
            Customer__c = sameStateCustomer.Id,
            Order__c = ord.Id,
            Invoice_Date__c = Date.today(),
            Status__c = 'Raised',
            Grand_Total__c = 1000,
            Remarks__c = 'Pack carefully',
            Delivery_remarks__c = 'Deliver by evening'
        );
        insert sameStateInv;

        Secondary_Invoice__c diffStateInv = new Secondary_Invoice__c(
            Store__c = distributor.Id,
            Customer__c = differentStateCustomer.Id,
            Order__c = ord.Id,
            Invoice_Date__c = Date.today(),
            Status__c = 'Raised',
            Grand_Total__c = 1000
        );
        insert diffStateInv;

        Secondary_Invoice__c nullFieldsInv = new Secondary_Invoice__c(
            Store__c = distributor.Id,
            Customer__c = sameStateCustomer.Id,
            Status__c = 'Raised',
            Grand_Total__c = 0
        );
        insert nullFieldsInv;

        List<Secondary_Invoice_Item__c> items = new List<Secondary_Invoice_Item__c>();
        items.add(new Secondary_Invoice_Item__c(
            Secondary_Invoice__c = sameStateInv.Id,
            Product_Name__c = 'Test Product',
            SKU_Code__c = 'SKU001',
            HSN_Code__c = '1001',
            Quantity__c = 10,
            Unit_Price__c = 100,
            MRP__c = 120,
            Qty_in_Cases__c = 1,
            Quantity_in_Kgs__c = 5,
            Taxable_Amount__c = 1000,
            Tax_Percent__c = 18,
            Tax_Amount__c = 180,
            Total_Amount__c = 1180.75
        ));
        items.add(new Secondary_Invoice_Item__c(
            Secondary_Invoice__c = diffStateInv.Id,
            Product_Name__c = 'Test Product 2',
            SKU_Code__c = 'SKU002',
            HSN_Code__c = '1002',
            Quantity__c = 5,
            Unit_Price__c = 200,
            MRP__c = 250,
            Qty_in_Cases__c = 1,
            Quantity_in_Kgs__c = 3,
            Taxable_Amount__c = 1000,
            Tax_Percent__c = 18,
            Tax_Amount__c = 180,
            Total_Amount__c = 1180.25
        ));
        items.add(new Secondary_Invoice_Item__c(
            Secondary_Invoice__c = nullFieldsInv.Id,
            Product_Name__c = 'Test Product 3',
            SKU_Code__c = 'SKU003'
        ));
        insert items;
    }

    static Secondary_Invoice__c getSameStateInvoice() {
        return [SELECT Id FROM Secondary_Invoice__c WHERE Customer__r.Name = 'Test Same State Customer' AND Order__c != null LIMIT 1];
    }

    static Secondary_Invoice__c getDiffStateInvoice() {
        return [SELECT Id FROM Secondary_Invoice__c WHERE Customer__r.Name = 'Test Different State Customer' LIMIT 1];
    }

    static Secondary_Invoice__c getNullFieldsInvoice() {
        return [SELECT Id FROM Secondary_Invoice__c WHERE Order__c = null LIMIT 1];
    }

    @isTest
    static void testControllerSameStateCustomer() {
        Secondary_Invoice__c inv = getSameStateInvoice();
        PageReference pageRef = Page.GTInvoice;
        pageRef.getParameters().put('id', inv.Id);
        Test.setCurrentPage(pageRef);

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(inv);
        GTInvoiceController ctrl = new GTInvoiceController(sc);
        Test.stopTest();

        System.assertEquals(true, ctrl.isStateMatching);
        System.assertNotEquals(null, ctrl.wrapper);
        System.assertEquals('A4', ctrl.pageSize);
        System.assert(ctrl.totalCgstAmount > 0);
        System.assert(ctrl.totalSgstAmount > 0);
        System.assertEquals(0, ctrl.totalIgstAmount);
    }

    @isTest
    static void testControllerDifferentStateCustomer() {
        Secondary_Invoice__c inv = getDiffStateInvoice();
        PageReference pageRef = Page.GTInvoice;
        pageRef.getParameters().put('id', inv.Id);
        Test.setCurrentPage(pageRef);

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(inv);
        GTInvoiceController ctrl = new GTInvoiceController(sc);
        Test.stopTest();

        System.assertEquals(false, ctrl.isStateMatching);
        System.assert(ctrl.totalIgstAmount > 0);
        System.assertEquals(0, ctrl.totalCgstAmount);
        System.assertEquals(0, ctrl.totalSgstAmount);
    }

    @isTest
    static void testControllerNullFieldsAndNoOrder() {
        Secondary_Invoice__c inv = getNullFieldsInvoice();
        PageReference pageRef = Page.GTInvoice;
        pageRef.getParameters().put('id', inv.Id);
        Test.setCurrentPage(pageRef);

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(inv);
        GTInvoiceController ctrl = new GTInvoiceController(sc);
        Test.stopTest();

        System.assertEquals('', ctrl.wrapper.beatName);
        System.assertEquals('', ctrl.wrapper.executiveCode);
        System.assertEquals('', ctrl.wrapper.poNo);
        System.assertEquals('', ctrl.wrapper.poDate);
    }

    @isTest
    static void testControllerPageSizeA5() {
        Secondary_Invoice__c inv = getSameStateInvoice();
        PageReference pageRef = Page.GTInvoice;
        pageRef.getParameters().put('id', inv.Id);
        pageRef.getParameters().put('pageSize', 'A5');
        Test.setCurrentPage(pageRef);

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(inv);
        GTInvoiceController ctrl = new GTInvoiceController(sc);
        Test.stopTest();

        System.assertEquals('A5', ctrl.pageSize);
    }

    @isTest
    static void testControllerPageSizeDefault() {
        Secondary_Invoice__c inv = getSameStateInvoice();
        PageReference pageRef = Page.GTInvoice;
        pageRef.getParameters().put('id', inv.Id);
        pageRef.getParameters().put('pageSize', 'A3');
        Test.setCurrentPage(pageRef);

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(inv);
        GTInvoiceController ctrl = new GTInvoiceController(sc);
        Test.stopTest();

        System.assertEquals('A4', ctrl.pageSize);
    }

    @isTest
    static void testControllerWithoutId() {
        PageReference pageRef = Page.GTInvoice;
        Test.setCurrentPage(pageRef);

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(new Secondary_Invoice__c());
        GTInvoiceController ctrl = new GTInvoiceController(sc);
        Test.stopTest();

        System.assertEquals(null, ctrl.recid);
        System.assertNotEquals(null, ctrl.wrapper);
    }
}
