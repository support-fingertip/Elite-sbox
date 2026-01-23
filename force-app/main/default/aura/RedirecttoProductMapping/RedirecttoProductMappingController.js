({
	doInit : function(component, event, helper) {
         component.set('v.openPopup',true);
	},
    onClickClosePopup: function(component, event, helper) {
        $A.get('e.force:refreshView').fire();
        var getMessage = event.getParam('eventType');
        if(getMessage == 'Cancel'){
            component.set('v.openPopup',false);
            var urlEvent = $A.get("e.force:navigateToURL");
            urlEvent.setParams({
                "url": "/lightning/o/Account/home"
            });
            urlEvent.fire();
        }
        else if(getMessage == 'Done')
        {
            component.set('v.openPopup',false);
            var Id = event.getParam('Id');
            var navEvt = $A.get("e.force:navigateToSObject");
            navEvt.setParams({
                "recordId": Id,
                "slideDevName": "detail"
            });
            navEvt.fire();
            $A.get('e.force:refreshView').fire();
        }
    },
})