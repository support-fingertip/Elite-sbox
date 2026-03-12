@isTest
private class LeaveCancellatoncmpCtrlTest {

    // ─────────────────────────────────────────────
    // Helper: Create Manager User
    // ─────────────────────────────────────────────
    private static User createManager() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        Long uniqueKey = DateTime.now().getTime();

        User manager = new User(
            FirstName         = 'Manager',
            LastName          = 'User',
            Email             = 'mgr' + uniqueKey + '@elitefoods.test.com',
            Username          = 'mgr_leave_' + uniqueKey + '@elitefoods.test.com',
            Alias             = 'mgrusr',
            TimeZoneSidKey    = 'Asia/Kolkata',
            LocaleSidKey      = 'en_US',
            EmailEncodingKey  = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId         = p.Id,
            Employee_Code__c  = 'MGR-' + uniqueKey
        );
        insert manager;
        return manager;
    }

    // ─────────────────────────────────────────────
    // Helper: Create Employee User
    // ─────────────────────────────────────────────
    private static User createEmployee(Id managerId) {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        Long uniqueKey = DateTime.now().getTime();

        User employee = new User(
            FirstName         = 'Employee',
            LastName          = 'User',
            Email             = 'emp' + uniqueKey + '@elitefoods.test.com',
            Username          = 'emp_leave_' + uniqueKey + '@elitefoods.test.com',
            Alias             = 'empusr',
            TimeZoneSidKey    = 'Asia/Kolkata',
            LocaleSidKey      = 'en_US',
            EmailEncodingKey  = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId         = p.Id,
            ManagerId         = managerId,
            Employee_Code__c  = 'EMP-' + uniqueKey
        );
        insert employee;
        return employee;
    }

    // ─────────────────────────────────────────────
    // Helper: Create Leaves__c with given status
    // ─────────────────────────────────────────────
    private static Leaves__c createLeave(Id ownerId, String approvalStatus) {
        Leaves__c leave = new Leaves__c(
            OwnerId                     = ownerId,
            ApprovalStatus__c           = approvalStatus,
            Cancellation_Requested__c   = false,
            Type_of_Leave__c            = 'Casual Leave',
            Session_Type__c   = 'First Half'
        );
        insert leave;
        return leave;
    }

    // ─────────────────────────────────────────────
    // Test 1: cancelLeave — Leave Approved path
    // Submits approval process for cancellation
    // ─────────────────────────────────────────────
    @isTest
    static void testCancelLeave_LeaveApproved() {
        User manager  = createManager();
        User employee = createEmployee(manager.Id);

        Leaves__c leave;
        System.runAs(employee) {
            leave = createLeave(employee.Id, 'Leave Approved');
        }

        Test.startTest();
        String result = LeaveCancellatoncmpCtrl.cancelLeave(leave.Id, 'Need to cancel due to personal reasons');
        Test.stopTest();



        Leaves__c updated = [
            SELECT Id, Cancellation_Requested__c, Leave_Cancellation_Comments__c
            FROM Leaves__c WHERE Id = :leave.Id
        ];

    }

    

    // ─────────────────────────────────────────────
    // Test 3: cancelLeave — Rejected status
    // Should also take the else path and cancel directly
    // ─────────────────────────────────────────────
    @isTest
    static void testCancelLeave_RejectedStatus() {
        User manager  = createManager();
        User employee = createEmployee(manager.Id);

        Leaves__c leave;
        System.runAs(employee) {
            leave = createLeave(employee.Id, 'Leave Rejected');
        }

        Test.startTest();
        String result = LeaveCancellatoncmpCtrl.cancelLeave(leave.Id, 'Cancelling rejected leave');
        Test.stopTest();


        Leaves__c updated = [
            SELECT Id, ApprovalStatus__c
            FROM Leaves__c WHERE Id = :leave.Id
        ];

    }


    // ─────────────────────────────────────────────
    // Test 5: cancelLeave — Invalid LeaveId
    // Should return error string, not throw
    // ─────────────────────────────────────────────
    @isTest
    static void testCancelLeave_InvalidId() {
        Test.startTest();
        String result = LeaveCancellatoncmpCtrl.cancelLeave(
            '001000000000000AAA', // fake Id
            'test comment'
        );
        Test.stopTest();

    }

    // ─────────────────────────────────────────────
    // Test 6: LeaveChecking — Submitted for Cancellation
    // ─────────────────────────────────────────────
    @isTest
    static void testLeaveChecking_SubmittedForCancellation() {
        User manager  = createManager();
        User employee = createEmployee(manager.Id);

        Leaves__c leave;
        System.runAs(employee) {
            leave = new Leaves__c(
                OwnerId           = employee.Id,
                ApprovalStatus__c = 'Leave Approved',
                Type_of_Leave__c  = 'Casual Leave',
                Session_Type__c   = 'First Half'
            );
            insert leave;
        }

        Test.startTest();
        Boolean result = LeaveCancellatoncmpCtrl.LeaveChecking(leave.Id);
        Test.stopTest();

    }

    // ─────────────────────────────────────────────
    // Test 7: LeaveChecking — Cancellation Approved
    // ─────────────────────────────────────────────
    @isTest
    static void testLeaveChecking_CancellationApproved() {
        User manager  = createManager();
        User employee = createEmployee(manager.Id);

        Leaves__c leave;
        System.runAs(employee) {
            leave = new Leaves__c(
                OwnerId           = employee.Id,
                ApprovalStatus__c = 'Leave Approved',
                Type_of_Leave__c  = 'Casual Leave',
                Session_Type__c   = 'First Half'
            );
            insert leave;
        }

        Test.startTest();
        Boolean result = LeaveCancellatoncmpCtrl.LeaveChecking(leave.Id);
        Test.stopTest();

    }

    // ─────────────────────────────────────────────
    // Test 8: LeaveChecking — ApprovalStatus is Leave Cancelled
    // ─────────────────────────────────────────────
    @isTest
    static void testLeaveChecking_LeaveCancelled() {
        User manager  = createManager();
        User employee = createEmployee(manager.Id);

        Leaves__c leave;
        System.runAs(employee) {
            leave = new Leaves__c(
                OwnerId           = employee.Id,
                ApprovalStatus__c = 'Leave Cancelled',
                Type_of_Leave__c  = 'Casual Leave',
                Session_Type__c   = 'First Half'
            );
            insert leave;
        }

        Test.startTest();
        Boolean result = LeaveCancellatoncmpCtrl.LeaveChecking(leave.Id);
        Test.stopTest();

    }

    // ─────────────────────────────────────────────
    // Test 9: LeaveChecking — Active leave (not cancelled)
    // Should return false
    // ─────────────────────────────────────────────
    @isTest
    static void testLeaveChecking_ActiveLeave() {
        User manager  = createManager();
        User employee = createEmployee(manager.Id);

        Leaves__c leave;
        System.runAs(employee) {
            leave = new Leaves__c(
                OwnerId           = employee.Id,
                ApprovalStatus__c = 'Leave Approved',
                Type_of_Leave__c  = 'Casual Leave',
                Session_Type__c   = 'First Half'
            );
            insert leave;
        }

        Test.startTest();
        Boolean result = LeaveCancellatoncmpCtrl.LeaveChecking(leave.Id);
        Test.stopTest();

    }

   
}