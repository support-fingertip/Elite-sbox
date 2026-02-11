({
     getAllValues : function(component, event, helper) 
    {
        var action = component.get("c.getAllData");
        action.setParams({
            'recordId': component.get("v.recordId"),
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") { 
                var result = response.getReturnValue();
                component.set('v.ratingField',result.picklistValues);
                component.set('v.lostReasonField',result.LostpicklistValues);
                component.set("v.lostReasonFieldval", result.LeadRec.Lost_Reasons__c);
                component.set("v.Comments", result.LeadRec.Other_reason__c);
                component.set("v.SelectedRating", result.RatingVal); 
                component.set("v.LostToCompetitorName", result.LeadRec.LostToCompetitorName);
                component.set("v.FollowUpDate", result.LeadRec.Followup_Date__c);
                component.set('v.steps', result.LeadStatuspicklistValues);
                component.set("v.currentStep",result.LeadRec.Lead_Status__c);
                component.set("v.ExsitedStep",result.LeadRec.Lead_Status__c);
                component.set("v.ApprovalStatus",result.LeadRec.Approval_Status__c);
                var stepsArray = result.LeadStatuspicklistValues;
                var indexOfLeadStatus = stepsArray.indexOf(result.LeadRec.Lead_Status__c);
                component.set("v.currentIndexExisted", indexOfLeadStatus);
                component.set("v.currentIndex", indexOfLeadStatus);
                helper.renderState(component);
                
            }
        });
        $A.enqueueAction(action);
    },
     getRatingfieldValue : function(component, event, helper) 
    {
     
        var action = component.get("c.RatingValue");
        action.setParams({
            'recordId': component.get("v.recordId"),
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") { 
                var result = response.getReturnValue();
                component.set("v.SelectedRating", result.Rating__c);
                component.set("v.FollowUpDate", result.Followup_Date__c);
            }
        });
        $A.enqueueAction(action);
    },
     getLeadLostValue : function(component, event, helper) 
    {
       
        var action = component.get("c.LeadRecord");
        action.setParams({
            'recordId': component.get("v.recordId"),
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") { 
                var result = response.getReturnValue();
                component.set("v.lostReasonFieldval", result.Lost_Reasons__c);
                component.set("v.Comments", result.Other_reason__c);
                 component.set("v.LostToCompetitorName", result.Lost_to_competitor_Name__c);
            }
        });
        $A.enqueueAction(action);
    },
    renderState: function(component) {
        var currentStep = component.get("v.currentStep"),
            allSteps = component.get("v.steps"),
            render = [],
            state = "",
            bgColor ='slds-path__title',
            currentIndex = component.get("v.currentIndex");
        
        allSteps.forEach(function(step,index){
            bgColor ='slds-path__title';
            if(currentStep === step) 
            {
                state = "colorItem8"; 
                bgColor ='slds-path__title-white';
            }
            else if( index <= currentIndex)
            {
                state = "colorItem"+(index+1);
            }
           	else 
            {
                state = "slds-is-incomplete";             
            }
            render.push({ label: step, selected: state === "colorItem8", state: state, bgColor :bgColor });
        });
        component.set("v.renderInfo", render);   
    },
    renderStateCLick: function(component) {
        var currentStep = component.get("v.currentStep"),
            allSteps = component.get("v.steps"),
            render = [],
            state = "",
            bgColor ='slds-path__title',
            ExsitedStep = component.get("v.ExsitedStep"),
            currentIndexExisted = component.get("v.currentIndexExisted");
        
        allSteps.forEach(function(step,index){
            bgColor ='slds-path__title';
            if(currentStep === step) 
            {
                state = "colorItem8"; 
                bgColor ='slds-path__title-white';
            }
            else if(ExsitedStep === step )
            {
                    state = "slds-is-current"; 
            }
            else if( index <= currentIndexExisted)
            {
                state = "colorItem"+(index+1);
            }
            
          	else 
            {
             	state = "slds-is-incomplete";             
           	} 
            
            
            render.push({ label: step, selected: state === "colorItem8", state: state, bgColor :bgColor });
        });
        component.set("v.renderInfo", render);   
    },
    showToast : function(message,type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type":type,
            "message":  message 
        });
        toastEvent.fire();
    },
})