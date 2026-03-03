@isTest
public class ReporteeViewControllerTest {

    @TestSetup
    static void setup() {
        UserRole testRole = [SELECT Id FROM UserRole LIMIT 1];
        Profile tseProfile = [SELECT Id FROM Profile WHERE Name = 'TSE' LIMIT 1];

        User manager = new User(
            Alias = 'mgr1',
            Email = 'reporteemanager@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Manager',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = tseProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'reporteemanager@test.com' + System.currentTimeMillis(),
            UserRoleId = testRole.Id,
            Sales_Channel__c = 'Cake',
            Employee_Code__c = 'RPM001'
        );
        insert manager;

        User subordinate = new User(
            Alias = 'sub1',
            Email = 'reporteesub@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Subordinate',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = tseProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'reporteesub@test.com' + System.currentTimeMillis(),
            UserRoleId = testRole.Id,
            ManagerId = manager.Id,
            Sales_Channel__c = 'Cake',
            Employee_Code__c = 'RPS001'
        );
        insert subordinate;

        Employee__c emp = new Employee__c(
            User__c = subordinate.Id,
            Is_Active__c = true
        );
        insert emp;
    }

    @isTest
    static void testGetSubordinates() {
        User manager = [SELECT Id FROM User WHERE Email = 'reporteemanager@test.com' LIMIT 1];
        Test.startTest();
        System.runAs(manager) {
            List<ReporteeViewController.SubordinateWrapper> subs = ReporteeViewController.getSubordinates();
            System.assertNotEquals(null, subs);
        }
        Test.stopTest();
    }

    @isTest
    static void testGetSubordinateBeats() {
        User subordinate = [SELECT Id FROM User WHERE Email = 'reporteesub@test.com' LIMIT 1];
        Account primaryCustomer = new Account(Name = 'Test Primary Customer');
        insert primaryCustomer;

        Child_beat__c beat = new Child_beat__c(
            Name = 'Test Beat',
            OwnerId = subordinate.Id,
            Active__c = true,
            Primary_Customer__c = primaryCustomer.Id
        );
        insert beat;

        Test.startTest();
        List<ReporteeViewController.BeatWrapper> beats = ReporteeViewController.getSubordinateBeats(subordinate.Id);
        System.assertNotEquals(null, beats);
        System.assertEquals(1, beats.size());
        Test.stopTest();
    }

    @isTest
    static void testGetSubordinatesNoSubordinates() {
        User subordinate = [SELECT Id FROM User WHERE Email = 'reporteesub@test.com' LIMIT 1];
        Test.startTest();
        System.runAs(subordinate) {
            List<ReporteeViewController.SubordinateWrapper> subs = ReporteeViewController.getSubordinates();
            System.assertNotEquals(null, subs);
        }
        Test.stopTest();
    }
}
