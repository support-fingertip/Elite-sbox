@isTest
public class EODReportTest {
    
    @isTest
    static void testBatchRunsForManager() {
        // Create a role (required for UserRoleId != null filter)
        UserRole role = new UserRole(Name = 'Test Manager Role');
        insert role;
        
        // Create manager user
        User manager = new User(
            FirstName = 'Test',
            LastName = 'Manager',
            Email = 'manager@test.com',
            Username = 'manager' + DateTime.now().getTime() + '@test.com',
            Alias = 'tmgr',
            Employee_Code__c  = 'sjk22ddhjkj18118',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            UserRoleId = role.Id
        );
        insert manager;
        
        // Create subordinate
        User subordinate = new User(
            FirstName = 'Test',
            LastName = 'Subordinate',
            Email = 'sub@test.com',
             Employee_Code__c  = 'sjkhjkj1822118',
            Username = 'sub' + DateTime.now().getTime() + '@test.com',
            Alias = 'tsub',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ManagerId = manager.Id
        );
        insert subordinate;
        Daily_Log__c daily = new Daily_Log__c();
        insert daily;
        
        Visit__c vs = new Visit__c(Daily_Log__c = daily.Id);
        insert vs;
        
        vs.ClockIn_Latitude__c = 37.7749;
        vs.Clockin_Longitude__c = 78.4194;
        vs.Actual_Start_Time__c = DateTime.now();
        update vs;
        
        vs.Distance__c = 12;
        update vs;
        
        daily.Day_ended_time__c = DateTime.now();
        daily.Clock_Out_Location__Longitude__s = 37.7749;
        daily.Clock_Out_Location__Latitude__s = 78.4194;
        update daily;
        
        // Run batch
        Test.startTest();
        Database.executeBatch(new EODReport(), 1);  // force single execution
        Test.stopTest();
        

    }
}