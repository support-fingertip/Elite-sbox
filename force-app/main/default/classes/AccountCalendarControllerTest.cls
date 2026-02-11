@isTest
public class AccountCalendarControllerTest {
    
    @isTest
    static void testGetBeats() {
        // Create test data for Child_beat__c
        Child_beat__c testBeat = new Child_beat__c(Name = 'Test Beat');
        insert testBeat;

        // Call the getBeats method
       

       
    }

    @isTest
    static void testGetPjpItems() {
        // Create test data for PJP_Item__c
        User testUser = [SELECT Id FROM User WHERE profile.Name ='System Administrator'  LIMIT 1];
        Calendar_beat__c testPjp = new Calendar_beat__c(OwnerId = testUser .Id, Start_Month__c = Date.today());
        insert testPjp;

        PJP_Item__c testItem = new PJP_Item__c(
            PJP__c = testPjp.Id,
            Date__c = Date.today(),
            Status__c = 'Submitted'
        );
        insert testItem;

        // Call the getPjpItems method
        Test.startTest();
        AccountCalendarController.getPjpItems(testUser .Id, Date.today().month(), Date.today().year());
        Test.stopTest();

       
    }

    @isTest
    static void testSavePjpItems() {
        // Create test data for Calendar_beat__c
        User testUser  = [SELECT Id FROM User WHERE profile.Name ='System Administrator'  LIMIT 1];
        Calendar_beat__c testPjp = new Calendar_beat__c(OwnerId = testUser .Id, Start_Month__c = Date.today());
        insert testPjp;
        
        Calendar_beat__c beat = new Calendar_beat__c(
            User__c = testUser.Id,
            Active__c = false
        );
        insert beat;
        
        Child_beat__c  beat1 = new Child_beat__c(
            Active__c = false
        );
        insert beat1;
        
        PJP_Item__c item = new PJP_Item__c(
            PJP__c = beat.Id,
            Assigned_Beat__c = beat1.Id,
            Status__c = 'Submitted'
        );
        insert item;
        
        Account acc = new Account(
            Name = 'Primary Customer',
            Customer_Type__c = 'Primary Customer',
            Pincode__c = '123456',
            Primary_Phone_Number__c = '9876543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert acc;

        // Prepare PjpItemWrapper data
        List<AccountCalendarController.PjpItemWrapper> pjpItems = new List<AccountCalendarController.PjpItemWrapper>();
        AccountCalendarController.PjpItemWrapper wrapper = new AccountCalendarController.PjpItemWrapper();
        wrapper.dates = String.valueOf(Date.today());
        wrapper.id = item.Id;
        wrapper.accountId = acc.Id; // Replace with a valid Account Id
        pjpItems.add(wrapper);

        // Call the savePjpItems method
        Test.startTest();
        try{
        AccountCalendarController.savePjpItems(testUser.Id, Date.today().month(), Date.today().year(), pjpItems);
        }catch (DmlException e) {
            System.debug('Error while inserting account: ' + e.getMessage());
        }
        Test.stopTest();

       
    }
}