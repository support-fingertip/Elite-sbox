public class dailylogTriggerHandler {
    //Before insert update the assigned beat
    public static void beforeInsert(List<Daily_Log__c> newDailyLogs) {
        Set<Id> ownerIds = new Set<Id>();
        for (Daily_Log__c dl : newDailyLogs) {
            ownerIds.add(dl.OwnerId);
        }
        
        Map<Id, Id> ownerToBeatMap = new Map<Id, Id>();
        for (PJP_Item__c pjp : [
            SELECT OwnerId__c, Beat__c
            FROM PJP_Item__c
            WHERE Date__c = TODAY AND OwnerId__c IN :ownerIds
        ]) {
            ownerToBeatMap.put(pjp.OwnerId__c, pjp.Beat__c);
        }
        
        for (Daily_Log__c dl : newDailyLogs) {
            if (ownerToBeatMap.containsKey(dl.OwnerId)) {
                dl.Assigned_Beat__c = ownerToBeatMap.get(dl.OwnerId);
            }
        }
    }
    
    public static void afterInsert(List<Daily_Log__c> newDailyLogs) {
        Set<String> uniqueFileIds = new Set<String>();
        Map<String, Id> dailyLogIdMap = new Map<String, Id>();
        Set<String> OwnerIds = new Set<String>();
        // Collect all unique file IDs from new accounts
        for (Daily_Log__c dl : newDailyLogs) {
            if (dl.UniqueFileId__c != null) {
                uniqueFileIds.add(dl.UniqueFileId__c);
                dailyLogIdMap.put(dl.UniqueFileId__c, dl.Id);
            }
        }
        
        CustomSharingService.linkFilesToRecords(uniqueFileIds, dailyLogIdMap);  
    }
    
    public static void beforeUpdate(List<Daily_Log__c> newDailyLogs, Map<Id, Daily_Log__c> oldDailyLogMap) {
        Set<Id> dailyLogIds = new Set<Id>();
        
        // Step 1: Collect relevant Daily Log IDs
        for (Daily_Log__c dl : newDailyLogs) {
            if (
                dl.Day_ended_time__c != oldDailyLogMap.get(dl.Id).Day_ended_time__c &&
                dl.Day_ended_time__c != null
            ) {
                dailyLogIds.add(dl.Id);
            }
        }
        
        if (dailyLogIds.isEmpty()) return;
        
        // Step 2: Query Daily Logs with their most recent Visit
        List<Daily_Log__c> logsWithLastVisit = [
            SELECT Id,
            (SELECT Id FROM Visits__r ORDER BY CreatedDate DESC LIMIT 1)
            FROM Daily_Log__c
            WHERE Id IN :dailyLogIds
        ];
        
        // Step 3: Assign Last_Visit__c field
        Map<Id, Id> lastVisitMap = new Map<Id, Id>();
        for (Daily_Log__c log : logsWithLastVisit) {
            if (!log.Visits__r.isEmpty()) {
                lastVisitMap.put(log.Id, log.Visits__r[0].Id);
            }
        }
        
        for (Daily_Log__c dl : newDailyLogs) {
            if (lastVisitMap.containsKey(dl.Id)) {
                dl.Last_Visit__c = lastVisitMap.get(dl.Id);
            }
        }
    }

    public static void afterUpdate(List<Daily_Log__c> newDailyLogs,map<Id,Daily_Log__c> oldDailyLogMap) {
        Set<Id> dailyLogIds = new Set<Id>();
        Map<Id, Visit__c> visitMap = new Map<Id, Visit__c>();
        Set<String> uniqueFileIds = new Set<String>();
        Map<String, Id> dailyLogIdMap = new Map<String, Id>();
        for (Daily_Log__c dl :newDailyLogs) 
        {
            //when ever end day is happening we are storing daily log id
            if ((dl.Clock_Out_Location__Latitude__s != oldDailyLogMap.get(dl.Id).Clock_Out_Location__Latitude__s ||
                dl.Clock_Out_Location__Longitude__s != oldDailyLogMap.get(dl.Id).Clock_Out_Location__Longitude__s)  &&
                (dl.Clock_Out_Location__Latitude__s!=null && dl.Clock_Out_Location__Longitude__s !=null)) 
            {
                dailyLogIds.add(dl.Id);
                if (dl.UniqueFileId__c != null) {
                    uniqueFileIds.add(dl.UniqueFileId__c);
                    dailyLogIdMap.put(dl.UniqueFileId__c, dl.Id);
                }
            }
            
        } 
        CustomSharingService.linkFilesToRecords(uniqueFileIds, dailyLogIdMap);
        
        //here we are getting the "Daily log" and "last visit Record"
        List<Daily_Log__c> dlList = [SELECT Id,Name,Clock_Out_Location__Latitude__s,Clock_Out_Location__Longitude__s,Is_System_Ended__c,
                                     (SELECT Id,Name,ClockIn_Latitude__c, Clockin_Longitude__c FROM visits__r
                                      WHERE Actual_End_Time__c!=null AND 	ClockIn_Latitude__c!=null AND 
                                      Clockin_Longitude__c!=null ORDER BY Actual_End_Time__c DESC) 
                                     FROM Daily_log__c WHERE Id IN : dailyLogIds];
        
        // List<Visit__c> recentCheckouts = new List<Visit__c>();
        for (Daily_Log__c dl : dlList) 
        {
            if (dl.visits__r.size()>0) {
                if(!dl.Is_System_Ended__c){
                    DistanceMatrixControllerForVisit.distanceCalculationForLastVisit(dl.Id,dl.visits__r[0].ClockIn_Latitude__c,dl.visits__r[0].Clockin_Longitude__c, dl.Clock_Out_Location__Latitude__s, dl.Clock_Out_Location__Longitude__s);
                }
            }
        }
    }
    
    
}