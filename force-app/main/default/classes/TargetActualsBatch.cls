global class TargetActualsBatch implements Database.Batchable<SObject>, Database.Stateful,Schedulable {
    
    public String monthParam;
    public String yearParam;
    
    public TargetActualsBatch() {
        this.monthParam = Date.today().month().toString();
        this.yearParam = Date.today().year().toString();
    }
    
    // Constructor to accept dynamic parameters, default to current month and year if none provided
    public TargetActualsBatch(String month, String year) {
        if (String.isBlank(month) || String.isBlank(year)) {
            // If no parameters provided, default to current month and year
            this.monthParam = Date.today().month().toString();
            this.yearParam = Date.today().year().toString();
        } else {
            this.monthParam = month;
            this.yearParam = year;
        }
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
    
        return Database.getQueryLocator([
            SELECT Id, User__c, Customer__c, SKU__c, Month__c, Year__c,Target_Revenue__c,Target_Quantity_KG__c,Sales_Channel__c
            FROM TargetActuals__c
            WHERE Month__c = :monthParam AND Year__c = :yearParam
        ]);
    }
    
    global void execute(Database.BatchableContext BC, List<TargetActuals__c> scope) {
        Set<Id> userIds = new Set<Id>();
        Set<Id> distributorIds = new Set<Id>();
        Set<Id> productIds = new Set<Id>();
        //   Set<String> salesChannels = new Set<String>();
        for (TargetActuals__c ta : scope) {
            if (ta.User__c != null) userIds.add(ta.User__c);
            if (ta.Customer__c != null) distributorIds.add(ta.Customer__c);
            if (ta.SKU__c != null) productIds.add(ta.SKU__c);
            // if(ta.Sales_Channel__c != null) salesChannels.add(ta.Sales_Channel__c);
        }
        //Integer currentMonth = Date.today().month();
        //Integer currentYear = Date.today().year();
        
        // Use class-level monthParam and yearParam
        Integer currentMonth = Integer.valueOf(monthParam); // Convert string to Integer
        Integer currentYear = Integer.valueOf(yearParam);  // Convert string to Integer
        
        // For mapping logic (TargetActuals__c lookups)
        Map<String, TargetActuals__c> skuKeyToTarget = new Map<String, TargetActuals__c>();
        Map<String, TargetActuals__c> distKeyToTarget = new Map<String, TargetActuals__c>();
        Map<String, TargetActuals__c> userKeyToTarget = new Map<String, TargetActuals__c>();
        
        for (TargetActuals__c ta : scope) {
            if (ta.SKU__c != null && ta.User__c != null) {
                skuKeyToTarget.put(ta.User__c + '_' + ta.SKU__c, ta);
            } else if (ta.Customer__c != null && ta.User__c != null && ta.SKU__c == null) {
                distKeyToTarget.put(ta.User__c + '_' + ta.Customer__c, ta);
            } else if (ta.User__c != null && ta.SKU__c == null && ta.Customer__c == null) {
                userKeyToTarget.put(ta.User__c, ta);
            }
        }
        
        Decimal ZERO = 0;
        List<TargetActuals_Mapping__c> mappingsToUpsert = new List<TargetActuals_Mapping__c>();
        
        // --- SKU targets: Order_Item__c
        Map<Id, Decimal> skuQty = new Map<Id, Decimal>();
        Map<Id, Decimal> skuRevenue = new Map<Id, Decimal>();
        List<Order_Item__c> skuOrderItems = [
            SELECT Id, Product__c, Order__r.OwnerId, Quantity__c, Total_Amount__c, NET_WEIGHT__c
            FROM Order_Item__c
            WHERE Product__c IN :productIds 
            AND Order__r.OwnerId IN :userIds AND Order__r.Status__c = 'Push to Logistics'
            AND CALENDAR_MONTH(Order__r.Order_Date__c) = :currentMonth
            AND CALENDAR_YEAR(Order__r.Order_Date__c) = :currentYear
        ];
        for (Order_Item__c oi : skuOrderItems) {
            String key = oi.Order__r.OwnerId + '_' + oi.Product__c;
            TargetActuals__c ta = skuKeyToTarget.get(key);
            if (ta != null) {
                Decimal q = oi.NET_WEIGHT__c == null ? ZERO : oi.NET_WEIGHT__c;
                Decimal r = oi.Total_Amount__c == null ? ZERO : oi.Total_Amount__c;
                skuQty.put(ta.Id, (skuQty.get(ta.Id) == null ? ZERO : skuQty.get(ta.Id)) + q);
                skuRevenue.put(ta.Id, (skuRevenue.get(ta.Id) == null ? ZERO : skuRevenue.get(ta.Id)) + r);
                
                mappingsToUpsert.add(new TargetActuals_Mapping__c(
                    TargetActuals__c = ta.Id,
                    Order_Item__c = oi.Id,
                    Quantity__c = q,
                    Revenue__c = r,
                    Mapping_Id__c = ta.Id + '-' + oi.Id
                ));
            }
        }
        // --- SKU targets: Invoice_Item__c
        List<Invoice_Item__c> skuInvoiceItems = [
            SELECT Id, Product__c,Order__r.OwnerId, Quantity__c, Total_Amount__c
            FROM Invoice_Item__c
            WHERE Product__c IN :productIds
            AND Order__r.OwnerId IN :userIds
            AND CALENDAR_MONTH(Invoice__r.Invoice_Date__c) = :currentMonth
            AND CALENDAR_YEAR(Invoice__r.Invoice_Date__c) = :currentYear
        ];
        for (Invoice_Item__c ii : skuInvoiceItems) {
            String key = ii.Order__r.OwnerId + '_' + ii.Product__c;
            TargetActuals__c ta = skuKeyToTarget.get(key);
            if (ta != null) {
                Decimal q = ii.Quantity__c == null ? ZERO : ii.Quantity__c;
                Decimal r = ii.Total_Amount__c == null ? ZERO : ii.Total_Amount__c;
                skuQty.put(ta.Id, (skuQty.get(ta.Id) == null ? ZERO : skuQty.get(ta.Id)) + q);
                skuRevenue.put(ta.Id, (skuRevenue.get(ta.Id) == null ? ZERO : skuRevenue.get(ta.Id)) + r);
                
                mappingsToUpsert.add(new TargetActuals_Mapping__c(
                    TargetActuals__c = ta.Id,
                    Invoice_item__c = ii.Id,
                    Quantity__c = q,
                    Revenue__c = r,
                    Mapping_Id__c = ta.Id + '-' + ii.Id
                ));
            }
        }
        
        // --- Distributor targets: Order_Item__c
        Map<Id, Decimal> distQty = new Map<Id, Decimal>();
        Map<Id, Decimal> distRevenue = new Map<Id, Decimal>();
        List<Order_Item__c> distOrderItems = [
            SELECT Id, Order__r.Account__c, Order__r.OwnerId, Quantity__c, Total_Amount__c, NET_WEIGHT__c,Product__r.Channel__c
            FROM Order_Item__c
            WHERE Order__r.Account__c IN :distributorIds 
            AND Order__r.OwnerId IN :userIds AND Order__r.Status__c = 'Push to Logistics'
            AND CALENDAR_MONTH(Order__r.Order_Date__c) = :currentMonth
            AND CALENDAR_YEAR(Order__r.Order_Date__c) = :currentYear
        ];
        for (Order_Item__c oi : distOrderItems) {
            String key = oi.Order__r.OwnerId + '_' + oi.Order__r.Account__c;
            TargetActuals__c ta = distKeyToTarget.get(key);
            if (ta != null) {
                Decimal q = oi.NET_WEIGHT__c == null ? ZERO : oi.NET_WEIGHT__c;
                Decimal r = oi.Total_Amount__c == null ? ZERO : oi.Total_Amount__c;
                distQty.put(ta.Id, (distQty.get(ta.Id) == null ? ZERO : distQty.get(ta.Id)) + q);
                distRevenue.put(ta.Id, (distRevenue.get(ta.Id) == null ? ZERO : distRevenue.get(ta.Id)) + r);
                
                mappingsToUpsert.add(new TargetActuals_Mapping__c(
                    TargetActuals__c = ta.Id,
                    Order_Item__c = oi.Id,
                    Quantity__c = q,
                    Revenue__c = r,
                    Mapping_Id__c = ta.Id + '-' + oi.Id
                ));
            }
        }
        // --- Distributor targets: Invoice_Item__c
        List<Invoice_Item__c> distInvoiceItems = [
            SELECT Id, Invoice__r.Store__c, Order__r.OwnerId, Quantity__c, Total_Amount__c,Product__r.Channel__c
            FROM Invoice_Item__c
            WHERE Invoice__r.Store__c IN :distributorIds
            AND Order__r.OwnerId IN :userIds
            AND CALENDAR_MONTH(Invoice__r.Invoice_Date__c) = :currentMonth
            AND CALENDAR_YEAR(Invoice__r.Invoice_Date__c) = :currentYear
        ];
        for (Invoice_Item__c ii : distInvoiceItems) {
            String key = ii.Order__r.OwnerId + '_' + ii.Invoice__r.Store__c;
            TargetActuals__c ta = distKeyToTarget.get(key);
            if (ta != null) {
                Decimal q = ii.Quantity__c == null ? ZERO : ii.Quantity__c;
                Decimal r = ii.Total_Amount__c == null ? ZERO : ii.Total_Amount__c;
                distQty.put(ta.Id, (distQty.get(ta.Id) == null ? ZERO : distQty.get(ta.Id)) + q);
                distRevenue.put(ta.Id, (distRevenue.get(ta.Id) == null ? ZERO : distRevenue.get(ta.Id)) + r);
                
                mappingsToUpsert.add(new TargetActuals_Mapping__c(
                    TargetActuals__c = ta.Id,
                    Invoice_item__c = ii.Id,
                    Quantity__c = q,
                    Revenue__c = r,
                    Mapping_Id__c = ta.Id + '-' + ii.Id
                ));
            }
        }
        
        // --- User only targets: Order_Item__c
        Map<Id, Decimal> userQty = new Map<Id, Decimal>();
        Map<Id, Decimal> userRevenue = new Map<Id, Decimal>();
        List<Order_Item__c> userOrderItems = [
            SELECT Id, Order__r.OwnerId, Quantity__c, Total_Amount__c, NET_WEIGHT__c,Product__r.Channel__c
            FROM Order_Item__c
            WHERE Order__r.OwnerId IN :userIds AND Order__r.Status__c = 'Push to Logistics'
            AND CALENDAR_MONTH(Order__r.Order_Date__c) = :currentMonth
            AND CALENDAR_YEAR(Order__r.Order_Date__c) = :currentYear
        ];
        for (Order_Item__c oi : userOrderItems) {
            TargetActuals__c ta = userKeyToTarget.get(oi.Order__r.OwnerId);
            if (ta != null) {
                Decimal q = oi.NET_WEIGHT__c == null ? ZERO : oi.NET_WEIGHT__c;
                Decimal r = oi.Total_Amount__c == null ? ZERO : oi.Total_Amount__c;
                userQty.put(ta.Id, (userQty.get(ta.Id) == null ? ZERO : userQty.get(ta.Id)) + q);
                userRevenue.put(ta.Id, (userRevenue.get(ta.Id) == null ? ZERO : userRevenue.get(ta.Id)) + r);
                
                mappingsToUpsert.add(new TargetActuals_Mapping__c(
                    TargetActuals__c = ta.Id,
                    Order_Item__c = oi.Id,
                    Quantity__c = q,
                    Revenue__c = r,
                    Mapping_Id__c = ta.Id + '-' + oi.Id
                ));
            }
        }
        // --- User only targets: Invoice_Item__c
        List<Invoice_Item__c> userInvoiceItems = [
            SELECT Id, Order__r.OwnerId, Quantity__c, Total_Amount__c,Product__r.Channel__c
            FROM Invoice_Item__c
            WHERE Order__r.OwnerId IN :userIds 
            AND CALENDAR_MONTH(Invoice__r.Invoice_Date__c) = :currentMonth
            AND CALENDAR_YEAR(Invoice__r.Invoice_Date__c) = :currentYear
        ];
        for (Invoice_Item__c ii : userInvoiceItems) {
            TargetActuals__c ta = userKeyToTarget.get(ii.Order__r.OwnerId);
            if (ta != null) {
                Decimal q = ii.Quantity__c == null ? ZERO : ii.Quantity__c;
                Decimal r = ii.Total_Amount__c == null ? ZERO : ii.Total_Amount__c;
                userQty.put(ta.Id, (userQty.get(ta.Id) == null ? ZERO : userQty.get(ta.Id)) + q);
                userRevenue.put(ta.Id, (userRevenue.get(ta.Id) == null ? ZERO : userRevenue.get(ta.Id)) + r);
                
                mappingsToUpsert.add(new TargetActuals_Mapping__c(
                    TargetActuals__c = ta.Id,
                    Invoice_item__c = ii.Id,
                    Quantity__c = q,
                    Revenue__c = r,
                    Mapping_Id__c = ta.Id + '-' + ii.Id
                ));
            }
        }
        
        // --- Update TargetActuals__c records
        List<TargetActuals__c> toUpdate = new List<TargetActuals__c>();
        for (TargetActuals__c ta : scope) {
            if (skuQty.containsKey(ta.Id) || skuRevenue.containsKey(ta.Id)) {
                ta.Actual_Quantity_KG__c = ta.Target_Quantity_KG__c != null ? skuQty.get(ta.Id) : null;
                ta.Actual_Revenue__c = ta.Target_Revenue__c != null ? skuRevenue.get(ta.Id) : null;
            } else if (distQty.containsKey(ta.Id) || distRevenue.containsKey(ta.Id)) {
                ta.Actual_Quantity_KG__c = ta.Target_Quantity_KG__c != null ? distQty.get(ta.Id) : null;
                ta.Actual_Revenue__c = ta.Target_Revenue__c != null ? distRevenue.get(ta.Id) : null;
            } else if (userQty.containsKey(ta.Id) || userRevenue.containsKey(ta.Id)) {
                ta.Actual_Quantity_KG__c = ta.Target_Quantity_KG__c != null ? userQty.get(ta.Id) : null;
                ta.Actual_Revenue__c = ta.Target_Revenue__c != null ? userRevenue.get(ta.Id) : null;
            } else {
                ta.Actual_Quantity_KG__c = ta.Target_Quantity_KG__c != null ? 0 : null;
                ta.Actual_Revenue__c = ta.Target_Revenue__c != null ? 0 : null;
            }
            toUpdate.add(ta);
        }
        if (!toUpdate.isEmpty()) update toUpdate;
        if (!mappingsToUpsert.isEmpty()) upsert mappingsToUpsert Mapping_Id__c;
    }
    
    global void finish(Database.BatchableContext BC) {}
    
    global void execute(SchedulableContext SC){
        
        Database.executeBatch(new TargetActualsBatch());
      /*  String cronExpression1 = '0 0 * * * ?'; // Run at 0th minute
        String cronExpression2 = '0 30 * * * ?'; // Run at 30th minute
        
        String jobName1 = 'TargetActualsBatch_1';
        String jobName2 = 'TargetActualsBatch_2';
        
        System.schedule(jobName1, cronExpression1, new TargetActualsBatch());
        System.schedule(jobName2, cronExpression2, new TargetActualsBatch());*/
    } 
    
    public static void transferTargets(Set<Id> empIds){
        
        List<Employee__c> oldEmps = [select Id,Name,User__c,Replaced_For__c,Replaced_For__r.User__c,DOJ__c from Employee__c where Id IN:empIds];
        
        Map<Id,Employee__c> empMap = new Map<Id,Employee__c>();
        
        for(Employee__c emp: oldEmps){
            empMap.put(emp.Replaced_For__r.User__c, emp);
        }
        
        if(!empMap.isEmpty()){
            List<TargetActuals__c> targets = [SELECT Id, User__c, Customer__c, SKU__c, Month__c, Year__c
                                              FROM TargetActuals__c where User__c IN: empMap.keyset() and End_Date__c >= TODAY];
            
            List<TargetActuals__c> newTargetsToCreateorUpdate = new List<TargetActuals__c>();
            for(TargetActuals__c tar: targets){
                
                Employee__c newEmp = empMap.get(tar.User__c);
                
                if(tar.End_Date__c >= newEmp.DOJ__c){
                    
                    TargetActuals__c newTar = new TargetActuals__c ();
                    
                    if(newEmp.DOJ__c.month() == Date.today().month()){
                        newTar = tar.clone(false, true, false, false);
                    }
                    else{
                        newTar.Id = tar.Id;
                    }
                    
                    newTar.User__c = newEmp.User__c;
                    newTar.OwnerId = newEmp.User__c;
                    newTargetsToCreateorUpdate.add(newTar);
                    
                }
                
            }
            
            if(newTargetsToCreateorUpdate.size() > 0){
                database.upsert(newTargetsToCreateorUpdate,false);
            }
            
        }
    }
}