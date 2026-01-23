({
    doInit : function(component, event, helper) {
        
        var recordId = component.get('v.recordId');
        var device = $A.get("$Browser.formFactor");
        if(device == 'DESKTOP'){
            var urlPdf = "/apex/OrderPdf?id=" + recordId;
            $A.get("e.force:closeQuickAction").fire();
            window.open(urlPdf, "_blank");
            
        }
        else{
            var OrgURL = component.get('v.customLabel');
            var urlOpen = OrgURL+'/OrderPdf?Id='+recordId;
            $A.get("e.force:closeQuickAction").fire();
            $A.get('e.force:refreshView').fire();
            var navService = component.find("navService");
            var pageReference = {
                type: "standard__webPage",
                attributes: {
                    url: urlOpen
                }
            };
            navService.navigate(pageReference);
            
        }
    }
})