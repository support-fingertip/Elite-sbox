global class DeactivatePJPScheduler  implements Database.Batchable<sObject>,Database.Stateful,Schedulable{
    
      public Database.QueryLocator start(Database.BatchableContext BC){
         String query = 'SELECT Id, Name, OwnerId,User__c,Start_Month__c,Next_Start_Date__c FROM Calendar_beat__c WHERE Active__c = true AND Next_Start_Date__c <= TODAY';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<Calendar_beat__c> scope){
        
        for(Calendar_Beat__c pjp: scope){
            pjp.Active__c = false;
        }
        
        try{
            Database.update(scope,false);
        }
        catch(Exception ex){
            system.debug(ex.getMessage());
        }

    }
    
    public void finish(Database.BatchableContext BC){
    }
    
    global void execute(SchedulableContext SC){
       
        
    } 
}