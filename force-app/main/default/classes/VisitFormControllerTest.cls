@isTest
public class VisitFormControllerTest {

    @testSetup
    static void setupData() {

        // Primary Account
        Account primaryAcc = new Account(
            Name = 'Primary Customer',
            Type = 'Distributor',
            State__c = 'Karnataka',
            District__c = 'kolar'
        );
        insert primaryAcc;

        // Secondary Account
        Account secondaryAcc = new Account(
            Name = 'Secondary Customer',
            ParentId = primaryAcc.Id,
            Type = 'Retailer',
            State__c = 'Karnataka',
            District__c = 'kolar'
        );
        insert secondaryAcc;

        // Product Mapping
        Product_Mapping__c pm = new Product_Mapping__c(
            Primary_Customer__c = primaryAcc.Id,
            Customer__c = secondaryAcc.Id,
            Exectuive__c = UserInfo.getUserId()
        );
        insert pm;
    }

    // Helper to get a small base64 image string for file upload tests
    static String getDummyBase64() {
        return EncodingUtil.base64Encode(Blob.valueOf('TestImageData'));
    }

    // =========================================================
    // getPrimaryCustomers
    // =========================================================
    @isTest
    static void testGetPrimaryCustomers() {
        Test.startTest();
        List<Account> result = VisitFormController.getPrimaryCustomers();
        Test.stopTest();
        System.assert(result.size() > 0, 'Expected at least one primary customer');
    }

    // =========================================================
    // getSecondaryCustomers
    // =========================================================
    @isTest
    static void testGetSecondaryCustomers() {
        Account primary = [SELECT Id FROM Account WHERE ParentId = NULL LIMIT 1];
        Test.startTest();
        List<Account> result = VisitFormController.getSecondaryCustomers(primary.Id);
        Test.stopTest();
        System.assert(result.size() > 0, 'Expected at least one secondary customer');
    }

    @isTest
    static void testGetSecondaryCustomersNull() {
        Test.startTest();
        List<Account> result = VisitFormController.getSecondaryCustomers(null);
        Test.stopTest();
        System.assertEquals(0, result.size(), 'Null Id should return empty list');
    }

    // =========================================================
    // getSecondaryCustomerAutoFill
    // =========================================================
    @isTest
    static void testGetSecondaryCustomerAutoFill() {
        Account secondary = [SELECT Id FROM Account WHERE ParentId != NULL LIMIT 1];
        Test.startTest();
        Map<String,String> result = VisitFormController.getSecondaryCustomerAutoFill(secondary.Id);
        Test.stopTest();
        System.assert(result.containsKey('secondaryCustomerId'), 'Should contain secondaryCustomerId');
        System.assert(result.containsKey('primaryCustomerId'), 'Should contain primaryCustomerId');
    }

    @isTest
    static void testGetSecondaryCustomerAutoFillNull() {
        Test.startTest();
        Map<String,String> result = VisitFormController.getSecondaryCustomerAutoFill(null);
        Test.stopTest();
        System.assert(result.isEmpty(), 'Null Id should return empty map');
    }

    // Test with an account that has no product mapping (falls back to ParentId)
    @isTest
    static void testGetSecondaryCustomerAutoFillNoMapping() {
        Account secondary = [SELECT Id FROM Account WHERE ParentId != NULL LIMIT 1];

        // Delete the product mapping so it falls back to ParentId
        List<Product_Mapping__c> mappings = [SELECT Id FROM Product_Mapping__c WHERE Customer__c = :secondary.Id];
        delete mappings;

        Test.startTest();
        Map<String,String> result = VisitFormController.getSecondaryCustomerAutoFill(secondary.Id);
        Test.stopTest();
        System.assert(result.containsKey('primaryCustomerId'), 'Should fall back to ParentId');
    }

    // =========================================================
    // getAllowedProducts
    // =========================================================
    @isTest
    static void testGetAllowedProducts() {
        Test.startTest();
        Map<String,List<String>> result = VisitFormController.getAllowedProducts();
        Test.stopTest();
        System.assert(result != null, 'Result should not be null');
    }

    // =========================================================
    // savePrimaryVisit - without images
    // =========================================================
    @isTest
    static void testSavePrimaryVisit() {
        Account primary = [SELECT Id FROM Account WHERE ParentId = NULL LIMIT 1];
        Test.startTest();
        Id visitId = VisitFormController.savePrimaryVisit(
            primary.Id, 'Staple', null, null, null, 'Remarks', 'General',
            null, null, null, null, 23.5, 86.4, null, null
        );
        Test.stopTest();
        System.assertNotEquals(null, visitId, 'Visit Id should not be null');
    }

    // savePrimaryVisit - with images and visitId/logId
    @isTest
    static void testSavePrimaryVisitWithImages() {
        Account primary = [SELECT Id FROM Account WHERE ParentId = NULL LIMIT 1];
        String base64Img = getDummyBase64();
        Test.startTest();
        Id visitId = VisitFormController.savePrimaryVisit(
            primary.Id, 'Staple', null, null, null, 'Remarks', 'General',
            base64Img, 'primaryImg.jpg', base64Img, 'compImg.jpg',
            23.5, 86.4, null, null
        );
        Test.stopTest();
        System.assertNotEquals(null, visitId, 'Visit Id should not be null');
        List<ContentDocumentLink> links = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :visitId];
        System.assert(links.size() > 0, 'Should have file attachments');
    }

    // =========================================================
    // saveSecondaryVisit - without images
    // =========================================================
    @isTest
    static void testSaveSecondaryVisit() {
        Account primary   = [SELECT Id FROM Account WHERE ParentId = NULL LIMIT 1];
        Account secondary = [SELECT Id FROM Account WHERE ParentId != NULL LIMIT 1];
        Test.startTest();
        Id visitId = VisitFormController.saveSecondaryVisit(
            primary.Id, secondary.Id, 'Staple', null, null, null, 'Remark', 'General',
            null, null, null, null, 22.1, 88.3, null, null
        );
        Test.stopTest();
        System.assertNotEquals(null, visitId, 'Visit Id should not be null');
    }

    // saveSecondaryVisit - with images and logId
    @isTest
    static void testSaveSecondaryVisitWithImages() {
        Account primary   = [SELECT Id FROM Account WHERE ParentId = NULL LIMIT 1];
        Account secondary = [SELECT Id FROM Account WHERE ParentId != NULL LIMIT 1];
        String base64Img = getDummyBase64();
        Test.startTest();
        Id visitId = VisitFormController.saveSecondaryVisit(
            primary.Id, secondary.Id, 'Staple', null, null, null, 'Remark', 'General',
            base64Img, 'custImg.jpg', base64Img, 'compImg.jpg',
            22.1, 88.3, null, null
        );
        Test.stopTest();
        System.assertNotEquals(null, visitId, 'Visit Id should not be null');
    }

    // =========================================================
    // saveNewPrimaryCustomerVisit - without images
    // =========================================================
    @isTest
    static void testSaveNewPrimaryCustomerVisit() {
        Test.startTest();
        Id visitId = VisitFormController.saveNewPrimaryCustomerVisit(
            'New Customer', 'ICDS', 'Address', 'Karnataka', 'kolar', '826001', '9999999999',
            'Staple', null, null, null, 'Remark', 'General',
            null, null, null, null, 22.4, 86.3, null
        );
        Test.stopTest();
        System.assertNotEquals(null, visitId, 'Visit Id should not be null');
    }

    // saveNewPrimaryCustomerVisit - with images
    @isTest
    static void testSaveNewPrimaryCustomerVisitWithImages() {
        String base64Img = getDummyBase64();
        Test.startTest();
        Id visitId = VisitFormController.saveNewPrimaryCustomerVisit(
            'New Customer 2', 'ICDS', 'Address', 'Karnataka', 'kolar', '826001', '9999999999',
            'Staple', null, null, null, 'Remark', 'General',
            base64Img, 'custImg.jpg', base64Img, 'compImg.jpg',
            22.4, 86.3, null
        );
        Test.stopTest();
        System.assertNotEquals(null, visitId, 'Visit Id should not be null');
    }

    // =========================================================
    // saveSubStockistExistingMarketVisit - without images
    // =========================================================
    @isTest
    static void testSaveSubStockistExistingMarketVisit() {
        Account primary = [SELECT Id FROM Account WHERE ParentId = NULL LIMIT 1];
        Test.startTest();
        Id visitId = VisitFormController.saveSubStockistExistingMarketVisit(
            'Sub Stockist', primary.Id, 'Address', 'Karnataka', 'kolar', '560001', '9999999999',
            'Staple', null, null, null, 'Remark', 'General',
            null, null, null, null, 22.5, 86.5, null
        );
        Test.stopTest();
        System.assertNotEquals(null, visitId, 'Visit Id should not be null');
    }

    // saveSubStockistExistingMarketVisit - with images and logId
    @isTest
    static void testSaveSubStockistWithImages() {
        Account primary = [SELECT Id FROM Account WHERE ParentId = NULL LIMIT 1];
        String base64Img = getDummyBase64();
        Test.startTest();
        Id visitId = VisitFormController.saveSubStockistExistingMarketVisit(
            'Sub Stockist 2', primary.Id, 'Address', 'Karnataka', 'kolar', '560001', '9999999999',
            'Staple', null, null, null, 'Remark', 'General',
            base64Img, 'custImg.jpg', base64Img, 'compImg.jpg',
            22.5, 86.5, null
        );
        Test.stopTest();
        System.assertNotEquals(null, visitId, 'Visit Id should not be null');
    }

    // =========================================================
    // saveOutletNewMarket - without images
    // =========================================================
    @isTest
    static void testSaveOutletNewMarket() {
        Test.startTest();
        Id visitId = VisitFormController.saveOutletNewMarket(
            'New Outlet', null, 'Address', 'Karnataka', 'kolar', '560001', '9999999999',
            'Staple', null, null, null, 'Remark', 'General',
            null, null, null, null, 22.6, 86.6, null
        );
        Test.stopTest();
        System.assertNotEquals(null, visitId, 'Visit Id should not be null');
    }

    // saveOutletNewMarket - with images
    @isTest
    static void testSaveOutletNewMarketWithImages() {
        String base64Img = getDummyBase64();
        Test.startTest();
        Id visitId = VisitFormController.saveOutletNewMarket(
            'New Outlet 2', null, 'Address', 'Karnataka', 'kolar', '560001', '9999999999',
            'Staple', null, null, null, 'Remark', 'General',
            base64Img, 'custImg.jpg', base64Img, 'compImg.jpg',
            22.6, 86.6, null
        );
        Test.stopTest();
        System.assertNotEquals(null, visitId, 'Visit Id should not be null');
    }

    // =========================================================
    // saveOutletExistingMarket - without images
    // =========================================================
    @isTest
    static void testSaveOutletExistingMarket() {
        Account primary = [SELECT Id FROM Account WHERE ParentId = NULL LIMIT 1];
        Test.startTest();
        Id visitId = VisitFormController.saveOutletExistingMarket(
            'Existing Outlet', primary.Id, null, 'Address', 'Karnataka', 'kolar', '560001', '9999999999',
            'Staple', null, null, null, 'Remark', 'General',
            null, null, null, null, 22.7, 86.7, null
        );
        Test.stopTest();
        System.assertNotEquals(null, visitId, 'Visit Id should not be null');
    }

    // saveOutletExistingMarket - with images
    @isTest
    static void testSaveOutletExistingMarketWithImages() {
        Account primary = [SELECT Id FROM Account WHERE ParentId = NULL LIMIT 1];
        String base64Img = getDummyBase64();
        Test.startTest();
        Id visitId = VisitFormController.saveOutletExistingMarket(
            'Existing Outlet 2', primary.Id, null, 'Address', 'Karnataka', 'kolar', '560001', '9999999999',
            'Staple', null, null, null, 'Remark', 'General',
            base64Img, 'custImg.jpg', base64Img, 'compImg.jpg',
            22.7, 86.7, null
        );
        Test.stopTest();
        System.assertNotEquals(null, visitId, 'Visit Id should not be null');
    }

    // =========================================================
    // getSecondaryCustomersFromProductMapping
    // =========================================================
    @isTest
    static void testGetSecondaryCustomersFromProductMapping() {
        Account primary = [SELECT Id FROM Account WHERE ParentId = NULL LIMIT 1];
        Test.startTest();
        List<Account> result = VisitFormController.getSecondaryCustomersFromProductMapping(primary.Id);
        Test.stopTest();
        System.assert(result.size() > 0, 'Expected at least one secondary from product mapping');
    }

    @isTest
    static void testGetSecondaryCustomersFromProductMappingNull() {
        Test.startTest();
        List<Account> result = VisitFormController.getSecondaryCustomersFromProductMapping(null);
        Test.stopTest();
        System.assertEquals(0, result.size(), 'Null Id should return empty list');
    }

    // =========================================================
    // getPrimaryCustomerBusinessType
    // =========================================================
    @isTest
    static void testGetPrimaryCustomerBusinessType() {
        Account primary = [SELECT Id FROM Account WHERE ParentId = NULL LIMIT 1];
        Test.startTest();
        String result = VisitFormController.getPrimaryCustomerBusinessType(primary.Id);
        Test.stopTest();
        System.assertEquals('Distributor', result, 'Should return Distributor');
    }

    @isTest
    static void testGetPrimaryCustomerBusinessTypeNull() {
        Test.startTest();
        String result = VisitFormController.getPrimaryCustomerBusinessType(null);
        Test.stopTest();
        System.assertEquals(null, result, 'Null Id should return null');
    }

    // =========================================================
    // getVisitFieldValues - all 6 branches
    // =========================================================
    @isTest
    static void testGetVisitFieldValuesExistingPrimary() {
        Account primary = [SELECT Id FROM Account WHERE ParentId = NULL LIMIT 1];
        Test.startTest();
        Map<String,String> result = VisitFormController.getVisitFieldValues('Existing Primary Customer', primary.Id);
        Test.stopTest();
        System.assertEquals('Existing Primary Customer', result.get('CustomerType'));
    }

    @isTest
    static void testGetVisitFieldValuesExistingSecondary() {
        Account primary = [SELECT Id FROM Account WHERE ParentId = NULL LIMIT 1];
        Test.startTest();
        Map<String,String> result = VisitFormController.getVisitFieldValues('Existing Secondary Customer', primary.Id);
        Test.stopTest();
        System.assertEquals('Existing Secondary Customer', result.get('CustomerType'));
    }

    @isTest
    static void testGetVisitFieldValuesNewPrimary() {
        Test.startTest();
        Map<String,String> result = VisitFormController.getVisitFieldValues('New Primary Customer', null);
        Test.stopTest();
        System.assertEquals('New Primary Customer', result.get('CustomerType'));
    }

    @isTest
    static void testGetVisitFieldValuesSubStockist() {
        Account primary = [SELECT Id FROM Account WHERE ParentId = NULL LIMIT 1];
        Test.startTest();
        Map<String,String> result = VisitFormController.getVisitFieldValues('Sub Stockiest – Existing Market Expansion', primary.Id);
        Test.stopTest();
        System.assertEquals('New Sub Stockiest', result.get('CustomerType'));
    }

    @isTest
    static void testGetVisitFieldValuesOutletNew() {
        Test.startTest();
        Map<String,String> result = VisitFormController.getVisitFieldValues('Outlet – New Market Expansion', null);
        Test.stopTest();
        System.assertEquals('New Outlet', result.get('CustomerType'));
        System.assertEquals('New Market Expansion', result.get('VisitType'));
    }

    @isTest
    static void testGetVisitFieldValuesOutletExisting() {
        Account primary = [SELECT Id FROM Account WHERE ParentId = NULL LIMIT 1];
        Test.startTest();
        Map<String,String> result = VisitFormController.getVisitFieldValues('Outlet – Existing Market Expansion', primary.Id);
        Test.stopTest();
        System.assertEquals('New Outlet', result.get('CustomerType'));
        System.assertEquals('Existing Market Expansion', result.get('VisitType'));
    }

    // =========================================================
    // searchSecondaryCustomers
    // =========================================================
    @isTest
    static void testSearchSecondaryCustomers() {
        Account primary = [SELECT Id FROM Account WHERE ParentId = NULL LIMIT 1];
        Test.startTest();
        List<Account> result = VisitFormController.searchSecondaryCustomers(primary.Id, 'Secondary');
        Test.stopTest();
        System.assert(result.size() > 0, 'Expected at least one result');
    }

    @isTest
    static void testSearchSecondaryCustomersBlank() {
        Account primary = [SELECT Id FROM Account WHERE ParentId = NULL LIMIT 1];
        Test.startTest();
        List<Account> result = VisitFormController.searchSecondaryCustomers(primary.Id, '');
        Test.stopTest();
        System.assertEquals(0, result.size(), 'Blank search should return empty list');
    }

    @isTest
    static void testSearchSecondaryCustomersNullId() {
        Test.startTest();
        List<Account> result = VisitFormController.searchSecondaryCustomers(null, 'test');
        Test.stopTest();
        System.assertEquals(0, result.size(), 'Null Id should return empty list');
    }

    // =========================================================
    // getTodayVisitForms
    // =========================================================
    @isTest
    static void testGetTodayVisitFormsNoSearch() {
        Test.startTest();
        List<Visit_Form__c> visits = VisitFormController.getTodayVisitForms(null);
        Test.stopTest();
        System.assert(visits != null, 'Should not be null');
    }

    @isTest
    static void testGetTodayVisitFormsWithSearch() {
        // First create a visit so there's data to search
        Account primary = [SELECT Id FROM Account WHERE ParentId = NULL LIMIT 1];
        VisitFormController.savePrimaryVisit(
            primary.Id, 'Staple', null, null, null, 'Remarks', 'General',
            null, null, null, null, 23.5, 86.4, null, null
        );
        Test.startTest();
        List<Visit_Form__c> visits = VisitFormController.getTodayVisitForms('Primary');
        Test.stopTest();
        System.assert(visits != null, 'Should not be null');
    }

    @isTest
    static void testGetTodayVisitFormsBlankSearch() {
        Test.startTest();
        List<Visit_Form__c> visits = VisitFormController.getTodayVisitForms('');
        Test.stopTest();
        System.assert(visits != null, 'Should not be null');
    }
}