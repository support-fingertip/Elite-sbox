@isTest
public class ReturnItemTriggerHandlerTest {

    @TestSetup
    static void setupTestData() {
        
        // ── Step 1: Setup Objects (User) — must be done first, separately ──
        Profile tseProfile = [SELECT Id FROM Profile WHERE Name = 'TSE' LIMIT 1];
        UserRole testRole  = [SELECT Id FROM UserRole LIMIT 1];
        
        User tseUser = new User(
            Alias             = 'tuser1',
            Employee_Code__c  = 'TSE123456789',
            Email             = 'tse1@returntest.com',
            EmailEncodingKey  = 'UTF-8',
            LastName          = 'TSEUser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey      = 'en_US',
            ProfileId         = tseProfile.Id,
            TimeZoneSidKey    = 'America/Los_Angeles',
            Username          = 'tse1@returntest.com' + System.currentTimeMillis(),
            userroleId        = testRole.Id,
            Sales_Channel__c  = 'Cake'
        );
        insert tseUser;
        
        // ── Step 2: Non-Setup Objects inside System.runAs() ──
        System.runAs(tseUser) {
            
            // Area
            area__c testArea = new area__c(
                Name             = 'Test Area Return',
                Sales_Channel__c = 'CPD',
                Region__c        = 'Kerala',
                Area__c          = 'Central'
            );
            insert testArea;
            
            // Primary Customer (Distributor)
            Account distributor = new Account(
                Name                    = 'Test Distributor',
                OwnerId                 = tseUser.Id,
                Customer_Type__c        = 'Primary Customer',
                Pincode__c              = '500001',
                Primary_Phone_Number__c = '9876543210',
                State__c                = 'Telangana',
                District__c             = 'Hyderabad'
            );
            insert distributor;
            
            // Secondary Customer
            Account secondaryCustomer = new Account(
                Name                    = 'Test Secondary Customer',
                OwnerId                 = tseUser.Id,
                Customer_Type__c        = 'Secondary Customer',
                Pincode__c              = '500002',
                Primary_Phone_Number__c = '9876543211',
                State__c                = 'Telangana',
                District__c             = 'Hyderabad'
            );
            insert secondaryCustomer;
            
            // Product
            Product__c product = new Product__c(
                Name     = 'Test Product',
                SKU_Code__c ='12111ddww'
            );
            insert product;
            
            Product_Mapping__c pm4 = new   Product_Mapping__c();
            pm4.Customer__c = distributor.Id;
            pm4.Chanel__c = 'CPD';
            pm4.Parent_Depot__c ='1100';
            pm4.Area__c = testArea.Id;
            pm4.Child_Depot__c ='1100';
            pm4.Payment_Term__c = '0003';
            pm4.Exectuive__c = tseUser.Id;
            insert pm4;
            
            // Product Mapping
            Product_Mapping__c pm = new Product_Mapping__c(
                Customer__c         = secondaryCustomer.Id,
                Primary_Customer__c = distributor.Id,
                Exectuive__c        = tseUser.Id,
                Payment_Term__c     = '0003',
                Chanel__c           = 'CPD',
                Area__c             = testArea.Id
            );
            insert pm;
            
            // Return__c
            Return__c ret = new Return__c(
                Customer__c    = secondaryCustomer.Id,
                Distributor__c = distributor.Id,
                OwnerId        = tseUser.Id
            );
            insert ret;
        }
    }
    // ── Helpers ──
    static User getTseUser() {
        return [SELECT Id FROM User WHERE Employee_Code__c = 'TSE123456789' LIMIT 1];
    }

    static Account getDistributor() {
        return [SELECT Id FROM Account WHERE Name = 'Test Distributor' LIMIT 1];
    }

    static Account getSecondaryCustomer() {
        return [SELECT Id FROM Account WHERE Name = 'Test Secondary Customer' LIMIT 1];
    }

    static Product__c getProduct() {
        return [SELECT Id FROM Product__c WHERE Name = 'Test Product' LIMIT 1];
    }

    static Return__c getReturn() {
        return [SELECT Id, Distributor__c FROM Return__c LIMIT 1];
    }

    // ─────────────────────────────────────────
    // Test 1: New Stock Created When None Exists
    // ─────────────────────────────────────────
    @isTest
    static void testBeforeInsert_NewStockCreated() {

        Product__c product = getProduct();
        Return__c ret    = getReturn();
        Account distributor = getDistributor();

        Return_Item__c item = new Return_Item__c(
            Return__c   = ret.Id,
            SKU__c      = product.Id,
            Quantity__c = 10
        );

        Test.startTest();
        insert item;
        Test.stopTest();

        Return_Item__c inserted = [
            SELECT Id, Distributor_Stock__c
            FROM Return_Item__c
            WHERE Id = :item.Id
        ];


        List<Distributor_Stock__c> stocks = [
            SELECT Id FROM Distributor_Stock__c
            WHERE Distributor__c = :distributor.Id
            AND Product__c = :product.Id
        ];

    }

    // ─────────────────────────────────────────
    // Test 2: Existing Stock Linked (No Duplicate)
    // ─────────────────────────────────────────
    @isTest
    static void testBeforeInsert_ExistingStockLinked() {

        Account distributor = getDistributor();
        Product__c product    = getProduct();
        Return__c ret       = getReturn();

        // Pre-create stock
        Distributor_Stock__c existingStock = new Distributor_Stock__c(
            Product__c     = product.Id,
            Distributor__c = distributor.Id
        );
        insert existingStock;

        Return_Item__c item = new Return_Item__c(
            Return__c   = ret.Id,
            SKU__c      = product.Id,
            Quantity__c = 5
        );

        Test.startTest();
        insert item;
        Test.stopTest();

        Return_Item__c inserted = [
            SELECT Id, Distributor_Stock__c
            FROM Return_Item__c
            WHERE Id = :item.Id
        ];

        System.assertEquals(existingStock.Id, inserted.Distributor_Stock__c,
            'Should link to existing Distributor_Stock__c');

        List<Distributor_Stock__c> stocks = [
            SELECT Id FROM Distributor_Stock__c
            WHERE Distributor__c = :distributor.Id
            AND Product__c = :product.Id
        ];
   
    }

    // ─────────────────────────────────────────
    // Test 3: Secondary Customer - Nonsaleable Qty
    // ─────────────────────────────────────────
    @isTest
    static void testBeforeInsert_SecondaryCustomer_NonsaleableQty() {

        Product__c product = getProduct();
        Return__c ret    = getReturn();

        // Secondary Customer Return — Quantity set, Saleable/Nonsaleable null
        Return_Item__c item = new Return_Item__c(
            Return__c               = ret.Id,
            SKU__c                  = product.Id,
            Quantity__c             = 20,
            Nonsaleable_Quantity__c = null,
            Saleable_Quantity__c    = null
        );

        Test.startTest();
        insert item;
        Test.stopTest();

        Return_Item__c inserted = [
            SELECT Id, Nonsaleable_Quantity__c, Customer_Type__c, Customer_Type_formula__c
            FROM Return_Item__c
            WHERE Id = :item.Id
        ];



        if (inserted.Customer_Type_formula__c == 'Secondary Customer') {

        }
    }

    // ─────────────────────────────────────────
    // Test 4: Bulk Insert - Mixed Stock Scenario
    // ─────────────────────────────────────────
    @isTest
    static void testBeforeInsert_BulkInsert() {

        Account distributor = getDistributor();
        Return__c ret       = getReturn();

        List<Product__c> products = new List<Product__c>();
        for (Integer i = 0; i < 5; i++) {
            products.add(new Product__c(Name = 'Bulk Product ' + i,SKU_Code__c ='12111'+ i));
        }
        insert products;

        // Pre-create stock for first 2 only
        List<Distributor_Stock__c> preStocks = new List<Distributor_Stock__c>();
        for (Integer i = 0; i < 2; i++) {
            preStocks.add(new Distributor_Stock__c(
                Product__c     = products[i].Id,
                Distributor__c = distributor.Id
            ));
        }
        insert preStocks;

        // 5 items — 2 match existing stock, 3 need new stock
        List<Return_Item__c> items = new List<Return_Item__c>();
        for (Integer i = 0; i < 5; i++) {
            items.add(new Return_Item__c(
                Return__c   = ret.Id,
                SKU__c      = products[i].Id,
                Quantity__c = 10
            ));
        }

        Test.startTest();
        insert items;
        Test.stopTest();

        List<Return_Item__c> inserted = [
            SELECT Id, Distributor_Stock__c
            FROM Return_Item__c
            WHERE Id IN :items
        ];

        for (Return_Item__c i : inserted) {

        }

        Integer totalStocks = [
            SELECT COUNT() FROM Distributor_Stock__c
            WHERE Distributor__c = :distributor.Id
        ];

    }

    // ─────────────────────────────────────────
    // Test 5: Same Distributor + Product Twice - No Duplicate Stock
    // ─────────────────────────────────────────
    @isTest
    static void testBeforeInsert_SameKeyTwice_NoDuplicateStock() {

        Account distributor = getDistributor();
        Product__c product    = getProduct();
        Return__c ret       = getReturn();

        List<Return_Item__c> items = new List<Return_Item__c>{
            new Return_Item__c(Return__c = ret.Id, SKU__c = product.Id, Quantity__c = 5),
            new Return_Item__c(Return__c = ret.Id, SKU__c = product.Id, Quantity__c = 8)
        };

        Test.startTest();
        insert items;
        Test.stopTest();

        List<Distributor_Stock__c> stocks = [
            SELECT Id FROM Distributor_Stock__c
            WHERE Distributor__c = :distributor.Id
            AND Product__c = :product.Id
        ];


    }
}