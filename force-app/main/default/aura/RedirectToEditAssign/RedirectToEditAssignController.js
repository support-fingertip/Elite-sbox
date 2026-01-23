({
    doInit : function(component, event, helper) {
        
        alert('record-aura:'+component.get('v.recordId') );
        
        var navService = component.find("navService");
        var pageRef = {
            type: "standard__navItemPage",
            attributes: {
                apiName: "UserAssignmentPage" // match with the Lightning App Page Name
            },
            state: {
                recordId: component.get('v.recordId')  // Pass the recordId to the app page as part of the state
            }
        };
        alert('pageRef-aura:'+JSON.stringify(pageRef));
        navService.navigate(pageRef);
    }
})