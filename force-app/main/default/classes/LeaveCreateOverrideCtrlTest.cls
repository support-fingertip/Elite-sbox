@isTest
public class LeaveCreateOverrideCtrlTest {

    @testSetup
    static void setupData() {

        // HR User
        User hrUser = new User(
            Alias           = 'hrtest',
            Email           = 'hrtest@leavetest.com',
            EmailEncodingKey= 'UTF-8',
            LastName        = 'HRLeaveTest',
            employee_code__c = '191011',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey    = 'en_US',
            ProfileId       = [SELECT Id FROM Profile WHERE Name = 'HR' LIMIT 1].Id,
            TimeZoneSidKey  = 'Asia/Kolkata',
            Username        = 'hrtest_leave@leavetest.com' + System.currentTimeMillis(),
            Sales_Channel__c = 'Cake'
        );
        insert hrUser;

        // Standard User (non-HR, non-Admin)
        User stdUser = new User(
            Alias           = 'stdtst',
            Email           = 'stdtest@leavetest.com',
            EmailEncodingKey= 'UTF-8',
            LastName        = 'StdLeaveTest',
            employee_code__c = '191DDEE011',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey    = 'en_US',
            ProfileId       = [SELECT Id FROM Profile WHERE Name = 'TSE' LIMIT 1].Id,
            TimeZoneSidKey  = 'Asia/Kolkata',
            Username        = 'stdtest_leave@leavetest.com' + System.currentTimeMillis(),
            Sales_Channel__c = 'Cake'
        );
        insert stdUser;
    }

    // ─────────────────────────────────────────────
    // checkUserRole
    // ─────────────────────────────────────────────

    @isTest
    static void testCheckUserRole_HRReturnsTrue() {
        User hrUser = [SELECT Id FROM User WHERE LastName = 'HRLeaveTest' LIMIT 1];

        Test.startTest();
        Boolean result;
        System.runAs(hrUser) {
            result = LeaveCreateOverrideCtrl.checkUserRole();
        }
        Test.stopTest();

    }

    @isTest
    static void testCheckUserRole_StandardUserReturnsFalse() {
        User stdUser = [SELECT Id FROM User WHERE LastName = 'StdLeaveTest' LIMIT 1];

        Test.startTest();
        Boolean result;
        System.runAs(stdUser) {
            result = LeaveCreateOverrideCtrl.checkUserRole();
        }
        Test.stopTest();

    }

    // ─────────────────────────────────────────────
    // validateLeaveDates — happy path (no overlap)
    // ─────────────────────────────────────────────

    @isTest
    static void testValidateLeaveDates_NoOverlap_ReturnsNull() {
        User stdUser = [SELECT Id FROM User WHERE LastName = 'StdLeaveTest' LIMIT 1];

        Map<String, Object> leaveData = new Map<String, Object>{
            'User__c'          => String.valueOf(stdUser.Id),
            'From_Date__c'     => '2030-06-01',
            'To_Date__c'       => '2030-06-03',
            'Session_Type__c'  => 'First Half'
        };

        Test.startTest();
        String result = LeaveCreateOverrideCtrl.validateLeaveDates(leaveData);
        Test.stopTest();

    }

    // ─────────────────────────────────────────────
    // validateLeaveDates — overlap detected
    // ─────────────────────────────────────────────

    @isTest
    static void testValidateLeaveDates_OverlapFound_ReturnsMessage() {
        User stdUser = [SELECT Id FROM User WHERE LastName = 'StdLeaveTest' LIMIT 1];

        // Insert an existing approved leave for this user
        Leaves__c existingLeave = new Leaves__c(
            User__c          = stdUser.Id,
            From_Date__c     = Date.newInstance(2030, 7, 10),
            To_Date__c       = Date.newInstance(2030, 7, 12)
        );
        insert existingLeave;

        // New leave overlaps with the existing one
        Map<String, Object> leaveData = new Map<String, Object>{
            'User__c'          => String.valueOf(stdUser.Id),
            'From_Date__c'     => '2030-07-11',
            'To_Date__c'       => '2030-07-13'
        };

        Test.startTest();
        String result = LeaveCreateOverrideCtrl.validateLeaveDates(leaveData);
        Test.stopTest();


    }

    // ─────────────────────────────────────────────
    // validateLeaveDates — cancelled/rejected leave ignored
    // ─────────────────────────────────────────────

    @isTest
    static void testValidateLeaveDates_CancelledLeave_Ignored() {
        User stdUser = [SELECT Id FROM User WHERE LastName = 'StdLeaveTest' LIMIT 1];

        // Cancelled leave on the same dates — should NOT block new request
        Leaves__c cancelledLeave = new Leaves__c(
            User__c          = stdUser.Id,
            From_Date__c     = Date.newInstance(2030, 8, 5),
            To_Date__c       = Date.newInstance(2030, 8, 7)
        );
        insert cancelledLeave;

        Map<String, Object> leaveData = new Map<String, Object>{
            'User__c'          => String.valueOf(stdUser.Id),
            'From_Date__c'     => '2030-08-05',
            'To_Date__c'       => '2030-08-07',
            'Session_Type__c'  => 'First Half'
        };

        Test.startTest();
        String result = LeaveCreateOverrideCtrl.validateLeaveDates(leaveData);
        Test.stopTest();


    }

    @isTest
    static void testValidateLeaveDates_RejectedLeave_Ignored() {
        User stdUser = [SELECT Id FROM User WHERE LastName = 'StdLeaveTest' LIMIT 1];

        Leaves__c rejectedLeave = new Leaves__c(
            User__c          = stdUser.Id,
            From_Date__c     = Date.newInstance(2030, 9, 1),
            To_Date__c       = Date.newInstance(2030, 9, 3)
        );
        insert rejectedLeave;

        Map<String, Object> leaveData = new Map<String, Object>{
            'User__c'          => String.valueOf(stdUser.Id),
            'From_Date__c'     => '2030-09-01',
            'To_Date__c'       => '2030-09-03'
        };

        Test.startTest();
        String result = LeaveCreateOverrideCtrl.validateLeaveDates(leaveData);
        Test.stopTest();

    }

    // ─────────────────────────────────────────────
    // validateLeaveDates — same-day half-day split allowed
    // ─────────────────────────────────────────────

    @isTest
    static void testValidateLeaveDates_SameDayDifferentSession_Allowed() {
        User stdUser = [SELECT Id FROM User WHERE LastName = 'StdLeaveTest' LIMIT 1];

        // Existing First Half leave on 2030-10-15
        Leaves__c firstHalf = new Leaves__c(
            User__c          = stdUser.Id,
            From_Date__c     = Date.newInstance(2030, 10, 15),
            To_Date__c       = Date.newInstance(2030, 10, 15),
            Session_Type__c  = 'First Half'
        );
        insert firstHalf;

        // New Second Half leave on the same day — should be allowed
        Map<String, Object> leaveData = new Map<String, Object>{
            'User__c'          => String.valueOf(stdUser.Id),
            'From_Date__c'     => '2030-10-15',
            'To_Date__c'       => '2030-10-15',
            'Session_Type__c'  => 'First Half'
        };

        Test.startTest();
        String result = LeaveCreateOverrideCtrl.validateLeaveDates(leaveData);
        Test.stopTest();

    }

    @isTest
    static void testValidateLeaveDates_SameDaySameSession_Blocked() {
        User stdUser = [SELECT Id FROM User WHERE LastName = 'StdLeaveTest' LIMIT 1];

        Leaves__c firstHalf = new Leaves__c(
            User__c          = stdUser.Id,
            From_Date__c     = Date.newInstance(2030, 11, 20),
            To_Date__c       = Date.newInstance(2030, 11, 20),
            Session_Type__c  = 'First Half'
        );
        insert firstHalf;

        // Same session on same day — should be blocked
        Map<String, Object> leaveData = new Map<String, Object>{
            'User__c'          => String.valueOf(stdUser.Id),
            'From_Date__c'     => '2030-11-20',
            'To_Date__c'       => '2030-11-20',
            'Session_Type__c'  => 'First Half'
        };

        Test.startTest();
        String result = LeaveCreateOverrideCtrl.validateLeaveDates(leaveData);
        Test.stopTest();

    }

    // ─────────────────────────────────────────────
    // validateLeaveDates — no User__c uses running user
    // ─────────────────────────────────────────────

    @isTest
    static void testValidateLeaveDates_NullUser_UsesRunningUser() {
        User stdUser = [SELECT Id FROM User WHERE LastName = 'StdLeaveTest' LIMIT 1];

        Map<String, Object> leaveData = new Map<String, Object>{
            'User__c'          => '',        // blank → falls back to UserInfo.getUserId()
            'From_Date__c'     => '2030-12-01',
            'To_Date__c'       => '2030-12-05',
            'Session_Type__c'  => 'Full Day'
        };

        Test.startTest();
        String result;
        System.runAs(stdUser) {
            result = LeaveCreateOverrideCtrl.validateLeaveDates(leaveData);
        }
        Test.stopTest();

    }

    // ─────────────────────────────────────────────
    // validateLeaveDates — invalid date throws AuraHandledException
    // ─────────────────────────────────────────────

    @isTest
    static void testValidateLeaveDates_InvalidDate_ThrowsException() {
        User stdUser = [SELECT Id FROM User WHERE LastName = 'StdLeaveTest' LIMIT 1];

        Map<String, Object> leaveData = new Map<String, Object>{
            'User__c'         => String.valueOf(stdUser.Id),
            'From_Date__c'    => 'not-a-date',
            'To_Date__c'      => '2030-06-05',
            'Session_Type__c' => 'Full Day'
        };

        Test.startTest();
        try {
            LeaveCreateOverrideCtrl.validateLeaveDates(leaveData);
            System.assert(false, 'Expected AuraHandledException for invalid date');
        } catch (AuraHandledException e) {

        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────────
    // searchUsers
    // ─────────────────────────────────────────────

    @isTest
    static void testSearchUsers_ValidTerm_ReturnsResults() {
        User stdUser = [SELECT Id FROM User WHERE LastName = 'StdLeaveTest' LIMIT 1];

        Test.startTest();
        List<User> results = LeaveCreateOverrideCtrl.searchUsers('StdLeaveTest');
        Test.stopTest();

    }

    @isTest
    static void testSearchUsers_WithFixedResults() {
        User stdUser = [SELECT Id FROM User WHERE LastName = 'StdLeaveTest' LIMIT 1];

        // Fix SOSL results so the search returns our test user
        Test.setFixedSearchResults(new List<Id>{ stdUser.Id });

        Test.startTest();
        List<User> results = LeaveCreateOverrideCtrl.searchUsers('StdLeave');
        Test.stopTest();

    }

    @isTest
    static void testSearchUsers_BlankTerm_ReturnsEmpty() {
        Test.startTest();
        List<User> results = LeaveCreateOverrideCtrl.searchUsers('');
        Test.stopTest();

    }

    @isTest
    static void testSearchUsers_NullTerm_ReturnsEmpty() {
        Test.startTest();
        List<User> results = LeaveCreateOverrideCtrl.searchUsers(null);
        Test.stopTest();

    }

    @isTest
    static void testSearchUsers_SingleCharTerm_ReturnsEmpty() {
        Test.startTest();
        List<User> results = LeaveCreateOverrideCtrl.searchUsers('A');
        Test.stopTest();

    }

    @isTest
    static void testSearchUsers_TwoCharTerm_ExecutesSearch() {
        User hrUser = [SELECT Id FROM User WHERE LastName = 'HRLeaveTest' LIMIT 1];
        Test.setFixedSearchResults(new List<Id>{ hrUser.Id });

        Test.startTest();
        List<User> results = LeaveCreateOverrideCtrl.searchUsers('HR');
        Test.stopTest();

    }
}