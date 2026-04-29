global class EmployeesWithoutAttendenceBatch implements Database.Batchable<SObject>, Database.Stateful {

    Map<Id, User> userMap = new Map<Id, User>();
    Map<Id, User> userMapSkipAttendence = new Map<Id, User>();
    Set<Id> usersWithLogs = new Set<Id>();
    Set<Id> usersWithoutLogs = new Set<Id>();
    Set<Id> usersWithLeave = new Set<Id>();
    
    // Store manager User directly (not just Id) so finish() doesn't depend on userMap
    Map<Id, List<User>> managerToMissingUsers = new Map<Id, List<User>>();
    Map<Id, User> managerMap = new Map<Id, User>();

    // Collect logs across the batch lifecycle and insert in finish()
    List<Apex_Log__c> logsToInsert = new List<Apex_Log__c>();

    global Database.QueryLocator start(Database.BatchableContext bc) {
        try {
            Decimal attendanceAlertDays = Decimal.valueOf(Label.Attendance_Alert_Days);
            Date threeDaysAgo = Date.today().addDays(-Integer.valueOf(attendanceAlertDays));

            // Step 1: Get all active users
            for (User u : [
                SELECT Id, Name, Email, Employee_Code__c, Profile.Name, Manager_Name__c, Reporting_Manager_Employee_Code__c, Phone, Sales_Channel__c,
                       Reporting_Manager_L2__c, Reporting_Manager_L2_Code__c, Reporting_Manager_L3__c, Reporting_Manager_L3_Code__c, Reporting_Manager_Phone_Number__c,
                       Title, Employee_Remarks__c
                FROM User
                WHERE IsActive = true AND CreatedDate <= :threeDaysAgo
            ]) {
                userMap.put(u.Id, u);
            }

            List<String> AttendenceSkipUserIds = Label.AttendenceSkipUserIds.split(';');
            List<String> AttendenceSkipprofileNames = Label.AttendenceSkipProfileNames.split(';');

            for (User u : [
                SELECT Id, Name, Email, Employee_Code__c, Profile.Name, Manager_Name__c, Reporting_Manager_Employee_Code__c, Phone, Sales_Channel__c
                FROM User
                WHERE IsActive = true AND ((Profile.Name IN :AttendenceSkipprofileNames) OR (User_Id__c IN :AttendenceSkipUserIds))
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
            
            //Step 3.1 : User with Leave
            List<Leaves__c> leaveList = [select Id,User__c from Leaves__c where From_Date__c <= TODAY AND To_Date__c >= TODAY
                                         AND ApprovalStatus__c IN ('Leave Approved','Submitted for Approval','Not Submitted')
                                         AND Leave_Cancellation_Status__c != 'Submitted for Cancellation' AND
                                         Leave_Cancellation_Status__c != 'Cancellation Approved'];
            usersWithLeave = new set<Id>();
            for(Leaves__c lv : leaveList)
            {
                if(lv.User__c != null)  usersWithLeave.add(lv.User__c);
            }

            // Step 4: Notification users
            List<String> profileNames = Label.Attendance_Notification_Users.split(';');
            return Database.getQueryLocator([
                SELECT Id, Name, Email, Profile.Name
                FROM User
                WHERE IsActive = true
                AND Profile.Name IN :profileNames
            ]);
        } catch (Exception e) {
            logError('start', e);
            // Return empty locator so batch finishes cleanly and finish() can insert logs
            return Database.getQueryLocator([SELECT Id FROM User WHERE Id = null]);
        }
    }

    global void execute(Database.BatchableContext bc, List<User> scope) {
        if (usersWithoutLogs == null || usersWithoutLogs.isEmpty()) return;

        try {
            CustomNotificationType notificationType = [
                SELECT Id
                FROM CustomNotificationType
                WHERE DeveloperName = 'Stock_Update_Notification'
                LIMIT 1
            ];

            for (User manager : scope) {
                try {
                    Set<Id> subordinateIds = RoleHeirarchyUtility.getUsersUnderRoleHierarchy(manager.Id);
                    if (subordinateIds == null) subordinateIds = new Set<Id>();
                    subordinateIds.retainAll(usersWithoutLogs);

                    if (subordinateIds.isEmpty()) continue;

                    List<User> missingUsers = new List<User>();
                    for (Id subId : subordinateIds) {
                        if (userMap.containsKey(subId) && !userMapSkipAttendence.containsKey(subId) && !usersWithLeave.contains(subId)) {
                            missingUsers.add(userMap.get(subId));
                        }
                    }

                    if (!missingUsers.isEmpty()) {
                        managerToMissingUsers.put(manager.Id, missingUsers);
                        managerMap.put(manager.Id, manager);

                        // Send push notification immediately
                        String title = 'Employee Attendance Alert';
                        String body = missingUsers.size() +
                            ' of your subordinate employee(s) have not marked attendance for the last 3 days. Please check your email for the employee list.';

                        try {
                            CustomNotificationService.notificationSend(
                                title,
                                UserInfo.getUserId(),
                                body,
                                new Set<String>{ manager.Id },
                                notificationType.Id
                            );
                        } catch (Exception notifyEx) {
                            logError('execute - notificationSend for manager ' + manager.Id, notifyEx);
                        }
                    }
                } catch (Exception innerEx) {
                    // Don't let one manager fail the whole batch
                    logError('execute - processing manager ' + manager.Id, innerEx);
                }
            }
        } catch (Exception e) {
            logError('execute', e);
        }
    }

    global void finish(Database.BatchableContext bc) {
        try {
            List<Messaging.SingleEmailMessage> allEmails = new List<Messaging.SingleEmailMessage>();

            // Parse extra admin emails from custom label
            List<String> extraAdminEmails = new List<String>();
            if (!String.isBlank(Label.SystemAdmin_Attendance_Emails)) {
                extraAdminEmails = Label.SystemAdmin_Attendance_Emails.split(';');
            }

            // Query OWEA once outside the loop
            OrgWideEmailAddress owea = [
                SELECT Id
                FROM OrgWideEmailAddress
                WHERE DisplayName = 'Elite Admin'
                LIMIT 1
            ];

            for (Id managerId : managerToMissingUsers.keySet()) {
                try {
                    User manager = managerMap.get(managerId);
                    if (manager == null) {
                        logError('finish - manager not found in managerMap for Id ' + managerId, null);
                        continue;
                    }

                    List<User> missingUsers = managerToMissingUsers.get(managerId);
                    if (missingUsers == null || missingUsers.isEmpty()) continue;

                    String emailBody = '<p>Dear ' + manager.Name + ',</p>';
                    emailBody += '<p>The following employees under your hierarchy have not submitted attendance for the past 3 days:</p>';
                    emailBody += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse:collapse;">';
                    emailBody += '<tr><th>S/No.</th><th>Employee Name</th><th>Employee Code</th><th>Phone Number</th><th>Sales Channel</th><th>Designation</th><th>Manager L1</th><th>Manager L1 Code</th><th>Manager L1 Phone Number</th><th>Manager L2</th><th>Manager L2 Code</th><th>Manager L3</th><th>Manager L3 Code</th><th>Attendance/Leave Remarks</th></tr>';

                    Integer i = 1;
                    for (User emp : missingUsers) {
                        emailBody += '<tr>'
                            + '<td>' + i + '</td>'
                            + '<td>' + (emp.Name != null ? emp.Name : '') + '</td>'
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

                    // Build To-Addresses, skipping nulls/blanks
                    List<String> toAddresses = new List<String>();
                    if (!String.isBlank(manager.Email)) {
                        toAddresses.add(manager.Email);
                    }

                    if (manager.Profile != null
                        && manager.Profile.Name == 'System Administrator'
                        && !extraAdminEmails.isEmpty()) {
                        for (String addr : extraAdminEmails) {
                            if (!String.isBlank(addr)) toAddresses.add(addr);
                        }
                    }

                    if (toAddresses.isEmpty()) {
                        logError('finish - no valid To addresses for manager ' + managerId, null);
                        continue;
                    }

                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    email.setToAddresses(toAddresses);
                    email.setSubject('Employee Attendance Alert');
                    email.setHtmlBody(emailBody);
                    email.setOrgWideEmailAddressId(owea.Id);

                    allEmails.add(email);
                } catch (Exception innerEx) {
                    logError('finish - building email for manager ' + managerId, innerEx);
                }
            }

            if (!allEmails.isEmpty()) {
                try {
                    Messaging.sendEmail(allEmails);
                } catch (Exception sendEx) {
                    logError('finish - Messaging.sendEmail', sendEx);
                }
            }
        } catch (Exception e) {
            logError('finish', e);
        } finally {
            // Always try to insert logs, even if finish() blew up
            insertLogs();
        }
    }

    // ---------- Logging helpers ----------

    private void logError(String contextLocation, Exception e) {
        try {
            Apex_Log__c log = new Apex_Log__c();
            log.Status__c = 'Failed';
            log.Request_Type__c = 'Employee_Attenendence_Alert';

            String msg = 'Location: ' + contextLocation;
            if (e != null) {
                msg += '\nType: ' + e.getTypeName();
                msg += '\nMessage: ' + e.getMessage();
                msg += '\nLine Number: ' + e.getLineNumber();
                msg += '\nStack Trace: ' + e.getStackTraceString();
            }

            // Truncate to fit a Long Text Area (max 131072) — adjust if your field is shorter
            if (msg.length() > 131000) {
                msg = msg.substring(0, 131000);
            }
            log.Error_Message__c = msg;

            logsToInsert.add(log);
        } catch (Exception ignore) {
            // Never let logging itself break the batch
            System.debug(LoggingLevel.ERROR, 'Failed to build Apex_Log__c: ' + ignore.getMessage());
        }
    }

    private void insertLogs() {
        if (logsToInsert == null || logsToInsert.isEmpty()) return;
        try {
            insert logsToInsert;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to insert Apex_Log__c records: ' + e.getMessage());
        }
    }
}