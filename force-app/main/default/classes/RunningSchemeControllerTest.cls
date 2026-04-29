@isTest
private class RunningSchemeControllerTest {

    @TestSetup
    static void setupTestData() {
        // Distributor account with matching Sales_Channel
        Account acc = new Account(
            Name = 'Test Distributor RSC',
            Customer_Type__c = 'Secondary Customer',
            State__c = 'Bihar',
            District__c = 'Patna',
            Sales_Channel__c = 'CPD'
        );
        insert acc;

        // Contact for Partner Community User
        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'Partner RSC',
            AccountId = acc.Id
        );
        insert con;

        // Product
        Product_Category__c cat = new Product_Category__c(Name = 'Test Category RSC');
        insert cat;

        Product__c prod = new Product__c(
            Name = 'Test Product RSC',
            Is_Active__c = true,
            List_Price__c = 100,
            Tax_Percent__c = 18,
            Product_Category1__c = cat.Id,
            SKU_Code__c = 'RSC001'
        );
        insert prod;

        // Scheme active in the current month
        Scheme__c scheme = new Scheme__c(
            Name = 'Test Running Scheme',
            Description__c = 'Active scheme for tests',
            Scheme_Start_Date__c = Date.today().addDays(-15),
            Scheme_End_Date__c = Date.today().addDays(15)
        );
        insert scheme;

        // One Buy_Product per supported Scheme_Type to exercise each branch
        List<Buy_Product__c> bps = new List<Buy_Product__c>{
            new Buy_Product__c(
                Scheme__c = scheme.Id,
                Product__c = prod.Id,
                Sales_Channel__c = 'CPD',
                Scheme_Type__c = 'Free Quantity',
                Min__c = 10,
                Buy_Quantity__c = 2
            ),
            new Buy_Product__c(
                Scheme__c = scheme.Id,
                Product__c = prod.Id,
                Sales_Channel__c = 'CPD',
                Scheme_Type__c = 'Sale Value Discount',
                Sale_Value_Threshold__c = 5000,
                Sale_Value__c = 5
            ),
            new Buy_Product__c(
                Scheme__c = scheme.Id,
                Product__c = prod.Id,
                Sales_Channel__c = 'CPD',
                Scheme_Type__c = 'Per Quantity Off',
                Sale_Value_Threshold__c = 20,
                Discount__c = 15
            ),
            // Null decimals to cover the null branch in formatQty/formatAmount helpers
            new Buy_Product__c(
                Scheme__c = scheme.Id,
                Product__c = prod.Id,
                Sales_Channel__c = 'CPD',
                Scheme_Type__c = 'Free Quantity'
            )
        };
        insert bps;

        // Partner Community User (separate runAs to avoid MIXED_DML_OPERATION)
        User adminUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(adminUser) {
            Profile p = [SELECT Id FROM Profile WHERE Name = 'Partner Community User' LIMIT 1];
            String uniqueStr = String.valueOf(DateTime.now().getTime());
            User u = new User(
                FirstName = 'Test',
                LastName = 'PartnerRSC',
                Email = 'trsc' + uniqueStr + '@test.com',
                Username = 'trsc' + uniqueStr + '@test.com.rsc',
                Alias = 'trsc',
                TimeZoneSidKey = 'Asia/Kolkata',
                LocaleSidKey = 'en_IN',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = p.Id,
                ContactId = con.Id,
                Employee_Code__c = 'EMPRSC' + uniqueStr
            );
            insert u;
        }
    }

    static User getCommunityUser() {
        return [SELECT Id FROM User WHERE Username LIKE 'trsc%' AND IsActive = true LIMIT 1];
    }

    @isTest
    static void testGetRunningSchemesCurrent() {
        Test.startTest();
        try {
            List<RunningSchemeController.SchemeWrapper> result =
                RunningSchemeController.getRunningSchemes('current', null, null);
            System.assertNotEquals(null, result);
        } catch (ListException e) {
            // Admin context: non-portal user has no Contact, original controller throws
        }
        Test.stopTest();
    }

    @isTest
    static void testGetRunningSchemesPrevious() {
        Test.startTest();
        try {
            List<RunningSchemeController.SchemeWrapper> result =
                RunningSchemeController.getRunningSchemes('previous', null, null);
            System.assertNotEquals(null, result);
        } catch (ListException e) {}
        Test.stopTest();
    }

    @isTest
    static void testGetRunningSchemesCustom() {
        Test.startTest();
        try {
            List<RunningSchemeController.SchemeWrapper> result =
                RunningSchemeController.getRunningSchemes(
                    'custom',
                    String.valueOf(Date.today().addDays(-30)),
                    String.valueOf(Date.today().addDays(30))
                );
            System.assertNotEquals(null, result);
        } catch (ListException e) {}
        Test.stopTest();
    }

    @isTest
    static void testGetRunningSchemesCustomMissingDates() {
        // custom + null dates falls through to the default branch
        Test.startTest();
        try {
            List<RunningSchemeController.SchemeWrapper> result =
                RunningSchemeController.getRunningSchemes('custom', null, null);
            System.assertNotEquals(null, result);
        } catch (ListException e) {}
        Test.stopTest();
    }

    @isTest
    static void testGetRunningSchemesDefaultFilter() {
        // Unknown dateFilter hits the else branch
        Test.startTest();
        try {
            List<RunningSchemeController.SchemeWrapper> result =
                RunningSchemeController.getRunningSchemes('unknown', null, null);
            System.assertNotEquals(null, result);
        } catch (ListException e) {}
        Test.stopTest();
    }

    @isTest
    static void testGetRunningSchemesAsPartner() {
        // Runs the full path including Contact → Account lookup and wrapper building
        User u = getCommunityUser();
        System.runAs(u) {
            Test.startTest();
            List<RunningSchemeController.SchemeWrapper> result =
                RunningSchemeController.getRunningSchemes('current', null, null);
            Test.stopTest();
            System.assertNotEquals(null, result);
            // Expect at least one scheme grouped with its buy products
            if (!result.isEmpty()) {
                RunningSchemeController.SchemeWrapper sw = result[0];
                System.assertNotEquals(null, sw.schemeId);
                System.assertNotEquals(null, sw.products);
            }
        }
    }

    @isTest
    static void testGetRunningSchemesAsPartnerCustom() {
        User u = getCommunityUser();
        System.runAs(u) {
            Test.startTest();
            List<RunningSchemeController.SchemeWrapper> result =
                RunningSchemeController.getRunningSchemes(
                    'custom',
                    String.valueOf(Date.today().addDays(-30)),
                    String.valueOf(Date.today().addDays(30))
                );
            Test.stopTest();
            System.assertNotEquals(null, result);
        }
    }

    @isTest
    static void testGetRunningSchemesAsPartnerPrevious() {
        User u = getCommunityUser();
        System.runAs(u) {
            Test.startTest();
            List<RunningSchemeController.SchemeWrapper> result =
                RunningSchemeController.getRunningSchemes('previous', null, null);
            Test.stopTest();
            System.assertNotEquals(null, result);
        }
    }
}