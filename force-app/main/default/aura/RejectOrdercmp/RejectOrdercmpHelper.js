({
    rejectRecords: function(component, event, helper) {
        
        var action = component.get("c.rejectOrder");
        action.setParams({ "recordId": component.get("v.recordId") });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                var toastEvent = $A.get("e.force:showToast");
                
                if (result.startsWith("Success:")) {
                    let msg =result.replace("Success:", "").trim();
                    helper.showToast("Success", "Success", msg);
                }
                else if (result.startsWith("Error:")) {
                    if (result.includes('ORDER_NOT_FOUND')) {
                        helper.showToast("error", "Error", 'Order Not found');
                    }
                    else if (result.includes('REJECTION_COMPLETED')) 
                    {    
                        helper.showToast("error", "Error", 'Rejection already is completed. Please refresh and check once');
                    }
                    else
                    {
                        let msg = result;
                        helper.showToast("error", "Error", msg);
                    }
                }
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
            } 
            else {
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