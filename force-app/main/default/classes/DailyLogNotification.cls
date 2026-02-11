public class DailyLogNotification {
    public static void getEmployeesWithoutAttendence() {
        Decimal attendanceAlertDays = Decimal.valueOf(Label.Attendance_Alert_Days);
        Date threeDaysAgo = Date.today().addDays(-Integer.valueOf(attendanceAlertDays));


        // Step 1: Get all active users
        List<User> allUsers = [
            SELECT Id, Name, Email, Employee_Code__c, Profile.Name 
            FROM User 
            WHERE IsActive = true
        ];
        Map<Id, User> userMap = new Map<Id, User>();
        for (User u : allUsers) userMap.put(u.Id, u);

        Set<Id> allUserIds = new Set<Id>(userMap.keySet());

        // Step 2: Get daily logs from last 3 days
        Set<Id> usersWithLogs = new Set<Id>();
        for (Daily_Log__c log : [
            SELECT Id, OwnerId 
            FROM Daily_Log__c 
            WHERE CreatedDate >= :threeDaysAgo
        ]) {
            usersWithLogs.add(log.OwnerId);
        }

        // Step 3: Determine users missing logs
        Set<Id> usersWithoutLogs = new Set<Id>(allUserIds);
        usersWithoutLogs.removeAll(usersWithLogs);
        if (usersWithoutLogs.isEmpty()) return;

        // Step 4: Parse custom label and find notification users
        List<String> profileNames = Label.Attendance_Notification_Users.split(';');
        List<User> notificationUsers = new List<User>();
        for (User u : allUsers) {
            if (profileNames.contains(u.Profile.Name)) {
                notificationUsers.add(u);
            }
        }

        // Step 5: Get notification type
        CustomNotificationType notificationType = [
            SELECT Id 
            FROM CustomNotificationType 
            WHERE DeveloperName = 'Stock_Update_Notification' 
            LIMIT 1
        ];

        List<Messaging.SingleEmailMessage> allEmails = new List<Messaging.SingleEmailMessage>();

        // Step 6: Notify each user in hierarchy
        for (User manager : notificationUsers) {
            Set<Id> subordinateIds = RoleHeirarchyUtility.getUsersUnderRoleHierarchy(manager.Id);
            subordinateIds.retainAll(usersWithoutLogs);

            if (subordinateIds.isEmpty()) continue;

            List<User> missingUsers = new List<User>();
            for (Id subId : subordinateIds) {
                if (userMap.containsKey(subId)) {
                    missingUsers.add(userMap.get(subId));
                }
            }

            // --- Send Custom Notification ---
            String title = 'Employee Attendance Alert';

            String body = missingUsers.size() + 
              ' of your subordinate employee(s) have not marked attendance for the last 3 days. Please check your email for the employee list.';


            CustomNotificationService.notificationSend(
                title, 
                UserInfo.getUserId(), 
                body, 
                new Set<String>{ manager.Id }, 
                notificationType.Id
            );

            // --- Build email ---
            String emailBody = '<p>Dear ' + manager.Name + ',</p>';
            emailBody += '<p>The following employees under your hierarchy have not submitted attendance for the past 3 days:</p>';
            emailBody += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse:collapse;">';
            emailBody += '<tr><th>S/No.</th><th>Employee Name</th><th>Employee Code</th></tr>';

            Integer i = 1;
            for (User emp : missingUsers) {
                emailBody += '<tr><td>' + i + '</td><td>' + emp.Name + '</td><td>' + (emp.Employee_Code__c != null ? emp.Employee_Code__c : '') + '</td></tr>';
                i++;
            }

            emailBody += '</table>';
            emailBody += '<p>Please follow up as needed.</p><p>Regards,<br/>ELITE FOODS PRIVATE LIMITED</p>';

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] { manager.Email });
            email.setSubject('Employee Attendance Alert');
            email.setHtmlBody(emailBody);

            allEmails.add(email);
        }

        // Step 7: Send all emails
        if (!allEmails.isEmpty()) {
            Messaging.sendEmail(allEmails);
        }
    }
}