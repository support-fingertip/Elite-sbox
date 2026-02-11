({
    createUser: function(component, event, helper) {
        console.log('Entered createUser');
        
        var action = component.get("c.createUser");
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
              
                    if (result.includes('DUPLICATE_USERNAME')) 
                    {
                            
                        let msg = 'Duplicate Username. The username already exists in another Salesforce organization. Usernames must be unique across all Salesforce organizations.'
                        helper.showToast("error", "Error", msg);
                    }
                    else if(result.includes("Employee_Code__c"))
                    {
                        helper.showToast("error", "Error",'An employee already exists with the same employee code');
                    }
                    else if(result.includes("REQUIRED_FIELD_MISSING"))
                    {
                        helper.showToast("error", "Error",'Please fill all mandatory fields before activating the employee');
                    }
                    else if(result.includes("ROLE_MISSING"))
                    {
                        helper.showToast("error", "Error",'Please assign a role to the employee before activating');
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