public class CustomNotificationService {
    
    public static void notificationSend(String notifyTitle,id notifyId,string notificationBody,set<string> targetUserIds,string notificationId){
        
        if (targetUserIds == null || targetUserIds.isEmpty()) return;
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle(notifyTitle);
        notification.setNotificationTypeId(notificationId);
        notification.setTargetId(notifyId);
        notification.setBody(notificationBody);
        notification.send(targetUserIds);
        
    }
    
    
    public static void notificationSendPageRef(String notifyTitle,string notificationBody,set<string> targetUserIds,string notificationId){
        if (targetUserIds == null || targetUserIds.isEmpty()) return;
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle(notifyTitle);
        notification.setNotificationTypeId(notificationId);
        
        // Redirect to Expense__c → Recently Viewed list
        notification.setTargetPageRef(
            '{"type":"standard__objectPage",' +
            '"attributes":{"objectApiName":"Expense__c","actionName":"list"},' +
            '"state":{"filterName":"Recent"}}'
        );
        notification.setBody(notificationBody);
        notification.send(targetUserIds);
        
    }
    
    
    
    
}