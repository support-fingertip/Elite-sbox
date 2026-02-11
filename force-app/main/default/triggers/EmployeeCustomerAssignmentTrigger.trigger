trigger EmployeeCustomerAssignmentTrigger on Employee_Customer_Assignment__c (before insert,after insert,before Update,after Update,After Delete) {
    if(trigger.isInsert)
    {
        if(trigger.isBefore)
        {
            EmployeeCustomerAssignmentTriggerHandler.beforeInsert(trigger.new);
        }
        else
        {
            EmployeeCustomerAssignmentTriggerHandler.afterInsert(trigger.new);
        }
    } 
    else if(trigger.isUpdate)
    {
        if(trigger.isBefore)
        {
            EmployeeCustomerAssignmentTriggerHandler.beforeUpdate(trigger.new,trigger.oldMap);
        }
        else
        {
            EmployeeCustomerAssignmentTriggerHandler.afterUpdate(trigger.new,trigger.oldMap);
        }
    }
    else if (Trigger.isDelete) {
        if(trigger.isAfter)
        {
            EmployeeCustomerAssignmentTriggerHandler.afterDelete(Trigger.old);
        }
    }

}