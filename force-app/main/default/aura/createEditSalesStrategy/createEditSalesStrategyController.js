({
    doInit : function(component, event, helper) {
        const recordId = component.get('v.recordId');
        const heading = recordId != undefined ? 'Edit Sales Strategy' : 'New Sales Strategy';
        
        component.set('v.heading',heading);
        component.set('v.isSchemeTrue',true);
    },
    onClickAction:function(component, event, helper) {
        var msg = event.getParam("message");
        if(msg == 'close'){
            let recordId = component.get('v.recordId');
            let navEvt = recordId ? 
                $A.get("e.force:navigateToSObject") : 
            $A.get("e.force:navigateToList");
            
            navEvt.setParams(recordId ? {
                "recordId": recordId,
                "slideDevName": "related"
            } : {
                "listViewId": event.getParam("id"),
                "listViewName": null,
                "scope": "Scheme__c"
            });
            
            navEvt.fire();
        }
        else if(msg == 'Done'){
            let recordId = event.getParam("id");
            let navEvt = $A.get("e.force:navigateToSObject");
            navEvt.setParams({
                "recordId": recordId,
                "slideDevName": "related"
            });
            navEvt.fire();
            setTimeout(() => {
                $A.get("e.force:refreshView").fire();
            }, 1000);
            }
    },
})