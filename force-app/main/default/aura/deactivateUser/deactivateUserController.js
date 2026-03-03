({
    
    initComponent: function(component, event, helper) {
        // Just show the modal — no immediate action
        component.set("v.showModal", true);
    },

    handleBeatOptionChange: function(component, event, helper) {
        component.set("v.selectedBeatOption", event.getParam("value"));
    },

    handleCancel: function(component, event, helper) {
        component.set("v.showModal", false);
        $A.get("e.force:closeQuickAction").fire();
    },

    handleDeactivate: function(component, event, helper) {
        var beatOption = component.get("v.selectedBeatOption");
        var action = component.get("c.deactivateUserWithBeatOption");
        action.setParams({
            "recordId": component.get("v.recordId"),
            "beatOption": beatOption
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (state === 'SUCCESS') {
                $A.get("e.force:showToast").setParams({
                    "type": "success",
                    "title": "Success",
                    "message": response.getReturnValue() || "User De-Activated Successfully"
                }).fire();
            }
            else if (state === 'ERROR') {
                var errors = response.getError();
                var message = 'Unknown error';
                if (errors && errors[0] && errors[0].message) {
                    message = errors[0].message;
                }
                
                $A.get("e.force:showToast").setParams({
                    "type": "error",
                    "title": "Error",
                    "message": message
                }).fire();
            }
            
            $A.get('e.force:refreshView').fire();
            event.stopPropagation();
            $A.get("e.force:closeQuickAction").fire();
        });
        $A.enqueueAction(action);
    }
    
})