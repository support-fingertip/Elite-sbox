public without sharing class LeaveCancellatoncmpCtrl {
    
    @AuraEnabled
    public static String cancelLeave(Id LeaveId, String comments) {
        System.debug('LeaveId >>> ' + LeaveId);
        try {
            // Added OwnerId to the query so we know who the 'User' is
            Leaves__c leave = [SELECT Id, ApprovalStatus__c, Cancellation_Requested__c, 
                              Type_of_Leave__c, Session_Type__c, Leave_Cancellation_Comments__c, OwnerId,
                              (SELECT Id FROM ProcessInstances WHERE Status = 'Pending')
                              FROM Leaves__c WHERE Id = :LeaveId LIMIT 1];
            
            System.debug('Leave Record: ' + leave);

            if(leave.ApprovalStatus__c == 'Leave Approved') {
                leave.Cancellation_Requested__c = true;
                leave.Leave_Cancellation_Comments__c = comments;
                
                try {
                    update leave;
                    
                    Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                    req.setComments(comments);
                    req.setObjectId(LeaveId);
                    
                    /* ADDED THIS LINE: Forces Salesforce to look for the Employee's manager 
                       even if an Admin/HR clicks the button */
                    req.setSubmitterId(leave.OwnerId); 
                    
                    Approval.ProcessResult result = Approval.process(req);
                    
                    if (result.isSuccess()) {
                        System.debug('Leave cancellation submitted for approval successfully.');
                    } else {
                        System.debug('Cancellation approval submission failed.');
                    }
                } catch (Exception e) {
                    System.debug('Error during approval submission: ' + e.getMessage());
                    throw new AuraHandledException('Failed to submit leave for approval: ' + e.getMessage());
                }
            } 
            else {
                leave.Cancellation_Requested__c = true;
                leave.Leave_Cancellation_Comments__c = comments;
                
                if (!leave.ProcessInstances.isEmpty()) {  
                    for (ProcessInstance instance : leave.ProcessInstances) {
                        List<ProcessInstanceWorkitem> workItems = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstanceId = :instance.Id];
                        for (ProcessInstanceWorkitem workItem : workItems) {
                            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                            req.setAction('Removed'); 
                            req.setWorkitemId(workItem.Id);
                            Approval.process(req);
                        }
                    }
                } 

                leave.ApprovalStatus__c = 'Leave Cancelled';
                update leave;
            }
            
            return 'Leave has been successfully cancelled.';
        } catch (Exception e) {
            return 'Error: ' + e.getMessage();
        }
    }

    @AuraEnabled
    public static boolean LeaveChecking(Id LeaveId) {
        Leaves__c leave = [SELECT Id, ApprovalStatus__c, Leave_Status__c 
                          FROM Leaves__c WHERE Id = :LeaveId LIMIT 1];
        
        boolean isCancelled = false;
        
        if(leave.Leave_Status__c == 'Submitted for Cancellation' || 
           leave.Leave_Status__c == 'Cancellation Approved' ||
           leave.ApprovalStatus__c == 'Leave Cancelled') {
            isCancelled = true;
        }
        
        return isCancelled;
    }
}