/****************************************************************
* Class Name : LeavesTriggerHandler
* Description: Logic handler for Leaves__c with exact API names 
* from the provided field list, including HR Profile notifications.
****************************************************************/
public with sharing class LeavesTriggerHandler {
    
    public static void handleBeforeInsert(List<Leaves__c> newLeaves) {
        syncUserAndOwner(newLeaves);
        assignApprovers(newLeaves); 
    }
    
    public static void handleAfterInsert(List<Leaves__c> newLeaves) {
        submitForApproval(newLeaves);
        sendRequestEmail(newLeaves); 
    }
    
    public static void handleBeforeUpdate(List<Leaves__c> newLeaves, Map<Id, Leaves__c> oldMap) {
        syncUserAndOwner(newLeaves);
        assignApprovers(newLeaves);
    }
    
    public static void handleAfterUpdate(List<Leaves__c> newLeaves, Map<Id, Leaves__c> oldMap) {
        List<Leaves__c> cancelledLeaves = new List<Leaves__c>();
        List<Leaves__c> approvedLeaves = new List<Leaves__c>();
        List<Leaves__c> cancellationApprovedLeaves = new List<Leaves__c>();
        
        for (Leaves__c leave : newLeaves) {
            Leaves__c oldLeave = oldMap.get(leave.Id);
            
            // Scenario 2: Submitted for Cancellation (already working)
            if (leave.Leave_Cancellation_Status__c == 'Submitted for Cancellation' &&
                oldLeave.Leave_Cancellation_Status__c != 'Submitted for Cancellation') {
                    cancelledLeaves.add(leave);
                }
            
            // Scenario 3: Leave Approved
            if (leave.ApprovalStatus__c == 'Leave Approved' &&
                oldLeave.ApprovalStatus__c != 'Leave Approved') {
                    approvedLeaves.add(leave);
                }
            
            // Scenario 4: Cancellation Approved
            if (leave.Leave_Cancellation_Status__c == 'Cancellation Approved' &&
                oldLeave.Leave_Cancellation_Status__c != 'Cancellation Approved') {
                    cancellationApprovedLeaves.add(leave);
                }
        }
        
        if (!cancelledLeaves.isEmpty()) {
            sendCancellationEmail(cancelledLeaves);
        }
        if (!approvedLeaves.isEmpty()) {
            sendLeaveApprovedEmail(approvedLeaves);
        }
        if (!cancellationApprovedLeaves.isEmpty()) {
            sendCancellationApprovedEmail(cancellationApprovedLeaves);
        }
    }
    
    
    // NEW: Helper method to query HR Profile Emails
    private static List<String> getHREmails() {
        List<String> hrEmails = new List<String>();
        for (User u : [SELECT Email FROM User WHERE Profile.Name = 'HR' AND IsActive = true]) {
            hrEmails.add(u.Email);
        }
        return hrEmails;
    }
    
    private static void syncUserAndOwner(List<Leaves__c> leaves) {
        Id currentUserId = UserInfo.getUserId();
        for (Leaves__c leave : leaves) {
            if (leave.User__c == null) leave.User__c = currentUserId;
            leave.OwnerId = leave.User__c;
        }
    }
    
    private static void assignApprovers(List<Leaves__c> leaves) {
        Set<Id> userIds = new Set<Id>();
        for (Leaves__c leave : leaves) {
            if (leave.User__c != null) userIds.add(leave.User__c);
        }
        if (userIds.isEmpty()) return;
        
        Map<Id, User> userMap = new Map<Id, User>([
            SELECT Id,Leave_HR__c,Leave_Approver_L1__c FROM User WHERE Id IN :userIds
        ]);
        
        for (Leaves__c leave : leaves) {
            if (leave.User__c != null && userMap.containsKey(leave.User__c)) {
                User employee = userMap.get(leave.User__c);
                if(employee.Leave_Approver_L1__c != null)
                {
                    leave.Approver__c = employee.Leave_Approver_L1__c;
                }
                
                if(employee.Leave_HR__c != null)
                {
                    leave.HR__c = employee.Leave_HR__c;
                }
                
            }
        }
    }
    
    private static void submitForApproval(List<Leaves__c> leaves) {
        List<Approval.ProcessSubmitRequest> requests = new List<Approval.ProcessSubmitRequest>();
        Map<Id, Leaves__c> fullRecords = new Map<Id, Leaves__c>([
            SELECT Id, Approver__c, User__c, User__r.ManagerId ,ApprovalStatus__c
            FROM Leaves__c WHERE Id IN :leaves
        ]);
        
        for (Leaves__c leave : leaves) {
            Leaves__c record = fullRecords.get(leave.Id);
            Id targetApprover = record.Approver__c != null ? record.Approver__c : record.User__r.ManagerId;
            if (targetApprover != null && record.ApprovalStatus__c != 'Leave Approved') {
                Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                req.setComments('Automated submission: Leave request sent to Manager.');
                req.setObjectId(leave.Id);
                req.setNextApproverIds(new Id[] { targetApprover });
                req.setSubmitterId(record.User__c); 
                requests.add(req);
            }
        }
        if (!requests.isEmpty()) {
            try { Approval.process(requests); } catch (Exception e) { System.debug('Approval Error: ' + e.getMessage()); }
        }
    }
    private static void sendRequestEmail(List<Leaves__c> leaves) {
        
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        Map<Id, Leaves__c> details = new Map<Id, Leaves__c>([
            SELECT Id,
            User__r.Name,
            From_Date__c,
            To_Date__c,
            Reason_for_Leave__c,
            Leave_Approver_L1_Email__c,
            Approver__r.Name,
            HR_Email__c,
            HR__r.Name,
            Type_of_Leave__c
            FROM Leaves__c
            WHERE Id IN :leaves
        ]);
        
        for (Leaves__c leave : leaves) {
            
            Leaves__c record = details.get(leave.Id);
            if (record == null) continue;
            
            String startDate = record.From_Date__c != null
                ? record.From_Date__c.format()
                : 'N/A';
            
            String endDate = record.To_Date__c != null
                ? record.To_Date__c.format()
                : 'N/A';
            
            // ===============================
            //send Email to HR
            // ===============================
            if (String.isNotBlank(record.HR_Email__c)) {
                
                Messaging.SingleEmailMessage hrMail = new Messaging.SingleEmailMessage();
                hrMail.setToAddresses(new List<String>{ record.HR_Email__c });
                
                hrMail.setSubject(
                    'Leave Request: ' + record.User__r.Name +
                    ' (' + startDate + ' to ' + endDate + ')'
                );
                
                String hrName = record.HR__r != null ? record.HR__r.Name : 'HR';
                
                hrMail.setPlainTextBody(
                    'Dear ' + hrName + ',\n\n' +
                    record.User__r.Name + ' has applied for leave.\n\n' +
                    'Leave Type: ' + record.Type_of_Leave__c + '\n' +
                    'Start Date: ' + startDate + '\n' +
                    'End Date: ' + endDate + '\n' +
                    'Reason: ' + record.Reason_for_Leave__c + '\n\n' +
                    'Please log in to Salesforce to take action.'
                );
                
                emails.add(hrMail);
            }
            
            // =============================
            //  Send Email to L1 Approver
            // ===============================
            if (String.isNotBlank(record.Leave_Approver_L1_Email__c)) {
                
                Messaging.SingleEmailMessage l1Mail = new Messaging.SingleEmailMessage();
                l1Mail.setToAddresses(new List<String>{ record.Leave_Approver_L1_Email__c });
                
                l1Mail.setSubject(
                    'Leave Request: ' + record.User__r.Name +
                    ' (' + startDate + ' to ' + endDate + ')'
                );
                
                String l1Name = record.Approver__r != null
                    ? record.Approver__r.Name
                    : 'Approver';
                
                l1Mail.setPlainTextBody(
                    'Dear ' + l1Name + ',\n\n' +
                    record.User__r.Name + ' has applied for leave.\n\n' +
                    'Leave Type: ' + record.Type_of_Leave__c + '\n' +
                    'Start Date: ' + startDate + '\n' +
                    'End Date: ' + endDate + '\n' +
                    'Reason: ' + record.Reason_for_Leave__c + '\n\n' +
                    'Please log in to Salesforce to take action.'
                );
                
                emails.add(l1Mail);
            }
        }
        
        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }
    private static void sendCancellationEmail(List<Leaves__c> leaves) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        List<String> hrRecipients = getHREmails(); // Fetch HR recipients
        
        Map<Id, Leaves__c> details = new Map<Id, Leaves__c>([
            SELECT Id, User__r.Name, From_Date__c, To_Date__c, Approver_Email__c, Leave_Cancellation_Comments__c,
            Type_of_Leave__c, No_of_Days__c ,HR_Email__c,Leave_Approver_L1_Email__c,  Approver__r.Name, HR__r.Name
            FROM Leaves__c WHERE Id IN :leaves
        ]);
        
        for (Leaves__c leave : leaves) {
            Leaves__c record = details.get(leave.Id);
            if (record != null) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                
                // Add Manager and HR to recipients
                List<String> toAddresses = new List<String>(hrRecipients);
                if (String.isNotBlank(record.Approver_Email__c)) toAddresses.add(record.Approver_Email__c);
                
                String startDate = record.From_Date__c != null
                    ? record.From_Date__c.format()
                    : 'N/A';
                
                String endDate = record.To_Date__c != null
                    ? record.To_Date__c.format()
                    : 'N/A';
                if (String.isNotBlank(record.HR_Email__c)) {
                }
                // ===============================
                //send Email to HR
                // ===============================
                if (String.isNotBlank(record.HR_Email__c)) {
                    
                    Messaging.SingleEmailMessage hrMail = new Messaging.SingleEmailMessage();
                    hrMail.setToAddresses(new List<String>{ record.HR_Email__c });
                    
                    hrMail.setSubject(
                        'Leave Cancellation Request: ' + record.User__r.Name +
                        ' (' + startDate + ' to ' + endDate + ')'
                    );
                    
                    String hrName = record.HR__r != null ? record.HR__r.Name : 'HR';
                    
                    hrMail.setPlainTextBody(
                        'Dear ' + hrName + ',\n\n' +
                        record.User__r.Name + ' has requested to CANCEL a scheduled leave.\n\n' +
                        'Leave Type: ' + record.Type_of_Leave__c + '\n' +
                        'Start Date: ' + startDate + '\n' +
                        'End Date: ' + endDate + '\n' +
                        'Reason: ' + record.Leave_Cancellation_Comments__c + '\n\n' +
                        'Please log in to Salesforce to take action.'
                    );
                    
                    emails.add(hrMail);
                }
                
                // =============================
                //  Send Email to L1 Approver
                // ===============================
                if (String.isNotBlank(record.Leave_Approver_L1_Email__c)) {
                    
                    Messaging.SingleEmailMessage l1Mail = new Messaging.SingleEmailMessage();
                    l1Mail.setToAddresses(new List<String>{ record.Leave_Approver_L1_Email__c });
                    
                    l1Mail.setSubject(
                        'Leave Cancellation Request: ' + record.User__r.Name +
                        ' (' + startDate + ' to ' + endDate + ')'
                    );
                    
                    String l1Name = record.Approver__r != null
                        ? record.Approver__r.Name
                        : 'Approver';
                    
                    l1Mail.setPlainTextBody(
                        'Dear ' + l1Name + ',\n\n' +
                        record.User__r.Name + ' has requested to CANCEL a scheduled leave.\n\n' +
                        'Leave Type: ' + record.Type_of_Leave__c + '\n' +
                        'Start Date: ' + startDate + '\n' +
                        'End Date: ' + endDate + '\n' +
                        'Reason: ' + record.Leave_Cancellation_Comments__c + '\n\n' +
                        'Please log in to Salesforce to take action.'
                    );
                    
                    emails.add(l1Mail);
                }
                
                
            }
        }
        if (!emails.isEmpty()) Messaging.sendEmail(emails);
    }
    
    //Added by pattu
    private static void sendLeaveApprovedEmail(List<Leaves__c> leaves) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        Map<Id, Leaves__c> details = new Map<Id, Leaves__c>([
            SELECT Id,
            User__r.Name,
            User__r.Email,
            From_Date__c,
            To_Date__c,
            Type_of_Leave__c,
            HR_Email__c,
            HR__r.Name,
            Leave_Approver_L1_Email__c,
            Approver__r.Name
            FROM Leaves__c
            WHERE Id IN :leaves
        ]);
        
        for (Leaves__c leave : leaves) {
            Leaves__c record = details.get(leave.Id);
            if (record == null) continue;
            
            String startDate = record.From_Date__c != null ? record.From_Date__c.format() : 'N/A';
            String endDate   = record.To_Date__c   != null ? record.To_Date__c.format()   : 'N/A';
            
            // --- Email to HR ---
            if (String.isNotBlank(record.HR_Email__c)) {
                Messaging.SingleEmailMessage hrMail = new Messaging.SingleEmailMessage();
                hrMail.setToAddresses(new List<String>{ record.HR_Email__c });
                hrMail.setSubject(
                    'Leave Approved: ' + record.User__r.Name +
                    ' (' + startDate + ' to ' + endDate + ')'
                );
                String hrName = record.HR__r != null ? record.HR__r.Name : 'HR';
                hrMail.setPlainTextBody(
                    'Dear ' + hrName + ',\n\n' +
                    'This is to inform you that the leave request of ' + record.User__r.Name + ' has been APPROVED.\n\n' +
                    'Leave Type : ' + record.Type_of_Leave__c + '\n' +
                    'Start Date : ' + startDate + '\n' +
                    'End Date   : ' + endDate + '\n\n' +
                    'Please update your records accordingly.\n\n'
                );
                emails.add(hrMail);
            }
            
            // --- Email to Employee ---
            if (String.isNotBlank(record.User__r.Email)) {
                Messaging.SingleEmailMessage empMail = new Messaging.SingleEmailMessage();
                empMail.setToAddresses(new List<String>{ record.User__r.Email });
                empMail.setSubject(
                    'Your Leave Has Been Approved (' + startDate + ' to ' + endDate + ')'
                );
                empMail.setPlainTextBody(
                    'Dear ' + record.User__r.Name + ',\n\n' +
                    'We are pleased to inform you that your leave request has been APPROVED.\n\n' +
                    'Leave Type : ' + record.Type_of_Leave__c + '\n' +
                    'Start Date : ' + startDate + '\n' +
                    'End Date   : ' + endDate + '\n\n' +
                    'Please ensure a smooth handover before your leave.\n\n'
                );
                emails.add(empMail);
            }
        }
        
        if (!emails.isEmpty()) {
            try { Messaging.sendEmail(emails); } catch (Exception e) { System.debug('Email Error: ' + e.getMessage()); }
        }
    }
    //Added by Pattu
    private static void sendCancellationApprovedEmail(List<Leaves__c> leaves) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        Map<Id, Leaves__c> details = new Map<Id, Leaves__c>([
            SELECT Id,
            User__r.Name,
            User__r.Email,
            From_Date__c,
            To_Date__c,
            Type_of_Leave__c,
            HR_Email__c,
            HR__r.Name,
            Leave_Approver_L1_Email__c,
            Approver__r.Name,
            Leave_Cancellation_Comments__c
            FROM Leaves__c
            WHERE Id IN :leaves
        ]);
        
        for (Leaves__c leave : leaves) {
            Leaves__c record = details.get(leave.Id);
            if (record == null) continue;
            
            String startDate = record.From_Date__c != null ? record.From_Date__c.format() : 'N/A';
            String endDate   = record.To_Date__c   != null ? record.To_Date__c.format()   : 'N/A';
            
            // --- Email to HR ---
            if (String.isNotBlank(record.HR_Email__c)) {
                Messaging.SingleEmailMessage hrMail = new Messaging.SingleEmailMessage();
                hrMail.setToAddresses(new List<String>{ record.HR_Email__c });
                hrMail.setSubject(
                    'Leave Cancellation Approved: ' + record.User__r.Name +
                    ' (' + startDate + ' to ' + endDate + ')'
                );
                String hrName = record.HR__r != null ? record.HR__r.Name : 'HR';
                hrMail.setPlainTextBody(
                    'Dear ' + hrName + ',\n\n' +
                    'This is to inform you that the leave cancellation request of ' + record.User__r.Name + ' has been APPROVED.\n\n' +
                    'Leave Type : ' + record.Type_of_Leave__c + '\n' +
                    'Start Date : ' + startDate + '\n' +
                    'End Date   : ' + endDate + '\n' +
                    'Cancellation Reason : ' + record.Leave_Cancellation_Comments__c + '\n\n' +
                    'Please update your records accordingly.\n\n'
                );
                emails.add(hrMail);
            }
            
            // --- Email to Employee ---
            if (String.isNotBlank(record.User__r.Email)) {
                Messaging.SingleEmailMessage empMail = new Messaging.SingleEmailMessage();
                empMail.setToAddresses(new List<String>{ record.User__r.Email });
                empMail.setSubject(
                    'Your Leave Cancellation Has Been Approved (' + startDate + ' to ' + endDate + ')'
                );
                empMail.setPlainTextBody(
                    'Dear ' + record.User__r.Name + ',\n\n' +
                    'We are pleased to inform you that your leave cancellation request has been APPROVED.\n\n' +
                    'Leave Type : ' + record.Type_of_Leave__c + '\n' +
                    'Start Date : ' + startDate + '\n' +
                    'End Date   : ' + endDate + '\n\n' +
                    'Your attendance has been updated. Please contact HR for any queries.\n\n' 
                );
                emails.add(empMail);
            }
        }
        
        if (!emails.isEmpty()) {
            try { Messaging.sendEmail(emails); } catch (Exception e) { System.debug('Email Error: ' + e.getMessage()); }
        }
    }
}