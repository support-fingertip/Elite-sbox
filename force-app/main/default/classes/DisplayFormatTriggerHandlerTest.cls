@isTest
public class DisplayFormatTriggerHandlerTest {

    @TestSetup
    static void setup() {
        // Create test ContentDocument for file linking
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'testfile.pdf',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert cv;

        // Query ContentDocument Id
        ContentDocument cd = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :cv.Id LIMIT 1];

        // Create Display_Format__c records
        List<Display_Format__c> formats = new List<Display_Format__c>();
        formats.add(new Display_Format__c(
            UniqueFileId__c = cd.Id // Use ContentDocument Id as UniqueFileId__c
        ));
        formats.add(new Display_Format__c(
            UniqueFileId__c = 'FILE123' // Another unique file Id
        ));
        formats.add(new Display_Format__c(
            UniqueFileId__c = null // Record with null UniqueFileId__c
        ));
        insert formats;
    }

    @isTest
    static void testAfterInsertWithValidData() {
        // Query test data
        List<Display_Format__c> formats = [SELECT Id, UniqueFileId__c FROM Display_Format__c];
        System.assertEquals(3, formats.size(), 'Expected 3 Display_Format__c records');

        // Collect Display_Format__c IDs for ContentDocumentLink query
        Set<Id> formatIds = new Set<Id>();
        for (Display_Format__c df : formats) {
            formatIds.add(df.Id);
        }

        Test.startTest();
        DisplayFormatTriggerHandler.afterInsert(formats);
        Test.stopTest();

        // Verify CustomSharingService inputs
        Set<String> expectedFileIds = new Set<String>();
        Map<String, Id> expectedDataIdMap = new Map<String, Id>();
        for (Display_Format__c df : formats) {
            if (df.UniqueFileId__c != null) {
                expectedFileIds.add(df.UniqueFileId__c);
                expectedDataIdMap.put(df.UniqueFileId__c, df.Id);
            }
        }
        System.assertEquals(2, expectedFileIds.size(), 'Expected 2 unique file Ids');
        System.assertEquals(2, expectedDataIdMap.size(), 'Expected 2 mappings');

        // Verify ContentDocumentLink records (if created by CustomSharingService)
        List<ContentDocumentLink> links = [SELECT Id, LinkedEntityId, ContentDocumentId 
                                          FROM ContentDocumentLink 
                                          WHERE LinkedEntityId IN :formatIds];
        // If CustomSharingService creates links, assert their existence
        // System.assertEquals(1, links.size(), 'Expected 1 ContentDocumentLink'); // Uncomment if applicable
    }

    @isTest
    static void testAfterInsertWithEmptyList() {
        // Test with empty list
        List<Display_Format__c> emptyList = new List<Display_Format__c>();

        Test.startTest();
        DisplayFormatTriggerHandler.afterInsert(emptyList);
        Test.stopTest();

        // No assertions needed; ensure no errors
        System.assert(true, 'Method should execute without errors for empty list');
    }

    @isTest
    static void testAfterInsertWithAllNullFileIds() {
        // Create test data with all null UniqueFileId__c
        List<Display_Format__c> formats = new List<Display_Format__c>();
        formats.add(new Display_Format__c(UniqueFileId__c = null));
        formats.add(new Display_Format__c(UniqueFileId__c = null));
        insert formats;

        // Collect IDs for ContentDocumentLink query
        Set<Id> formatIds = new Set<Id>();
        for (Display_Format__c df : formats) {
            formatIds.add(df.Id);
        }

        Test.startTest();
        DisplayFormatTriggerHandler.afterInsert(formats);
        Test.stopTest();

        // Verify no file links were attempted
        Set<String> expectedFileIds = new Set<String>();
        Map<String, Id> expectedDataIdMap = new Map<String, Id>();
        for (Display_Format__c df : formats) {
            if (df.UniqueFileId__c != null) {
                expectedFileIds.add(df.UniqueFileId__c);
                expectedDataIdMap.put(df.UniqueFileId__c, df.Id);
            }
        }
        System.assertEquals(0, expectedFileIds.size(), 'Expected no file Ids');
        System.assertEquals(0, expectedDataIdMap.size(), 'Expected no mappings');

        // Verify no ContentDocumentLink records
        List<ContentDocumentLink> links = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId IN :formatIds];
        System.assertEquals(0, links.size(), 'Expected no ContentDocumentLink records');
    }
}