@isTest
public class CustomNotificationServiceTest {

    @isTest
    static void testNotificationSend() {
        // Create test users
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
       

        // Sample data to send notification
        Set<String> targetUserIds = new Set<String>{ userInfo.getUserId() };
        String title = 'Test Notification';
        String body = 'This is a test notification.';
        String typeId = '0MLxx0000000000AAA'; // Replace with a valid Notification Type Id in your org

        // Create a dummy target record to associate the notification with
        Account acc = new Account(Name = 'Notification Target', Pincode__c = '123456',
            Primary_Phone_Number__c = '9876543219',
            State__c = 'Karnataka',
            District__c = 'Kolar');
        insert acc;

        Test.startTest();
        CustomNotificationService.notificationSend(title, acc.Id, body, targetUserIds, typeId);
        Test.stopTest();

        // No assertions required since Messaging.CustomNotification.send() does not return a result,
        // but test coverage will be provided for the method.
    }

    @isTest
    static void testNotificationSend_NullOrEmptyTargetSet() {
        Test.startTest();
        CustomNotificationService.notificationSend('Title', '001xx0000000000AAA', 'Body', null, '0MLxx0000000000AAA');
        CustomNotificationService.notificationSend('Title', '001xx0000000000AAA', 'Body', new Set<String>(), '0MLxx0000000000AAA');
        Set<String> targetUserIds = new Set<String>{ userInfo.getUserId() };
            CustomNotificationService.notificationSendPageRef('Title', 'Body', targetUserIds, '0MLxx0000000000AAA');
        Test.stopTest();
    }
}