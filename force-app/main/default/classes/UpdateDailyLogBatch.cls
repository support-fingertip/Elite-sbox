public class UpdateDailyLogBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id 
            FROM Daily_Log__c where Day_started_time__c != today 
        ]);
    }
    
    public void execute(Database.BatchableContext bc, List<Daily_Log__c> dailyLogs) {
        Set<Id> dailyLogIds = new Set<Id>();
        for (Daily_Log__c log : dailyLogs) {
            dailyLogIds.add(log.Id);
        }
        
        if (dailyLogIds.isEmpty()) return;
        
        Map<Id, Daily_Log__c> logsToUpdateMap = new Map<Id, Daily_Log__c>();
        
        // -------------------------
        // 1) Aggregate Visit Data
        // -------------------------
        List<AggregateResult> visitAgg = [
            SELECT Daily_Log__c logId,
                   Visit_Output__c output,
                   Location_Type__c locType,
                   COUNT(Id) cnt
            FROM Visit__c
            WHERE Daily_Log__c IN :dailyLogIds
            GROUP BY Daily_Log__c, Visit_Output__c, Location_Type__c
        ];
        
        for (AggregateResult ar : visitAgg) {
            Id logId   = (Id) ar.get('logId');
            String output  = (String) ar.get('output');
            String locType = (String) ar.get('locType');
            Integer cnt    = (Integer) ar.get('cnt');
            
            Daily_Log__c log = logsToUpdateMap.get(logId);
            if (log == null) {
                log = new Daily_Log__c(
                    Id = logId, 
                    Total_Productive_Calls__c = 0,
                    Total_Non_Productive_Calls__c = 0,
                    Normal_Call__c = 0,
                    Telephonic_Call__c = 0,
                    Total_Visits__c = 0
                );
            }
            
            // Productive / Non-productive
            if (output == 'PJP Successful') {
                log.Total_Productive_Calls__c += cnt;
            } else if (output == 'PJP Unsuccessful') {
                log.Total_Non_Productive_Calls__c += cnt;
            }
            
            // Normal / Telephonic
            if (locType == 'In Location') {
                log.Normal_Call__c += cnt;
            } else if (locType == 'Out Location') {
                log.Telephonic_Call__c += cnt;
            }
            
            // Total Calls (Visits)
            log.Total_Visits__c += cnt;
            
            logsToUpdateMap.put(logId, log);
        }
        
        // -------------------------
        // 2) Unique Outlets by Beat
        // -------------------------
        Map<Id, Set<Id>> logToBeatIds = new Map<Id, Set<Id>>();
        for (Visit__c v : [
            SELECT Daily_Log__c, Child_Beat__c
            FROM Visit__c
            WHERE Daily_Log__c IN :dailyLogIds
            AND Child_Beat__c != null
        ]) {
            if (!logToBeatIds.containsKey(v.Daily_Log__c)) {
                logToBeatIds.put(v.Daily_Log__c, new Set<Id>());
            }
            logToBeatIds.get(v.Daily_Log__c).add(v.Child_Beat__c);
        }
        
        Set<Id> allBeatIds = new Set<Id>();
        for (Set<Id> beatSet : logToBeatIds.values()) {
            allBeatIds.addAll(beatSet);
        }
        
        Map<Id, Decimal> beatTotals = new Map<Id, Decimal>();
        if (!allBeatIds.isEmpty()) {
            for (Child_Beat__c beat : [
                SELECT Id, Beat_Outlet_Count__c
                FROM Child_Beat__c
                WHERE Id IN :allBeatIds
            ]) {
                beatTotals.put(beat.Id, beat.Beat_Outlet_Count__c);
            }
        }
        
        for (Id logId : logToBeatIds.keySet()) {
            Decimal totalOutlets = 0;
            for (Id beatId : logToBeatIds.get(logId)) {
                totalOutlets += (beatTotals.containsKey(beatId) ? beatTotals.get(beatId) : 0);
            }
            
            Daily_Log__c log = logsToUpdateMap.containsKey(logId) 
                ? logsToUpdateMap.get(logId) 
                : new Daily_Log__c(Id = logId);
            
            log.Total_Outlets__c = totalOutlets;
            logsToUpdateMap.put(logId, log);
        }
        
        // -------------------------
        // 3) Update Daily Logs
        // -------------------------
        if (!logsToUpdateMap.isEmpty()) {
            update logsToUpdateMap.values();
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        // Optional: add logging or chain another batch
    }
}