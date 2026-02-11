public class UpdateDailyLogBatchForAccountCount implements Database.Batchable<SObject> {    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Fetch all Daily Logs in the system
        return Database.getQueryLocator([
            SELECT Id, OwnerId, Date__c
            FROM Daily_Log__c where Day_started_time__c != today
        ]);
    }
    
    public void execute(Database.BatchableContext bc, List<Daily_Log__c> scope) {
        // Collect unique (OwnerId, Date) pairs
        Map<String, List<Daily_Log__c>> logKeyToRecords = new Map<String, List<Daily_Log__c>>();
        Set<Id> ownerIds = new Set<Id>();
        Set<Date> logDates = new Set<Date>();
        
        for (Daily_Log__c log : scope) {
            String key = log.OwnerId + '_' + log.Date__c;
            
            if (!logKeyToRecords.containsKey(key)) {
                logKeyToRecords.put(key, new List<Daily_Log__c>());
            }
            logKeyToRecords.get(key).add(log);
            
            ownerIds.add(log.OwnerId);
            logDates.add(log.Date__c);
        }
        
        // Aggregate Accounts per user per date
        Map<String, Integer> accountCountMap = new Map<String, Integer>();
        
        for (AggregateResult ar : [
            SELECT CreatedById ownerId, DAY_ONLY(CreatedDate) day, COUNT(Id) cnt
            FROM Account
            WHERE CreatedById IN :ownerIds
            AND DAY_ONLY(CreatedDate) IN :logDates
            GROUP BY CreatedById, DAY_ONLY(CreatedDate)
        ]) {
            String key = (String)ar.get('ownerId') + '_' + (Date)ar.get('day');
            accountCountMap.put(key, (Integer)ar.get('cnt'));
        }
        
        // Update Daily Logs
        List<Daily_Log__c> logsToUpdate = new List<Daily_Log__c>();
        for (String key : logKeyToRecords.keySet()) {
            Integer cnt = accountCountMap.containsKey(key) ? accountCountMap.get(key) : 0;
            for (Daily_Log__c log : logKeyToRecords.get(key)) {
                log.New_Calls__c = cnt;
                logsToUpdate.add(log);
            }
        }
        
        if (!logsToUpdate.isEmpty()) {
            update logsToUpdate;
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        System.debug('✅ Daily Log Account Count Batch completed for all logs.');
    }
    
}