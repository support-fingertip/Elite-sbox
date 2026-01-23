({
    
    createUser: function(component, event, helper) {
        var action = component.get("c.deactivateUser");
        action.setParams({
            "recordId": component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (state === 'SUCCESS') {
                $A.get("e.force:showToast").setParams({
                    "type": "success",
                    "title": "Success",
                    "message": "User De-Activated Successfully"
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