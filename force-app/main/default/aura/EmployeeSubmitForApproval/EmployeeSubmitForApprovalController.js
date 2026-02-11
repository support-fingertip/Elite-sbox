({
    doInit: function(component, event, helper) {
        if ($A.get("$Browser.formFactor") === "PHONE") {
            component.set("v.loadingScreenSize", 4);
        } else {
            component.set("v.loadingScreenSize", 1);
        }
        component.set("v.isloading", true);
        var action = component.get("c.getAssignments");
        action.setParams({
            'recordId': component.get('v.recordId')
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                if (result === "Success") {
                    component.set("v.showWarning", false);
                } else {
                    var message = 'Are you sure you want to submit the employee for approval without any assigned ' + result + '?';
                    component.set("v.assignmentWarning", message);
                    component.set("v.showWarning", true);
                }
            } else {
                console.error('Error in getAssignments:', response.getError());
            }
            component.set("v.isloading", false);
        });
        $A.enqueueAction(action);
    },
    
    Approval: function(component, event, helper) {
        component.set("v.isloading", true);
        var submitAction = component.get("c.submitForApproval");
        submitAction.setParams({
            'recordId': component.get('v.recordId'),
            'comments':component.get('v.Comments'),
        });
        submitAction.setCallback(this, function(submitResponse) {
            var submitState = submitResponse.getState();
            if (submitState === "SUCCESS") {
                component.set("v.isloading", false);
                $A.get("e.force:closeQuickAction").fire();
                var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                    "recordId": component.get('v.recordId'),
                    "slideDevName": "detail"
                });
                navEvt.fire();
                $A.get('e.force:refreshView').fire();
                
                helper.showToast("Employee has been submitted for approval successfully","Success");
                
            } else {
                component.set("v.isloading", false);
                $A.get("e.force:closeQuickAction").fire();
                var errorMsg = submitResponse.getError()[0].message; 
                helper.showToast('Error while submitting for approval: ' + errorMsg, 'info');
                
                //helper.showToast("Manager Not Defined, This approval request requires the next approver to be determined by the Manager field. This value is empty.", "info");
            }
        });
        $A.enqueueAction(submitAction);
    },
    Cancel: function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
        component.set("v.isloading", false);
    }
})