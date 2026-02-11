public class BeatVisitSummaries {
    @AuraEnabled
    public static Map<String, Object> getBeatVisitSummaries(Date startDate, Date endDate, String userId) {
        Map<String, Object> response = new Map<String, Object>();
        
        // Step 1: Get Visits
        List<Visit__c> visits = [
            SELECT Id, Visit_Date__c, Account1__c, Account1__r.Name,
            Child_Beat__c, Child_Beat__r.Name
            FROM Visit__c
            WHERE Visit_Date__c >= :startDate 
            AND Visit_Date__c <= :endDate 
            AND OwnerId = :userId
        ];
        
        // Build maps: Date → Visited Accounts, Date → Beats
        Map<Date, Set<Id>> dateToAccountMap = new Map<Date, Set<Id>>();
        Set<Id> allBeats = new Set<Id>();
        
        for (Visit__c v : visits) {
            if (!dateToAccountMap.containsKey(v.Visit_Date__c)) {
                dateToAccountMap.put(v.Visit_Date__c, new Set<Id>());
            }
            if (v.Account1__c != null) {
                dateToAccountMap.get(v.Visit_Date__c).add(v.Account1__c);
            }
            if (v.Child_Beat__c != null) {
                allBeats.add(v.Child_Beat__c);
            }
        }
        
        // Step 2: Query Beat Items once
        Map<Id, List<Junction_Beat__c>> beatToItemsMap = new Map<Id, List<Junction_Beat__c>>();
        if (!allBeats.isEmpty()) {
            for (Junction_Beat__c bi : [
                SELECT Id, Name, Account__c,Account__r.Name,Child_beat__c,Child_beat__r.Name
                FROM Junction_Beat__c
                WHERE Child_beat__c IN :allBeats
            ]) {
                if (!beatToItemsMap.containsKey(bi.Child_beat__c)) {
                    beatToItemsMap.put(bi.Child_beat__c, new List<Junction_Beat__c>());
                }
                beatToItemsMap.get(bi.Child_beat__c).add(bi);
            }
        }
        
        // Step 3: Flatten → Date → Beat Items
        Map<Date, List<Junction_Beat__c>> dateToBeatItemsMap = new Map<Date, List<Junction_Beat__c>>();
        for (Visit__c v : visits) {
            if (v.Child_Beat__c != null && beatToItemsMap.containsKey(v.Child_Beat__c)) {
                if (!dateToBeatItemsMap.containsKey(v.Visit_Date__c)) {
                    dateToBeatItemsMap.put(v.Visit_Date__c, new List<Junction_Beat__c>());
                }
                dateToBeatItemsMap.get(v.Visit_Date__c).addAll(beatToItemsMap.get(v.Child_Beat__c));
            }
        }
        
        // Step 4: Iterate Date → Beat Items (ONLY 2 NESTED LOOPS)
        List<BeatSummary> table1 = new List<BeatSummary>();
        List<DailyOutletSummary> table2 = new List<DailyOutletSummary>();
        List<OutletEntry> workedAll = new List<OutletEntry>();
        List<OutletEntry> notWorkedAll = new List<OutletEntry>();
        
        for (Date d : dateToBeatItemsMap.keySet()) {
            DailyOutletSummary daily = new DailyOutletSummary();
            daily.workDate = d;
            
            Map<Id, BeatSummary> beatSummaryMap = new Map<Id, BeatSummary>();
            Set<Id> visitedAccs = dateToAccountMap.get(d);
            
            for (Junction_Beat__c bi : dateToBeatItemsMap.get(d)) {
                Boolean visited = visitedAccs != null && visitedAccs.contains(bi.Account__c);
                
                OutletEntry entry = new OutletEntry();
                entry.outletId = bi.Account__c;
                entry.outletName = bi.Account__r.Name;
                entry.beatId = bi.Child_beat__c;
                entry.beatName = bi.Child_beat__r.Name;
                
                // Daily outlet summary
                if (visited) {
                    daily.workedOutlets.add(entry);
                    workedAll.add(entry);
                } else {
                    daily.notWorkedOutlets.add(entry);
                    notWorkedAll.add(entry);
                }
                
                // Beat summary (per day, per beat)
                if (!beatSummaryMap.containsKey(bi.Child_beat__c)) {
                    BeatSummary bs = new BeatSummary();
                    bs.workDate = d;
                    bs.beatId = bi.Child_beat__c;
                    bs.beatName = bi.Child_beat__r.Name;
                    bs.workedCount = 0;
                    bs.notWorkedCount = 0;
                    beatSummaryMap.put(bi.Child_beat__c, bs);
                }
                if (visited) {
                    beatSummaryMap.get(bi.Child_beat__c).workedCount++;
                } else {
                    beatSummaryMap.get(bi.Child_beat__c).notWorkedCount++;
                }
            }
            
            table1.addAll(beatSummaryMap.values());
            table2.add(daily);
        }
        
        // Step 5: Response
        response.put('table1', table1);
        response.put('table2', table2);
        response.put('table3Worked', workedAll);
        response.put('table3NotWorked', notWorkedAll);
        
        return response;
    }

    public class BeatSummary {
        public Date workDate { get; set; }
        public String beatName { get; set; }
        public Id beatId { get; set; }
        public Integer workedCount { get; set; }
        public Integer notWorkedCount { get; set; }
    }
    
    public class DailyOutletSummary {
        public Date workDate { get; set; }
        public List<OutletEntry> workedOutlets { get; set; }
        public List<OutletEntry> notWorkedOutlets { get; set; }
        public DailyOutletSummary() {
            workedOutlets = new List<OutletEntry>();
            notWorkedOutlets = new List<OutletEntry>();
        }
    }
    
    public class OutletEntry {
        public Id outletId { get; set; }
        public String outletName { get; set; }
        public Id beatId { get; set; }
        public String beatName { get; set; }
    }
    
}