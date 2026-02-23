({
    doInit : function(component, event, helper) {
        // To Disable Pull Refresh
        var detail = {};
        detail["isPullToRefreshEnabled"] = false;
        detail["isPullToShowMoreEnabled"] = false;
        var updateScrollSettingsEvent = new CustomEvent("updateScrollSettings", {
            detail: detail,
            bubbles: true,
            composed: true
        });
        dispatchEvent(updateScrollSettingsEvent);
        
        var action = component.get("c.checkUserRole");
        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                component.set("v.showUserField", response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
        
    },

    handleDateChange : function(component, event, helper) {
        var fromDate = component.get("v.fromDate");
        var toDate = component.get("v.toDate");
        // Show session field only if it's a single day leave
        if(fromDate && toDate && fromDate === toDate) {
            component.set("v.showSession", true);
        } else {
            component.set("v.showSession", false);
        }
    },
    
    handleManualSubmit : function(component, event, helper) {
        component.find("leaveForm").submit();
    },
    handleSubmit : function(component, event, helper) {
        event.preventDefault(); 
        component.set("v.isProcessing", true);
        
        var fields = event.getParam('fields');
        
        // Use selected user (from HR field) or current user
        var targetUserId = fields.User__c ? fields.User__c : $A.get("$SObjectType.CurrentUser.Id");
        
        var fromDate = new Date(fields.From_Date__c);
        var toDate = new Date(fields.To_Date__c);
        
        // Set 'today' to midnight for accurate comparison
        var today = new Date();
        today.setHours(0,0,0,0);

        // Calculate 15 days ago (Backdated limit)
        var fifteenDaysBack = new Date();
        fifteenDaysBack.setDate(today.getDate() - 16);
        fifteenDaysBack.setHours(0, 0, 0, 0);

        // 1. Validation: To Date cannot be before From Date
        if(toDate < fromDate) {
            helper.showToast("Error", "To Date cannot be earlier than From Date.", "error");
            component.set("v.isProcessing", false);
            return;
        }

        // 2. 15-Day Backwards Rule: Cannot be older than 15 days ago
        if(fromDate < fifteenDaysBack) {
            helper.showToast("Restricted", "You cannot apply for leave older than 15 days from today.", "error");
            component.set("v.isProcessing", false);
            return;
        }
        
      
        // 3. Server Overlap Check
        var action = component.get("c.validateLeaveDates");
        action.setParams({
            "leaveData": {
                "User__c": targetUserId, 
                "From_Date__c": fields.From_Date__c,
                "To_Date__c": fields.To_Date__c,
               
            }
        });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var errorMsg = response.getReturnValue();
                if (errorMsg) {
                    helper.showToast("You have already applied for leave on the selected date(s).", errorMsg, "error");
                    component.set("v.isProcessing", false);
                } else {
                    // All validations passed -> Submit the form
                    var showUserField = component.get("v.showUserField");
                    fields.User__c = targetUserId;
                    fields.ApprovalStatus__c = showUserField ? 'Leave Approved' : ''
                    component.find("leaveForm").submit(fields);
                }
            } else {
                component.set("v.isProcessing", false);
                helper.showToast("Error", "Server validation failed.", "error");
            }
        });
        $A.enqueueAction(action);
    },

    handleSuccess : function(component, event, helper) {
        helper.showToast("Success", "Leave request created successfully.", "success");
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({ "recordId": event.getParams().response.id });
        navEvt.fire();
    },

    closeModel : function(component, event, helper) {
        var homeEvt = $A.get("e.force:navigateToObjectHome");
        if (homeEvt) {
            homeEvt.setParams({ "scope": "Leaves__c" });
            homeEvt.fire();
        } else {
            window.history.back();
        }
    }
})