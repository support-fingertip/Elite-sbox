@IsTest
private class AccountEditAccessControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test profiles
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        // Create test users
        User adminUser = new User(
            Alias = 'admin',
            Email = 'adminuser@testorg.com',
              Employee_Code__c = '8811145535',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = adminProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'adminuser5523@testorg.com'
        );
        
       
        
        User standardUser = new User(
            Alias = 'stduser',
            Email = 'standarduser@testorg.com',
            Employee_Code__c = '8866445535',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'standarduser7723@testorg.com'
        );
        
        insert new List<User>{adminUser, standardUser};
    }
    
    @IsTest
    static void testGetEditPermissionForAdmin() {
        User adminUser = [SELECT Id FROM User WHERE UserName = 'adminuser5523@testorg.com' LIMIT 1];
        
        Test.startTest();
        Boolean result = AccountEditAccessController.getEditPermission(adminUser.Id);
        Test.stopTest();
        
    }
    
   
    
    @IsTest
    static void testGetEditPermissionForStandardUser() {
        User standardUser = [SELECT Id FROM User WHERE UserName = 'standarduser7723@testorg.com' LIMIT 1];
        
        Test.startTest();
        Boolean result = AccountEditAccessController.getEditPermission(standardUser.Id);
        Test.stopTest();
        
    }
    
    @IsTest
    static void testGetEditPermissionWithInvalidUserId() {
        // Test with a non-existent user ID
        Id fakeUserId = '005000000000000'; // Invalid format but correct length
        
        Test.startTest();
        try {
            Boolean result = AccountEditAccessController.getEditPermission(fakeUserId);
        } catch (Exception e) {
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testGetEditPermissionWithNullUserId() {
        Test.startTest();
        try {
            Boolean result = AccountEditAccessController.getEditPermission(null);
        } catch (Exception e) {
        }
        Test.stopTest();
    }
}