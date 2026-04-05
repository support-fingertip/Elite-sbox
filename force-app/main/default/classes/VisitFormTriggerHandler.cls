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

        // -----------------------------------------------
        // STEP 1: Load Daily_Log__c records to get the log date & owner context
        // -----------------------------------------------
        Map<Id, Daily_Log__c> dailyLogMap = new Map<Id, Daily_Log__c>([
            SELECT Id, OwnerId, Date__c
            FROM Daily_Log__c
            WHERE Id IN :dailyLogIds
        ]);

        // -----------------------------------------------
        // STEP 2: Fetch ALL Visit_Form__c records linked to these Daily Logs
        //         (excluding those already linked to a Visit__c)
        //         Ordered ASC so first/last can be derived naturally
        // -----------------------------------------------
        List<Visit_Form__c> allVFs = [
            SELECT Id, Daily_Log__c, CustomerId__c, CreatedDate, OwnerId FROM Visit_Form__c WHERE Daily_Log__c IN :dailyLogIds  
            AND Daily_Log__c != null AND Visit__c = null ORDER BY CreatedDate ASC
        ];

        // Group Visit Forms by Daily Log
        Map<Id, List<Visit_Form__c>> vfByDailyLog = new Map<Id, List<Visit_Form__c>>();
        for (Visit_Form__c vf : allVFs) {
            if (!vfByDailyLog.containsKey(vf.Daily_Log__c)) { vfByDailyLog.put(vf.Daily_Log__c, new List<Visit_Form__c>()); }
            vfByDailyLog.get(vf.Daily_Log__c).add(vf);
        }

        // Collect all unique CustomerIds across all Daily Logs
        Set<String> allCustomerIds = new Set<String>();
        for (Visit_Form__c vf : allVFs) {
            if (vf.CustomerId__c != null) {
                allCustomerIds.add(vf.CustomerId__c);
            }
        }

        // -----------------------------------------------
        // STEP 3: Collect OwnerIds and Dates per Daily Log
        //         to query Orders and Visits for the same day + owner
        // -----------------------------------------------
        Set<Id> allOwnerIds = new Set<Id>();
        Set<Date> allDates  = new Set<Date>();

        for (Daily_Log__c dl : dailyLogMap.values()) {
            if (dl.OwnerId != null) allOwnerIds.add(dl.OwnerId);
            if (dl.Date__c  != null) allDates.add(dl.Date__c);
        }

        // -----------------------------------------------
        // STEP 4: Query Order__c — find CustomerIds that already exist
        //         in Order__c.Account__c for the same day & owner
        // Key: OwnerId + Date → Set<CustomerId>
        // -----------------------------------------------
        Map<String, Set<String>> orderCustomersByOwnerDate = new Map<String, Set<String>>();

        if (!allOwnerIds.isEmpty() && !allDates.isEmpty() && !allCustomerIds.isEmpty()) {
            for (Order__c ord : [ SELECT OwnerId, Account__c, CreatedDate  FROM Order__c WHERE OwnerId IN :allOwnerIds AND Account__c IN :allCustomerIds
                  AND DAY_ONLY(CreatedDate) IN :allDates AND Account__c != null  AND Status__c != 'Rejected'
            ]) {
                String key = ord.OwnerId + '_' + String.valueOf(Date.valueOf(ord.CreatedDate));
                if (!orderCustomersByOwnerDate.containsKey(key)) { orderCustomersByOwnerDate.put(key, new Set<String>()); }
                orderCustomersByOwnerDate.get(key).add(ord.Account__c);
            }
        }

        // -----------------------------------------------
        // STEP 5: Query Visit__c — find CustomerIds that already exist
        //         in Visit__c.Account1__c for the same day & owner
        // -----------------------------------------------
        Map<String, Set<String>> visitCustomersByOwnerDate = new Map<String, Set<String>>();

        if (!allOwnerIds.isEmpty() && !allDates.isEmpty() && !allCustomerIds.isEmpty()) {
            for (Visit__c v : [ SELECT OwnerId, Account1__c, CreatedDate FROM Visit__c
                WHERE OwnerId IN :allOwnerIds AND Account1__c IN :allCustomerIds AND DAY_ONLY(CreatedDate) IN :allDates AND Account1__c != null
            ]) {
                String key = v.OwnerId + '_' + String.valueOf(Date.valueOf(v.CreatedDate));
                if (!visitCustomersByOwnerDate.containsKey(key)) { visitCustomersByOwnerDate.put(key, new Set<String>());}
                visitCustomersByOwnerDate.get(key).add(v.Account1__c);
            }
        }

        // -----------------------------------------------
        // STEP 6: For each Daily Log, compute all three values:
        //
        //   Total_Visit_form_Calls__c   → count of ALL Visit Forms (no exclusions)
        //   Unique_Visit_form_Visits__c → count of unique CustomerIds, excluding
        //                                 customers already in Order__c / Visit__c
        //   First_Visit_Form_Visit__c   → earliest Visit Form of ALL records
        //   Last_Visit_Form_Visit__c    → latest  Visit Form of ALL records
        // -----------------------------------------------
        Map<Id, Daily_Log__c> logsToUpdateMap = new Map<Id, Daily_Log__c>();

        for (Id dlId : dailyLogIds) {
            Daily_Log__c dl = dailyLogMap.get(dlId);

            List<Visit_Form__c> vfsForLog = vfByDailyLog.containsKey(dlId) ? vfByDailyLog.get(dlId) : new List<Visit_Form__c>();

            // Build lookup key for this Daily Log's owner + date
            String ownerDateKey = (dl != null && dl.OwnerId != null && dl.Date__c != null) ? dl.OwnerId + '_' + String.valueOf(dl.Date__c): null;

            // Customers already covered by Order__c or Visit__c on that day
            Set<String> excludedCustomers = new Set<String>();
            if (ownerDateKey != null) {
                if (orderCustomersByOwnerDate.containsKey(ownerDateKey)) { excludedCustomers.addAll(orderCustomersByOwnerDate.get(ownerDateKey));}
                if (visitCustomersByOwnerDate.containsKey(ownerDateKey)) { excludedCustomers.addAll(visitCustomersByOwnerDate.get(ownerDateKey));}
            }

            // --- Totals (ALL Visit Forms, no exclusions) ---
            Integer totalCount      = vfsForLog.size();
            // vfsForLog is ASC by CreatedDate, so index 0 = first, last index = last
            Id firstVFId = vfsForLog.isEmpty() ? null : vfsForLog[0].Id;
            Id lastVFId  = vfsForLog.isEmpty() ? null : vfsForLog[vfsForLog.size() - 1].Id;

            // --- Unique count (exclusion + dedup logic) ---
            Set<String> seenCustomers = new Set<String>();
            Integer uniqueCount = 0;

            for (Visit_Form__c vf : vfsForLog) {
                String cId = vf.CustomerId__c;
                if (cId == null || cId == '') {
                    uniqueCount++;
                    continue;
                }
                // Skip if customer already has an Order or Visit for this day/owner
                if (excludedCustomers.contains(cId)) continue;
                // Skip duplicate customer within this Daily Log's Visit Forms
                if (seenCustomers.contains(cId)) continue;
                seenCustomers.add(cId);
                uniqueCount++;
            }

            // Build the Daily_Log__c update record
            logsToUpdateMap.put(dlId, new Daily_Log__c(
                Id                        = dlId,
                Total_Visit_form_Calls__c  = totalCount,   // ALL records, no filter
                Unique_Visit_form_Visits__c = uniqueCount, // filtered + deduped
                First_Visit_Form_Visit__c  = firstVFId,   // based on ALL records
                Last_Visit_Form_Visit__c   = lastVFId     // based on ALL records
            ));
        }

        // -----------------------------------------------
        // STEP 7: Perform the DML update
        // -----------------------------------------------
        if (!logsToUpdateMap.isEmpty()) {
            update logsToUpdateMap.values();
        }
    }
}