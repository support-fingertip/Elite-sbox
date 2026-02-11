({
    trasferRecords: function(component, event, helper) {
        console.log('Entered createUser');
        
        var action = component.get("c.customerReplacement");
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
                    
                     if (result.includes('TRANSFERRED_TO_MISSING')) 
                    {    
                        helper.showToast("error", "Error", 'Transferred to not found');
                    }
                    else if(result.includes("CUSTOMER_NOT_FOUND"))
                    {
                        helper.showToast("error", "Error",'Customer record not found');
                    }
                    else if(result.includes("TRANSFER_COMPLETED"))
                    {
                        helper.showToast("error", "Error",'Customer Beats, Secoundary Customers and Executive Mappings already transferred. Please refresh and check.');
                    }
                    else
                    {
                        let msg = result;
                        helper.showToast("error", "Error", msg);
                    }
                    
   
                }
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