({
    
    init : function(component, event, helper) {

        component.set("v.isProcessing", false);
        
    },
    transfer: function(component, event, helper) {
        component.set("v.isProcessing", true);
        helper.rejectRecords(component, event, helper);
    },
    closeModel: function(component, event, helper) {
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
    }
    
})