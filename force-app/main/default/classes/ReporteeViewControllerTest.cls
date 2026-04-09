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

        // Use System.runAs() to avoid MIXED_DML_OPERATION error
        System.runAs(sub) {
            Employee__c subEmp = new Employee__c(
                Name = 'Sub Reportee',
                Mail_Id__c = 'sub.reportee.test@example.com',
                User_Name__c = 'sub.reportee.test@example.com.testuser',
                Primary_Phone_Number__c = '9876543210',
                Employee_Code__c = 'SUB001TEST',
                Designation__c = 'TSE',
                Profile__c = 'TSE',
                Role_Id__c = testRole.Id,
                Is_Active__c = true,
                Basic_Pay__c = 25000,
                Aadhar_Number__c = '123456789012',
                Gross_Salary__c = 35000,
                DA__c = 5000,
                TA_limit__c = 2000,
                Area__c = 'Central',
                Region__c = 'West',
                ASM_TSM__c = manager.Id,
                RSM__c = manager.Id,
                Employee_Approver_3_HR__c = manager.Id,
                Secondary_Customer_Approver_1__c = manager.Id,
                Secondary_Customer_Approver_2__c = manager.Id,
                Primary_Customer_Approver_1__c = manager.Id,
                Primary_Customer_Approver_2__c = manager.Id,
                Primary_Customer_Approver_3_CD__c = manager.Id,
                PJP_Approver_1__c = manager.Id,
                PJP_Approver_2__c = manager.Id,
                Expense_Approver_1__c = manager.Id,
                Expense_Approver_2_Finance_Department__c = manager.Id,
                Sales_Channel__c = 'Cake',
                State__c = 'Uttar Pradesh',
                District__c = 'Lucknow',
                Pincode__c = '226001',
                User__c = sub.Id,
                Cloning_is_Completed__c = false,
                Role__c = 'TSE'
            );
            insert subEmp;
        }
    }

    @isTest
    static void testGetSubordinates() {
        User manager = [SELECT Id FROM User WHERE Employee_Code__c = 'MGR001TEST' LIMIT 1];
        System.runAs(manager) {
            List<ReporteeViewController.SubordinateWrapper> subs = ReporteeViewController.getSubordinates();
            System.assertNotEquals(null, subs, 'Should return non-null list');
        }
    }

    @isTest
    static void testGetSubordinatesAsSubordinate() {
        User sub = [SELECT Id FROM User WHERE Employee_Code__c = 'SUB001TEST' LIMIT 1];
        System.runAs(sub) {
            List<ReporteeViewController.SubordinateWrapper> subs = ReporteeViewController.getSubordinates();
            System.assertNotEquals(null, subs, 'Should return non-null list even with no direct reports');
        }
    }

    @isTest
    static void testGetSubordinateBeats() {
        User sub = [SELECT Id FROM User WHERE Employee_Code__c = 'SUB001TEST' LIMIT 1];

        Child_beat__c beat = new Child_beat__c(
            Name = 'Test Beat Reportee',
            Active__c = true,
            OwnerId = sub.Id,
            Beat_Type__c = 'Secondary'
        );
        insert beat;

        List<ReporteeViewController.BeatWrapper> beats = ReporteeViewController.getSubordinateBeats(sub.Id);
        System.assertNotEquals(null, beats, 'Should return non-null list');
        System.assert(beats.size() >= 1, 'Should return at least one beat for the subordinate');
    }

    @isTest
    static void testGetSubordinateBeatsNullId() {
        List<ReporteeViewController.BeatWrapper> beats = ReporteeViewController.getSubordinateBeats(null);
        System.assertNotEquals(null, beats, 'Should return non-null list for null userId');
        System.assertEquals(0, beats.size(), 'Should return empty list for null userId');
    }

    @isTest
    static void testGetSubordinateBeatOutlets() {
        User sub = [SELECT Id FROM User WHERE Employee_Code__c = 'SUB001TEST' LIMIT 1];

        Child_beat__c beat = new Child_beat__c(
            Name = 'Test Beat Outlets',
            Active__c = true,
            Beat_Type__c ='Secondary',
            OwnerId = sub.Id
        );
        insert beat;

        List<Junction_Beat__c> outlets = ReporteeViewController.getSubordinateBeatOutlets(beat.Id);
        System.assertNotEquals(null, outlets, 'Should return non-null list');
    }

    @isTest
    static void testGetSubordinateBeatOutletsWithData() {
        User sub = [SELECT Id FROM User WHERE Employee_Code__c = 'SUB001TEST' LIMIT 1];

        Child_beat__c beat = new Child_beat__c(
            Name = 'Test Beat With Outlets',
            Active__c = true,
            Beat_Type__c ='Secondary',
            OwnerId = sub.Id
        );
        insert beat;

        Junction_Beat__c junction = new Junction_Beat__c(
            Child_Beat__c = beat.Id
        );
        insert junction;

        List<Junction_Beat__c> outlets = ReporteeViewController.getSubordinateBeatOutlets(beat.Id);
        System.assertNotEquals(null, outlets, 'Should return non-null list');
        System.assert(outlets.size() >= 1, 'Should return at least one outlet for the beat');
    }

    @isTest
    static void testGetSubordinateBeatOutletsNullId() {
        List<Junction_Beat__c> outlets = ReporteeViewController.getSubordinateBeatOutlets(null);
        System.assertNotEquals(null, outlets, 'Should return non-null list for null beatId');
        System.assertEquals(0, outlets.size(), 'Should return empty list for null beatId');
    }

    @isTest
    static void testGetSubordinatesReturnsListType() {
        User manager = [SELECT Id FROM User WHERE Employee_Code__c = 'MGR001TEST' LIMIT 1];
        System.runAs(manager) {
            List<ReporteeViewController.SubordinateWrapper> subs = ReporteeViewController.getSubordinates();
            System.assertNotEquals(null, subs, 'Result should not be null');
            System.assert(subs.size() >= 0, 'List size should be zero or more');
        }
    }
}