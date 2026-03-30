@isTest
private class DMSPortalLwcTest {

    @TestSetup
    static void setupTestData() {
        // Create Account
        Account acc = new Account(Name = 'Test Distributor', Customer_Type__c = 'Secondary Customer', 	State__c = 'Bihar' , District__c='	Patna');
        insert acc;

        Account secAcc = new Account(Name = 'Test Secondary Customer', Customer_Type__c = 'Secondary Customer', State__c = 'Bihar' , District__c='Patna');
        insert secAcc;

        // Create Contact
        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = acc.Id);
        insert con;

        // Create Product Category
        Product_Category__c prodCat = new Product_Category__c(Name = 'Test Category');
        insert prodCat;

        // Create Product
        Product__c prod = new Product__c(
            Name = 'Test Product',
            Is_Active__c = true,
            List_Price__c = 100,
            Tax_Percent__c = 18,
            Product_Category1__c = prodCat.Id,
            SKU_Code__c = '11324'
        );
        insert prod;

        // Create Invoice
        Invoice__c inv = new Invoice__c(
            Store__c = acc.Id,
            Invoice_Date__c = Date.today(),
            Status__c = 'Raised',
            Invoice_No__c = '22211',
            GRN_Status__c = 'GRN Pending'
        );
        insert inv;

        // Create Invoice Item
        Invoice_Item__c invItem = new Invoice_Item__c(
            Invoice__c = inv.Id,
            Product__c = prod.Id,
            SKU__c = prod.Id,
            Qyt__c = 10,
            Price_per_unit__c = 100,
            GST_Amount__c = 18,
            Bill_Amount__c = 1180
        );
        insert invItem;

        // Create Order
        Order__c ord = new Order__c(
            Account__c = acc.Id,
            Order_Date__c = Date.today(),
            Order_Status__c = 'Push to Logistics'
        );
        insert ord;

        // Create Order Item
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

        // Create Claim
        Claim__c claim = new Claim__c(
            Customer__c = acc.Id,
            Claim_Date__c = Date.today(),
            Claim_Amount__c = 500,
            Description__c = 'Test Claim',
            Status__c = 'New'
        );
        insert claim;

        // Create Secondary Credit Note
        Secondary_Credit_Note__c creditNote = new Secondary_Credit_Note__c(
            Customer__c = acc.Id,
            Credit_Date__c = Date.today(),
            Amount__c = 200,
            Reason__c = 'Test Reason',
            Status__c = 'New'
        );
        insert creditNote;

        // Create Secondary Debit Note
        Secondary_Debit_Note__c debitNote = new Secondary_Debit_Note__c(
            Customer__c = acc.Id,
            Note_Date__c = Date.today(),
            Amount__c = 150,
            Reason__c = 'Test Reason',
            Status__c = 'New'
        );
        insert debitNote;

        // Create Secondary Invoice
        Secondary_Invoice__c secInv = new Secondary_Invoice__c(
            Store__c = acc.Id,
            Customer__c = secAcc.Id,
            Invoice_Date__c = Date.today(),
            Status__c = 'Open',
            Grand_Total__c = 500,
            Total_Tax__c = 50,
            Total_Quantity__c = 5
        );
        insert secInv;

        // Create Secondary Invoice Item
        Secondary_Invoice_Item__c secInvItem = new Secondary_Invoice_Item__c(
            Secondary_Invoice__c = secInv.Id,
            Product__c = prod.Id,
            Quantity__c = 5,
            Unit_Price__c = 100,
            Tax_Amount__c = 50,
            Total_Amount__c = 550
        );
        insert secInvItem;

        // Create Return (Secondary)
        Return__c secReturn = new Return__c(
            Customer__c = secAcc.Id,
            Distributor__c = acc.Id,
            Return_Date__c = Date.today(),
            Total_Amount__c = 300,
            Total_Quantity__c = 3
        );
        insert secReturn;

        // Create Return Item
        Return_Item__c retItem = new Return_Item__c(
            Return__c = secReturn.Id,
            SKU__c = prod.Id,
            Quantity__c = 3,
            Unit_Price__c = 100,
            Total_Amount__c = 300
        );
        insert retItem;

        // Create Distributor Stock
        Distributor_Stock__c stock = new Distributor_Stock__c(
            Product__c = prod.Id,
            Distributor__c = acc.Id
        );
        insert stock;

        // Create GRN
        Goods_Received_Note__c grn = new Goods_Received_Note__c(
            Invoice__c = inv.Id,
            GRN_Date__c = Date.today()
        );
        insert grn;

        // Create GRN Item
        Goods_Received_Note_Item__c grnItem = new Goods_Received_Note_Item__c(
            Goods_Received_Note__c = grn.Id,
            Product__c = prod.Id,
            Invoice_Item__c = invItem.Id,
            Invoiced_Quantity__c = 10,
            Received_Quantity__c = 10,
            Distributor_Stock__c = stock.Id
        );
        insert grnItem;

        // Create Collection (Payment Receipt)
        Collection__c collection = new Collection__c(
            Customer__c = acc.Id
        );
        insert collection;

        // Create Collection Item
        Collection_Item__c colItem = new Collection_Item__c(
            Collection__c = collection.Id,
            Amount_Received__c = 500,
            Invoice_Number__c = 'INV-001'
        );
        insert colItem;

        // Create Secondary Receipt
        Secondary_Receipt__c secReceipt = new Secondary_Receipt__c(
            Customer__c = secAcc.Id,
            Payment_Date__c = Date.today(),
            Total_Amount__c = 200,
            Payment_Mode__c = 'Cash'
        );
        insert secReceipt;

        // Create Secondary Receipt Item
        Secondary_Receipt_Item__c secRecItem = new Secondary_Receipt_Item__c(
            Secondary_Receipt__c = secReceipt.Id,
            Secondary_Invoice__c = secInv.Id,
            Amount__c = 200
        );
        insert secRecItem;

        // Create Secondary Receipt Debit Item
        Secondary_Receipt_Debit_Item__c secRecDebitItem = new Secondary_Receipt_Debit_Item__c(
            Secondary_Receipt__c = secReceipt.Id,
            Secondary_Debit_Note__c = debitNote.Id,
            Amount__c = 100
        );
        insert secRecDebitItem;

        // Create Stock Adjustment
        Stock_Adjustment__c stockAdj = new Stock_Adjustment__c(
            Distributor__c = acc.Id,
            Product__c = prod.Id,
            Quantity__c = 5,
            Reason__c = 'Test',
            Distributor_Stock__c = stock.Id
        );
        insert stockAdj;
    }

    // Helper to get test data
    static Account getDistributor() {
        return [SELECT Id FROM Account WHERE Name = 'Test Distributor' LIMIT 1];
    }
    static Account getSecondaryCustomer() {
        return [SELECT Id FROM Account WHERE Name = 'Test Secondary Customer' LIMIT 1];
    }
    static Product__c getProduct() {
        return [SELECT Id FROM Product__c WHERE Name = 'Test Product' LIMIT 1];
    }
    static Invoice__c getInvoice() {
        return [SELECT Id FROM Invoice__c LIMIT 1];
    }
    static Order__c getOrder() {
        return [SELECT Id FROM Order__c LIMIT 1];
    }
    static Goods_Received_Note__c getGRN() {
        return [SELECT Id FROM Goods_Received_Note__c LIMIT 1];
    }
    static Collection__c getCollection() {
        return [SELECT Id FROM Collection__c LIMIT 1];
    }
    static Secondary_Receipt__c getSecondaryReceipt() {
        return [SELECT Id FROM Secondary_Receipt__c LIMIT 1];
    }
    static Return__c getReturn() {
        return [SELECT Id FROM Return__c LIMIT 1];
    }
    static Secondary_Invoice__c getSecondaryInvoice() {
        return [SELECT Id FROM Secondary_Invoice__c LIMIT 1];
    }

    @isTest
    static void testGetSecondaryReceiptItemsByReceiptId() {
        Secondary_Receipt__c receipt = getSecondaryReceipt();
        Test.startTest();
        List<DMSPortalLwc.SecondaryReceiptItemWrapper> result = DMSPortalLwc.getSecondaryReceiptItemsByReceiptId(receipt.Id);
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetPendingSecondaryInvoicesByCustomer() {
        Account secAcc = getSecondaryCustomer();
        Test.startTest();
        List<DMSPortalLwc.SecInvData> result = DMSPortalLwc.getPendingSecondaryInvoicesByCustomer(secAcc.Id);
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetPendingSecondaryInvoicesByCustomerNull() {
        Test.startTest();
        List<DMSPortalLwc.SecInvData> result = DMSPortalLwc.getPendingSecondaryInvoicesByCustomer(null);
        Test.stopTest();
        System.assertEquals(0, result.size());
    }

    @isTest
    static void testGetGraphData() {
        Test.startTest();
        DMSPortalLwc.GraphData result = DMSPortalLwc.getGraphData();
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testSalesData() {
        Test.startTest();
        List<Map<String, String>> result = DMSPortalLwc.salesData();
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testOrderData() {
        Test.startTest();
        List<Map<String, String>> result = DMSPortalLwc.orderData();
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testTargetData() {
        Test.startTest();
        List<DMSPortalLwc.kpi_graph_target> result = DMSPortalLwc.targetData();
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testAllOrderData() {
        Test.startTest();
        DMSPortalLwc.DmsData result = DMSPortalLwc.allOrderData('All', Date.today().addDays(-30), Date.today(), 'Primary');
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testAllOrderDataWithStatus() {
        Test.startTest();
        DMSPortalLwc.DmsData result = DMSPortalLwc.allOrderData('Open', Date.today().addDays(-30), Date.today(), 'Primary');
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testAllInvoiceDataAll() {
        Test.startTest();
        DMSPortalLwc.DmsData result = DMSPortalLwc.allInvoiceData('All', Date.today().addDays(-30), Date.today());
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testAllInvoiceDataGRNPending() {
        Test.startTest();
        DMSPortalLwc.DmsData result = DMSPortalLwc.allInvoiceData('GRN Pending', Date.today().addDays(-30), Date.today());
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testAllInvoiceDataGRNCompleted() {
        Test.startTest();
        DMSPortalLwc.DmsData result = DMSPortalLwc.allInvoiceData('GRN Completed', Date.today().addDays(-30), Date.today());
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetInvoiceItems() {
        Invoice__c inv = getInvoice();
        Test.startTest();
        List<DMSPortalLwc.Invoice_Item_Data> result = DMSPortalLwc.getInvoiceItems(inv.Id);
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetInvoiceItemsBlank() {
        Test.startTest();
        List<DMSPortalLwc.Invoice_Item_Data> result = DMSPortalLwc.getInvoiceItems('');
        Test.stopTest();
        System.assertEquals(0, result.size());
    }

    @isTest
    static void testAllPrimaryReturnsData() {
        Test.startTest();
        DMSPortalLwc.DmsData result = DMSPortalLwc.allPrimaryReturnsData(Date.today().addDays(-30), Date.today());
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetPrimaryReturns() {
        Test.startTest();
        List<DMSPortalLwc.PrimaryReturnWrapper> result = DMSPortalLwc.getPrimaryReturns(Date.today().addDays(-30), Date.today());
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetPrimaryReturnItems() {
        Return__c ret = getReturn();
        Test.startTest();
        List<Return_Item__c> result = DMSPortalLwc.getPrimaryReturnItems(ret.Id);
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testAllPaymentReceiptData() {
        Test.startTest();
        DMSPortalLwc.DmsData result = DMSPortalLwc.allPaymentReceiptData(Date.today().addDays(-30), Date.today());
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetPaymentReceiptDetails() {
        Collection__c col = getCollection();
        Test.startTest();
        Collection_Item__c result = DMSPortalLwc.getPaymentReceiptDetails(col.Id);
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetReceiptItems() {
        Collection__c col = getCollection();
        Test.startTest();
        List<Collection_Item__c> result = DMSPortalLwc.getReceiptItems(col.Id);
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testAllGRNData() {
        Test.startTest();
        DMSPortalLwc.DmsData result = DMSPortalLwc.allGRNData(Date.today().addDays(-30), Date.today());
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetGRNItems() {
        Goods_Received_Note__c grn = getGRN();
        Test.startTest();
        List<Goods_Received_Note_Item__c> result = DMSPortalLwc.getGRNItems(grn.Id);
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetGRNImages() {
        Goods_Received_Note__c grn = getGRN();
        Test.startTest();
        List<ContentDistribution> result = DMSPortalLwc.getGRNImages(grn.Id);
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetGRNList() {
        Test.startTest();
        List<Goods_Received_Note__c> result = DMSPortalLwc.getGRNList(Date.today().addDays(-30), Date.today());
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testAllClaimDataAll() {
        Test.startTest();
        DMSPortalLwc.DmsData result = DMSPortalLwc.allClaimData(Date.today().addDays(-30), Date.today(), 'All');
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testAllClaimDataWithStatus() {
        Test.startTest();
        DMSPortalLwc.DmsData result = DMSPortalLwc.allClaimData(Date.today().addDays(-30), Date.today(), 'New');
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testAllDistributorStockData() {
        Test.startTest();
        DMSPortalLwc.DmsData result = DMSPortalLwc.allDistributorStockData('All');
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testAllCreditNoteDataAll() {
        Test.startTest();
        DMSPortalLwc.DmsData result = DMSPortalLwc.allCreditNoteData(Date.today().addDays(-30), Date.today(), 'All');
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testAllCreditNoteDataWithStatus() {
        Test.startTest();
        DMSPortalLwc.DmsData result = DMSPortalLwc.allCreditNoteData(Date.today().addDays(-30), Date.today(), 'New');
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testSaveCreditNote() {
        Account acc = getDistributor();
        String jsonData = '{"customerId":"' + acc.Id + '","noteDate":"' + String.valueOf(Date.today()) + '","amount":"100","reason":"Test","description":"Test desc"}';
        Test.startTest();
        DMSPortalLwc.saveCreditNote(jsonData);
        Test.stopTest();
        List<Secondary_Credit_Note__c> notes = [SELECT Id FROM Secondary_Credit_Note__c WHERE Amount__c = 100];
        System.assert(notes.size() > 0);
    }

    @isTest
    static void testAllDebitNoteDataAll() {
        Test.startTest();
        DMSPortalLwc.DmsData result = DMSPortalLwc.allDebitNoteData(Date.today().addDays(-30), Date.today(), 'All');
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testAllDebitNoteDataWithStatus() {
        Test.startTest();
        DMSPortalLwc.DmsData result = DMSPortalLwc.allDebitNoteData(Date.today().addDays(-30), Date.today(), 'New');
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testSaveDebitNote() {
        Account acc = getDistributor();
        String jsonData = '{"customerId":"' + acc.Id + '","noteDate":"' + String.valueOf(Date.today()) + '","amount":"75","reason":"Test","description":"Test desc"}';
        Test.startTest();
        DMSPortalLwc.saveDebitNote(jsonData);
        Test.stopTest();
        List<Secondary_Debit_Note__c> notes = [SELECT Id FROM Secondary_Debit_Note__c WHERE Amount__c = 75];
        System.assert(notes.size() > 0);
    }

    @isTest
    static void testAllSecoundaryInvoiceDataAll() {
        Test.startTest();
        DMSPortalLwc.DmsData result = DMSPortalLwc.allSecoundaryInvoiceData('All', Date.today().addDays(-30), Date.today());
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testAllSecoundaryInvoiceDataWithStatus() {
        Test.startTest();
        DMSPortalLwc.DmsData result = DMSPortalLwc.allSecoundaryInvoiceData('Open', Date.today().addDays(-30), Date.today());
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetSecondaryInvoiceItems() {
        Secondary_Invoice__c secInv = getSecondaryInvoice();
        Test.startTest();
        List<Secondary_Invoice_Item__c> result = DMSPortalLwc.getSecondaryInvoiceItems(secInv.Id);
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetSecondaryInvoiceItemsByReceiptId() {
        Secondary_Receipt__c receipt = getSecondaryReceipt();
        Test.startTest();
        List<Secondary_Invoice_Item__c> result = DMSPortalLwc.getSecondaryInvoiceItemsByReceiptId(receipt.Id);
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testAllSecoundaryReturnsData() {
        Test.startTest();
        DMSPortalLwc.DmsData result = DMSPortalLwc.allSecoundaryReturnsData(Date.today().addDays(-30), Date.today());
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetSecondaryReturnItems() {
        Return__c ret = getReturn();
        Test.startTest();
        List<Return_Item__c> result = DMSPortalLwc.getSecondaryReturnItems(ret.Id);
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetSecondaryReturnItemList() {
        Test.startTest();
        List<Secondary_Retrun__c> result = DMSPortalLwc.getSecondaryReturnItemList(Date.today().addDays(-30), Date.today());
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetGRNData() {
        Invoice__c inv = getInvoice();
        Test.startTest();
        List<Invoice_Item__c> result = DMSPortalLwc.getGRNData(inv.Id);
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testCreatePaymentWithItems() {
        Invoice__c inv = getInvoice();
        Payment_Receipt_Item__c item = new Payment_Receipt_Item__c(
            Invoice__c = inv.Id,
            Amount__c = 500
        );
        Test.startTest();
        Id receiptId = DMSPortalLwc.createPaymentWithItems(new List<Payment_Receipt_Item__c>{item}, 500);
        Test.stopTest();
        System.assertNotEquals(null, receiptId);
    }

    @isTest
    static void testGetInvoicesByIds() {
        Invoice__c inv = getInvoice();
        Test.startTest();
        List<Invoice__c> result = DMSPortalLwc.getInvoicesByIds(new List<Id>{inv.Id});
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetInvoicesByIdsEmpty() {
        Test.startTest();
        List<Invoice__c> result = DMSPortalLwc.getInvoicesByIds(new List<Id>());
        Test.stopTest();
        System.assertEquals(0, result.size());
    }

    @isTest
    static void testGetInvoicesByIdsNull() {
        Test.startTest();
        List<Invoice__c> result = DMSPortalLwc.getInvoicesByIds(null);
        Test.stopTest();
        System.assertEquals(0, result.size());
    }

    @isTest
    static void testGetAllAccounts() {
        Test.startTest();
        List<Account> result = DMSPortalLwc.getAllAccounts();
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testSearchCustomers() {
        Test.startTest();
        List<Account> result = DMSPortalLwc.searchCustomers('Test');
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testSearchCustomersBlank() {
        Test.startTest();
        List<Account> result = DMSPortalLwc.searchCustomers('');
        Test.stopTest();
        System.assertEquals(0, result.size());
    }

    @isTest
    static void testGetSecondaryOrders() {
        Test.startTest();
        DMSPortalLwc.DmsData result = DMSPortalLwc.getSecondaryOrders('All', Date.today().addDays(-30), Date.today(), 'Secondary');
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetSecondaryOrdersWithStatus() {
        Test.startTest();
        DMSPortalLwc.DmsData result = DMSPortalLwc.getSecondaryOrders('Open', Date.today().addDays(-30), Date.today(), 'Secondary');
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetOrderItems() {
        Order__c ord = getOrder();
        Test.startTest();
        List<Map<String, Object>> result = DMSPortalLwc.getOrderItems(ord.Id);
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetOrderlineItems() {
        Order__c ord = getOrder();
        Test.startTest();
        List<Map<String, Object>> result = DMSPortalLwc.getOrderlineItems(ord.Id);
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetActiveProducts() {
        Test.startTest();
        List<DMSPortalLwc.ProductWrapper> result = DMSPortalLwc.getActiveProducts();
        Test.stopTest();
        System.assertNotEquals(null, result);
        System.assert(result.size() > 0);
    }

    @isTest
    static void testGetProductCategories() {
        Test.startTest();
        List<String> result = DMSPortalLwc.getProductCategories();
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetUsers() {
        Test.startTest();
        List<User> result = DMSPortalLwc.getUsers('', 'All');
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetUsersWithSearch() {
        Test.startTest();
        List<User> result = DMSPortalLwc.getUsers('Test', 'Active');
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetSecondaryCustomers() {
        Test.startTest();
        DMSPortalLwc.ReturnAccData result = DMSPortalLwc.getSecondaryCustomers('All');
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetStockAdjustments() {
        Test.startTest();
        DMSPortalLwc.StockAdjustmentBox result = DMSPortalLwc.getStockAdjustments(Date.today().addDays(-30), Date.today(), 'All');
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetStockData() {
        Test.startTest();
        DMSPortalLwc.StockAdjustmentBox result = DMSPortalLwc.getStockData();
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testSaveStockAdjustments() {
        Account acc = getDistributor();
        Product__c prod = getProduct();
        Distributor_Stock__c stock = [SELECT Id FROM Distributor_Stock__c LIMIT 1];
        Stock_Adjustment__c adj = new Stock_Adjustment__c(
            Distributor__c = acc.Id,
            Product__c = prod.Id,
            Product_Name__c = prod.Id,
            Quantity__c = 2,
            Reason__c = 'Test',
            Distributor_Stock__c = stock.Id
        );
        Test.startTest();
        DMSPortalLwc.saveStockAdjustments(new List<Stock_Adjustment__c>{adj});
        Test.stopTest();
    }

    @isTest
    static void testGetInvoicePdfUrl() {
        Invoice__c inv = getInvoice();
        Test.startTest();
        String result = DMSPortalLwc.getInvoicePdfUrl(inv.Id);
        Test.stopTest();
        System.assert(result.contains('/apex/GTInvoice'));
    }

    @isTest
    static void testAllSecondaryReceiptData() {
        Test.startTest();
        DMSPortalLwc.DmsData result = DMSPortalLwc.allSecondaryReceiptData(Date.today().addDays(-30), Date.today(), 'All');
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testSaveSecondaryReceipt() {
        Account secAcc = getSecondaryCustomer();
        Secondary_Invoice__c secInv = getSecondaryInvoice();

        Secondary_Receipt__c receipt = new Secondary_Receipt__c(
            Customer__c = secAcc.Id,
            Payment_Date__c = Date.today(),
            Total_Amount__c = 100,
            Payment_Mode__c = 'Cash'
        );

        Secondary_Receipt_Item__c recItem = new Secondary_Receipt_Item__c(
            Secondary_Invoice__c = secInv.Id,
            Amount__c = 100
        );

        Test.startTest();
        DMSPortalLwc.saveSecondaryReceipt(receipt, new List<Secondary_Receipt_Item__c>{recItem});
        Test.stopTest();
        System.assertNotEquals(null, receipt.Id);
    }

    @isTest
    static void testSaveSecondaryReceiptWithDetails() {
        Account secAcc = getSecondaryCustomer();
        Secondary_Invoice__c secInv = getSecondaryInvoice();
        Secondary_Debit_Note__c dn = [SELECT Id FROM Secondary_Debit_Note__c LIMIT 1];

        Secondary_Receipt__c receipt = new Secondary_Receipt__c(
            Customer__c = secAcc.Id,
            Payment_Date__c = Date.today(),
            Total_Amount__c = 150,
            Payment_Mode__c = 'Cash'
        );

        Secondary_Receipt_Item__c recItem = new Secondary_Receipt_Item__c(
            Secondary_Invoice__c = secInv.Id,
            Amount__c = 100
        );

        Secondary_Receipt_Debit_Item__c debitItem = new Secondary_Receipt_Debit_Item__c(
            Secondary_Debit_Note__c = dn.Id,
            Amount__c = 50
        );

        Test.startTest();
        DMSPortalLwc.saveSecondaryReceiptWithDetails(receipt, new List<Secondary_Receipt_Item__c>{recItem}, new List<Secondary_Receipt_Debit_Item__c>{debitItem});
        Test.stopTest();
        System.assertNotEquals(null, receipt.Id);
    }

    @isTest
    static void testGetOpeningBalance() {
        Account secAcc = getSecondaryCustomer();
        Test.startTest();
        DMSPortalLwc.OpeningBalanceResult result = DMSPortalLwc.getOpeningBalance(secAcc.Id, String.valueOf(Date.today().addDays(1)));
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetOpeningBalanceBlankDate() {
        Account secAcc = getSecondaryCustomer();
        Test.startTest();
        DMSPortalLwc.OpeningBalanceResult result = DMSPortalLwc.getOpeningBalance(secAcc.Id, '');
        Test.stopTest();
        System.assertEquals(0, result.balance);
    }

    @isTest
    static void testGetSecondaryLedger() {
        Account secAcc = getSecondaryCustomer();
        Test.startTest();
        DMSPortalLwc.SecondaryLedgerResult result = DMSPortalLwc.getSecondaryLedger(
            secAcc.Id,
            String.valueOf(Date.today().addDays(-30)),
            String.valueOf(Date.today()),
            'All'
        );
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetSecondaryLedgerBlankDates() {
        Account secAcc = getSecondaryCustomer();
        Test.startTest();
        DMSPortalLwc.SecondaryLedgerResult result = DMSPortalLwc.getSecondaryLedger(secAcc.Id, '', '', 'All');
        Test.stopTest();
        System.assertEquals(0, result.ledgerData.size());
    }

    @isTest
    static void testGetPendingDebitNotesByCustomer() {
        Account acc = getDistributor();
        Test.startTest();
        List<DMSPortalLwc.DebitNoteData> result = DMSPortalLwc.getPendingDebitNotesByCustomer(acc.Id);
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetPendingDebitNotesByCustomerNull() {
        Test.startTest();
        List<DMSPortalLwc.DebitNoteData> result = DMSPortalLwc.getPendingDebitNotesByCustomer(null);
        Test.stopTest();
        System.assertEquals(0, result.size());
    }

    @isTest
    static void testGetSecondaryCustomerAgingReport() {
        Account secAcc = getSecondaryCustomer();
        Test.startTest();
        DMSPortalLwc.AgingReportData result = DMSPortalLwc.getSecondaryCustomerAgingReport(secAcc.Id);
        Test.stopTest();
        System.assertNotEquals(null, result);
        System.assertNotEquals(null, result.buckets);
    }

    @isTest
    static void testGetCategorySlabClaimCategorySummary() {
        Test.startTest();
        List<DMSPortalLwc.ClaimReportItem> result = DMSPortalLwc.getCategorySlabClaimCategorySummary(
            String.valueOf(Date.today().addDays(-30)),
            String.valueOf(Date.today())
        );
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetCategorySlabClaimCategoryCustomerDetail() {
        Test.startTest();
        List<DMSPortalLwc.ClaimReportItem> result = DMSPortalLwc.getCategorySlabClaimCategoryCustomerDetail(
            String.valueOf(Date.today().addDays(-30)),
            String.valueOf(Date.today())
        );
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetSchemeClaimCustomerSummary() {
        Test.startTest();
        List<DMSPortalLwc.ClaimReportItem> result = DMSPortalLwc.getSchemeClaimCustomerSummary(
            String.valueOf(Date.today().addDays(-30)),
            String.valueOf(Date.today())
        );
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetCombinedClaimCategoryCustomerSummary() {
        Test.startTest();
        List<DMSPortalLwc.ClaimReportItem> result = DMSPortalLwc.getCombinedClaimCategoryCustomerSummary(
            String.valueOf(Date.today().addDays(-30)),
            String.valueOf(Date.today())
        );
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetTotalClaimCategoryCustomerSummary() {
        Test.startTest();
        List<DMSPortalLwc.ClaimReportItem> result = DMSPortalLwc.getTotalClaimCategoryCustomerSummary(
            String.valueOf(Date.today().addDays(-30)),
            String.valueOf(Date.today())
        );
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetAllProducts() {
        Test.startTest();
        DMSPortalLwc.secondaryReturnData result = DMSPortalLwc.getAllProducts();
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetProductGalleryData() {
        Test.startTest();
        List<Product__c> result = DMSPortalLwc.getProductGalleryData();
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testSaveSecondaryReturn() {
        Account secAcc = getSecondaryCustomer();
        Product__c prod = getProduct();

        Return_Item__c item = new Return_Item__c(
            SKU__c = prod.Id,
            Quantity__c = 2,
            Unit_Price__c = 100,
            Total_Amount__c = 200
        );

        Test.startTest();
        Id retId = DMSPortalLwc.saveSecondaryReturn(new List<Return_Item__c>{item}, 200, 2, secAcc.Id);
        Test.stopTest();
        System.assertNotEquals(null, retId);
    }

    @isTest
    static void testSaveSecondaryReturnNullItems() {
        Account secAcc = getSecondaryCustomer();
        Test.startTest();
        try {
            DMSPortalLwc.saveSecondaryReturn(null, 0, 0, secAcc.Id);
            System.assert(false, 'Should have thrown exception');
        } catch (AuraHandledException e) {
            System.assert(true);
        }
        Test.stopTest();
    }

    @isTest
    static void testSaveClaims() {
        Account acc = getDistributor();
        Claim__c claim = new Claim__c(
            Claim_Amount__c = 100,
            Description__c = 'Test'
        );
        Test.startTest();
        DMSPortalLwc.saveClaims(new List<Claim__c>{claim});
        Test.stopTest();
    }

    @isTest
    static void testSaveClaimsNull() {
        Test.startTest();
        try {
            DMSPortalLwc.saveClaims(null);
            System.assert(false, 'Should have thrown exception');
        } catch (AuraHandledException e) {
            System.assert(true);
        }
        Test.stopTest();
    }

    @isTest
    static void testLedgerEntryCompareTo() {
        DMSPortalLwc.LedgerEntry entry1 = new DMSPortalLwc.LedgerEntry();
        entry1.transactionDate = Date.today();
        DMSPortalLwc.LedgerEntry entry2 = new DMSPortalLwc.LedgerEntry();
        entry2.transactionDate = Date.today().addDays(1);
        DMSPortalLwc.LedgerEntry entry3 = new DMSPortalLwc.LedgerEntry();
        entry3.transactionDate = Date.today();

        System.assertEquals(-1, entry1.compareTo(entry2));
        System.assertEquals(1, entry2.compareTo(entry1));
        System.assertEquals(0, entry1.compareTo(entry3));
    }

    @isTest
    static void testLedgerEntryCompareToNull() {
        DMSPortalLwc.LedgerEntry entry1 = new DMSPortalLwc.LedgerEntry();
        entry1.transactionDate = null;
        DMSPortalLwc.LedgerEntry entry2 = new DMSPortalLwc.LedgerEntry();
        entry2.transactionDate = Date.today();

        System.assertEquals(-1, entry1.compareTo(entry2));
    }

    @isTest
    static void testWrapperClasses() {
        // Test all wrapper classes are instantiable
        DMSPortalLwc.DmsData dmsData = new DMSPortalLwc.DmsData();
        DMSPortalLwc.OrdData ordData = new DMSPortalLwc.OrdData();
        DMSPortalLwc.InvData invData = new DMSPortalLwc.InvData();
        DMSPortalLwc.PReturnData pRetData = new DMSPortalLwc.PReturnData();
        DMSPortalLwc.PaymentData payData = new DMSPortalLwc.PaymentData();
        DMSPortalLwc.GRNData grnData = new DMSPortalLwc.GRNData();
        DMSPortalLwc.ClaimData claimData = new DMSPortalLwc.ClaimData();
        DMSPortalLwc.DistributorStock distStock = new DMSPortalLwc.DistributorStock();
        DMSPortalLwc.CreditNote creditNote = new DMSPortalLwc.CreditNote();
        DMSPortalLwc.DebitNote debitNote = new DMSPortalLwc.DebitNote();
        DMSPortalLwc.SecInvData secInvData = new DMSPortalLwc.SecInvData();
        DMSPortalLwc.SReturnData sRetData = new DMSPortalLwc.SReturnData();
        DMSPortalLwc.GraphData graphData = new DMSPortalLwc.GraphData();
        DMSPortalLwc.kpi_graph_target kpiTarget = new DMSPortalLwc.kpi_graph_target();
        DMSPortalLwc.OrderItemWrapper oiWrapper = new DMSPortalLwc.OrderItemWrapper();
        DMSPortalLwc.GRN_Item_Wrapper grnWrapper = new DMSPortalLwc.GRN_Item_Wrapper();
        DMSPortalLwc.SecondaryReceipt secReceipt = new DMSPortalLwc.SecondaryReceipt();
        DMSPortalLwc.secondaryReturnData secRetData = new DMSPortalLwc.secondaryReturnData();
        DMSPortalLwc.StockAdjustmentBox saBox = new DMSPortalLwc.StockAdjustmentBox();
        DMSPortalLwc.StockAdjustmentData saData = new DMSPortalLwc.StockAdjustmentData();
        DMSPortalLwc.ReturnAccData retAccData = new DMSPortalLwc.ReturnAccData();
        DMSPortalLwc.AccData accData = new DMSPortalLwc.AccData();
        DMSPortalLwc.Invoice_Item_Data iiData = new DMSPortalLwc.Invoice_Item_Data();
        DMSPortalLwc.PrimaryReturnWrapper prWrapper = new DMSPortalLwc.PrimaryReturnWrapper();
        DMSPortalLwc.SecondaryReceiptItemWrapper sriWrapper = new DMSPortalLwc.SecondaryReceiptItemWrapper();
        DMSPortalLwc.OpeningBalanceResult obResult = new DMSPortalLwc.OpeningBalanceResult();
        DMSPortalLwc.SecondaryLedgerResult slResult = new DMSPortalLwc.SecondaryLedgerResult();
        DMSPortalLwc.DebitNoteData dnData = new DMSPortalLwc.DebitNoteData();
        DMSPortalLwc.AdvanceData advData = new DMSPortalLwc.AdvanceData();
        DMSPortalLwc.AgingBucket agBucket = new DMSPortalLwc.AgingBucket();
        DMSPortalLwc.AgingReportData arData = new DMSPortalLwc.AgingReportData();
        DMSPortalLwc.ClaimReportItem crItem = new DMSPortalLwc.ClaimReportItem();

        System.assertNotEquals(null, dmsData);
    }
}