public class DailyLogOrderAmountBatch implements Database.Batchable<SObject>, Database.Stateful {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Fetch all daily logs except today's
        return Database.getQueryLocator([
            SELECT Id, OwnerId, Date__c
            FROM Daily_Log__c
            WHERE Day_started_time__c != TODAY
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Daily_Log__c> scope) {
        Set<Id> userIds = new Set<Id>();
        Set<Date> orderDates = new Set<Date>();

        for (Daily_Log__c dl : scope) {
            if (dl.OwnerId != null) userIds.add(dl.OwnerId);
            if (dl.Date__c != null) orderDates.add(dl.Date__c);
        }

        if (userIds.isEmpty() || orderDates.isEmpty()) return;

        // Maps with nested structure: userId + date → sum
        Map<String, Decimal> totalMap     = new Map<String, Decimal>();
        Map<String, Decimal> primaryMap   = new Map<String, Decimal>();
        Map<String, Decimal> secondaryMap = new Map<String, Decimal>();

        Map<String, Decimal> totalLinesSoldMap = new Map<String, Decimal>();
        Map<String, Decimal> totalLinesSoldPrimaryMap = new Map<String, Decimal>();
        Map<String, Decimal> totalLinesSoldSubStockiestMap = new Map<String, Decimal>();
        Map<String, Decimal> totalLinesSoldOutletMap = new Map<String, Decimal>();

        for (AggregateResult ar : [
            SELECT OwnerId ownerId,
                   Order_Date__c orderDate,
                   Order_Type__c ordtype,
                   Account__r.Secondary_Customer_Type__c secType,
                   SUM(Grand_Total__c) sumTotal,
                   SUM(TLSD__c) orderItemCount
            FROM Order__c
            WHERE OwnerId IN :userIds
            AND Order_Date__c IN :orderDates
            GROUP BY OwnerId, Order_Date__c, Order_Type__c, Account__r.Secondary_Customer_Type__c
        ]) {
            Id ownerId       = (Id)ar.get('ownerId');
            Date orderDate   = (Date)ar.get('orderDate');
            String orderType = (String)ar.get('ordtype');
            String secType   = (String)ar.get('secType');
            Decimal orderItemCount = (Decimal)ar.get('orderItemCount');
            Decimal sumTotal = (Decimal)ar.get('sumTotal');

            String key = ownerId + '-' + orderDate;

            // Total Amount
            totalMap.put(key, (totalMap.containsKey(key) ? totalMap.get(key) : 0) + sumTotal);

            // Total Line Sold
            totalLinesSoldMap.put(key, (totalLinesSoldMap.containsKey(key) ? totalLinesSoldMap.get(key) : 0) + orderItemCount);

            if (orderType == 'Primary Order') {
                primaryMap.put(key, (primaryMap.containsKey(key) ? primaryMap.get(key) : 0) + sumTotal);
                totalLinesSoldPrimaryMap.put(key, (totalLinesSoldPrimaryMap.containsKey(key) ? totalLinesSoldPrimaryMap.get(key) : 0) + orderItemCount);
            } else if (orderType == 'Secondary Order') {
                secondaryMap.put(key, (secondaryMap.containsKey(key) ? secondaryMap.get(key) : 0) + sumTotal);
                if (secType == 'Sub Stockiest') {
                    totalLinesSoldSubStockiestMap.put(key, (totalLinesSoldSubStockiestMap.containsKey(key) ? totalLinesSoldSubStockiestMap.get(key) : 0) + orderItemCount);
                } else {
                    totalLinesSoldOutletMap.put(key, (totalLinesSoldOutletMap.containsKey(key) ? totalLinesSoldOutletMap.get(key) : 0) + orderItemCount);
                }
            }
        }

        List<Daily_Log__c> logsToUpdate = new List<Daily_Log__c>();
        for (Daily_Log__c dl : scope) {
            String key = dl.OwnerId + '-' + dl.Date__c;

            dl.Total_Order_Amount__c    = totalMap.containsKey(key) ? totalMap.get(key) : 0;
            dl.Primary_Order_Amount__c  = primaryMap.containsKey(key) ? primaryMap.get(key) : 0;
            dl.Secondary_Order_Amont__c = secondaryMap.containsKey(key) ? secondaryMap.get(key) : 0;

            dl.TLSD__c = totalLinesSoldMap.containsKey(key) ? totalLinesSoldMap.get(key) : 0;
            dl.TLSD_Retailers_Outlets__c = totalLinesSoldOutletMap.containsKey(key) ? totalLinesSoldOutletMap.get(key) : 0;
            dl.TLSD_Sub_Stockist__c = totalLinesSoldSubStockiestMap.containsKey(key) ? totalLinesSoldSubStockiestMap.get(key) : 0;    
            dl.TLSD_Primary__c = totalLinesSoldPrimaryMap.containsKey(key) ? totalLinesSoldPrimaryMap.get(key) : 0;   

            logsToUpdate.add(dl);
        }

        if (!logsToUpdate.isEmpty()) {
            update logsToUpdate;
        }
    }

    public void finish(Database.BatchableContext bc) {
        // Optional: logging, chaining, or email notifications
    }
}