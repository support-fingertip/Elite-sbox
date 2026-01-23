trigger TargetActualsTrigger on TargetActuals__c (before insert,before update) {
    
    
    if(trigger.isBefore && trigger.isInsert){
        for(TargetActuals__c ta: trigger.new){
            if(ta.User__c != null){
                ta.OwnerId = ta.User__c;
            }
            else{
                 ta.addError('User cannot be blank.');
            }
        }
    }
    
    if(trigger.isBefore && trigger.isUpdate){
        for(TargetActuals__c ta: trigger.new){
            
            if (!System.isBatch() && !System.isScheduled()) {
                
                if(ta.Start_Date__c <= Date.today()){
                    ta.addError('Target Update for Past or Current month is not permitted!');
                }
            }
               /*if((ta.Target_Quantity_KG__c != trigger.oldmap.get(ta.id).Target_Quantity_KG__c || 
                 	ta.Target_Revenue__c != trigger.oldmap.get(ta.id).Target_Revenue__c) && 
                 		ta.Month__c <= String.valueof(Date.today().month())){
                            
                            ta.addError('Target Update for Past or Current month is not permitted!');
                   
               }*/
            	   
        }
        
    }
    
    if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){
         for(TargetActuals__c ta: trigger.new){
             if(ta.Target_Quantity_KG__c == null && ta.Target_Revenue__c == null){
                 ta.addError('Enter atleast one target value for defining the target.');
             }   
             
         }
    }

}