({
    onInit: function(component, event, helper) {
        var action = component.get('c.getUsersForBeatSharing');
        action.setParams({
            'employeeId': component.get('v.recordId')
        });
        action.setCallback(this, function(response) {
            component.set('v.isLoading', false);
            var state = response.getState();
            if (state === 'SUCCESS') {
                component.set('v.userList', response.getReturnValue());
            } else {
                var errors = response.getError();
                var msg = errors && errors[0] ? errors[0].message : 'Unknown error';
                $A.get('e.force:showToast').setParams({
                    'type': 'error',
                    'title': 'Error',
                    'message': msg
                }).fire();
            }
        });
        $A.enqueueAction(action);
    },

    handleUserSelect: function(component, event, helper) {
        component.set('v.selectedUserId', event.target.value);
    },

    handleShare: function(component, event, helper) {
        var targetUserId = component.get('v.selectedUserId');
        if (!targetUserId) return;

        var action = component.get('c.shareBeatToUser');
        action.setParams({
            'employeeId': component.get('v.recordId'),
            'targetUserId': targetUserId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            var result = state === 'SUCCESS' ? response.getReturnValue() : null;
            var isError = !result || result.startsWith('Error');
            $A.get('e.force:showToast').setParams({
                'type': isError ? 'error' : 'success',
                'title': isError ? 'Error' : 'Success',
                'message': isError ? (result ? result.replace('Error: ', '') : 'Unknown error') : 'Beats shared successfully'
            }).fire();
            $A.get('e.force:refreshView').fire();
            $A.get('e.force:closeQuickAction').fire();
        });
        $A.enqueueAction(action);
    },

    handleCancel: function(component, event, helper) {
        $A.get('e.force:closeQuickAction').fire();
    }
})
