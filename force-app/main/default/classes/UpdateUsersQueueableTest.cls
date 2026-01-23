@isTest
private class UpdateUsersQueueableTest {
    @isTest
    static void testUpdateUsersQueueable() {
        // Step 1: Create a test user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            FirstName = 'Queue',
            LastName = 'User',
            Email = 'queueuser@test.com',
            Username = 'queueuser' + System.currentTimeMillis() + '@test.com',
            Alias = 'qusr',
            Employee_Code__c ='jksdkjh9191i1',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert u;

        // Step 2: Modify the user record for update
        u.FirstName = 'UpdatedQueue';

        // Step 3: Add to list and enqueue the job
        List<User> usersToUpdate = new List<User>{u};

        Test.startTest();
        System.enqueueJob(new UpdateUsersQueueable(usersToUpdate));
        Test.stopTest();

        // No assertions required per your request
    }
}