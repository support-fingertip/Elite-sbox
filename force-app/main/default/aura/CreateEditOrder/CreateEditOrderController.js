({
    doInit : function(component, event, helper) {
        const recordId = component.get('v.recordId');
        const heading = recordId != undefined ? 'Edit Order' : 'New Order';
        component.set('v.heading',heading);
        component.set('v.isOrderTrue',true);
    },
    onClickAction:function(component, event, helper) {
        var msg = event.getParam("message");
        if(msg == 'close' || msg == 'Done'){
            // Navigate to the Order Today list view. Use force:navigateToList (loads
            // the list fresh) when we have the ListView Id; otherwise fall back to the
            // URL. Do NOT fire force:refreshView here — racing the navigation leaves
            // the list view stuck loading until a manual browser refresh.
            var listViewId = event.getParam("id");
            if(listViewId){
                var navList = $A.get("e.force:navigateToList");
                navList.setParams({
                    listViewId: listViewId,
                    listViewName: null,
                    scope: "Order__c"
                });
                navList.fire();
            } else {
                var urlEvent = $A.get("e.force:navigateToURL");
                urlEvent.setParams({
                    "url": "/lightning/o/Order__c/list?filterName=TODAY"
                });
                urlEvent.fire();
            }
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