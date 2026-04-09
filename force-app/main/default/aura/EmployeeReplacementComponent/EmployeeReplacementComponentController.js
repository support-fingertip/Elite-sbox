({

    init : function(component, event, helper) {

        component.set("v.isProcessing", false);
        component.set("v.modeOptions", [
            { label: 'Clone  (keeps old user records, creates new ones for the new DSM)', value: 'clone' },
            { label: 'Transfer (re-assigns existing records from old DSM to new DSM)', value: 'transfer' }
        ]);

    },
    transfer: function(component, event, helper) {
        component.set("v.isProcessing", true);
        helper.trasferRecords(component, event, helper);
    },
    closeModel: function(component, event, helper) {
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
    }

})