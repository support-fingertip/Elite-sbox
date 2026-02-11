({
    doInit : function(component, event, helper) {
        component.set("v.isLoading", true);
        var action = component.get("c.getUserDetails");
        action.setParams({ employeeId : component.get("v.recordId") });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                var result = response.getReturnValue();
                if(result && result.Id) {
                    component.set("v.userId", result.Id);
                    component.set("v.username", result.Username);
                    component.set("v.isLoading", false);
                }
            } else {
                console.error(response.getError());
            }
        });

        $A.enqueueAction(action);
    },

    resetPassword : function(component, event, helper) {
        var password = component.get("v.newPassword");
        var userId = component.get("v.userId");

        component.set("v.errorMessage", '');
        component.set("v.successMessage", '');

        if (!password || password.length < 8) {
            component.set("v.errorMessage", 'Password must be at least 8 characters.');
            return;
        }

        var action = component.get("c.setPassword");
        action.setParams({ userId: userId, newPassword: password });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                component.set("v.successMessage", 'Password reset successfully!');
                component.set("v.newPassword", '');
            } else {
                var errors = response.getError();
                component.set("v.errorMessage", errors && errors[0] && errors[0].message ? errors[0].message : 'Unknown error');
            }
        });

        $A.enqueueAction(action);
    },

    clearMessages : function(component, event, helper) {
        component.set("v.errorMessage", '');
        component.set("v.successMessage", '');
    }
});