public without sharing class OrderTriggerHandler {
    
    public static void serialNumberMethod(List<Order__c> ordList) {
        // Filter only primary orders that need numbering today
        List<Order__c> primaryOrders = new List<Order__c>();
        Date today = Date.today();
        set<String> customerWithExecutiveIds = new set<String>();
         set<String> customerCodes = new set<String>();
        for(Order__c ord : ordList) {
            if(ord.Customer_Name__c != null)  ord.Customer_Name_Search__c = ord.Customer_Name__c;
            if(ord.Customer_SAP_Code__c != null)  ord.SAP_Code__c = ord.Customer_SAP_Code__c;
            if(ord.Outlet_Id__c != null)  ord.Outlet_Id_Search__c = ord.Outlet_Id__c;
            if(ord.Customer_Code__c != null)  ord.Customer_Code_Search__c = ord.Customer_Code__c;
            if(ord.OwnerCode__c != null)  ord.Owner_Code_Search__c = ord.OwnerCode__c;
            if(ord.Owner_Name__c != null)  ord.Owner_Name_Search__c = ord.Owner_Name__c;
            if(ord.Account__c !=null && ord.Order_Type__c == 'Secondary Order')
            {
                string key = ord.Account__c +'-'+ord.OwnerId;
                customerWithExecutiveIds.add(key);
                customerCodes.add(ord.Account__c);
            }
            if(ord.Order_Type__c == 'Primary Order' && (ord.Order_Date__c == null || ord.Order_Date__c == today)) {
                primaryOrders.add(ord);
            }
        }
        
        list<Product_Mapping__c> secondaryMappings = [select Id,Primary_Customer__c,Customer__c,Customer_Executive_Pair__c,Sub_Stockiest__c
                                                      from Product_Mapping__c where 
                                                      Customer_Executive_Pair__c In:customerWithExecutiveIds and Primary_Customer__c != null];
        list<Product_Mapping__c> allsecondaryMappings = [select Id,Primary_Customer__c,Customer__c,Customer_Executive_Pair__c,Sub_Stockiest__c
                                                         from Product_Mapping__c where Customer__c In:customerCodes and Primary_Customer__c != null];
        
        if(!secondaryMappings.isEmpty() || !allsecondaryMappings.isEmpty())
        {
            map<String,String> keyWithPrimaryCustomer = new map<String,String>();
            map<String,String> keyWithSubStockiest = new map<String,String>();
            for(Product_Mapping__c pm :secondaryMappings)
            {
                keyWithPrimaryCustomer.put(pm.Customer_Executive_Pair__c,pm.Primary_Customer__c);
                if(pm.Sub_Stockiest__c != null)
                {
                     keyWithSubStockiest.put(pm.Customer_Executive_Pair__c,pm.Sub_Stockiest__c);
                }
            }
            
            map<String,String> secondaryCustomerWithPrimaryCustomer = new map<String,String>();
            map<String,String> secondaryCustomerWithSubStockiest = new map<String,String>();
            for(Product_Mapping__c pm :allsecondaryMappings)
            {
                secondaryCustomerWithPrimaryCustomer.put(pm.Customer__c,pm.Primary_Customer__c);
                if(pm.Sub_Stockiest__c != null)
                {
                    secondaryCustomerWithSubStockiest.put(pm.Customer__c,pm.Sub_Stockiest__c);
                }
            }

            for(Order__c ord : ordList) {
                if(ord.Account__c !=null && ord.Order_Type__c == 'Secondary Order')
                {
                    string key = ord.Account__c +'-'+ord.OwnerId;
                    if(keyWithPrimaryCustomer.containsKey(key))
                    {
                        string DistributorId =  keyWithPrimaryCustomer.get(key);
                        ord.Distributor__c = DistributorId;
                    }
                    else if(secondaryCustomerWithPrimaryCustomer.containsKey(ord.Account__c))
                    {
                        string DistributorId =  secondaryCustomerWithPrimaryCustomer.get(ord.Account__c);
                        ord.Distributor__c = DistributorId;
                    }
                    
                    
                    if(keyWithSubStockiest.containsKey(key))
                    {
                        string subStockiestId =  keyWithSubStockiest.get(key);
                        ord.Sub_Stockiest__c = subStockiestId;
                    }
                    else if(secondaryCustomerWithPrimaryCustomer.containsKey(ord.Account__c))
                    {
                        string subStockiestId =  secondaryCustomerWithSubStockiest.get(ord.Account__c);
                        ord.Sub_Stockiest__c = subStockiestId;
                    }
                }
                
            }
            
        }
        
        if(primaryOrders.isEmpty()) return;
        
        try {
            // Lock the counter record for this order type and date
            List<Order_Counter__c> counters = [SELECT Id, Last_Number__c 
                                               FROM Order_Counter__c 
                                               WHERE Type__c = 'PrimaryOrder' 
                                               AND Date__c = :today
                                               WITH SECURITY_ENFORCED
                                               FOR UPDATE];
            
            Order_Counter__c counter;
            Decimal nextNumber;
            
            if(counters.isEmpty()) {
                // Create new counter if none exists for today
                counter = new Order_Counter__c(
                    Type__c = 'PrimaryOrder',
                    Date__c = today,
                    Last_Number__c = 0
                );
                nextNumber = 1;
            } else {
                counter = counters[0];
                nextNumber = counter.Last_Number__c + 1;
            }
            
            // Assign numbers to all orders
            for(Order__c ord : primaryOrders) {
                ord.SNUM__c = nextNumber++;
                if(ord.Order_Date__c == null) {
                    ord.Order_Date__c = today;
                }
            }
            
            // Update counter with new last number
            counter.Last_Number__c = nextNumber - 1;
            upsert counter;
            
        } catch(Exception e) {
            // Handle errors gracefully
            for(Order__c ord : primaryOrders) {
                ord.addError('Error assigning order number: ' + e.getMessage());
            }
        }
    }
    
    public static void afterInsert(List<Order__c> newOrderList) {
        // Map to hold latest order per Account
        Map<Id, Order__c> latestOrderMap = new Map<Id, Order__c>();
        Set<Id> visitIds = new Set<Id>();
        set<Id> userIds = new set<Id>();
        Set<Date> orderDates = new Set<Date>();
        List<Order__c> ordersToUpdate = new List<Order__c>();
        for (Order__c ord : newOrderList) {
            //  Set the Auto Number (Name) into Order_Id_Text__c
            if (String.isBlank(ord.Order_Id_Text__c) && !String.isBlank(ord.Name)) {
                ordersToUpdate.add(new Order__c(
                    Id = ord.Id,
                    Order_Id_Text__c = ord.Name
                ));
            }
            if (ord.Account__c != null) {
                if(ord.Visit__c != null)
                {
                    visitIds.add(ord.Visit__c);
                }
                // Check if we already have an order for this Account
                if (!latestOrderMap.containsKey(ord.Account__c)) {
                    latestOrderMap.put(ord.Account__c, ord);
                } else {
                    // Compare CreatedDate, keep the latest one
                    Order__c existing = latestOrderMap.get(ord.Account__c);
                    if (ord.CreatedDate > existing.CreatedDate) {
                        latestOrderMap.put(ord.Account__c, ord);
                    }
                }
            }
            userIds.add(ord.OwnerId);
            orderDates.add(ord.Order_Date__c);
        }
        
        
        // Update Orders with their Auto Number
        if (!ordersToUpdate.isEmpty()) {
            database.update(ordersToUpdate,false);
        }
        
        
        // Build Account list for update
        List<Account> accountsToUpdate = new List<Account>();
        for (Id accId : latestOrderMap.keySet()) {
            accountsToUpdate.add(new Account(
                Id = accId,
                Last_Order__c = latestOrderMap.get(accId).Id
            ));
        }
        
        if (!accountsToUpdate.isEmpty()) {
            database.update(accountsToUpdate,false);
        }
        
        if (!visitIds.isEmpty()) {
            list<Visit__c> VisitsToUpdateStatus = [select Id,Name,Visit_Output__c from Visit__c where Id IN:visitIds ];         
            for(Visit__c vis: VisitsToUpdateStatus)
            {
                vis.Visit_Output__c = 'PJP Successful';
            }
            database.update(VisitsToUpdateStatus,false);
        }
        
        if(!userIds.isEmpty() && !orderDates.isEmpty())
        {
            getNonPJPOrderCount(userIds,orderDates);
        }
    }
    

    public static void afterUpdate(List<Order__c> newOrderList,Map<Id,Order__c> oldMap)
    {
        set<Id> userIds = new set<Id>();
        Set<Date> orderDates = new Set<Date>();
        set<Id> visitIds = new set<Id>();
        for (Order__c ord : newOrderList) {
            if(ord.Status__c != oldMap.get(ord.Id).Status__c)
            {
                userIds.add(ord.OwnerId);
                orderDates.add(ord.Order_Date__c);
                if(ord.Visit__c != null )
                {
                    visitIds.add(ord.Visit__c);
                }
            }  
               
        }
        if(!userIds.isEmpty() && !orderDates.isEmpty())
        {
            OrderAmountUpdateOnDailyLog(userIds,orderDates);
        }
        
        //Update Visit Status after Rejected
        if (!visitIds.isEmpty()) {
            updateVisitStatusAfterRejection(visitIds);
        }
       
        
    }
    public static void afterDelete(List<Order__c> oldOrderList) {
        Set<Id> accountIds = new Set<Id>();
        set<Id> userIds = new set<Id>();
        Set<Date> orderDates = new Set<Date>();
        Set<Id> visitIds = new Set<Id>();
        for (Order__c ord : oldOrderList) {
            userIds.add(ord.OwnerId);
            orderDates.add(ord.Order_Date__c);
            if (ord.Account__c != null) {
                accountIds.add(ord.Account__c);
            }
            if(ord.Visit__c != null)
            {
                visitIds.add(ord.Visit__c );
            }
        }
        
        if (!accountIds.isEmpty()) {
            // Query all remaining orders, sorted latest first
            List<Order__c> remainingOrders = [
                SELECT Id, Account__c, CreatedDate
                FROM Order__c
                WHERE Account__c IN :accountIds
                ORDER BY Account__c, CreatedDate DESC
            ];
            
            // Map to hold latest order per account
            Map<Id, Id> latestOrderMap = new Map<Id, Id>();
            
            for (Order__c ord : remainingOrders) {
                if (!latestOrderMap.containsKey(ord.Account__c)) {
                    latestOrderMap.put(ord.Account__c, ord.Id); // first (latest) order for that account
                }
            }
            
            // Prepare account updates
            List<Account> accountsToUpdate = new List<Account>();
            for (Id accId : accountIds) {
                Account acc = new Account(Id = accId);
                if (latestOrderMap.containsKey(accId)) {
                    acc.Last_Order__c = latestOrderMap.get(accId);
                } else {
                    acc.Last_Order__c = null;
                }
                accountsToUpdate.add(acc);
            }
            
            if (!accountsToUpdate.isEmpty()) {
                database.update(accountsToUpdate,false);
            }
        }
        if(!userIds.isEmpty() && !orderDates.isEmpty())
        {
            OrderAmountUpdateOnDailyLog(userIds,orderDates);
        }
        
        //Update Visit Status after Rejected
        if (!visitIds.isEmpty()) {
            updateVisitStatusAfterRejection(visitIds);
        }
   
    }
 
    public static void beforeUpdate(List<Order__c> newOrderList,Map<Id,Order__c> oldMap)
    {
        for (Order__c ord : newOrderList) {
            if(ord.OwnerId != oldMap.get(ord.Id).OwnerId)
            {
                if(ord.OwnerCode__c != null)  ord.Owner_Code_Search__c = ord.OwnerCode__c;
                if(ord.Owner_Name__c != null)  ord.Owner_Name_Search__c = ord.Owner_Name__c;
            }  
        }
    }
    
    public static void updateVisitStatusAfterRejection(set<Id> visitIds)
    {
        if (!visitIds.isEmpty()) {
            // Step 1: Query all visits
            List<Visit__c> visits = [
                SELECT Id, Visit_Output__c 
                FROM Visit__c 
                WHERE Id IN :visitIds
            ];
            
            // Step 2: Find visits that still have orders
            Set<Id> visitsWithOrders = new Set<Id>();
            for (AggregateResult ar : [
                SELECT Visit__c vId, COUNT(Id) cnt
                FROM Order__c
                WHERE Visit__c IN :visitIds and Status__c != 'Rejected'
                GROUP BY Visit__c
            ]) {
                visitsWithOrders.add((Id) ar.get('vId'));
            }
            
            // Step 3: Update visits that no longer have orders
            List<Visit__c> visitsToUpdate = new List<Visit__c>();
            for (Visit__c v : visits) {
                if (!visitsWithOrders.contains(v.Id)) {
                    v.Visit_Output__c = 'PJP Unsuccessful';
                    visitsToUpdate.add(v);
                }
            }
            
            if (!visitsToUpdate.isEmpty()) {
                update visitsToUpdate;
            }
        }
    }
    
    public static void getNonPJPOrderCount(Set<Id> userIds, Set<Date> orderDates) {
        if (userIds.isEmpty() || orderDates.isEmpty()) return;
        
        // Step 1: Fetch all orders (both PJP and Non-PJP)
        List<Order__c> orders = [
            SELECT Id, OwnerId, Order_Date__c, Account__c, Visit__c,Location_Type__c
            FROM Order__c
            WHERE OwnerId IN :userIds
            AND Order_Date__c IN :orderDates
            AND Status__c != 'Rejected'
            AND Account__c != null
        ];
        
        // Step 2: Build maps for each Owner + Date + Customer
        Map<String, Set<Id>> visitOrders = new Map<String, Set<Id>>();   // customers with Visit__c != null
        Map<String, Set<Id>> nonVisitOrders = new Map<String, Set<Id>>(); // customers with Visit__c = null
        
        Map<String, Set<Id>> inLocationMap = new Map<String, Set<Id>>();   // Visit__c = null & Location_Type__c = 'In Location'
        Map<String, Set<Id>> outLocationMap = new Map<String, Set<Id>>();  // Visit__c = null & Location_Type__c = 'Out Location'        
        
        for (Order__c o : orders) {
            String key = o.OwnerId + '-' + o.Order_Date__c;
            
            if (o.Visit__c != null) {
                if (!visitOrders.containsKey(key)) visitOrders.put(key, new Set<Id>());
                visitOrders.get(key).add(o.Account__c);
            } else {
                if (!nonVisitOrders.containsKey(key)) nonVisitOrders.put(key, new Set<Id>());
                nonVisitOrders.get(key).add(o.Account__c);
                
                // Track In/Out location customers separately
                if (o.Location_Type__c == 'In Location') {
                    if (!inLocationMap.containsKey(key)) inLocationMap.put(key, new Set<Id>());
                    inLocationMap.get(key).add(o.Account__c);
                } else if (o.Location_Type__c == 'Out Location') {
                    if (!outLocationMap.containsKey(key)) outLocationMap.put(key, new Set<Id>());
                    outLocationMap.get(key).add(o.Account__c);
                }
                
                
            }
        }
        
        // Step 3: Compute valid Non-PJP customers (who have no Visit__c != null)
        Map<String, Decimal> finalNonPjpCount = new Map<String, Decimal>();
        Map<String, Decimal> finalInLocationCount = new Map<String, Decimal>();
        Map<String, Decimal> finalOutLocationCount = new Map<String, Decimal>();
        
        
        for (String key : nonVisitOrders.keySet()) {
            Set<Id> nonPjpCustomers = nonVisitOrders.get(key);
            Set<Id> pjpCustomers = visitOrders.containsKey(key) ? visitOrders.get(key) : new Set<Id>();
            
            // Remove customers who already have a PJP order that day
            nonPjpCustomers.removeAll(pjpCustomers);
            
            
            // Now calculate In/Out location counts (based on filtered customers)
            Set<Id> inLoc = inLocationMap.containsKey(key) ? new Set<Id>(inLocationMap.get(key)) : new Set<Id>();
            Set<Id> outLoc = outLocationMap.containsKey(key) ? new Set<Id>(outLocationMap.get(key)) : new Set<Id>();
            
            inLoc.retainAll(nonPjpCustomers);
            outLoc.retainAll(nonPjpCustomers);
            outLoc.removeAll(inLoc);
            
            finalNonPjpCount.put(key, Decimal.valueOf(nonPjpCustomers.size()));
            
            finalInLocationCount.put(key, Decimal.valueOf(inLoc.size()));
            finalOutLocationCount.put(key, Decimal.valueOf(outLoc.size()));
        }
        
        // Step 4: Update Daily_Log__c records
        List<Daily_Log__c> logsToUpdate = [
            SELECT Id, OwnerId, Date__c
            FROM Daily_Log__c
            WHERE OwnerId IN :userIds
            AND Date__c IN :orderDates
        ];
        
        for (Daily_Log__c dl : logsToUpdate) {
            String key = dl.OwnerId + '-' + dl.Date__c;
            dl.Non_PJP_Order_Calls__c = finalNonPjpCount.containsKey(key) ? finalNonPjpCount.get(key) : 0;
            dl.Non_PJP_Normal_Calls__c = finalInLocationCount.containsKey(key) ? finalInLocationCount.get(key) : 0;
            dl.Non_PJP_Telephonic_Calls__c = finalOutLocationCount.containsKey(key) ? finalOutLocationCount.get(key) : 0;
        }
        
        if (!logsToUpdate.isEmpty()) {
            update logsToUpdate;
        }
    }
        
    public static void OrderAmountUpdateOnDailyLog(Set<Id> userIds,Set<Date> orderDates) {
        if (userIds.isEmpty() || orderDates.isEmpty()) return;
        
        Map<String, Decimal> totalMap     = new Map<String, Decimal>();
        Map<String, Decimal> primaryMap   = new Map<String, Decimal>();
        Map<String, Decimal> secondaryMap = new Map<String, Decimal>();
        
        // Maps with nested structure: userId + date → sum
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
            AND Status__c != 'Rejected'
            GROUP BY OwnerId,Order_Date__c, Order_Type__c,Account__r.Secondary_Customer_Type__c
        ]) {
            Id ownerId       = (Id)ar.get('ownerId');
            Date orderDate   = (Date)ar.get('orderDate');
            String orderType = (String)ar.get('ordtype');
            String secType = (String)ar.get('secType');
            Decimal orderItemCount = (Decimal)ar.get('orderItemCount');
            Decimal sumTotal = (Decimal)ar.get('sumTotal');
            
            String key = ownerId + '-' + orderDate;
            // total Amount
            totalMap.put(key, (totalMap.containsKey(key) ? totalMap.get(key) : 0) + sumTotal);
            
            //Total Line Sold
            totalLinesSoldMap.put(key, (totalLinesSoldMap.containsKey(key) ? totalLinesSoldMap.get(key) : 0) + orderItemCount);
            
            if (orderType == 'Primary Order') {
                primaryMap.put(key, (primaryMap.containsKey(key) ? primaryMap.get(key) : 0) + sumTotal);
                totalLinesSoldPrimaryMap.put(key, (totalLinesSoldPrimaryMap.containsKey(key) ? totalLinesSoldPrimaryMap.get(key) : 0) + orderItemCount);
            } else if (orderType == 'Secondary Order') {
                secondaryMap.put(key, (secondaryMap.containsKey(key) ? secondaryMap.get(key) : 0) + sumTotal);
                if(secType == 'Sub Stockiest')
                {
                    totalLinesSoldSubStockiestMap.put(key, (totalLinesSoldSubStockiestMap.containsKey(key) ? totalLinesSoldSubStockiestMap.get(key) : 0) + orderItemCount);
                }
                else
                {
                    totalLinesSoldOutletMap.put(key, (totalLinesSoldOutletMap.containsKey(key) ? totalLinesSoldOutletMap.get(key) : 0) + orderItemCount);
                }
            }
        }
        
        // Step 1: Fetch all orders (both PJP and Non-PJP)
        List<Order__c> orders = [
            SELECT Id, OwnerId, Order_Date__c, Account__c, Visit__c,Location_Type__c
            FROM Order__c
            WHERE OwnerId IN :userIds
            AND Order_Date__c IN :orderDates
            AND Status__c != 'Rejected'
            AND Account__c != null
        ];
        
        // Step 2: Build maps for each Owner + Date + Customer
        Map<String, Set<Id>> visitOrders = new Map<String, Set<Id>>();   // customers with Visit__c != null
        Map<String, Set<Id>> nonVisitOrders = new Map<String, Set<Id>>(); // customers with Visit__c = null
        
        Map<String, Set<Id>> inLocationMap = new Map<String, Set<Id>>();   // Visit__c = null & Location_Type__c = 'In Location'
        Map<String, Set<Id>> outLocationMap = new Map<String, Set<Id>>();  // Visit__c = null & Location_Type__c = 'Out Location'    
        
        for (Order__c o : orders) {
            String key = o.OwnerId + '-' + o.Order_Date__c;
            
            if (o.Visit__c != null) {
                if (!visitOrders.containsKey(key)) visitOrders.put(key, new Set<Id>());
                visitOrders.get(key).add(o.Account__c);
            } else {
                if (!nonVisitOrders.containsKey(key)) nonVisitOrders.put(key, new Set<Id>());
                nonVisitOrders.get(key).add(o.Account__c);
                
                // Track In/Out location customers separately
                if (o.Location_Type__c == 'In Location') {
                    if (!inLocationMap.containsKey(key)) inLocationMap.put(key, new Set<Id>());
                    inLocationMap.get(key).add(o.Account__c);
                } else if (o.Location_Type__c == 'Out Location') {
                    if (!outLocationMap.containsKey(key)) outLocationMap.put(key, new Set<Id>());
                    outLocationMap.get(key).add(o.Account__c);
                }
            }
        }
        
        // Step 3: Compute valid Non-PJP customers (who have no Visit__c != null)
        Map<String, Decimal> finalNonPjpCount = new Map<String, Decimal>();
        Map<String, Decimal> finalInLocationCount = new Map<String, Decimal>();
        Map<String, Decimal> finalOutLocationCount = new Map<String, Decimal>();
        
        
        for (String key : nonVisitOrders.keySet()) {
            Set<Id> nonPjpCustomers = nonVisitOrders.get(key);
            Set<Id> pjpCustomers = visitOrders.containsKey(key) ? visitOrders.get(key) : new Set<Id>();
            
            // Remove customers who already have a PJP order that day
            nonPjpCustomers.removeAll(pjpCustomers);
            
            // Now calculate In/Out location counts (based on filtered customers)
            Set<Id> inLoc = inLocationMap.containsKey(key) ? new Set<Id>(inLocationMap.get(key)) : new Set<Id>();
            Set<Id> outLoc = outLocationMap.containsKey(key) ? new Set<Id>(outLocationMap.get(key)) : new Set<Id>();
            
            inLoc.retainAll(nonPjpCustomers);
            outLoc.retainAll(nonPjpCustomers);
            outLoc.removeAll(inLoc);
            
            finalNonPjpCount.put(key, Decimal.valueOf(nonPjpCustomers.size()));

            finalInLocationCount.put(key, Decimal.valueOf(inLoc.size()));
            finalOutLocationCount.put(key, Decimal.valueOf(outLoc.size()));
        }
        
        
        // Query daily logs for those users & dates
        List<Daily_Log__c> dailyLogs = [
            SELECT Id, OwnerId, Date__c
            FROM Daily_Log__c
            WHERE OwnerId IN :userIds
            AND Date__c IN :orderDates
        ];
        
        List<Daily_Log__c> logsToUpdate = new List<Daily_Log__c>();
        for (Daily_Log__c dl : dailyLogs) {
            String key = dl.OwnerId + '-' + dl.Date__c;
            
            dl.Total_Order_Amount__c    = totalMap.containsKey(key) ? totalMap.get(key) : 0;
            dl.Primary_Order_Amount__c  = primaryMap.containsKey(key) ? primaryMap.get(key) : 0;
            dl.Secondary_Order_Amont__c = secondaryMap.containsKey(key) ? secondaryMap.get(key) : 0;
            
            
            dl.TLSD__c = totalLinesSoldMap.containsKey(key) ? totalLinesSoldMap.get(key) : 0;
            dl.TLSD_Retailers_Outlets__c = totalLinesSoldOutletMap.containsKey(key) ? totalLinesSoldOutletMap.get(key) : 0;
            dl.TLSD_Sub_Stockist__c = totalLinesSoldSubStockiestMap.containsKey(key) ? totalLinesSoldSubStockiestMap.get(key) : 0;    
            dl.TLSD_Primary__c = totalLinesSoldPrimaryMap.containsKey(key) ? totalLinesSoldPrimaryMap.get(key) : 0;   
            // Update Visit-null order count
            dl.Non_PJP_Order_Calls__c = finalNonPjpCount.containsKey(key) ? finalNonPjpCount.get(key) : 0;
            dl.Non_PJP_Normal_Calls__c = finalInLocationCount.containsKey(key) ? finalInLocationCount.get(key) : 0;
            dl.Non_PJP_Telephonic_Calls__c = finalOutLocationCount.containsKey(key) ? finalOutLocationCount.get(key) : 0;
            
            logsToUpdate.add(dl);
        }
        
        if (!logsToUpdate.isEmpty()) {
            update logsToUpdate;
        }
    }
    
    
}