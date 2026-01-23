({
	doInit : function(component, event, helper) {
        component.set("v.openPopup", true);
	},
    onPageReferenceChange: function(component, event, helper) {
        // Force refresh the page
        $A.get('e.force:refreshView').fire();
    }
})