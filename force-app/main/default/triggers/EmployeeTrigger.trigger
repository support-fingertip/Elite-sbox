trigger EmployeeTrigger on Employee__c (before insert,before update, after Update,before Delete) {
    if(trigger.isinsert)
    {
        if(trigger.isBefore)
        {
            EmployeeTriggerHandler.beforeInsert(trigger.new);
        }
    }
    else if(trigger.isUpdate)
    {
        if(trigger.isBefore)
        {
            if(!EmployeeTriggerHandler.stopbeforeUpdate)
            {
                EmployeeTriggerHandler.stopbeforeUpdate = true;
                EmployeeTriggerHandler.beforeUpdate(trigger.new, trigger.oldMap);
            }
        }
        else
        {
            if(!EmployeeTriggerHandler.stopAfterUpdate)
            {
                EmployeeTriggerHandler.stopAfterUpdate = true;
                EmployeeTriggerHandler.AfterUpdate(trigger.new, trigger.oldMap);
            }
        }
        
    }
    else if (Trigger.isDelete && Trigger.isBefore) {
        if(Label.RestrictEmployeeDeletion == 'TRUE')
        {
            // Restrict deletion of Employee records
            for (Employee__c emp : Trigger.old) {
                emp.addError('Deletion of Employee records is not allowed.');
            }
        }
     
    }
    
    
    /*
    *********************************************************  
    @Event      	: After Update
    @Created Date   : Aug 19, 2025
    @author 		: Mayuri Patel
    @description 	: Targets Transfer in case of replacement
    ********************************************************
    */
    if(trigger.isAfter && trigger.isUpdate){
        Set<Id> empIds = new Set<Id>();
        for(Employee__c emp: trigger.new){
            if(emp.Is_Employee_Replaced__c &&
               emp.Is_Employee_Replaced__c != trigger.oldmap.get(emp.Id).Is_Employee_Replaced__c){
                   empIds.add(emp.Id);
               }
        }
        if(!empIds.isEmpty()){
            PrimaryTargetsBatch.transferTargets(empIds);
        }
    }

}