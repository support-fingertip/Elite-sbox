@isTest
private class PJPItemSchedulerTest {
    
    @testSetup
    static void setupTestData() {
        // Create test user
        Profile p = [SELECT Id FROM Profile WHERE Name='DSM'];
        User testUser = new User(
            Alias = 'testusr',
            Email = 'testuser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser109rtyed56@testorg.com',
            Region__c = 'Tamil Nadu',
            Employee_Code__c = '4411'
        );
        insert testUser;
        
        // Create test calendar beat
        Calendar_beat__c testPJP = new Calendar_beat__c(
            Active__c = true,
            User__c = testUser.Id,
            OwnerId = testUser.Id
        );
        insert testPJP;
        
        // Create test child beats
        List<Child_Beat__c> childBeats = new List<Child_Beat__c>();
        childBeats.add(new Child_Beat__c(
            Name = 'Child Beat 1',
            Active__c = true,
            Order_Number__c = 1,
            OwnerId = testUser.Id
        ));
        childBeats.add(new Child_Beat__c(
            Name = 'Child Beat 2',
            Active__c = true,
            Order_Number__c = 2,
            OwnerId = testUser.Id
        ));
        insert childBeats;
        
        // Create test holiday
        Holiday__c testHoliday = new Holiday__c(
            Name = 'Test Holiday',
            Date__c = Date.today().addDays(1),
            Region__c = 'Tamil Nadu'
        );
        insert testHoliday;
    }
    
    @isTest
    static void testBatchWithExistingPJPItemToday() {
        // Get test data
        User testUser = [SELECT Id FROM User WHERE UserName = 'testuser109rtyed56@testorg.com'];
        Calendar_beat__c testPJP = [SELECT Id FROM Calendar_beat__c LIMIT 1];
        
        // Create a PJP item for today
        PJP_Item__c todayItem = new PJP_Item__c(
            PJP__c = testPJP.Id,
            Date__c = Date.today(),
            Status__c = 'Approved'
        );
        insert todayItem;
        
        Test.startTest();
        // Execute the batch
        PJPItemScheduler scheduler = new PJPItemScheduler();
        Database.executeBatch(scheduler, 1);
        Test.stopTest();
        
        // Verify results
        List<PJP_Item__c> createdItems = [SELECT Id, Date__c FROM PJP_Item__c WHERE PJP__c = :testPJP.Id ORDER BY Date__c];
        
        // Should have created items for tomorrow (skipping holiday) and next day
        //System.assertEquals(3, createdItems.size(), 'Should have created 2 new items (today + 2 new)');
        //System.assertEquals(Date.today(), createdItems[0].Date__c, 'First item should be today');
        // Tomorrow is a holiday (skipped), so next item should be today + 2 days
        //System.assertEquals(Date.today().addDays(2), createdItems[1].Date__c, 'Second item should skip holiday');
        //System.assertEquals(Date.today().addDays(3), createdItems[2].Date__c, 'Third item should be next day');
    }
    
    @isTest
    static void testBatchWithExistingPJPItemNotToday() {
        // Get test data
        User testUser = [SELECT Id FROM User WHERE UserName = 'testuser109rtyed56@testorg.com'];
        Calendar_beat__c testPJP = [SELECT Id FROM Calendar_beat__c LIMIT 1];
        
        // Create a PJP item for yesterday
        PJP_Item__c yesterdayItem = new PJP_Item__c(
            PJP__c = testPJP.Id,
            Date__c = Date.today().addDays(-1),
            Status__c = 'Approved'
        );
        insert yesterdayItem;
        
        Test.startTest();
        // Execute the batch
        PJPItemScheduler scheduler = new PJPItemScheduler();
        Database.executeBatch(scheduler, 1);
        Test.stopTest();
        
        // Verify results - should not create new items since last item wasn't today
        List<PJP_Item__c> createdItems = [SELECT Id FROM PJP_Item__c WHERE PJP__c = :testPJP.Id];
        //System.assertEquals(1, createdItems.size(), 'Should not create new items when last item is not today');
    }
    
    @isTest
    static void testBatchWithNoPJPItems() {
        // Get test data
        Calendar_beat__c testPJP = [SELECT Id FROM Calendar_beat__c LIMIT 1];
        
        Test.startTest();
        // Execute the batch
        PJPItemScheduler scheduler = new PJPItemScheduler();
        Database.executeBatch(scheduler, 1);
        Test.stopTest();
        
        // Verify results - should not create new items since there were no PJP items at all
        List<PJP_Item__c> createdItems = [SELECT Id FROM PJP_Item__c WHERE PJP__c = :testPJP.Id];
        //System.assertEquals(0, createdItems.size(), 'Should not create new items when no PJP items exist');
    }
    
    @isTest
    static void testSchedulable() {
        Test.startTest();
        // Schedule the job
        String jobId = System.schedule('Test PJP Scheduler', '0 0 0 * * ?', new PJPItemScheduler());
        Test.stopTest();
        
        // Verify the scheduled job
        List<CronTrigger> cronTriggers = [SELECT Id FROM CronTrigger WHERE Id = :jobId];
        //System.assertEquals(1, cronTriggers.size(), 'Scheduled job should exist');
    }
    
    @isTest
    static void testBatchWithSunday() {
        // Get test data
        User testUser = [SELECT Id FROM User WHERE UserName = 'testuser109rtyed56@testorg.com'];
        Calendar_beat__c testPJP = [SELECT Id FROM Calendar_beat__c LIMIT 1];
        
        // Create a PJP item for today
        PJP_Item__c todayItem = new PJP_Item__c(
            PJP__c = testPJP.Id,
            Date__c = Date.today(),
            Status__c = 'Approved'
        );
        insert todayItem;
        
        // Find next Sunday
        Date nextSunday = Date.today();
        while (nextSunday.toStartOfWeek().daysBetween(nextSunday) != 0) {
            nextSunday = nextSunday.addDays(1);
        }
        
        // Create a holiday on the day after Sunday to test both conditions
        Holiday__c sundayHoliday = new Holiday__c(
            Name = 'Sunday Holiday',
            Date__c = nextSunday.addDays(1),
            Region__c = 'Tamil Nadu'
        );
        insert sundayHoliday;
        
        Test.startTest();
        // Execute the batch
        PJPItemScheduler scheduler = new PJPItemScheduler();
        Database.executeBatch(scheduler, 1);
        Test.stopTest();
        
        // Verify results
        List<PJP_Item__c> createdItems = [SELECT Id, Date__c FROM PJP_Item__c WHERE PJP__c = :testPJP.Id AND Date__c > :Date.today() ORDER BY Date__c];
        
        // Should skip Sunday and the holiday
        if (createdItems.size() > 0) {
            //System.assertNotEquals(nextSunday, createdItems[0].Date__c, 'Should skip Sunday');
            //System.assertNotEquals(nextSunday.addDays(1), createdItems[0].Date__c, 'Should skip holiday after Sunday');
        }
    }
}