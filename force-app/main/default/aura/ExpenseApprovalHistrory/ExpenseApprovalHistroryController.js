({
    doInit : function(component, event, helper)
    {
        component.set('v.spinner', true); 
        var action = component.get("c.GetData");
        action.setParams({
            expenseId: component.get("v.recordId"),
            filter: 'All'
        }); 
        action.setCallback(this, function(response){ 
            if(response.getState()=="SUCCESS"){ 
                component.set("v.paginationList",response.getReturnValue()); 
                component.set("v.selFilter",'All'); 
            }
            component.set('v.spinner', false); 
        });
        $A.enqueueAction(action);
    },
    //On Piclist Change
    onChange : function(component, event, helper)
    {
        component.set('v.spinner', true); 
        var pageSize = component.get("v.pageSize");
        var action = component.get("c.GetData");
        action.setParams({
            ldId: component.get("v.recordId"),
            filter: component.get('v.selFilter')
        }); 
        action.setCallback(this, function(response){ 
            if(response.getState()=="SUCCESS"){ 
                component.set("v.paginationList", response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
        component.set('v.spinner', false); 
    },
    refresh : function(component, event, helper)
    {
        var action = component.get('c.doInit')
        $A.enqueueAction(action);
        $A.get("e.force:refreshView").fire();
    }
})