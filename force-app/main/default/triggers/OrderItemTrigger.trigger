trigger OrderItemTrigger on Order_Item__c (after insert,after update, after undelete, after delete) {
    /*if(Trigger.isInsert){ 
        if(Trigger.isAfter)
        {
            OrderItemTriggerHandler.updateOrderAmount(trigger.new);
            Set<Id> orderIds = new Set<Id>();
            for(Order_Item__c item : trigger.new) {
                if(item.Order__c != null) {
                    orderIds.add(item.Order__c);
                }
            }
            if(!orderIds.isEmpty()) {
                // Query orders to get Executive__c field
                List<Order__c> orders = [
                    SELECT Id, Executive__c, OwnerId 
                    FROM Order__c 
                    WHERE Id IN :orderIds 
                    AND Executive__c != null
                ];
                
                if(!orders.isEmpty()) {
                    OrderItemTriggerHandler.updateOwnerAndGrantAccessFromItems(orders, UserInfo.getUserId());
                }
            }
        }
    } 
    else if(Trigger.isUpdate)
    {
        if(Trigger.isAfter)
        {
            OrderItemTriggerHandler.updateOrderAmount(Trigger.new);
        }
    }
    else if(Trigger.isUndelete)
    {
        if(Trigger.isAfter)
        {
            OrderItemTriggerHandler.updateOrderAmount(Trigger.new);
        }
    }
    else if(Trigger.isDelete)
    {
        if(Trigger.isAfter)
        {
            OrderItemTriggerHandler.updateOrderAmount(Trigger.old);
        }
    }*/

}