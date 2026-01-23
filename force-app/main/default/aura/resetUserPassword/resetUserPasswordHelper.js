({
    resetUserPassword: function(component, event, helper) {
        var action = component.get("c.resetUserPassword");
        action.setParams({ "recordId": component.get("v.recordId") });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                
                var toastEvent = $A.get("e.force:showToast");
                
                if (result.startsWith("Success:")) {
                    let msg = result.replace("Success:", "").trim();
                    helper.showToast("success", "Success", msg);
                } else if (result.startsWith("Error:")) {
                    let msg = result.replace("Error:", "").trim();
                    helper.showToast("error", "Error", msg);
                }
            } else {
                console.error("Failed:", response.getError());
                
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "error",
                    "title": "Error",
                    "message": "An unknown error occurred. Please try again."
                });
                toastEvent.fire();
                $A.get("e.force:refreshView").fire();
                
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                if (dismissActionPanel) {
                    dismissActionPanel.fire();
                }
            }
        });

        $A.enqueueAction(action);
    },

    showToast: function(type, title, message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type": type,
            "title": title,
            "message": message
        });
        toastEvent.fire();
        $A.get("e.force:refreshView").fire();
        
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        if (dismissActionPanel) {
            dismissActionPanel.fire();
        }
    }
})