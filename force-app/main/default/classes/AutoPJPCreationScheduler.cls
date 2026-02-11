global class AutoPJPCreationScheduler  implements Database.Batchable<sObject>,Database.Stateful,Schedulable{
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT Id, Name, OwnerId,User__c,Start_Month__c,Next_Start_Date__c,Recurring_Frequency__c FROM Calendar_beat__c WHERE Active__c = true AND Recurring_Frequency__c != null AND Next_PJP_Run__c = TODAY';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<Calendar_beat__c> pjpRecords){
        
        
        Calendar_beat__c pjp = pjpRecords[0];
        Integer frequency = (Integer) pjp.Recurring_Frequency__c;
        
        Date today = Date.today();
        Date newStartDate = today.addDays(-frequency); // Start from the next day after the last item
        
        pjp.Next_PJP_Run__c = today.addDays(frequency);
        pjp.Last_PJP_Run__c = today;
        
        List<PJP_Item__c> futureItems = [select Id,Date__c from PJP_Item__c where PJP__c = : pjp.Id and Date__c >=:System.TODAY() limit 1];
        system.debug('futureItems:' + futureItems);
        
        if(futureItems.isEmpty()){
            List<PJP_Item__c> items = [select Id,Name,Beat__c,Assigned_Beat__c,Date__c,PJP__c, Order_Number__c,
                                       Status__c from PJP_Item__c
                                       where PJP__c = : pjp.Id and (Date__c <:System.TODAY() and Date__c >= :newStartDate)
                                       order by Date__c asc];     
            
            if (!items.isEmpty()) {
                
                
                // Create a map to store unique items by date
                Map<Date,PJP_Item__c> itemsMap = new Map<Date,PJP_Item__c>();
                for(PJP_Item__c itm : items){
                    if(!itemsMap.containsKey(itm.Date__c)){
                        itemsMap.put(itm.Date__c, itm);
                    }
                }
                Date pjpDate = today;
                List<PJP_Item__c> itemsToCreate = new List<PJP_Item__c>();
                while(newStartDate <= today){
                    if(itemsMap.containsKey(newStartDate)){
                        PJP_Item__c newItem = new PJP_Item__c();
                        newItem.PJP__c = pjp.Id;
                        newItem.Date__c = pjpDate;
                        newItem.Beat__c = itemsMap.get(newStartDate).Beat__c; // Set to null or appropriate value
                        newItem.Assigned_Beat__c = itemsMap.get(newStartDate).Beat__c; // Set to null or appropriate value
                        newItem.Order_Number__c = 1; // Set to default or appropriate value
                        newItem.Status__c = 'Approved'; // Set to default or appropriate value
                        itemsToCreate.add(newItem);
                    }
                    newStartDate = newStartDate.addDays(1);
                    pjpDate = pjpDate.addDays(1);
                }
                
                if(!itemsToCreate.isEmpty()){
                    try{
                        insert itemsToCreate;
                    }
                    catch(Exception e){
                        ExceptionHandler.addLog(e, String.valueOf(itemsToCreate), 'userProfileLWC.createPJP');
                    }
                }
            }
        }   
        
        try{
            update pjp;
        }
        catch(Exception e){
            ExceptionHandler.addLog(e, String.valueOf(pjp), 'userProfileLWC.createPJP');
        }
        
        
        
    }
    
    public void finish(Database.BatchableContext BC){
    }
    
    global void execute(SchedulableContext SC){
        
        Database.executeBatch(new AutoPJPCreationScheduler(), 1);
        /* String cronExpression = '0 00 6 * * ?'; // Cron expression for 6:00 AM every day
        String jobName = 'AutoPJPCreationScheduler';
        
        System.schedule(jobName, cronExpression, new AutoPJPCreationScheduler());*/
    } 
    
}