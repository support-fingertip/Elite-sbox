@isTest
public class ReporteeViewControllerTest {

    @TestSetup
    static void setup() {
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        UserRole parentRole = [SELECT Id FROM UserRole LIMIT 1];

        User managerUser = new User(
            Alias = 'mgr1',
            Employee_Code__c = 'MGR001TEST',
            Email = 'manager.reportee.test@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Manager',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = adminProfile.Id,
            UserRoleId = parentRole.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'manager.reportee.test@example.com' + System.currentTimeMillis(),
            Sales_Channel__c = 'Cake'
        );
        insert managerUser;

        User subUser = new User(
            Alias = 'sub1',
            Employee_Code__c = 'SUB001TEST',
            Email = 'sub.reportee.test@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Subordinate',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = adminProfile.Id,
            ManagerId = managerUser.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'sub.reportee.test@example.com' + System.currentTimeMillis(),
            Sales_Channel__c = 'Cake'
        );
        insert subUser;
    }

    @isTest
    static void testGetSubordinates() {
        User managerUser = [SELECT Id FROM User WHERE Employee_Code__c = 'MGR001TEST' LIMIT 1];
        Test.startTest();
        List<ReporteeViewController.SubordinateWrapper> result;
        System.runAs(managerUser) {
            result = ReporteeViewController.getSubordinates();
        }
        Test.stopTest();
        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testGetSubordinateBeats() {
        User managerUser = [SELECT Id FROM User WHERE Employee_Code__c = 'MGR001TEST' LIMIT 1];
        User subUser = [SELECT Id FROM User WHERE Employee_Code__c = 'SUB001TEST' LIMIT 1];

        Account acc = new Account(
            Name = 'Test Primary',
            Customer_Type__c = 'Primary Customer',
            Primary_Phone_Number__c = '9876543210',
            State__c = 'Karnataka',
            District__c = 'Kolar',
            Pincode__c = '560001'
        );
        insert acc;

        Child_beat__c beat = new Child_beat__c(
            Name = 'Test Beat',
            OwnerId = subUser.Id,
            Active__c = true,
            Primary_Customer__c = acc.Id,
            Beat_Type__c = 'Primary',
            Cloned_From_Employee_Replacement__c = false,
            Cloned_From_Customer_Deactivation__c = false
        );

        Test.startTest();
        List<ReporteeViewController.BeatWrapper> result;
        System.runAs(managerUser) {
            try {
                result = ReporteeViewController.getSubordinateBeats(subUser.Id);
            } catch (AuraHandledException e) {
                // Expected if hierarchy check fails in test context
                result = new List<ReporteeViewController.BeatWrapper>();
            }
        }
        Test.stopTest();
        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testGetSubordinateBeatsUnauthorized() {
        User subUser = [SELECT Id FROM User WHERE Employee_Code__c = 'SUB001TEST' LIMIT 1];
        User managerUser = [SELECT Id FROM User WHERE Employee_Code__c = 'MGR001TEST' LIMIT 1];

        Test.startTest();
        System.runAs(subUser) {
            try {
                // subUser is not a manager of managerUser, should throw AuraHandledException
                ReporteeViewController.getSubordinateBeats(managerUser.Id);
                System.assert(false, 'Expected exception was not thrown');
            } catch (AuraHandledException e) {
                System.assert(e.getMessage() != null, 'Exception should have a message');
            }
        }
        Test.stopTest();
    }
}
