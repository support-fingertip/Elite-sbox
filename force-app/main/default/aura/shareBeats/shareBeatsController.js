({
    loadUsers: function(component, event, helper) {
        component.set("v.isLoading", true);
        var action = component.get("c.getUsersForBeatSharing");
        action.setParams({ "employeeId": component.get("v.recordId") });
        action.setCallback(this, function(response) {
            component.set("v.isLoading", false);
            if (response.getState() === 'SUCCESS') {
                component.set("v.users", response.getReturnValue());
            } else {
                var errors = response.getError();
                var message = errors && errors[0] ? errors[0].message : 'Failed to load users.';
                $A.get("e.force:showToast").setParams({ "type": "error", "title": "Error", "message": message }).fire();
            }
        });
        $A.enqueueAction(action);
    },

    handleCancel: function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },

    handleShare: function(component, event, helper) {
        var targetUserId = component.get("v.selectedUserId");
        if (!targetUserId) {
            $A.get("e.force:showToast").setParams({ "type": "warning", "title": "Warning", "message": "Please select a user to share beats with." }).fire();
            return;
        }
        component.set("v.isLoading", true);
        var action = component.get("c.shareBeatToUser");
        action.setParams({
            "employeeId": component.get("v.recordId"),
            "targetUserId": targetUserId
        });
        action.setCallback(this, function(response) {
            component.set("v.isLoading", false);
            if (response.getState() === 'SUCCESS') {
                $A.get("e.force:showToast").setParams({ "type": "success", "title": "Success", "message": response.getReturnValue() }).fire();
            } else {
                var errors = response.getError();
                var message = errors && errors[0] ? errors[0].message : 'Failed to share beats.';
                $A.get("e.force:showToast").setParams({ "type": "error", "title": "Error", "message": message }).fire();
            }
            $A.get('e.force:refreshView').fire();
            $A.get("e.force:closeQuickAction").fire();
        });
        $A.enqueueAction(action);
    }
})
