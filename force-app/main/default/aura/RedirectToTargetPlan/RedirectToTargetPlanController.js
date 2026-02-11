({
	doInit : function(component, event, helper) {
         component.set('v.openPopup',true);
	},
    onClickClosePopup: function(component, event, helper) {
         component.set('v.openPopup',false);
        $A.get('e.force:refreshView').fire();
        var getMessage = event.getParam('eventType');
        if(getMessage == 'Cancel'){
            var urlEvent = $A.get("e.force:navigateToURL");
            urlEvent.setParams({
                "url": "/lightning/o/Target_Plan__c/home"
            });
            urlEvent.fire();
        }
        else if(getMessage == 'Done')
        {
            var Id = event.getParam('Id');
            $A.get('e.force:refreshView').fire();
            var navEvt = $A.get("e.force:navigateToSObject");
            navEvt.setParams({
                "recordId": Id,
                "slideDevName": "detail"
            });
            navEvt.fire();
        }
    },
})