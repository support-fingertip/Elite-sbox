({
    Approval: function(component, event, helper) {
         component.set("v.Saving", true);
        var comments = component.get('v.Comments');
        if(comments == null || comments== undefined || comments == '')
        {
            helper.showToast("Please Enter Comments","error","Error");
            component.set("v.Saving", false);
        }
        else
        {
            
            var submitValidateAction = component.get("c.validateCreditField");
            submitValidateAction.setParams({
                'recordId': component.get('v.recordId'),
                'comments':comments,
            });
            submitValidateAction.setCallback(this, function(submitResponse) {
                var submitState = submitResponse.getState();
                if (submitState === "SUCCESS") {
                    var retValue = submitResponse.getReturnValue();
                    if(retValue == 'Credit_Limit')
                    {
                        helper.showToast("Please fill in the credit limit before submitting for credit approval","Error","Error");
                    }
                    else if(retValue == 'Credit_Days')
                    {
                        helper.showToast("Please fill in the credit days before submitting for credit approval","Error","Error");
                    }
                    else if(retValue == 'Success')
                    {
                        helper.submitForApproval(component,event,helper);
                    }
                  
                    component.set("v.Saving", false);
                } else {
                    $A.get("e.force:closeQuickAction").fire();
                    var errorMsg = submitResponse.getError()[0].message; 
                    helper.showToast('Error while submitting for approval: ' + errorMsg, 'info','Info');
                }
            });
            $A.enqueueAction(submitValidateAction);
            
        }
    },
    Cancel: function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
         component.set("v.Saving", false);
    }
 })