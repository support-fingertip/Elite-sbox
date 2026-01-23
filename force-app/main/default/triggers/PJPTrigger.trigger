trigger PJPTrigger on Calendar_beat__c(before insert,after update,after insert) {
    
    if (Label.Enable_PJP_Trigger == 'TRUE') {
        Set<Id> userIds = new Set<Id>();
        Set<Id> pjpIds = new Set<Id>();
        if (Trigger.isBefore && Trigger.isInsert) {
            for (Calendar_beat__c pjp : Trigger.new) {
                if (pjp.User__c != null) {
                    pjp.OwnerId = pjp.User__c;
                    userIds.add(pjp.User__c);
                }
            }
            
            if (userIds.size() > 0) {
                List<Calendar_beat__c> beats = [
                    SELECT Id
                    FROM Calendar_beat__c
                    WHERE User__c IN :userIds AND Active__c = TRUE
                ];
                if (beats.size() > 0) {
                    for (Calendar_beat__c beat : Trigger.new) {
                        if (userIds.contains(beat.User__c)) {
                            // If there is already an active PJP for the user, throw an error
                            beat.addError(
                                'Active PJP already exists for this user. Cannot create new record.'
                            );
                        }
                    }
                }
                
                List<Employee__c> employees = [
                    SELECT id, name, User__c, PJP_Approver_1__c, PJP_Approver_2__c
                    FROM Employee__c
                    WHERE User__c IN :userIds
                ];
                // Create a map with the key as User__c and the value as Employee__c
                Map<String, Employee__c> employeeMap = new Map<String, Employee__c>();
                
                // Loop through the employee records and populate the map
                for (Employee__c employee : employees) {
                    employeeMap.put(employee.User__c, employee);
                }
                
                if (!employeeMap.isEmpty()) {
                    for (Calendar_beat__c beat : Trigger.new) {
                        if (employeeMap.containsKey(beat.User__c)) {
                            beat.Approver__c = employeeMap.get(beat.User__c)
                                .PJP_Approver_1__c;
                        }
                    }
                }
            }
        }
        if (Trigger.isAfter && Trigger.isUpdate) {
            for (Calendar_beat__c pjp : Trigger.new) {
                if (
                    pjp.Approval_Status__c != null &&
                    pjp.Approval_Status__c !=
                    Trigger.oldMap.get(pjp.Id).Approval_Status__c
                ) {
                    pjpIds.add(pjp.Id);
                }
            }
            
            if (pjpIds.size() > 0) {
                List<PJP_Item__c> items = [
                    SELECT Id, PJP__r.Approval_Status__c, Beat__c, Assigned_Beat__c
                    FROM PJP_Item__c
                    WHERE
                    PJP__c IN :pjpIds
                    AND (Status__c = 'Submitted'
                         OR Status__c = 'Rejected')
                ];
                if (items.size() > 0) {
                    for (PJP_Item__c item : items) {
                        item.Status__c = item.PJP__r.Approval_Status__c;
                        if (item.PJP__r.Approval_Status__c == 'Approved')
                            item.Beat__c = item.Assigned_Beat__c;
                    }
                    
                    update items;
                }
            }
        }
        
        if (Trigger.isAfter && Trigger.isInsert) {
            List<Calendar_beat__c> beatsToUpdate = new List<Calendar_beat__c>();
            
            for (Calendar_beat__c beat : Trigger.new) {
                if (beat.PJP_ID__c != null) {
                    beatsToUpdate.add(
                        new Calendar_beat__c(
                            Id = beat.Id,
                            PJP_Id_Text__c = String.valueOf(beat.PJP_ID__c)
                        )
                    );
                }
            }
            
            if (!beatsToUpdate.isEmpty()) {
                update beatsToUpdate;
            }
        }
    }
    
}