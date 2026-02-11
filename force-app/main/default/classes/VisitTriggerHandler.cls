public class VisitTriggerHandler {
    public static void afterInsert(List<Visit__c> newVisits) {
        Set<String> uniqueFileIds = new Set<String>();
        Map<String, Id> visitIdMap = new Map<String, Id>();
        Set<String> OwnerIds = new Set<String>();
        Set<Id> dailyLogIds = new Set<Id>();
        Set<Id> dailyLogIdsToAddFirstVsit = new Set<Id>();
        for (Visit__c dl : newVisits) {
             // Collect all unique file IDs from new accounts
            if (dl.UniqueFileId__c != null) {
                uniqueFileIds.add(dl.UniqueFileId__c);
                visitIdMap.put(dl.UniqueFileId__c, dl.Id);
            }
             //From Google API Get the Distance
            if(label.ActivateGMapAPI == 'True')
            {  
                if(dl.ClockIn_Latitude__c!=null && dl.Clockin_Longitude__c!=null && dl.Actual_Start_Time__c!=null){
                    DistanceMatrixControllerForVisit.distanceCalculation(dl.Id);
                }
                
            }
         	//When visit Disntance is Changed we are updating distance on Dailylog
            if (dl.Daily_log__c != null)
            {
                dailyLogIdsToAddFirstVsit.add(dl.Daily_log__c);
                if((dl.Distance__c != null) || (dl.Distance_Salesforce__c != null))
                {
                    dailyLogIds.add(dl.Daily_log__c);
                }
            }
        }   
        updateDailyLogs(dailyLogIds,dailyLogIdsToAddFirstVsit);
        
        CustomSharingService.linkFilesToRecords(uniqueFileIds, visitIdMap);
        
    }
    //For Rollup summary of Distance and to link the files
    public static void afterUpdate(List<Visit__c> newVisits,map<Id,Visit__c> oldmap) {
        Set<String> uniqueFileIds = new Set<String>();
        Map<String, Id> visitIdMap = new Map<String, Id>();
        Set<String> OwnerIds = new Set<String>();
        Set<Id> dailyLogIds = new Set<Id>();
        
        Set<Id> visitSummaryLogIds = new Set<Id>();
        // Collect all unique file IDs from new accounts
        for (Visit__c dl : newVisits) {
            if (dl.UniqueFileId__c != null && oldmap.get(dl.Id).UniqueFileId__c !=dl.UniqueFileId__c ) {
                uniqueFileIds.add(dl.UniqueFileId__c);
                visitIdMap.put(dl.UniqueFileId__c, dl.Id);
            }
            
            if ( dl.Daily_log__c != null &&
                ((dl.Daily_log__c != oldmap.get(dl.Id).Daily_log__c) ||
                 (dl.Distance__c != null && dl.Distance__c != oldmap.get(dl.Id).Distance__c)  ||
                 (dl.Distance_Salesforce__c != null  && dl.Distance_Salesforce__c != oldmap.get(dl.Id).Distance_Salesforce__c)
                )
            ) 
            {
                dailyLogIds.add(dl.Daily_log__c);
            }
            
            if((dl.Actual_End_Time__c != null && (dl.Actual_End_Time__c != oldmap.get(dl.Id).Actual_End_Time__c))
              ||( dl.Visit_Output__c != null &&  (dl.Visit_Output__c != oldmap.get(dl.Id).Visit_Output__c) ))
            {
                visitSummaryLogIds.add(dl.Daily_log__c);
            }
        }
        
        if(!dailyLogIds.isEmpty())
        {
            updateDailyLogs(dailyLogIds,new Set<Id>());
        }
     
       
        if(!visitSummaryLogIds.isEmpty())
        {
            updateVisitSummary(visitSummaryLogIds);
        }
        CustomSharingService.linkFilesToRecords(uniqueFileIds, visitIdMap);
        
    }
	//For Rollup summary of Distance
    public static void afterDelete(List<Visit__c> oldVisits) {
        Set<Id> dailyLogIds = new Set<Id>();
        for (Visit__c vis : oldVisits) {
            if (vis.Daily_log__c != null &&  ((vis.Distance__c != null) || (vis.Distance_Salesforce__c != null)))
            {
                dailyLogIds.add(vis.Daily_log__c);
            }
        }
        updateDailyLogs(dailyLogIds,new Set<Id>());
        
    }
    
    //Update Total visit and total productive and non-productive calls
    public static void updateVisitSummary(Set<Id> dailyLogIds) {
        if (dailyLogIds == null || dailyLogIds.isEmpty()) return;
        
        Map<Id, Daily_Log__c> logsToUpdateMap = new Map<Id, Daily_Log__c>();
        
        // ------------------------------------
        // 1) Productive / Non-Productive / In / Out calls
        // ------------------------------------
        List<AggregateResult> visitAgg = [
            SELECT Daily_Log__c logId,
            Visit_Output__c output,
            Location_Type__c locType,
            COUNT(Id) cnt
            FROM Visit__c
            WHERE Daily_Log__c IN :dailyLogIds and Daily_Log__c!= null
            GROUP BY Daily_Log__c, Visit_Output__c, Location_Type__c
        ];
        
        for (AggregateResult ar : visitAgg) {
            Id logId = (Id) ar.get('logId');
            String output = (String) ar.get('output');
            String locType = (String) ar.get('locType');
            Integer cnt = (Integer) ar.get('cnt');
            
            // Always reuse the same instance
            Daily_Log__c log = logsToUpdateMap.get(logId);
            if (log == null) {
                log = new Daily_Log__c(Id = logId, 
                                       Total_Productive_Calls__c = 0,
                                       Total_Non_Productive_Calls__c = 0,
                                       Normal_Call__c = 0,
                                       Telephonic_Call__c = 0
                                      );
            }
            // Productive vs non-productive
            if (output == 'PJP Successful') {
                log.Total_Productive_Calls__c = (log.Total_Productive_Calls__c == null ? 0 : log.Total_Productive_Calls__c) + cnt;
            } else if (output == 'PJP Unsuccessful') {
                log.Total_Non_Productive_Calls__c = (log.Total_Non_Productive_Calls__c == null ? 0 : log.Total_Non_Productive_Calls__c) + cnt;
            }
            
            // In vs out location
            if (locType == 'In Location') {
                log.Normal_Call__c = (log.Normal_Call__c == null ? 0 : log.Normal_Call__c) + cnt;
            } else if (locType == 'Out Location') {
                log.Telephonic_Call__c = (log.Telephonic_Call__c == null ? 0 : log.Telephonic_Call__c) + cnt;
            }
            
            logsToUpdateMap.put(logId, log);
        }
        
        // ------------------------------------
        // 2) Total Outlets (unique beats per DailyLog)
        // ------------------------------------
        // Step 1: Collect distinct beats per daily log
        Map<Id, Set<Id>> logToBeatIds = new Map<Id, Set<Id>>();
        
        for (Visit__c v : [
            SELECT Daily_Log__c, Child_Beat__c
            FROM Visit__c
            WHERE Daily_Log__c IN :dailyLogIds
            AND Child_Beat__c != null
        ]) {
            if(v.Daily_Log__c != null)
            {
                if (!logToBeatIds.containsKey(v.Daily_Log__c)) {
                    logToBeatIds.put(v.Daily_Log__c, new Set<Id>());
                }
                logToBeatIds.get(v.Daily_Log__c).add(v.Child_Beat__c);
            }
        }
        
        // Step 2: Collect all beat Ids in one Set
        Set<Id> allBeatIds = new Set<Id>();
        for (Set<Id> beatSet : logToBeatIds.values()) {
            allBeatIds.addAll(beatSet);
        }
        
        // Now query beats
        Map<Id, Decimal> beatTotals = new Map<Id, Decimal>();
        for (Child_Beat__c beat : [
            SELECT Id, Beat_Outlet_Count__c
            FROM Child_Beat__c
            WHERE Id IN :allBeatIds
        ]) {
            beatTotals.put(beat.Id, beat.Beat_Outlet_Count__c);
        }

        
        // Step 3: Sum per daily log
        for (Id logId : logToBeatIds.keySet()) {
            if(logId != null)
            {
                
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
        }
        // ------------------------------------
        // 3) Final update
        // ------------------------------------
        if (!logsToUpdateMap.isEmpty()) {
            update logsToUpdateMap.values();
        }
    }
    

    //Roll up summary of distance
    public static void updateDailyLogs(Set<Id> dailyLogIds,Set<Id> dailyLogIdsToAddFirstVsit) {
        
        Map<Id, Daily_Log__c> logsToUpdateMap = new Map<Id, Daily_Log__c>();        
        if(!dailyLogIds.isEmpty())
        {
            
            List<AggregateResult> totalDistance = [
                SELECT SUM(Distance__c) dis, SUM(Distance_Salesforce__c) disSalesforce, COUNT(Id) VisitCount, Daily_log__c  
                FROM Visit__c 
                WHERE Daily_log__c IN :dailyLogIds 
                GROUP BY Daily_log__c
            ];

            for (AggregateResult ar : totalDistance) {
                logsToUpdateMap.put((Id) ar.get('Daily_log__c'), new Daily_Log__c(
                    Id = (Id) ar.get('Daily_log__c'),
                    KMs_Travelled__c = (Double) ar.get('dis'),
                    Distance_Salesforce__c = (Double) ar.get('disSalesforce'),
                    Total_Visits__c = (Integer) ar.get('VisitCount') 
                ));
            }
            
        }
        
        //Only works on Inserting 
        if(!dailyLogIdsToAddFirstVsit.isEmpty())
        {
            // Step 1: Get Daily Logs where First_Visit__c is still null
            Map<Id, Daily_Log__c> dailyLogsToUpdate = new Map<Id, Daily_Log__c>(
                [SELECT Id, First_Visit__c FROM Daily_Log__c WHERE Id IN :dailyLogIdsToAddFirstVsit AND First_Visit__c = NULL]
            );
     
            // Step 2: Get earliest Visit for those Daily Logs
            List<Visit__c> firstVisits = [ SELECT Id, Daily_Log__c, CreatedDate FROM Visit__c
                                          WHERE Daily_Log__c IN :dailyLogsToUpdate.keySet() ORDER BY CreatedDate ASC];
            
            // Step 3: Track first Visit per Daily Log
            Map<Id, Id> firstVisitMap = new Map<Id, Id>();
            for (Visit__c v : firstVisits) {
                if (!firstVisitMap.containsKey(v.Daily_Log__c)) {
                    firstVisitMap.put(v.Daily_Log__c, v.Id);
                }
            }
            
            for (Id dlId : dailyLogsToUpdate.keySet()) {
                if (firstVisitMap.containsKey(dlId)) {
                    Daily_Log__c existing = logsToUpdateMap.get(dlId);
                    if (existing == null) {
                        existing = new Daily_Log__c(Id = dlId);
                    }
                    existing.First_Visit__c = firstVisitMap.get(dlId);
                    logsToUpdateMap.put(dlId, existing);
                    
                }
            }
        }
        
        
        if (!logsToUpdateMap.isEmpty()) {
            update logsToUpdateMap.values();
        }
    }
    
}