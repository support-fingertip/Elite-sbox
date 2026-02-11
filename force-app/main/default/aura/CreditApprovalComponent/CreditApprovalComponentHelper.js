({
	  showToast : function(message,type,title) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title":title,
            "type":type,
            "message":  message
        });
        toastEvent.fire();
    },
    submitForApproval : function(component,event,helper) {
         if(!window.navigator.onLine){
            helper.showToast('You are offline!','info');
        }
        else
        {
            var submitAction = component.get("c.submitForApproval");
            submitAction.setParams({
                'recordId': component.get('v.recordId'),
                'comments':comments,
            });
            submitAction.setCallback(this, function(submitResponse) {
                var submitState = submitResponse.getState();
                if (submitState === "SUCCESS") {
                    $A.get("e.force:closeQuickAction").fire();
                    var navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                        "recordId": component.get('v.recordId'),
                        "slideDevName": "detail"
                    });
                    navEvt.fire();
                    $A.get('e.force:refreshView').fire();
                    
                    helper.showToast("Primary customer has been submitted for credit approval","Success","Success");
                    
                } else {
                    $A.get("e.force:closeQuickAction").fire();
                    var errorMsg = submitResponse.getError()[0].message; 
                    helper.showToast('Error while submitting for approval: ' + errorMsg, 'info','Info');
                }
            });
            $A.enqueueAction(submitAction);
        }
    }
})