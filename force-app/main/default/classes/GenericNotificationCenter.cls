/****************************************************************
* Class Name : VoxbayAPI
* Company : Fingertipplus
* Created Date :  01-04-2025
* @description : This class used to send the notifications
* @author : Durga Prasad
* Change Log:
* Used By : AccountTriggerHandler,EmployeeTriggerHandler
* -----------------------------------------------------------------------------
* Ver | Author | Date | Description
* -----------------------------------------------------------------------------
* 1.0 | Durga Prasad | 01-04-2025 | Initial version
* -----------------------------------------------------------------------------
******************************************************************/
public class GenericNotificationCenter {
 	/**
     * Method Name: notificationSend
     * @author: Durga Prasad
     * @description: Sends a custom notification to the specified set of users with the given title, body, and target record ID.
     * @parameters:
     * - String notifyTitle: The title of the notification.
     * - Id notifyId: The record ID that the notification should link to (target ID).
     * - String notificationBody: The body content of the notification.
     * - Set<String> targetUserIds: A set of user IDs to whom the notification will be sent.
     * @return: void
     */
    public static void notificationSend(String notifyTitle,id notifyId,string notificationBody,set<string> targetUserIds){
        
        
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName 
            FROM CustomNotificationType 
            WHERE DeveloperName = 'Customer_Approval_Notification'
            LIMIT 1
        ];
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle(notifyTitle);
        notification.setNotificationTypeId(notificationType.Id);
        notification.setTargetId(notifyId);
        notification.setBody(notificationBody);
        notification.send(targetUserIds);
        System.debug('Notification sent' + targetUserIds);
        
        

    }
}