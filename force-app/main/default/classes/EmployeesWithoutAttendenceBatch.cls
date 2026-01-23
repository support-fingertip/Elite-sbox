global class EmployeesWithoutAttendenceBatch implements Database.Batchable<SObject>, Database.Stateful {

    Map<Id, User> userMap = new Map<Id, User>();
    Map<Id, User> userMapSkipAttendence = new Map<Id, User>();
    Set<Id> usersWithLogs = new Set<Id>();
    Set<Id> usersWithoutLogs = new Set<Id>();

    // Instead of storing Messaging.SingleEmailMessage → store data
    Map<Id, List<User>> managerToMissingUsers = new Map<Id, List<User>>();

    global Database.QueryLocator start(Database.BatchableContext bc) {
        Decimal attendanceAlertDays = Decimal.valueOf(Label.Attendance_Alert_Days);
        Date threeDaysAgo = Date.today().addDays(-Integer.valueOf(attendanceAlertDays));

        // Step 1: Get all active users
        for (User u : [
            SELECT Id, Name, Email, Employee_Code__c, Profile.Name ,Manager_Name__c,Reporting_Manager_Employee_Code__c,Phone,Sales_Channel__c,
            Reporting_Manager_L2__c,Reporting_Manager_L2_Code__c,Reporting_Manager_L3__c,Reporting_Manager_L3_Code__c,Reporting_Manager_Phone_Number__c,
            Title,Employee_Remarks__c
            FROM User 
            WHERE IsActive = true AND CreatedDate <= :threeDaysAgo
        ]) {
            userMap.put(u.Id, u);
        }
        List<String> AttendenceSkipUserIds = Label.AttendenceSkipUserIds.split(';');
        
        List<String> AttendenceSkipprofileNames = Label.AttendenceSkipProfileNames.split(';');
        // Step 1: Get all active users
        for (User u : [
            SELECT Id, Name, Email, Employee_Code__c, Profile.Name,Manager_Name__c,Reporting_Manager_Employee_Code__c,Phone,Sales_Channel__c
            FROM User 
            WHERE IsActive = true AND ((Profile.Name IN :AttendenceSkipprofileNames) Or (User_Id__c IN: AttendenceSkipUserIds))
        ]) {
            userMapSkipAttendence.put(u.Id, u);
        }
        
        

        // Step 2: Get daily logs
        for (Daily_Log__c log : [
            SELECT Id, OwnerId 
            FROM Daily_Log__c 
            WHERE CreatedDate >= :threeDaysAgo
        ]) {
            usersWithLogs.add(log.OwnerId);
        }

        // Step 3: Users without logs
        usersWithoutLogs = new Set<Id>(userMap.keySet());
        usersWithoutLogs.removeAll(usersWithLogs);

        // Step 4: Notification users
        List<String> profileNames = Label.Attendance_Notification_Users.split(';');
        return Database.getQueryLocator([
            SELECT Id, Name, Email, Profile.Name
            FROM User
            WHERE IsActive = true
            AND Profile.Name IN :profileNames
        ]);
    }

    global void execute(Database.BatchableContext bc, List<User> scope) {
        if (usersWithoutLogs.isEmpty()) return;

        CustomNotificationType notificationType = [
            SELECT Id 
            FROM CustomNotificationType 
            WHERE DeveloperName = 'Stock_Update_Notification' 
            LIMIT 1
        ];

        for (User manager : scope) {
            Set<Id> subordinateIds = RoleHeirarchyUtility.getUsersUnderRoleHierarchy(manager.Id);
            subordinateIds.retainAll(usersWithoutLogs);

            if (subordinateIds.isEmpty()) continue;

            List<User> missingUsers = new List<User>();
            for (Id subId : subordinateIds) {
                if (userMap.containsKey(subId) && !userMapSkipAttendence.containsKey(subId)) {
                    missingUsers.add(userMap.get(subId));
                }
            }

            if (!missingUsers.isEmpty()) {
                managerToMissingUsers.put(manager.Id, missingUsers);

                // Send push notification immediately
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
            }
        }
    }

    global void finish(Database.BatchableContext bc) {
        // Now build & send emails
        List<Messaging.SingleEmailMessage> allEmails = new List<Messaging.SingleEmailMessage>();
        
        // Label for extra emails
        List<String> extraAdminEmails = new List<String>();
        if (!String.isBlank(Label.SystemAdmin_Attendance_Emails)) {
            // Step 4: Parse custom label and find notification users
            extraAdminEmails = Label.SystemAdmin_Attendance_Emails.split(';');
        }

        for (Id managerId : managerToMissingUsers.keySet()) {
            User manager = userMap.get(managerId);
            List<User> missingUsers = managerToMissingUsers.get(managerId);

            String emailBody = '<p>Dear ' + manager.Name + ',</p>';
            emailBody += '<p>The following employees under your hierarchy have not submitted attendance for the past 3 days:</p>';
            emailBody += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse:collapse;">';
            emailBody += '<tr><th>S/No.</th><th>Employee Name</th><th>Employee Code</th><th>Phone Number</th><th>Sales Channel</th><th>Designation</th><th>Manager L1</th><th>Manager L1 Code</th><th>Manager L1 Phone Number</th><th>Manager L2</th><th>Manager L2 Code</th><th>Manager L3</th><th>Manager L3 Code</th><th>Attendance/Leave Remarks</th></tr>';

            Integer i = 1;
            for (User emp : missingUsers) {
                emailBody += '<tr>'
                    + '<td>' + i + '</td>'
                    + '<td>' + emp.Name + '</td>'
                    + '<td>' + (emp.Employee_Code__c != null ? emp.Employee_Code__c : '') + '</td>'
                    + '<td>' + (emp.Phone != null ? emp.Phone : '') + '</td>'
                    + '<td>' + (emp.Sales_Channel__c != null ? emp.Sales_Channel__c : '') + '</td>'
                    + '<td>' + (emp.Title != null ? emp.Title : '') + '</td>'
                    + '<td>' + (emp.Manager_Name__c != null ? emp.Manager_Name__c : '') + '</td>'
                    + '<td>' + (emp.Reporting_Manager_Employee_Code__c != null ? emp.Reporting_Manager_Employee_Code__c : '') + '</td>'
                    + '<td>' + (emp.Reporting_Manager_Phone_Number__c != null ? emp.Reporting_Manager_Phone_Number__c : '') + '</td>'
                    + '<td>' + (emp.Reporting_Manager_L2__c != null ? emp.Reporting_Manager_L2__c : '') + '</td>'
                    + '<td>' + (emp.Reporting_Manager_L2_Code__c != null ? emp.Reporting_Manager_L2_Code__c : '') + '</td>'
                    + '<td>' + (emp.Reporting_Manager_L3__c != null ? emp.Reporting_Manager_L3__c : '') + '</td>'
                    + '<td>' + (emp.Reporting_Manager_L3_Code__c != null ? emp.Reporting_Manager_L3_Code__c : '') + '</td>'
                    + '<td>' + (emp.Employee_Remarks__c != null ? emp.Employee_Remarks__c : '') + '</td>'
                    + '</tr>';
                i++;
            }


            emailBody += '</table>';
            emailBody += '<p>Please follow up as needed.</p><p>Regards,<br/>ELITE FOODS PRIVATE LIMITED</p>';

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
               // Always send to the manager
            List<String> toAddresses = new List<String>{ manager.Email };
                
                // If manager is System Admin, add extra recipients
                if (manager.Profile.Name == 'System Administrator' && !extraAdminEmails.isEmpty()) {
                    toAddresses.addAll(extraAdminEmails);
                }
            email.setToAddresses(toAddresses);
            
            email.setSubject('Employee Attendance Alert');
            email.setHtmlBody(emailBody);
            
            // Set sender using Org-Wide Email Address (Name = "System Admin Email")
            OrgWideEmailAddress owea = [
                SELECT Id 
                FROM OrgWideEmailAddress 
                WHERE DisplayName = 'Elite Admin' // or use Address = 'admin@yourdomain.com'
                LIMIT 1
            ];
            email.setOrgWideEmailAddressId(owea.Id);
            

            allEmails.add(email);
        }

        if (!allEmails.isEmpty()) {
            Messaging.sendEmail(allEmails);
        }
    }

}