({
    onInit: function(component, event, helper) {
        helper.loadUsers(component);
    },

    handleUserSelect: function(component, event, helper) {
        component.set('v.selectedUserId', event.target.value);
    },

    handleShare: function(component, event, helper) {
        helper.shareBeats(component);
    },

    handleCancel: function(component, event, helper) {
        $A.get('e.force:closeQuickAction').fire();
    }
})
