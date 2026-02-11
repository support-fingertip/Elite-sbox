({
    handleInit: function(component, event, helper) {
        // Prevent multiple executions
        if (!component.get("v.isInitialized")) {
            component.set("v.isInitialized", true);
            helper.updateUser(component, event, helper);
        }
    }
})