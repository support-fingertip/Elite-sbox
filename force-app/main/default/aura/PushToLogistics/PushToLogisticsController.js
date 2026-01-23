({
  /*  doInit : function(component, event, helper) {
        var action = component.get("c.pushToLogistics");
        action.setParams({
            'recId' :component.get('v.recordId'),
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state == "SUCCESS") {
                var db = response.getReturnValue();
                helper.showToast('Order has been pushed to Logistics',"Success");
                $A.get("e.force:closeQuickAction").fire();
                $A.get('e.force:refreshView').fire();
            }
        });
        $A.enqueueAction(action);	
    }*/
   
    doInit: function(component,event,helper){
        var action = component.get("c.sendOrder");
        action.setParams({
            "recId":component.get("v.recordId")
        });
        action.setCallback(this,function(response){
            if(response.getState() == 'SUCCESS' ) {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "Info",
                    "title": "Sending Order",
                    "message":"Order is being sent to Azure. Once the response is received, the order status will be updated."
                });
                toastEvent.fire();
                 $A.get('e.force:refreshView').fire();
                 event.stopPropagation();
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
                
            }
            else
            {
                (state === 'ERROR')
                {
                    console.log('failed');
                }
            }
        });
        $A.enqueueAction(action);
    },
   
})