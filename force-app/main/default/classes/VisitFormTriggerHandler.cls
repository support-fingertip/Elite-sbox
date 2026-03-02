public class VisitFormTriggerHandler {

    // Called after Visit_Form__c records are inserted
    public static void afterInsert(List<Visit_Form__c> newVisitForms) {
        Set<Id> dailyLogIds = new Set<Id>();

        for (Visit_Form__c vf : newVisitForms) {
            if (vf.Daily_Log__c != null) {
                dailyLogIds.add(vf.Daily_Log__c);
            }
        }

        if (!dailyLogIds.isEmpty()) {
            updateDailyLogVisitFormSummary(dailyLogIds);
        }
    }

    // Called after Visit_Form__c records are deleted
    public static void afterDelete(List<Visit_Form__c> oldVisitForms) {
        Set<Id> dailyLogIds = new Set<Id>();

        for (Visit_Form__c vf : oldVisitForms) {
            if (vf.Daily_Log__c != null) {
                dailyLogIds.add(vf.Daily_Log__c);
            }
        }

        if (!dailyLogIds.isEmpty()) {
            updateDailyLogVisitFormSummary(dailyLogIds);
        }
    }

    // Core method: aggregates Visit_Form__c data and updates Daily_Log__c
    private static void updateDailyLogVisitFormSummary(Set<Id> dailyLogIds) {
        if (dailyLogIds == null || dailyLogIds.isEmpty()) return;

        Map<Id, Daily_Log__c> logsToUpdateMap = new Map<Id, Daily_Log__c>();

        // -----------------------------------------------
        // 1) Aggregate total Visit Form count per Daily Log
        // -----------------------------------------------
        List<AggregateResult> visitFormAgg = [
            SELECT Daily_Log__c dlId, COUNT(Id) cnt
            FROM Visit_Form__c
            WHERE Daily_Log__c IN :dailyLogIds
              AND Daily_Log__c != null
            GROUP BY Daily_Log__c
        ];

        // Populate total count
        Set<Id> logsWithRecords = new Set<Id>();
        for (AggregateResult ar : visitFormAgg) {
            Id logId = (Id) ar.get('dlId');
            Integer cnt = (Integer) ar.get('cnt');
            logsWithRecords.add(logId);

            Daily_Log__c log = new Daily_Log__c(
                Id = logId,
                Total_Visit_form_Calls__c = cnt
            );
            logsToUpdateMap.put(logId, log);
        }

        // For Daily Logs that no longer have any Visit_Form__c records (all deleted),
        // reset the fields to null / 0
        for (Id dlId : dailyLogIds) {
            if (!logsWithRecords.contains(dlId)) {
                logsToUpdateMap.put(dlId, new Daily_Log__c(
                    Id = dlId,
                    Total_Visit_form_Calls__c = 0,
                    First_Visit_Form_Visit__c = null,
                    Last_Visit_Form_Visit__c = null
                ));
            }
        }

        // -----------------------------------------------
        // 2) Find the FIRST Visit Form per Daily Log (earliest CreatedDate)
        // -----------------------------------------------
        List<Visit_Form__c> allVisitForms = [
            SELECT Id, Daily_Log__c, CreatedDate
            FROM Visit_Form__c
            WHERE Daily_Log__c IN :logsWithRecords
            ORDER BY CreatedDate ASC
        ];

        Map<Id, Id> firstVisitFormMap = new Map<Id, Id>();
        Map<Id, Id> lastVisitFormMap  = new Map<Id, Id>();

        for (Visit_Form__c vf : allVisitForms) {
            // First occurrence per Daily Log (ASC order → first wins)
            if (!firstVisitFormMap.containsKey(vf.Daily_Log__c)) {
                firstVisitFormMap.put(vf.Daily_Log__c, vf.Id);
            }
            // Last occurrence per Daily Log (ASC order → keep overwriting)
            lastVisitFormMap.put(vf.Daily_Log__c, vf.Id);
        }

        // -----------------------------------------------
        // 3) Assign First & Last Visit Form to Daily Logs
        // -----------------------------------------------
        for (Id dlId : logsWithRecords) {
            Daily_Log__c log = logsToUpdateMap.get(dlId);
            if (log == null) {
                log = new Daily_Log__c(Id = dlId);
            }

            if (firstVisitFormMap.containsKey(dlId)) {
                log.First_Visit_Form_Visit__c = firstVisitFormMap.get(dlId);
            }
            if (lastVisitFormMap.containsKey(dlId)) {
                log.Last_Visit_Form_Visit__c = lastVisitFormMap.get(dlId);
            }

            logsToUpdateMap.put(dlId, log);
        }

        // -----------------------------------------------
        // 4) Perform the DML update
        // -----------------------------------------------
        if (!logsToUpdateMap.isEmpty()) {
            update logsToUpdateMap.values();
        }
    }
}