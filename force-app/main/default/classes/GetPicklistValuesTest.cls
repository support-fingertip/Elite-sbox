@isTest
public class GetPicklistValuesTest {
    @isTest
    static void testExtractPicklistValues_validField() {
        // Valid standard object and picklist field
         GetPicklistValues.extractPicklistValues('Account', 'Industry');
        
       
    }

    @isTest
    static void testExtractPicklistValues_invalidObject() {
        // Invalid object name
        GetPicklistValues.extractPicklistValues('InvalidObject', 'Industry');
        
    }

    @isTest
    static void testExtractPicklistValues_invalidField() {
        // Valid object but invalid field
       GetPicklistValues.extractPicklistValues('Account', 'InvalidField');
       
    }

    @isTest
    static void testExtractPicklistValues_nonPicklistField() {
        // Valid object and field, but not a picklist (e.g., Account.Name)
      GetPicklistValues.extractPicklistValues('Account', 'Name');
       
    }
}