({
    doInit : function(component, event, helper) {
        const recordId = component.get('v.recordId');
        const heading = recordId != undefined ? 'Edit Order' : 'New Order';
        component.set('v.heading',heading);
        component.set('v.isOrderTrue',true);
    },
    onClickAction:function(component, event, helper) {
        var msg = event.getParam("message");
        if(msg == 'close'){
            var urlEvent = $A.get("e.force:navigateToURL");
            urlEvent.setParams({
                "url": "/lightning/o/Order__c/list?filterName=TODAY"
            });
            urlEvent.fire();
            $A.get('e.force:refreshView').fire();
        }
        else if(msg == 'Done'){
            var urlEvent = $A.get("e.force:navigateToURL");
            urlEvent.setParams({
                "url": "/lightning/o/Order__c/list?filterName=TODAY"
            });
            urlEvent.fire();
            $A.get('e.force:refreshView').fire();
        }
    },
    onPageReferenceChange: function(component, event, helper) {
        var detail = {};
        detail["isPullToRefreshEnabled"] = false;
        detail["isPullToShowMoreEnabled"] = false;
        var updateScrollSettingsEvent = new CustomEvent("updateScrollSettings", {
            detail: detail,
            bubbles: true,
            composed: true
        });
        dispatchEvent(updateScrollSettingsEvent);
        // Force refresh the page
       // $A.get('e.force:refreshView').fire();
    }
})