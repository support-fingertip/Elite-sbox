global class Batch_TargetActualsActuals implements Database.Batchable<SObject>, Database.Stateful {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        Integer currentMonth = Date.today().month();
        Integer currentYear = Date.today().year();
        return Database.getQueryLocator([
            SELECT Id, User__c, Customer__c, SKU__c, Month__c, Year__c
            FROM TargetActuals__c
            WHERE Month__c = :currentMonth.toString() AND Year__c = :currentYear.toString()
        ]);
    }

    global void execute(Database.BatchableContext BC, List<TargetActuals__c> scope) {
        // Gather filtering keys
        Set<Id> userIds = new Set<Id>();
        Set<Id> distributorIds = new Set<Id>();
        Set<Id> productIds = new Set<Id>();
        for (TargetActuals__c ta : scope) {
            if (ta.User__c != null) userIds.add(ta.User__c);
            if (ta.Customer__c != null) distributorIds.add(ta.Customer__c);
            if (ta.SKU__c != null) productIds.add(ta.SKU__c);
        }
        Integer currentMonth = Date.today().month();
        Integer currentYear = Date.today().year();

        // --- SKU targets: Aggregate for specific SKU + User
        Map<String, AggregateResult> skuOrderAgg = new Map<String, AggregateResult>();
        for (AggregateResult ar : [
            SELECT Product__c, Order__r.OwnerId user,
                SUM(NET_WEIGHT__c) qty, SUM(Total_Amount__c) revenue
            FROM Order_Item__c
            WHERE Product__c IN :productIds
              AND Order__r.OwnerId IN :userIds AND Order__r.Status__c = 'Push to Logistics'
              AND CALENDAR_MONTH(Order__r.Order_Date__c) = :currentMonth
              AND CALENDAR_YEAR(Order__r.Order_Date__c) = :currentYear
            GROUP BY Product__c, Order__r.OwnerId
        ]) {
            String key = (String)ar.get('user') + '_' + (String)ar.get('Product__c');
            skuOrderAgg.put(key, ar);
        }
        Map<String, AggregateResult> skuInvoiceAgg = new Map<String, AggregateResult>();
        for (AggregateResult ar : [
            SELECT Product__c, Invoice__r.OwnerId user,
                SUM(Quantity__c) qty, SUM(Total_Amount__c) revenue
            FROM Invoice_Item__c
            WHERE Product__c IN :productIds
              AND Invoice__r.OwnerId IN :userIds
              AND CALENDAR_MONTH(Invoice__r.Invoice_Date__c) = :currentMonth
              AND CALENDAR_YEAR(Invoice__r.Invoice_Date__c) = :currentYear
            GROUP BY Product__c, Invoice__r.OwnerId
        ]) {
            String key = (String)ar.get('user') + '_' + (String)ar.get('Product__c');
            skuInvoiceAgg.put(key, ar);
        }

        // --- Distributor targets: Aggregate for all SKUs, that Distributor + User
        Map<String, AggregateResult> distOrderAgg = new Map<String, AggregateResult>();
        for (AggregateResult ar : [
            SELECT Order__r.Account__c distributor, Order__r.OwnerId user,
                SUM(NET_WEIGHT__c) qty, SUM(Total_Amount__c) revenue
            FROM Order_Item__c
            WHERE Order__r.Account__c IN :distributorIds
              AND Order__r.OwnerId IN :userIds AND Order__r.Status__c = 'Push to Logistics'
              AND CALENDAR_MONTH(Order__r.Order_Date__c) = :currentMonth
              AND CALENDAR_YEAR(Order__r.Order_Date__c) = :currentYear
            GROUP BY Order__r.Account__c, Order__r.OwnerId
        ]) {
            String key = (String)ar.get('user') + '_' + (String)ar.get('distributor');
            distOrderAgg.put(key, ar);
        }
        Map<String, AggregateResult> distInvoiceAgg = new Map<String, AggregateResult>();
        for (AggregateResult ar : [
            SELECT Invoice__r.Store__c distributor, Invoice__r.OwnerId user,
                SUM(Quantity__c) qty, SUM(Total_Amount__c) revenue
            FROM Invoice_Item__c
            WHERE Invoice__r.Store__c IN :distributorIds
              AND Invoice__r.OwnerId IN :userIds
              AND CALENDAR_MONTH(Invoice__r.Invoice_Date__c) = :currentMonth
              AND CALENDAR_YEAR(Invoice__r.Invoice_Date__c) = :currentYear
            GROUP BY Invoice__r.Store__c, Invoice__r.OwnerId
        ]) {
            String key = (String)ar.get('user') + '_' + (String)ar.get('distributor');
            distInvoiceAgg.put(key, ar);
        }
        
        // Scenario 3: User only
        Map<Id, AggregateResult> userOrderAgg = new Map<Id, AggregateResult>();
        for (AggregateResult ar : [
            SELECT Order__r.OwnerId user,
                SUM(NET_WEIGHT__c) qty, SUM(Total_Amount__c) revenue
            FROM Order_Item__c
            WHERE Order__r.OwnerId IN :userIds AND Order__r.Status__c = 'Push to Logistics'
              AND CALENDAR_MONTH(Order__r.Order_Date__c) = :currentMonth
              AND CALENDAR_YEAR(Order__r.Order_Date__c) = :currentYear
            GROUP BY Order__r.OwnerId
        ]) {
            userOrderAgg.put((Id)ar.get('user'), ar);
        }
        Map<Id, AggregateResult> userInvoiceAgg = new Map<Id, AggregateResult>();
        for (AggregateResult ar : [
            SELECT Invoice__r.OwnerId user,
                SUM(Quantity__c) qty, SUM(Total_Amount__c) revenue
            FROM Invoice_Item__c
            WHERE Invoice__r.OwnerId IN :userIds
              AND CALENDAR_MONTH(Invoice__r.Invoice_Date__c) = :currentMonth
              AND CALENDAR_YEAR(Invoice__r.Invoice_Date__c) = :currentYear
            GROUP BY Invoice__r.OwnerId
        ]) {
            userInvoiceAgg.put((Id)ar.get('user'), ar);
        }

        // --- Update TargetActuals__c records
        List<TargetActuals__c> toUpdate = new List<TargetActuals__c>();
        for (TargetActuals__c ta : scope) {
            Decimal qty = 0, revenue = 0;
            // If mapped to SKU, aggregate for SKU + User
            if (ta.SKU__c != null && ta.User__c != null) {
                String key = ta.User__c + '_' + ta.SKU__c;
                if (skuOrderAgg.containsKey(key)) {
                    AggregateResult ar = skuOrderAgg.get(key);
                    qty += (ar.get('qty') != null ? (Decimal)ar.get('qty') : 0);
                    revenue += (ar.get('revenue') != null ? (Decimal)ar.get('revenue') : 0);
                }
                if (skuInvoiceAgg.containsKey(key)) {
                    AggregateResult ar = skuInvoiceAgg.get(key);
                    qty += (ar.get('qty') != null ? (Decimal)ar.get('qty') : 0);
                    revenue += (ar.get('revenue') != null ? (Decimal)ar.get('revenue') : 0);
                }
            }
            // If mapped to distributor only, aggregate for all SKUs for Distributor + User
            else if (ta.Customer__c != null && ta.User__c != null && ta.SKU__c == null) {
                String key = ta.User__c + '_' + ta.Customer__c;
                if (distOrderAgg.containsKey(key)) {
                    AggregateResult ar = distOrderAgg.get(key);
                    qty += (ar.get('qty') != null ? (Decimal)ar.get('qty') : 0);
                    revenue += (ar.get('revenue') != null ? (Decimal)ar.get('revenue') : 0);
                }
                if (distInvoiceAgg.containsKey(key)) {
                    AggregateResult ar = distInvoiceAgg.get(key);
                    qty += (ar.get('qty') != null ? (Decimal)ar.get('qty') : 0);
                    revenue += (ar.get('revenue') != null ? (Decimal)ar.get('revenue') : 0);
                }
            }
           // User Only Target
            else if (ta.User__c != null && ta.SKU__c == null && ta.Customer__c == null) {
                if (userOrderAgg.containsKey(ta.User__c)) {
                    AggregateResult ar = userOrderAgg.get(ta.User__c);
                    qty += (ar.get('qty') != null ? (Decimal)ar.get('qty') : 0);
                    revenue += (ar.get('revenue') != null ? (Decimal)ar.get('revenue') : 0);
                }
                if (userInvoiceAgg.containsKey(ta.User__c)) {
                    AggregateResult ar = userInvoiceAgg.get(ta.User__c);
                    qty += (ar.get('qty') != null ? (Decimal)ar.get('qty') : 0);
                    revenue += (ar.get('revenue') != null ? (Decimal)ar.get('revenue') : 0);
                }
            }
            ta.Actual_Quantity_KG__c = qty;
            ta.Actual_Revenue__c = revenue;
            toUpdate.add(ta);
        }
        if (!toUpdate.isEmpty()) update toUpdate;
    }

    global void finish(Database.BatchableContext BC) {
        //Database.executeBatch(new TargetActualsBatch(), 200);
    }
}