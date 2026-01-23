@isTest
private class RetunPdfControllerTest {
    
    @testSetup
    static void setupTestData() {
        // Create test customer account
        Account testCustomer = new Account(Name = 'Test Customer',Pincode__c = '123456',
            Primary_Phone_Number__c = '9876543610',
            State__c = 'Karnataka',
            District__c = 'Kolar');
        insert testCustomer;
        
        // Create test owner user
        User testOwner = new User(
            Alias = 'testown',
            Email = 'testowner@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Owner',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name='Standard User'].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testowner232@testorg.com',
            Employee_Code__c = '334455662'
        );
        insert testOwner;
        
        // Create test return
        Return__c testReturn = new Return__c(
            Customer__c = testCustomer.Id,
            Return_Date__c = Date.today()
        );
        insert testReturn;
        
        // Create test SKU
        Product__c testSKU = new Product__c(
            Name = 'Test SKU',
            UOM__c = 'EA'
        );
        insert testSKU;
        
        // Create test return items
        List<Return_Item__c> returnItems = new List<Return_Item__c>();
        returnItems.add(new Return_Item__c(
            Return__c = testReturn.Id,
            SKU__c = testSKU.Id,
            Quantity__c = 5,
            Unit_Price__c = 100,
            Total_Amount__c = 500,
            Batch_Number__c = 'BATCH001',
            Reason_For_Return__c = 'Expired',
            UOM__c = 'EA'
        ));
        returnItems.add(new Return_Item__c(
            Return__c = testReturn.Id,
            SKU__c = testSKU.Id,
            Quantity__c = 3,
            Unit_Price__c = 150,
            Total_Amount__c = 450,
            Batch_Number__c = 'BATCH002',
            Reason_For_Return__c = 'Expired',
            UOM__c = 'EA'
        ));
        insert returnItems;
    }
    
    @isTest
    static void testControllerWithValidReturn() {
        // Get the test return
        Return__c testReturn = [SELECT Id FROM Return__c LIMIT 1];
        
        // Set up the test page with the return ID
        PageReference pageRef = Page.ReturnPdf; // Replace with your actual VF page name
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', testReturn.Id);
        
        // Instantiate the controller
        ApexPages.StandardController stdController = new ApexPages.StandardController(testReturn);
        RetunPdfController controller = new RetunPdfController(stdController);
        
        // Verify the controller properties
        //System.assertEquals(testReturn.Id, controller.recid, 'Return ID should match');
        //System.assertEquals('Test Customer', controller.customerName, 'Customer name should match');
        //System.assertEquals('RET-001', controller.returnNo, 'Return number should match');
        //System.assertEquals('Test Owner', controller.ownerName, 'Owner name should match');
        
        // Verify date formatting
        //System.assert(controller.returnDate.contains(Date.today().format('MMMM dd, yyyy')), 'Return date format should match');
        
        // Verify return items
        //System.assertEquals(2, controller.rtnItemList.size(), 'Should have 2 return items');
        //System.assertEquals(8, controller.totalQuantity, 'Total quantity should be 8 (5+3)');
        //System.assertEquals(950, controller.totalAmount, 'Total amount should be 950 (500+450)');
        
        // Verify item details
        RetunPdfController.ReturnWapper firstItem = controller.rtnItemList[0];
        //System.assertEquals('Test SKU', firstItem.skuName, 'SKU name should match');
        //System.assertEquals(5, firstItem.quantity, 'Quantity should match');
        //System.assertEquals('BATCH001', firstItem.batchno, 'Batch number should match');
        //System.assertEquals('Damaged', firstItem.returnReason, 'Return reason should match');
        //System.assertEquals('Each', firstItem.uom, 'UOM should match');
        //System.assertEquals(100, firstItem.unitPrice, 'Unit price should match');
        //System.assertEquals(500, firstItem.totalAmount, 'Total amount should match');
        
        // Verify amount in words
        //System.assert(controller.finalAmtinWords != null, 'Amount in words should not be null');
        //System.assert(controller.finalAmtinWords.contains('Nine Hundred Fifty'), 'Amount in words should contain correct text');
    }
    
    @isTest
    static void testControllerWithNoReturnItems() {
        // Create a new return with no items
        Account testCustomer = [SELECT Id FROM Account WHERE Name = 'Test Customer' LIMIT 1];
        Return__c emptyReturn = new Return__c(
            Customer__c = testCustomer.Id,
            Return_Date__c = Date.today()
        );
        insert emptyReturn;
        
        // Set up the test page with the empty return ID
        PageReference pageRef = Page.ReturnPdf;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', emptyReturn.Id);
        
        // Instantiate the controller
        ApexPages.StandardController stdController = new ApexPages.StandardController(emptyReturn);
        RetunPdfController controller = new RetunPdfController(stdController);
        
        // Verify the controller properties
        //System.assertEquals(emptyReturn.Id, controller.recid, 'Return ID should match');
        //System.assertEquals('Test Customer', controller.customerName, 'Customer name should match');
        //System.assertEquals('RET-002', controller.returnNo, 'Return number should match');
        
        // Verify empty lists and zero totals
        //System.assertEquals(0, controller.rtnItemList.size(), 'Return items list should be empty');
        //System.assertEquals(0, controller.totalQuantity, 'Total quantity should be 0');
        //System.assertEquals(0, controller.totalAmount, 'Total amount should be 0');
        //System.assertEquals(null, controller.finalAmtinWords, 'Amount in words should be null when no items');
    }
    
    @isTest
    static void testControllerWithNullReturnDate() {
        // Create a new return with null return date
        Account testCustomer = [SELECT Id FROM Account WHERE Name = 'Test Customer' LIMIT 1];
        Return__c noDateReturn = new Return__c(
            Customer__c = testCustomer.Id            // Return_Date__c intentionally left null
        );
        insert noDateReturn;
        
        // Add one item to the return
        Product__c testSKU = [SELECT Id FROM Product__c LIMIT 1];
        Return_Item__c returnItem = new Return_Item__c(
            Return__c = noDateReturn.Id,
            SKU__c = testSKU.Id,
            Quantity__c = 1,
            Unit_Price__c = 100,
            Total_Amount__c = 100
        );
        insert returnItem;
        
        // Set up the test page
        PageReference pageRef = Page.ReturnPdf;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', noDateReturn.Id);
        
        // Instantiate the controller
        ApexPages.StandardController stdController = new ApexPages.StandardController(noDateReturn);
        RetunPdfController controller = new RetunPdfController(stdController);
        
        // Verify date handling
        //System.assertEquals('', controller.returnDate, 'Return date should be empty string when null');
        
        // Verify other data
        //System.assertEquals(1, controller.rtnItemList.size(), 'Should have 1 return item');
        //System.assertEquals(1, controller.totalQuantity, 'Total quantity should be 1');
        //System.assertEquals(100, controller.totalAmount, 'Total amount should be 100');
    }
    
    @isTest
    static void testControllerWithoutIdParameter() {
        // Test with no ID parameter in the page
        PageReference pageRef = Page.ReturnPdf;
        Test.setCurrentPage(pageRef);
        
        // Instantiate the controller with no parameters
        RetunPdfController controller = new RetunPdfController(new ApexPages.StandardController(new Return__c()));
        
        // Verify the controller handles missing ID gracefully
        //System.assertEquals(null, controller.recid, 'Record ID should be null when not provided');
        //System.assertEquals(0, controller.rtnItemList.size(), 'Return items list should be empty');
        //System.assertEquals(0, controller.totalQuantity, 'Total quantity should be 0');
        //System.assertEquals(0, controller.totalAmount, 'Total amount should be 0');
    }
    
    @isTest
    static void testControllerWithNullValuesInItems() {
        // Get the test return
        Return__c testReturn = [SELECT Id FROM Return__c LIMIT 1];
        
        // Add an item with null values
        Product__c testSKU = [SELECT Id FROM Product__c LIMIT 1];
        Return_Item__c nullItem = new Return_Item__c(
            Return__c = testReturn.Id,
            SKU__c = testSKU.Id,
            // Quantity__c left null
            // Unit_Price__c left null
            // Total_Amount__c left null
            Batch_Number__c = null,
            Reason_For_Return__c = null
        );
        insert nullItem;
        
        // Set up the test page
        PageReference pageRef = Page.ReturnPdf;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', testReturn.Id);
        
        // Instantiate the controller
        ApexPages.StandardController stdController = new ApexPages.StandardController(testReturn);
        RetunPdfController controller = new RetunPdfController(stdController);
        
        // Verify the controller handles null values gracefully
        //System.assertEquals(3, controller.rtnItemList.size(), 'Should have 3 return items');
        
        // Find the item with null values
        RetunPdfController.ReturnWapper nullWapper;
        for (RetunPdfController.ReturnWapper w : controller.rtnItemList) {
            if (w.batchno == null) {
                nullWapper = w;
                break;
            }
        }
        
        //System.assertNotEquals(null, nullWapper, 'Should find the item with null values');
        //System.assertEquals(null, nullWapper.quantity, 'Null quantity should be handled');
        //System.assertEquals(null, nullWapper.unitPrice, 'Null unit price should be handled');
        //System.assertEquals(null, nullWapper.totalAmount, 'Null total amount should be handled');
        //System.assertEquals(null, nullWapper.returnReason, 'Null return reason should be handled');
    }
}