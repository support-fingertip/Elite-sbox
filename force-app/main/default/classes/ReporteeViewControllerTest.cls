@isTest
public class ReporteeViewControllerTest {

    @TestSetup
    static void setup() {
        Profile tseProfile = [SELECT Id FROM Profile WHERE Name = 'TSE' LIMIT 1];
        UserRole testRole = [SELECT Id FROM UserRole LIMIT 1];

        User manager = new User(
            Alias = 'mgr1',
            Employee_Code__c = 'MGR001TEST',
            Email = 'manager.reportee.test@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Manager',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = tseProfile.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            Username = 'manager.reportee.test@example.com' + System.currentTimeMillis(),
            Sales_Channel__c = 'Cake',
            UserRoleId = testRole.Id
        );
        insert manager;

        User sub = new User(
            Alias = 'sub1',
            Employee_Code__c = 'SUB001TEST',
            Email = 'sub.reportee.test@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Subordinate',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = tseProfile.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            Username = 'sub.reportee.test@example.com' + System.currentTimeMillis(),
            Sales_Channel__c = 'Cake',
            ManagerId = manager.Id,
            UserRoleId = testRole.Id
        );
        insert sub;

        Employee__c subEmp = new Employee__c(
            Name = 'Sub Reportee',
            User__c = sub.Id,
            Is_Active__c = true,
            Role__c = 'TSE'
        );
        insert subEmp;
    }

    @isTest
    static void testGetSubordinates() {
        User manager = [SELECT Id FROM User WHERE Employee_Code__c = 'MGR001TEST' LIMIT 1];
        System.runAs(manager) {
            List<ReporteeViewController.SubordinateWrapper> subs = ReporteeViewController.getSubordinates();
            // Result may be empty in test since role hierarchy may not have subordinates
            System.assertNotEquals(null, subs, 'Should return non-null list');
        }
    }

    @isTest
    static void testGetSubordinateBeats() {
        User sub = [SELECT Id FROM User WHERE Employee_Code__c = 'SUB001TEST' LIMIT 1];
        // Create a beat for the subordinate
        Child_beat__c beat = new Child_beat__c(
            Name = 'Test Beat Reportee',
            Active__c = true,
            OwnerId = sub.Id
        );
        insert beat;

        List<ReporteeViewController.BeatWrapper> beats = ReporteeViewController.getSubordinateBeats(sub.Id);
        System.assertNotEquals(null, beats, 'Should return non-null list');
    }

    @isTest
    static void testGetSubordinateBeatOutlets() {
        User sub = [SELECT Id FROM User WHERE Employee_Code__c = 'SUB001TEST' LIMIT 1];
        Child_beat__c beat = new Child_beat__c(
            Name = 'Test Beat Outlets',
            Active__c = true,
            OwnerId = sub.Id
        );
        insert beat;

        List<Junction_Beat__c> outlets = ReporteeViewController.getSubordinateBeatOutlets(beat.Id);
        System.assertNotEquals(null, outlets, 'Should return non-null list');
    }

    @isTest
    static void testGetSubordinateBeatOutletsNullId() {
        List<Junction_Beat__c> outlets = ReporteeViewController.getSubordinateBeatOutlets(null);
        System.assertEquals(0, outlets.size(), 'Should return empty list for null beatId');
    }

    @isTest
    static void testGetSubordinateBeatsNullId() {
        List<ReporteeViewController.BeatWrapper> beats = ReporteeViewController.getSubordinateBeats(null);
        System.assertEquals(0, beats.size(), 'Should return empty list for null userId');
    }
}
