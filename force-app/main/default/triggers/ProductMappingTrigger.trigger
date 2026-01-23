trigger ProductMappingTrigger on Product_Mapping__c (Before insert,After insert,before update,After Update,after delete) 
{
    if(trigger.isInsert)
    {
        if(trigger.isBefore)
        {
            ProductMappingTriggerHandler.beforeInsert(trigger.new);
        }
        else
        {
            system.debug('enterdd--trigger');
            if(!ProductMappingTriggerHandler.isProductMappingAutoInsert)
            {
                ProductMappingTriggerHandler.isProductMappingAutoInsert = true;
                ProductMappingTriggerHandler.afterInsert(trigger.new);
            }
          
        }
    } 
    else if(trigger.isUpdate)
    {
        if(trigger.isBefore)
        {
             ProductMappingTriggerHandler.beforeUpdate(trigger.new,trigger.oldMap);
        }
        else if(trigger.isAfter)
        {
            if(!ProductMappingTriggerHandler.isProductMappingAutoUpdate)
            {
                ProductMappingTriggerHandler.isProductMappingAutoUpdate = true;
                ProductMappingTriggerHandler.afterUpdate(trigger.new,trigger.oldMap,trigger.newMap);
            }
           
        }
    }
    else if (Trigger.isDelete) {
        if(trigger.isAfter)
        {
            ProductMappingTriggerHandler.afterDelete(Trigger.old);
        }
    }
}