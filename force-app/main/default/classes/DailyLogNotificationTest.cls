@isTest
private class DailyLogNotificationTest {

    @testSetup
    static void setupData() {
        // Create roles
        UserRole managerRole = new UserRole(Name = 'RSM');
        insert managerRole;

        UserRole empRole = new UserRole(Name = 'TSE', ParentRoleId = managerRole.Id);
        insert empRole;

        // Create manager
        Profile prof = [SELECT Id FROM Profile WHERE Name = 'RSM' LIMIT 1];
        User manager = new User(
            FirstName = 'Manager',
            LastName = 'One',
            Email = 'manager@test.com',
            Username = 'manager@test.com.test',
            Alias = 'mngr1',
            ProfileId = prof.Id,
            Employee_Code__C = '293820jeje',
            UserRoleId = managerRole.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert manager;

        // Create subordinate users
        List<User> subordinates = new List<User>();
        for (Integer i = 0; i < 3; i++) {
            subordinates.add(new User(
                FirstName = 'Emp',
                LastName = 'User' + i,
                Email = 'emp' + i + '@test.com',
                Username = 'emp' + i + '@test.com.test',
                Alias = 'emp' + i,
                ProfileId = prof.Id,
                UserRoleId = empRole.Id,
                TimeZoneSidKey = 'Asia/Kolkata',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                Employee_Code__c = 'EMP00' + i
            ));
        }
        insert subordinates;

        // Create daily log for only one subordinate (to simulate attendance)
       // insert new Daily_Log__c(OwnerId = subordinates[0].Id);
    }

    @isTest
    static void testAttendanceNotification() {
        Test.startTest();

        // Call method
        DailyLogNotification.getEmployeesWithoutAttendence();

        Test.stopTest();

        // We cannot assert emails or notifications directly,
        // but we ensure no exceptions and full coverage.
    }

    @isTest
    static void testNoUsersMissingLogs() {
        // Add Daily Logs for all users to simulate full attendance
        List<User> allUsers = [SELECT Id FROM User WHERE Username LIKE 'emp%@test.com.test'];
        List<Daily_Log__c> logs = new List<Daily_Log__c>();
        for (User u : allUsers) {
            logs.add(new Daily_Log__c(OwnerId = u.Id));
        }
        insert logs;

        Test.startTest();
        //DailyLogNotification.getEmployeesWithoutAttendence();
        Database.executeBatch(new EmployeesWithoutAttendenceBatch(), 30);// Should exit early 
        Test.stopTest();
    }
}