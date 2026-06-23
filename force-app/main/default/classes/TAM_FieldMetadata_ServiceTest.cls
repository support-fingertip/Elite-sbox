/**
 * Smoke + structural coverage for TAM_FieldMetadata_Service.
 *
 * The service has a single @AuraEnabled entry point (getFields) used by the
 * tamCriteriaBuilder LWC to populate Object / Field / User-Field pickers.
 * It walks Schema.describe results for the requested SObject and returns a
 * FieldInfo list. The tests below exercise the happy path against the
 * standard Account object so the call hits every branch (numeric / date /
 * user-reference / picklist) without depending on org-specific custom data.
 */
@isTest
public class TAM_FieldMetadata_ServiceTest {

    @isTest
    static void getFieldsReturnsKnownAccountFields() {
        Test.startTest();
        List<TAM_FieldMetadata_Service.FieldInfo> fields =
            TAM_FieldMetadata_Service.getFields('Account');
        Test.stopTest();

        System.assertNotEquals(null, fields);
        System.assert(!fields.isEmpty(), 'Account has fields');

        // Account always has Name (text), CreatedDate (datetime) and OwnerId
        // (lookup to User) — verify the service surfaces them, including the
        // isUserField flag for OwnerId.
        Map<String, TAM_FieldMetadata_Service.FieldInfo> byApi = new Map<String, TAM_FieldMetadata_Service.FieldInfo>();
        for (TAM_FieldMetadata_Service.FieldInfo fi : fields) byApi.put(fi.apiName, fi);

        // Field map keys are lowercase, so look them up that way.
        TAM_FieldMetadata_Service.FieldInfo name = lookupCaseInsensitive(byApi, 'Name');
        TAM_FieldMetadata_Service.FieldInfo createdDate = lookupCaseInsensitive(byApi, 'CreatedDate');
        TAM_FieldMetadata_Service.FieldInfo ownerId = lookupCaseInsensitive(byApi, 'OwnerId');

        System.assertNotEquals(null, name, 'Name field should be present');
        System.assertNotEquals(null, createdDate, 'CreatedDate should be present');
        System.assertNotEquals(null, ownerId, 'OwnerId should be present');
        System.assertEquals(true, ownerId.isUserField,
            'OwnerId is a reference to User and should be flagged as a User field');
    }

    @isTest
    static void getFieldsHandlesUnknownObjectGracefully() {
        Test.startTest();
        Boolean threw = false;
        List<TAM_FieldMetadata_Service.FieldInfo> result = null;
        try {
            result = TAM_FieldMetadata_Service.getFields('No_Such_Object__c');
        } catch (Exception ex) {
            // The service may throw when the global describe doesn't know the
            // name; either contract (null/empty list OR a thrown exception)
            // is acceptable — the test exists to lock the call shape and
            // ensure the entry point is exercised for coverage.
            threw = true;
        }
        Test.stopTest();
        System.assert(threw || result == null || result.isEmpty(),
            'unknown object should return empty / null OR throw — got: ' + result);
    }

    private static TAM_FieldMetadata_Service.FieldInfo lookupCaseInsensitive(
        Map<String, TAM_FieldMetadata_Service.FieldInfo> byApi, String name
    ) {
        if (byApi.containsKey(name)) return byApi.get(name);
        String lower = name.toLowerCase();
        for (String k : byApi.keySet()) {
            if (k != null && k.toLowerCase() == lower) return byApi.get(k);
        }
        return null;
    }
}