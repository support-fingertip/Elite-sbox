@isTest
private class SchemeLwcTest {
    @TestSetup
    static void setupTestData() {
        // Create test products
        Product__c testProduct = new Product__c(
            Name = 'Test Product',
            Is_Active__c = true,
            Channel__c = 'Cake',
            SKU_Code__c = 'SKU001'
        );
        insert testProduct;
        
        // Create product category
        Product_Category__c testCategory = new Product_Category__c(
            Name = 'Test Category'
        );
        insert testCategory;
        
        // Create sales channel to SKU mapping
        Sales_Channel_To_SKU__c channelMapping = new Sales_Channel_To_SKU__c(
            Sales_Channel__c = 'Cake',
            SKU__c = testProduct.Id
        );
        insert channelMapping;
        
        // Create test scheme
        Scheme__c testScheme = new Scheme__c(
            Name = 'Test Scheme',
            Scheme_End_Date__c = Date.today().addDays(30),
            Scheme_Start_Date__c = Date.today(),
            IsActive__c = true,
            Product_Category__c = testCategory.Id,
            Description__c = 'Test Description'
        );
        insert testScheme;
        
        // Create buy product
        Buy_Product__c buyProduct = new Buy_Product__c(
            Scheme__c = testScheme.Id,
            Buy_Quantity__c = 10,
            Buy_Value__c = 100,
            Offer_Percent__c = 10,
            Product__c = testProduct.Id,
            Sales_Channel__c = 'Cake',
            Scheme_Type__c = 'Free Quantity'
        );
        insert buyProduct;
        
        // Create exclude product
        Exclude_Product__c excludeProduct = new Exclude_Product__c(
            Scheme__c = testScheme.Id,
            Product_Category__c = testCategory.Id
        );
        insert excludeProduct;
        
        // Create exclude line item
        Exclude_Line_Item__c excludeItem = new Exclude_Line_Item__c(
            Exclude_Product__c = excludeProduct.Id,
            Product__c = testProduct.Id
        );
        insert excludeItem;
        
        // Create region
        Region__c testRegion = new Region__c(
            Name = 'Test Region'
        );
        insert testRegion;
        
        // Create area
        Area__c testArea = new Area__c(
            Name = 'Test Area'
        );
        insert testArea;
        
        // Create account
        Account testAccount = new Account(
            Name = 'Test Account',Pincode__c = '123456',
            Primary_Phone_Number__c = '9856543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'        );
        insert testAccount;
        
        // Create mapping
        Mapping__c testMapping = new Mapping__c(
            Scheme__c = testScheme.Id,
            Region__c = testRegion.Id,
            Account__c = testAccount.Id,
            Area__c = testArea.Id
        );
        insert testMapping;
    }
    
    @isTest
    static void testGetAllProduct() {
        Scheme__c testScheme = [SELECT Id FROM Scheme__c LIMIT 1];
        
        Test.startTest();
        SchemeLwc.userData result = SchemeLwc.getAllProduct(testScheme.Id);
        Test.stopTest();
        
       
    }
    
    @isTest
    static void testGetAllProductById() {
        Test.startTest();
        SchemeLwc.userData result = SchemeLwc.getAllProductById('Retail');
        Test.stopTest();
        
    }
    
    @isTest
    static void testSaveData() {
        Scheme__c testScheme = [SELECT Id FROM Scheme__c LIMIT 1];
        Product__c testProduct = [SELECT Id FROM Product__c LIMIT 1];
        
        List<Buy_Product__c> buyProducts = new List<Buy_Product__c>{
            new Buy_Product__c(
                Buy_Quantity__c = 5,
                Buy_Value__c = 50,
                Offer_Percent__c = 5,
                Product__c = testProduct.Id,
                Sales_Channel__c = 'Retail',
                Scheme_Type__c = 'Discount'
            )
        };
        
        Scheme__c schemeData = new Scheme__c(
            Id = testScheme.Id,
            Description__c = 'Updated Description'
        );
        
        Test.startTest();
        Id resultId = SchemeLwc.saveData(buyProducts, schemeData, null, null, null);
        Test.stopTest();
        
        
        List<Buy_Product__c> updatedBuyProducts = [SELECT Id FROM Buy_Product__c WHERE Scheme__c = :testScheme.Id];
    }
    
    @isTest
    static void testSaveExclude() {
        Exclude_Product__c excludeProduct = [SELECT Id FROM Exclude_Product__c LIMIT 1];
        Product__c testProduct = [SELECT Id FROM Product__c LIMIT 1];
        
        List<Exclude_Line_Item__c> excludeItems = new List<Exclude_Line_Item__c>{
            new Exclude_Line_Item__c(
                Product__c = testProduct.Id
            )
        };
        
        Test.startTest();
        SchemeLwc.userData result = SchemeLwc.saveExclude(null, excludeItems, excludeProduct.Id, new List<String>());
        Test.stopTest();
        
      
    }
    
    @isTest
    static void testMapRegion() {
        Scheme__c testScheme = [SELECT Id FROM Scheme__c LIMIT 1];
        
        Test.startTest();
        SchemeLwc.userData result = SchemeLwc.mapRegion(null, testScheme.Id, true, true, true);
        Test.stopTest();
        
     
    }
    
    @isTest
    static void testSaveMapping() {
        Scheme__c testScheme = [SELECT Id FROM Scheme__c LIMIT 1];
        Region__c testRegion = [SELECT Id FROM Region__c LIMIT 1];
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Area__c testArea = [SELECT Id FROM Area__c LIMIT 1];
        
        List<Mapping__c> mappings = new List<Mapping__c>{
            new Mapping__c(
                Scheme__c = testScheme.Id,
                Region__c = testRegion.Id
            )
        };
        
        List<String> deleteIds = new List<String>();
        
        Test.startTest();
        SchemeLwc.saveMapping(mappings, testScheme.Id, deleteIds);
        Test.stopTest();
        
        List<Mapping__c> updatedMappings = [SELECT Id FROM Mapping__c WHERE Scheme__c = :testScheme.Id];
    }
    
    @isTest
    static void testSaveDataNegative() {
        Test.startTest();
        try {
            SchemeLwc.saveData(null, null, null, null, null);
        } catch (AuraHandledException e) {
        }
        Test.stopTest();
    }
    
    @isTest
    static void testSaveDataMissingFields() {
        Scheme__c testScheme = [SELECT Id FROM Scheme__c LIMIT 1];
        Product__c testProduct = [SELECT Id FROM Product__c LIMIT 1];
        
        List<Buy_Product__c> buyProducts = new List<Buy_Product__c>{
            new Buy_Product__c(
                Product__c = testProduct.Id
            )
        };
        
        Test.startTest();
        try {
            SchemeLwc.saveData(buyProducts, testScheme, null, null, null);
        } catch (AuraHandledException e) {
        }
        Test.stopTest();
    }
}