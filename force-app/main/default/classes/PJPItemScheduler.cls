global class PJPItemScheduler implements Database.Batchable<sObject>,Database.Stateful,Schedulable{
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT Id, Name, OwnerId,User__c,Start_Month__c,Next_Start_Date__c,(select Id,Name,Date__c,PJP__c from PJP_Items__r order by Date__c desc limit 1) FROM Calendar_beat__c WHERE Active__c = true AND Auto_PJP_Creation__c = true';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<Calendar_beat__c> pjpRecords){
        
        
        Calendar_beat__c pjp = pjpRecords[0];
        String ids = pjp.User__c;
        
        
        PJP_Item__c lastPJPItem = new PJP_Item__c();
        
        if(pjp.PJP_Items__r.size()>0){
            lastPJPItem = pjp.PJP_Items__r[0];
            
            if(lastPJPItem.Date__c == Date.today()){
                List<Child_Beat__c> childBeats = [SELECT Id, Name,isRepeat__c,Order_Number__c,
                                                  Primary_Customer__c, Sub_Stockist__c
                                                  FROM Child_Beat__c
                                                  WHERE OwnerId =:ids AND  Active__c = true order by Order_Number__c];
                
                
                List<User> selUser = [SELECT Id, Name, Region__c
                                      FROM User
                                      WHERE Id = :ids];
                
                String userRegion = selUser[0].Region__c;
                
                List<Holiday__c> holi = [SELECT id, name,Date__c from Holiday__c  WHERE Region__c INCLUDES (:userRegion)
                                         ORDER BY CreatedDate ASC];
                
                Set<Date> dates = new Set<Date>();
                
                for(Holiday__c hd: holi){
                    dates.add(hd.Date__c);
                }
                
                
                List<PJP_Item__c> itemsToCreate = new List<PJP_Item__c>();
                
                Date dt = Date.today().addDays(1);
                
                for(Child_Beat__c cb: childBeats){
                    
                    Integer dayOfWeek = dt.toStartOfWeek().daysBetween(dt);
                    
                    if(dayOfWeek == 0){
                        dt = dt.addDays(1);
                    }
                    else{
                        while(dates.contains(dt)){
                            dt = dt.addDays(1);
                        }
                    }
                    
                    
                    PJP_Item__c item = new PJP_Item__c();
                    item.PJP__c = pjp.Id;
                    item.Date__c = dt;
                    item.Beat__c = cb.Id;
                    item.Assigned_Beat__c = cb.Id;
                    item.Beat__c = cb.Id;
                    /*  item.Order_Number__c = cb.Beat_Assignment__r[0].Order_Number__c; */
                    item.Order_Number__c = cb.Order_Number__c;
                    item.Status__c = 'Approved';
                    itemsToCreate.add(item);
                    dt = dt.addDays(1);
                }
                
                if(!itemsToCreate.isEmpty()){
                    insert itemsToCreate;
                }
            }
            
        }
        
        
        
    }
    
    public void finish(Database.BatchableContext BC){
    }
    
    global void execute(SchedulableContext SC){
        
        Database.executeBatch(new PJPItemScheduler(), 1);
       /* String cronExpression = '0 55 23 * * ?'; // Cron expression for 11:55 PM every day
        String jobName = 'PJPItemScheduler';
        
        System.schedule(jobName, cronExpression, new PJPItemScheduler());*/
    } 
    
}