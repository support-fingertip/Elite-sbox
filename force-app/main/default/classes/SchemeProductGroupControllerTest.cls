@isTest
private class SchemeProductGroupControllerTest {

    @TestSetup
    static void setupData() {
        Product__c p1 = new Product__c(
            Name = 'SPG SKU 1', Is_Active__c = true, SKU_Code__c = 'SPG-001',
            MRP__c = 10, Net_Weight__c = 25
        );
        Product__c p2 = new Product__c(
            Name = 'SPG SKU 2', Is_Active__c = true, SKU_Code__c = 'SPG-002',
            MRP__c = 10, Net_Weight__c = 25
        );
        Product__c p3 = new Product__c(
            Name = 'SPG SKU 3', Is_Active__c = true, SKU_Code__c = 'SPG-003',
            MRP__c = 20, Net_Weight__c = 50
        );
        insert new List<Product__c>{ p1, p2, p3 };

        insert new List<Sales_Channel_To_SKU__c>{
            new Sales_Channel_To_SKU__c(Sales_Channel__c = 'Cake', SKU__c = p1.Id),
            new Sales_Channel_To_SKU__c(Sales_Channel__c = 'Cake', SKU__c = p2.Id),
            new Sales_Channel_To_SKU__c(Sales_Channel__c = 'Cake', SKU__c = p3.Id)
        };
    }

    private static SchemeProductGroupController.GroupHeader buildHeader(
        String label, String channel, String purpose, Decimal mrp, Decimal weight
    ) {
        SchemeProductGroupController.GroupHeader h = new SchemeProductGroupController.GroupHeader();
        h.groupLabel   = label;
        h.salesChannel = channel;
        h.groupPurpose = purpose;
        h.mrp          = mrp;
        h.netWeight    = weight;
        h.description  = 'unit test';
        h.isActive     = true;
        return h;
    }

    @isTest
    static void picklistsReturnsAll() {
        Test.startTest();
        SchemeProductGroupController.BuilderPicklists pl = SchemeProductGroupController.getPicklists();
        Test.stopTest();
        System.assertNotEquals(null, pl);
        System.assertNotEquals(null, pl.salesChannels);
        System.assertNotEquals(null, pl.groupPurposes);
        System.assertNotEquals(null, pl.categories);
        System.assertNotEquals(null, pl.productGroups);
        System.assertNotEquals(null, pl.productSubGroups);
        System.assertNotEquals(null, pl.varients);
    }

    @isTest
    static void getSkusReturnsChannelMatches() {
        Test.startTest();
        List<SchemeProductGroupController.SkuRow> rows =
            SchemeProductGroupController.getSkusForChannel('Cake');
        Test.stopTest();
        System.assertEquals(3, rows.size());
    }

    @isTest
    static void getSkusEmptyWhenChannelBlank() {
        List<SchemeProductGroupController.SkuRow> rows =
            SchemeProductGroupController.getSkusForChannel('');
        System.assertEquals(0, rows.size());
    }

    @isTest
    static void saveCreatesParentAndItems() {
        List<Product__c> prods = [SELECT Id FROM Product__c WHERE MRP__c = 10];
        List<Id> ids = new List<Id>();
        for (Product__c p : prods) ids.add(p.Id);

        Test.startTest();
        Id groupId = SchemeProductGroupController.saveGroup(
            buildHeader('Cake-25g-MRP10', 'Cake', 'Price_Division', 10, 25),
            ids,
            null
        );
        Test.stopTest();

        System.assertNotEquals(null, groupId);
        System.assertEquals(
            2,
            [SELECT COUNT() FROM Scheme_Product_Group_Item__c WHERE Scheme_Product_Group__c = :groupId]
        );
    }

    @isTest
    static void priceDivisionRejectsMixedMrp() {
        List<Product__c> prods = [SELECT Id FROM Product__c];
        List<Id> ids = new List<Id>();
        for (Product__c p : prods) ids.add(p.Id);

        Boolean threw = false;
        try {
            SchemeProductGroupController.saveGroup(
                buildHeader('Mixed', 'Cake', 'Price_Division', 10, 25),
                ids,
                null
            );
        } catch (AuraHandledException e) {
            threw = true;
        }
        System.assert(threw, 'Mixed MRP should have thrown');
    }

    @isTest
    static void focQualifierAllowsMixed() {
        List<Product__c> prods = [SELECT Id FROM Product__c];
        List<Id> ids = new List<Id>();
        for (Product__c p : prods) ids.add(p.Id);

        Test.startTest();
        Id groupId = SchemeProductGroupController.saveGroup(
            buildHeader('FOC Pool', 'Cake', 'FOC_Qualifier', null, null),
            ids,
            null
        );
        Test.stopTest();
        System.assertNotEquals(null, groupId);
        System.assertEquals(
            3,
            [SELECT COUNT() FROM Scheme_Product_Group_Item__c WHERE Scheme_Product_Group__c = :groupId]
        );
    }

    @isTest
    static void saveRejectsDuplicateProductIds() {
        Product__c p = [SELECT Id FROM Product__c WHERE MRP__c = 10 LIMIT 1];
        Boolean threw = false;
        try {
            SchemeProductGroupController.saveGroup(
                buildHeader('Dup', 'Cake', 'FOC_Qualifier', null, null),
                new List<Id>{ p.Id, p.Id },
                null
            );
        } catch (AuraHandledException e) {
            threw = true;
        }
        System.assert(threw, 'Duplicate product Ids should have thrown');
    }

    @isTest
    static void saveRejectsCrossGroupConflict() {
        Product__c p = [SELECT Id FROM Product__c WHERE MRP__c = 10 LIMIT 1];
        SchemeProductGroupController.saveGroup(
            buildHeader('First', 'Cake', 'FOC_Qualifier', null, null),
            new List<Id>{ p.Id },
            null
        );
        Boolean threw = false;
        try {
            SchemeProductGroupController.saveGroup(
                buildHeader('Second', 'Cake', 'FOC_Qualifier', null, null),
                new List<Id>{ p.Id },
                null
            );
        } catch (AuraHandledException e) {
            threw = true;
        }
        System.assert(threw, 'Cross-group conflict should have thrown');
    }

    @isTest
    static void editRewritesItems() {
        List<Product__c> prods = [SELECT Id FROM Product__c WHERE MRP__c = 10];
        List<Id> originalIds = new List<Id>();
        for (Product__c p : prods) originalIds.add(p.Id);

        Id groupId = SchemeProductGroupController.saveGroup(
            buildHeader('Editable', 'Cake', 'FOC_Qualifier', null, null),
            originalIds,
            null
        );

        Product__c other = [SELECT Id FROM Product__c WHERE MRP__c = 20 LIMIT 1];
        Test.startTest();
        SchemeProductGroupController.saveGroup(
            buildHeader('Editable', 'Cake', 'FOC_Qualifier', null, null),
            new List<Id>{ other.Id },
            groupId
        );
        Test.stopTest();

        List<Scheme_Product_Group_Item__c> items = [
            SELECT Product__c FROM Scheme_Product_Group_Item__c WHERE Scheme_Product_Group__c = :groupId
        ];
        System.assertEquals(1, items.size());
        System.assertEquals(other.Id, items[0].Product__c);
    }

    @isTest
    static void loadGroupReturnsHeaderAndIds() {
        Product__c p = [SELECT Id FROM Product__c WHERE MRP__c = 10 LIMIT 1];
        Id groupId = SchemeProductGroupController.saveGroup(
            buildHeader('LoadMe', 'Cake', 'FOC_Qualifier', null, null),
            new List<Id>{ p.Id },
            null
        );

        Test.startTest();
        SchemeProductGroupController.LoadGroupResult res =
            SchemeProductGroupController.loadGroup(groupId);
        Test.stopTest();

        System.assertEquals(groupId, res.id);
        System.assertEquals('LoadMe', res.header.groupLabel);
        System.assertEquals('Cake', res.header.salesChannel);
        System.assertEquals(1, res.productIds.size());
        System.assertEquals(p.Id, res.productIds[0]);
    }

    @isTest
    static void getConflictingProductIdsExcludesSelf() {
        Product__c p = [SELECT Id FROM Product__c WHERE MRP__c = 10 LIMIT 1];
        Id groupId = SchemeProductGroupController.saveGroup(
            buildHeader('Self', 'Cake', 'FOC_Qualifier', null, null),
            new List<Id>{ p.Id },
            null
        );

        Test.startTest();
        List<SchemeProductGroupController.ConflictRow> conflicts =
            SchemeProductGroupController.getConflictingProductIds(
                'Cake', new List<Id>{ p.Id }, groupId
            );
        Test.stopTest();

        System.assertEquals(0, conflicts.size(), 'Self group should be excluded');
    }
}
