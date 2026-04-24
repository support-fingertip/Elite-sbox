@isTest
private class GTInvoiceControllerTest {

    @TestSetup
    static void setupTestData() {
        Account distributor = new Account(
            Name = 'Test Distributor',
            Customer_Type__c = 'Secondary Customer',
            State__c = 'Bihar',
            District__c = 'Patna',
            Street__c = '1st Cross',
            Building_Name__c = 'Building A',
            City_Town__c = 'Patna',
            Land_Mark__c = 'Near Park',
            Door_No__c = '12',
            Pincode__c = '800001',
            GST_Number__c = '10AAAAA0000A1Z5',
            Primary_Phone_Number__c = '9999999999',
            Email_ID__c = 'distributor@test.com',
            Account_No__c = '1234567890',
            IFSC_Code__c = 'ABCD0123456',
            Bank_Name__c = 'Test Bank',
            Branch_Name__c = 'Main Branch',
            Account_Holder_Name__c = 'Test Distributor Holder'
        );
        insert distributor;

        Account sameStateCustomer = new Account(
            Name = 'Test Same State Customer',
            Customer_Type__c = 'Secondary Customer',
            State__c = 'Bihar',
            District__c = 'Patna',
            Street__c = '2nd Cross',
            City_Town__c = 'Patna',
            Door_No__c = '34',
            Pincode__c = '800002',
            GST_Number__c = '10BBBBB0000B1Z5',
            Primary_Phone_Number__c = '8888888888',
            Email_ID__c = 'samestate@test.com'
        );
        insert sameStateCustomer;

        Account differentStateCustomer = new Account(
            Name = 'Test Different State Customer',
            Customer_Type__c = 'Secondary Customer',
            State__c = 'Kerala',
            District__c = 'Ernakulam',
            City_Town__c = 'Kochi',
            Pincode__c = '682001',
            GST_Number__c = '32CCCCC0000C1Z5'
        );
        insert differentStateCustomer;

        Product__c product = new Product__c(
            Name = 'Test Product',
            SKU_Code__c = 'SKU001',
            HSN_Code__c = '1001',
            MRP__c = 120,
            Uom_Conversion__c = 10,
            Net_Weight__c = 0.5
        );
        insert product;

        Order__c ord = new Order__c(
            Account__c = distributor.Id,
            Order_Date__c = Date.today()
        );
        insert ord;

        Order_Item__c ordItem = new Order_Item__c(
            Order__c = ord.Id,
            Product__c = product.Id,
            Quantity__c = 10,
            Unit_Price__c = 100,
            Tax_Percent__c = 18,
            Tax_Amount__c = 180,
            Total_Amount__c = 1180
        );
        insert ordItem;

        Distributor_Stock__c stock = new Distributor_Stock__c(
            Product__c = product.Id,
            Distributor__c = distributor.Id
        );
        insert stock;

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
            Product__c = product.Id,
            Product_Name__c = 'Test Product',
            Quantity__c = 10,
            Unit_Price__c = 100,
            Tax_Percent__c = 18,
            Tax_Amount__c = 180,
            Total_Amount__c = 1180.75,
            Distributor_Stock__c = stock.Id,
            Order_Item__c = ordItem.Id
        ));
        items.add(new Secondary_Invoice_Item__c(
            Secondary_Invoice__c = diffStateInv.Id,
            Product__c = product.Id,
            Product_Name__c = 'Test Product 2',
            Quantity__c = 5,
            Unit_Price__c = 200,
            Tax_Percent__c = 18,
            Tax_Amount__c = 180,
            Total_Amount__c = 1180.25,
            Distributor_Stock__c = stock.Id,
            Order_Item__c = ordItem.Id
        ));
        items.add(new Secondary_Invoice_Item__c(
            Secondary_Invoice__c = nullFieldsInv.Id,
            Product__c = product.Id,
            Product_Name__c = 'Test Product 3',
            Distributor_Stock__c = stock.Id,
            Order_Item__c = ordItem.Id
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
        System.assertEquals('Test Distributor Holder', ctrl.bankBeneficiaryName);
        System.assertEquals('1234567890', ctrl.accountNo);
        System.assertEquals('Pack carefully', ctrl.wrapper.packingRemarks);
        System.assertEquals('Deliver by evening', ctrl.wrapper.delivaryRemarks);
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
        System.assertEquals('', ctrl.wrapper.invoiceDate);
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

    @isTest
    static void testWrapperClasses() {
        Test.startTest();
        GTInvoiceController.DistributorWrapper dw = new GTInvoiceController.DistributorWrapper();
        dw.distributorName = 'D';
        dw.distributorAddress = 'Addr';
        dw.distributorPhone = '1';
        dw.distributorEmail = 'd@test.com';
        dw.distributoGst = 'GST';
        dw.invoiceNo = 'INV';
        dw.invoiceDate = '01/01/2026';
        dw.poDate = '01/01/2026';
        dw.poNo = 'PO';
        dw.dealerName = 'DL';
        dw.dealerAddress = 'DLAddr';
        dw.dealerPhone = '2';
        dw.dealerGst = 'DLGST';
        dw.dealerExecutiveName = 'Exec';
        dw.executiveCode = 'EC';
        dw.beatName = 'BN';
        dw.packingRemarks = 'PR';
        dw.delivaryRemarks = 'DR';

        GTInvoiceController.InvoiceItemWapper iw = new GTInvoiceController.InvoiceItemWapper();
        iw.index = 1;
        iw.skuName = 'SKU';
        iw.skuCode = 'C';
        iw.hsnCode = 'H';
        iw.mrp = 1;
        iw.qtyinCases = 1;
        iw.qtyinKg = 1;
        iw.taxableAmount = 1;
        iw.quantity = 1;
        iw.unitPrice = 1;
        iw.taxpercent = 1;
        iw.taxAmount = 1;
        iw.totalAmount = 1;
        iw.cgstPecentage = 1;
        iw.sgstPercenate = 1;
        iw.igstPercenate = 1;
        iw.cgstAmount = 1;
        iw.sgstAmount = 1;
        iw.igstAmount = 1;
        Test.stopTest();

        System.assertEquals('D', dw.distributorName);
        System.assertEquals(1, iw.index);
    }
}
