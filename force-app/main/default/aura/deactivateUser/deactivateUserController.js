({
    handleBeatOptionChange: function (component, event, helper) {
        component.set('v.beatOption', event.getParam('value'));
    },

    handleCancel: function (component, event, helper) {
        $A.get('e.force:closeQuickAction').fire();
    },

    handleConfirm: function (component, event, helper) {
        var action = component.get('c.deactivateUserWithBeatOption');
        action.setParams({
            'recordId': component.get('v.recordId'),
            'beatOption': component.get('v.beatOption')
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var result = response.getReturnValue();
                var type = result && result.startsWith('Error') ? 'error' : 'success';
                var message = result && result.startsWith('Error') ? result.replace('Error: ', '') : 'User De-Activated Successfully';
                $A.get('e.force:showToast').setParams({
                    'type': type,
                    'title': type === 'success' ? 'Success' : 'Error',
                    'message': message
                }).fire();
            } else if (state === 'ERROR') {
                var errors = response.getError();
                var message = 'Unknown error';
                if (errors && errors[0] && errors[0].message) {
                    message = errors[0].message;
                }
                $A.get('e.force:showToast').setParams({
                    'type': 'error',
                    'title': 'Error',
                    'message': message
                }).fire();
            }
            $A.get('e.force:refreshView').fire();
            $A.get('e.force:closeQuickAction').fire();
        });
        $A.enqueueAction(action);
    }
})