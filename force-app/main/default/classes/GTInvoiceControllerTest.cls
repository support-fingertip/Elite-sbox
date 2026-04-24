@isTest
private class GTInvoiceControllerTest {

    @TestSetup
    static void setupTestData() {
        // Distributor (Store) account in Bihar
        Account distributor = new Account(
            Name = 'Test Distributor GT',
            Customer_Type__c = 'Secondary Customer',
            State__c = 'Bihar',
            District__c = 'Patna',
            Street__c = 'MG Road',
            Building_Name__c = 'Tower A',
            City_Town__c = 'Patna',
            Land_Mark__c = 'Near Mall',
            Door_No__c = '12',
            Pincode__c = '800001',
            GST_Number__c = '10ABCDE1234F1Z5',
            Primary_Phone_Number__c = '9876543210',
            Email_ID__c = 'dist@test.com',
            Account_No__c = '1234567890',
            IFSC_Code__c = 'HDFC0001234',
            Bank_Name__c = 'HDFC',
            Branch_Name__c = 'Patna Main',
            Account_Holder_Name__c = 'Test Distributor GT'
        );
        insert distributor;

        // Dealer (Customer) in same state -> isStateMatching = true
        Account dealerSameState = new Account(
            Name = 'Dealer Same State',
            Customer_Type__c = 'Secondary Customer',
            State__c = 'Bihar',
            District__c = 'Patna',
            Street__c = 'Station Road',
            Building_Name__c = 'Shop 4',
            City_Town__c = 'Patna',
            Land_Mark__c = 'Bus Stand',
            Door_No__c = '44',
            Pincode__c = '800002',
            GST_Number__c = '10ZYXWV9876E1Z5',
            Primary_Phone_Number__c = '9123456780',
            Email_ID__c = 'dealer1@test.com'
        );
        insert dealerSameState;

        // Dealer in a different state -> isStateMatching = false (IGST branch)
        Account dealerOtherState = new Account(
            Name = 'Dealer Other State',
            Customer_Type__c = 'Secondary Customer',
            State__c = 'Karnataka',
            District__c = 'Bengaluru'
        );
        insert dealerOtherState;

        // Minimal dealer account (to cover null-address branches on the dealer side)
        Account dealerMinimal = new Account(
            Name = 'Dealer Minimal',
            Customer_Type__c = 'Secondary Customer',
            State__c = 'Bihar',
            District__c = 'Patna'
        );
        insert dealerMinimal;

        // Product
        Product_Category__c cat = new Product_Category__c(Name = 'GT Category');
        insert cat;

        Product__c prod = new Product__c(
            Name = 'GT Product',
            Is_Active__c = true,
            List_Price__c = 100,
            Tax_Percent__c = 18,
            Product_Category1__c = cat.Id,
            SKU_Code__c = 'GT001'
        );
        insert prod;

        // Order (used by invoice to populate PO / executive / beat fields)
        Order__c ord = new Order__c(
            Account__c = dealerSameState.Id,
            Order_Date__c = Date.today()
        );
        insert ord;

        // Invoice #1 - same-state dealer, with Order (CGST/SGST branch)
        Secondary_Invoice__c invSameState = new Secondary_Invoice__c(
            Store__c = distributor.Id,
            Customer__c = dealerSameState.Id,
            Order__c = ord.Id,
            Invoice_Date__c = Date.today(),
            Status__c = 'Raised',
            Grand_Total__c = 1180,
            Total_Tax__c = 180,
            Total_Quantity__c = 10,
            Remarks__c = 'Pack carefully',
            Delivery_remarks__c = 'Deliver before noon'
        );
        insert invSameState;

        // Invoice #2 - different-state dealer, no Order (IGST + null Order branches)
        Secondary_Invoice__c invOtherState = new Secondary_Invoice__c(
            Store__c = distributor.Id,
            Customer__c = dealerOtherState.Id,
            Invoice_Date__c = Date.today(),
            Status__c = 'Raised',
            Grand_Total__c = 500,
            Total_Tax__c = 90,
            Total_Quantity__c = 5
        );
        insert invOtherState;

        // Invoice #3 - minimal dealer, null Invoice_Date to hit date-null formatting branch
        Secondary_Invoice__c invMinimal = new Secondary_Invoice__c(
            Store__c = distributor.Id,
            Customer__c = dealerMinimal.Id,
            Status__c = 'Raised'
        );
        insert invMinimal;

        // Distributor stock (required by Secondary_Invoice_Item__c in this org's data model)
        Distributor_Stock__c stock = new Distributor_Stock__c(
            Product__c = prod.Id,
            Distributor__c = distributor.Id
        );
        insert stock;

        Order_Item__c ordItem = new Order_Item__c(
            Order__c = ord.Id,
            Product__c = prod.Id,
            Quantity__c = 10,
            Unit_Price__c = 100,
            Tax_Percent__c = 18,
            Tax_Amount__c = 180,
            Total_Amount__c = 1180
        );
        insert ordItem;

        // Items for same-state invoice (MRP__c and Taxable_Amount__c are formula fields - derived)
        insert new Secondary_Invoice_Item__c(
            Secondary_Invoice__c = invSameState.Id,
            Product__c = prod.Id,
            Quantity__c = 10,
            Unit_Price__c = 100,
            Tax_Percent__c = 18,
            Tax_Amount__c = 180,
            Total_Amount__c = 1180,
            Distributor_Stock__c = stock.Id,
            Order_Item__c = ordItem.Id
        );

        // Item for other-state invoice (IGST branch)
        insert new Secondary_Invoice_Item__c(
            Secondary_Invoice__c = invOtherState.Id,
            Product__c = prod.Id,
            Quantity__c = 5,
            Unit_Price__c = 100,
            Tax_Percent__c = 18,
            Tax_Amount__c = 90,
            Total_Amount__c = 590,
            Distributor_Stock__c = stock.Id,
            Order_Item__c = ordItem.Id
        );

        // Item with null optional fields (hits the null-coalescing branches)
        insert new Secondary_Invoice_Item__c(
            Secondary_Invoice__c = invMinimal.Id,
            Product__c = prod.Id,
            Distributor_Stock__c = stock.Id,
            Order_Item__c = ordItem.Id
        );
    }

    static Secondary_Invoice__c getInvoiceWithDealer(String dealerName) {
        return [
            SELECT Id FROM Secondary_Invoice__c
            WHERE Customer__r.Name = :dealerName
            LIMIT 1
        ];
    }

    @isTest
    static void testControllerWithoutId() {
        // No id param -> early return, wrapper initialised
        Test.startTest();
        GTInvoiceController ctrl = new GTInvoiceController(
            new ApexPages.StandardController(new Secondary_Invoice__c())
        );
        Test.stopTest();
        System.assertEquals(null, ctrl.recid);
        System.assertNotEquals(null, ctrl.wrapper);
        System.assertEquals('A4', ctrl.pageSize);
    }

    @isTest
    static void testControllerSameStateCgstSgst() {
        Secondary_Invoice__c inv = getInvoiceWithDealer('Dealer Same State');
        ApexPages.currentPage().getParameters().put('id', inv.Id);

        Test.startTest();
        GTInvoiceController ctrl = new GTInvoiceController(
            new ApexPages.StandardController(inv)
        );
        Test.stopTest();

        System.assertEquals(inv.Id, ctrl.recid);
        System.assertEquals(true, ctrl.isStateMatching);
        System.assertNotEquals(null, ctrl.wrapper);
        System.assertEquals('Test Distributor GT', ctrl.wrapper.distributorName);
        System.assertEquals('Dealer Same State', ctrl.wrapper.dealerName);
        System.assertEquals(1, ctrl.invoiceItemList.size());

        GTInvoiceController.InvoiceItemWapper item = ctrl.invoiceItemList[0];
        System.assertEquals(9, item.cgstPecentage);
        System.assertEquals(9, item.sgstPercenate);
        System.assertEquals(90, item.cgstAmount);
        System.assertEquals(90, item.sgstAmount);
        System.assertEquals(0, item.igstAmount);

        System.assertEquals(10, ctrl.totalQuantity);
        System.assertEquals(90, ctrl.totalCgstAmount);
        System.assertEquals(90, ctrl.totalSgstAmount);
        System.assertEquals(0, ctrl.totalIgstAmount);
        System.assertNotEquals(null, ctrl.finalAmtinWords);
        System.assertEquals('Pack carefully', ctrl.wrapper.packingRemarks);
        System.assertEquals('Deliver before noon', ctrl.wrapper.delivaryRemarks);
    }

    @isTest
    static void testControllerDifferentStateIgst() {
        Secondary_Invoice__c inv = getInvoiceWithDealer('Dealer Other State');
        ApexPages.currentPage().getParameters().put('id', inv.Id);

        Test.startTest();
        GTInvoiceController ctrl = new GTInvoiceController(
            new ApexPages.StandardController(inv)
        );
        Test.stopTest();

        System.assertEquals(false, ctrl.isStateMatching);
        System.assertEquals(1, ctrl.invoiceItemList.size());

        GTInvoiceController.InvoiceItemWapper item = ctrl.invoiceItemList[0];
        System.assertEquals(18, item.igstPercenate);
        System.assertEquals(90, item.igstAmount);
        System.assertEquals(0, item.cgstAmount);
        System.assertEquals(0, item.sgstAmount);

        // No Order on this invoice -> fields should be empty strings
        System.assertEquals('', ctrl.wrapper.dealerExecutiveName);
        System.assertEquals('', ctrl.wrapper.beatName);
        System.assertEquals('', ctrl.wrapper.executiveCode);
        System.assertEquals('', ctrl.wrapper.poNo);
    }

    @isTest
    static void testControllerNullFieldsAndMinimalInvoice() {
        // Invoice with null invoice date and an item with all optional decimals null
        Secondary_Invoice__c inv = getInvoiceWithDealer('Dealer Minimal');
        ApexPages.currentPage().getParameters().put('id', inv.Id);

        Test.startTest();
        GTInvoiceController ctrl = new GTInvoiceController(
            new ApexPages.StandardController(inv)
        );
        Test.stopTest();

        // Null invoice date -> formatted as empty string
        System.assertEquals('', ctrl.wrapper.invoiceDate);
        System.assertEquals(1, ctrl.invoiceItemList.size());

        GTInvoiceController.InvoiceItemWapper item = ctrl.invoiceItemList[0];
        System.assertEquals(0, item.quantity);
        System.assertEquals(0, item.unitPrice);
        System.assertEquals(0, item.mrp);
        System.assertEquals(0, item.totalAmount);
        System.assertEquals('', item.hsnCode);
        System.assertEquals(0, ctrl.totalQuantity);
        System.assertEquals(0, ctrl.totalAmount);
    }

    @isTest
    static void testControllerPageSizeA5() {
        Secondary_Invoice__c inv = getInvoiceWithDealer('Dealer Same State');
        ApexPages.currentPage().getParameters().put('id', inv.Id);
        ApexPages.currentPage().getParameters().put('pageSize', 'A5');

        Test.startTest();
        GTInvoiceController ctrl = new GTInvoiceController(
            new ApexPages.StandardController(inv)
        );
        Test.stopTest();

        System.assertEquals('A5', ctrl.pageSize);
    }

    @isTest
    static void testControllerPageSizeDefaultsToA4() {
        ApexPages.currentPage().getParameters().put('pageSize', 'Letter');

        Test.startTest();
        GTInvoiceController ctrl = new GTInvoiceController(
            new ApexPages.StandardController(new Secondary_Invoice__c())
        );
        Test.stopTest();

        System.assertEquals('A4', ctrl.pageSize);
    }
}
