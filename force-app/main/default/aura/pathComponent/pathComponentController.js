({
    doInit: function (component, event, helper) {
        helper.getAllValues(component,event,helper);
        var todayy = new Date();
        var formattedMaxDate = todayy.toISOString().split('T')[0];
        component.set('v.TodaysDate',formattedMaxDate);
    },
    click: function(component, event, helper) {
        var target = event.target;
        if (target.tagName.toLowerCase() === 'span' && target.parentNode.tagName.toLowerCase() === 'a') {
            target = target.parentNode;
        }
        var index = parseInt(target.dataset.index);
        var value;
        if (index != undefined && !isNaN(index)) {
            value = component.get("v.steps")[index];
            component.set("v.currentStep", value);
            component.set("v.currentIndex", index);
            component.set("v.selectedValue", value);
            helper.renderStateCLick(component);
            if(component.get("v.currentStep")=='Follow Up')
            {
                helper.getRatingfieldValue(component, event, helper);
                component.set("v.Followuppop", true);
            }
            else if(component.get("v.currentStep")==='Closed Lost')
            {
                helper.getLeadLostValue(component, event, helper);
                component.set("v.LostPop", true);  
            }
        }
    },
    
    
    click2:function(component, event, helper) {
        var target = event.target;
        if (target.tagName.toLowerCase() === 'span' && target.parentNode.tagName.toLowerCase() === 'a') {
            target = target.parentNode;
        }
        var index = parseInt(target.dataset.index);
        var value;
        if (index != undefined && !isNaN(index)) {
            value = component.get("v.steps")[index];
            component.set("v.currentStep", value);
            component.set("v.currentIndex", index);
            component.set("v.selectedValue", value);
            helper.renderStateCLick(component);
           
        }
    },
    Cancel:function (component, event, helper) {
        component.set("v.Followuppop", false);
        component.set("v.LostPop", false);
        component.set('v.searchUsers',[]);
    },
    SaveRatingPop: function(component, event, helper) 
    {
        var followUp = component.get("v.FollowUpDate");
        var todayy = component.get("v.TodaysDate");
        if(followUp != null){
            if(followUp >= todayy ){
                var action = component.get("c.SaveRatingpop");
                action.setParams({
                    'Rating':component.get("v.SelectedRating"),
                    'LeadId':component.get("v.recordId"),
                    'FollowUpDate':followUp,
                })
                action.setCallback(this, function(response) {
                    var state = response.getState();
                    if (state === "SUCCESS") { 
                        helper.showToast('Rating saved successfully','success');
                        component.set("v.Followuppop", false);
                        component.set('v.searchUsers',[]);
                        $A.get('e.force:refreshView').fire();
                        helper.getAllValues(component,event, helper);
                        
                    }
                    
                });
                $A.enqueueAction(action);
            }
        }
        else{
            helper.showToast('Please select FollowUp date','error');
        }
    },
    SavelostPop:function(component, event, helper){       
        var lostreason = component.get("v.lostReasonFieldval");
        var compname = component.get("v.LostToCompetitorName");
        var otherreason = component.get("v.Comments");
        
        if(lostreason !=null && lostreason!=''){
            if(lostreason == 'Other' && (otherreason == null || otherreason == '')){
                helper.showToast('Please enter Other Reason','error');
            }
            else if(lostreason == 'Lost to competitor' && (compname == null || compname == '')){
                helper.showToast('Please enter Competitor Name','error');
            }
                else{
                    var action = component.get("c.Savelostpop");
                    action.setParams({
                        'OtherReason':component.get("v.Comments"),
                        'lostReason':lostreason,
                        'LostToCompetitorName':component.get("v.LostToCompetitorName"),
                        'LeadId':component.get("v.recordId"),
                        
                    })
                    action.setCallback(this, function(response) {
                        var state = response.getState();
                        if (state === "SUCCESS") { 
                            helper.showToast('Lost reason saved successfully','success');
                            component.set("v.LostPop", false);
                            $A.get('e.force:refreshView').fire();
                            helper.getAllValues(component,event, helper);
                        }
                    });
                    $A.enqueueAction(action);
                }
        }
        else{
            helper.showToast('Please select Lost Reason','error');
        }
        
    },
    MarkStatus : function(component, event, helper) 
    {
        var action = component.get("c.MarkStatusAPex");
        action.setParams({
            'recordId':  component.get("v.recordId"),
            'currentStep': component.get("v.currentStep"),
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") { 
                $A.get('e.force:refreshView').fire();
                helper.showToast('Lead Status changed successfully','success');
                helper.getAllValues(component,event, helper);
            }
        });
        $A.enqueueAction(action);
    },
    
})