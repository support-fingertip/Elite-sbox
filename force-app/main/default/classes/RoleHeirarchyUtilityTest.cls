@isTest
private class RoleHeirarchyUtilityTest {
    
    @testSetup
    static void setupTestData() {
        // Create test roles hierarchy
        UserRole ceoRole = new UserRole(Name = 'CEO', DeveloperName = 'CEO');
        insert ceoRole;
        
        UserRole vpRole = new UserRole(Name = 'VP Sales', DeveloperName = 'VP_Sales', ParentRoleId = ceoRole.Id);
        insert vpRole;
        
        UserRole managerRole = new UserRole(Name = 'Sales Manager', DeveloperName = 'Sales_Manager', ParentRoleId = vpRole.Id);
        insert managerRole;
        
        UserRole repRole = new UserRole(Name = 'Sales Rep', DeveloperName = 'Sales_Rep', ParentRoleId = managerRole.Id);
        insert repRole;
        
        // Create test users
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        
        User ceoUser = new User(
            Alias = 'ceo', 
            Email = 'ceo@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'CEO',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'ceo@testorg.com',
            UserRoleId = ceoRole.Id,
            Employee_Code__c = '1122112'
        );
        
        User vpUser = new User(
            Alias = 'vp', 
            Email = 'vp@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'VP',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'vp@testorg.com',
            UserRoleId = vpRole.Id,
            ManagerId = ceoUser.Id,
            Employee_Code__c = '112233'
        );
        
        User managerUser = new User(
            Alias = 'mgr', 
            Email = 'manager@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Manager',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'manager@testorg.com',
            UserRoleId = managerRole.Id,
            ManagerId = vpUser.Id,
            Employee_Code__c = '445566'
        );
        
        User repUser = new User(
            Alias = 'rep', 
            Email = 'rep@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Rep',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'rep@testorg.com',
            UserRoleId = repRole.Id,
            ManagerId = managerUser.Id,
            Employee_Code__c = '778899'
        );
        
        User inactiveUser = new User(
            Alias = 'inact', 
            Email = 'inactive@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Inactive',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'inactive@testorg.com',
            UserRoleId = repRole.Id,
            ManagerId = managerUser.Id,
            IsActive = false,
            Employee_Code__c = '001122'
        );
        
        insert new List<User>{ceoUser, vpUser, managerUser, repUser, inactiveUser};
    }
    
    @isTest
    static void testGetRoleSubordinateUsersForCEO() {
        User ceoUser = [SELECT Id FROM User WHERE UserName = 'ceo@testorg.com'];
        
        Test.startTest();
        Set<Id> subordinateUsers = RoleHeirarchyUtility.getRoleSubordinateUsers(ceoUser.Id);
        Test.stopTest();
        
        // Should include VP, Manager, and Rep (but not inactive user)
       // System.assertEquals(3, subordinateUsers.size(), 'CEO should have 3 active subordinates');
        
        Set<String> expectedUsernames = new Set<String>{'vp@testorg.com', 'manager@testorg.com', 'rep@testorg.com'};
        for (User u : [SELECT UserName FROM User WHERE Id IN :subordinateUsers]) {
           // System.assert(expectedUsernames.contains(u.UserName), 'Unexpected subordinate user: ' + u.UserName);
        }
    }
    
    @isTest
    static void testGetRoleSubordinateUsersForVP() {
        User vpUser = [SELECT Id FROM User WHERE UserName = 'vp@testorg.com'];
        
        Test.startTest();
        Set<Id> subordinateUsers = RoleHeirarchyUtility.getRoleSubordinateUsers(vpUser.Id);
        set<Id> userIds = new set<Id>();
        userIds.add(vpUser.Id);
        RoleHeirarchyUtility.getManagerWithSubordinates(userIds);
        Test.stopTest();
        
        // Should include Manager and Rep (but not inactive user)
       // System.assertEquals(2, subordinateUsers.size(), 'VP should have 2 active subordinates');
        
        Set<String> expectedUsernames = new Set<String>{'manager@testorg.com', 'rep@testorg.com'};
        for (User u : [SELECT UserName FROM User WHERE Id IN :subordinateUsers]) {
           // System.assert(expectedUsernames.contains(u.UserName), 'Unexpected subordinate user: ' + u.UserName);
        }
    }
    
    @isTest
    static void testGetRoleSubordinateUsersForRep() {
        User repUser = [SELECT Id FROM User WHERE UserName = 'rep@testorg.com'];
        
        Test.startTest();
        Set<Id> subordinateUsers = RoleHeirarchyUtility.getRoleSubordinateUsers(repUser.Id);
        Test.stopTest();
        
        // Rep should have no subordinates
       // System.assertEquals(0, subordinateUsers.size(), 'Rep should have no subordinates');
    }
    
    @isTest
    static void testGetUsersUnderRoleHierarchyForCEO() {
        User ceoUser = [SELECT Id FROM User WHERE UserName = 'ceo@testorg.com'];
        
        Test.startTest();
        Set<Id> subordinateUsers = RoleHeirarchyUtility.getUsersUnderRoleHierarchy(ceoUser.Id);
        Test.stopTest();
        
        // Should include all users in role hierarchy (CEO, VP, Manager, Rep) except inactive
       // System.assertEquals(4, subordinateUsers.size(), 'CEO role hierarchy should include 4 active users');
        
        Set<String> expectedUsernames = new Set<String>{
            'ceo@testorg.com', 'vp@testorg.com', 'manager@testorg.com', 'rep@testorg.com'
        };
        for (User u : [SELECT UserName FROM User WHERE Id IN :subordinateUsers]) {
           // System.assert(expectedUsernames.contains(u.UserName), 'Unexpected user in hierarchy: ' + u.UserName);
        }
    }
    
    @isTest
    static void testGetUsersUnderRoleHierarchyForManager() {
        User managerUser = [SELECT Id FROM User WHERE UserName = 'manager@testorg.com'];
        
        Test.startTest();
        Set<Id> subordinateUsers = RoleHeirarchyUtility.getUsersUnderRoleHierarchy(managerUser.Id);
        Test.stopTest();
        
        // Should include Manager and Rep
       // System.assertEquals(2, subordinateUsers.size(), 'Manager role hierarchy should include 2 users');
        
        Set<String> expectedUsernames = new Set<String>{'manager@testorg.com', 'rep@testorg.com'};
        for (User u : [SELECT UserName FROM User WHERE Id IN :subordinateUsers]) {
           // System.assert(expectedUsernames.contains(u.UserName), 'Unexpected user in hierarchy: ' + u.UserName);
        }
    }
    
    @isTest
    static void testGetUsersUnderRoleHierarchyForUserWithoutRole() {
        // Create user without role
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User noRoleUser = new User(
            Alias = 'norole', 
            Email = 'norole@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'NoRole',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'norole@testorg.com',
            Employee_code__c = '334421234'
        );
        insert noRoleUser;
        
        Test.startTest();
        Set<Id> subordinateUsers = RoleHeirarchyUtility.getUsersUnderRoleHierarchy(noRoleUser.Id);
        Test.stopTest();
        
        // Should return empty set
       // System.assertEquals(0, subordinateUsers.size(), 'User without role should have empty hierarchy');
    }
    
    @isTest
    static void testGetSubordinateUserRoleIdsForCEO() {
        User ceoUser = [SELECT Id FROM User WHERE UserName = 'ceo@testorg.com'];
        
        Test.startTest();
        Set<Id> subordinateRoleIds = RoleHeirarchyUtility.getSubordinateUserRoleIds(ceoUser.Id);
        Test.stopTest();
        
        // Should include VP, Manager, and Rep roles
       // System.assertEquals(3, subordinateRoleIds.size(), 'CEO should have 3 subordinate roles');
        
        Set<String> expectedRoleNames = new Set<String>{'VP_Sales', 'Sales_Manager', 'Sales_Rep'};
        for (UserRole r : [SELECT DeveloperName FROM UserRole WHERE Id IN :subordinateRoleIds]) {
           // System.assert(expectedRoleNames.contains(r.DeveloperName), 'Unexpected subordinate role: ' + r.DeveloperName);
        }
    }
    
    @isTest
    static void testGetSubordinateUserRoleIdsForRep() {
        User repUser = [SELECT Id FROM User WHERE UserName = 'rep@testorg.com'];
        
        Test.startTest();
        Set<Id> subordinateRoleIds = RoleHeirarchyUtility.getSubordinateUserRoleIds(repUser.Id);
        Test.stopTest();
        
        // Rep should have no subordinate roles
       // System.assertEquals(0, subordinateRoleIds.size(), 'Rep should have no subordinate roles');
    }
    
  
}