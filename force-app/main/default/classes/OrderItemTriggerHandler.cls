public without sharing class OrderItemTriggerHandler {
    public static void updateOrderAmount(List<Order_Item__c> newOrderItemList) {
        set<Id> userIds = new set<Id>();
        Set<Date> orderDates = new Set<Date>();
        for (Order_Item__c ord : newOrderItemList) {
            userIds.add(ord.Order_Owner_Id__c);
            if (ord.Order_Date__c != null) {
                orderDates.add(ord.Order_Date__c);
            }
        }
        if(!userIds.isEmpty() && !orderDates.isEmpty())
        {
            //system.debug('userIds'+userIds);
            OrderAmountUpdateOnDailyLog(userIds,orderDates);
        }
        
    }
    public static void OrderAmountUpdateOnDailyLog(Set<Id> userIds, Set<Date> orderDates) {
        if (userIds.isEmpty() || orderDates.isEmpty()) return;
        
        // Maps with nested structure: userId + date → sum
        Map<String, Decimal> totalMap     = new Map<String, Decimal>();
        Map<String, Decimal> primaryMap   = new Map<String, Decimal>();
        Map<String, Decimal> secondaryMap = new Map<String, Decimal>();
        
        // Maps with nested structure: userId + date → line counts
        Map<String, Decimal> totalLinesSoldMap            = new Map<String, Decimal>();
        Map<String, Decimal> totalLinesSoldPrimaryMap     = new Map<String, Decimal>();
        Map<String, Decimal> totalLinesSoldSubStockiestMap = new Map<String, Decimal>();
        Map<String, Decimal> totalLinesSoldOutletMap      = new Map<String, Decimal>();
        
        for (AggregateResult ar : [
            SELECT 
            Order__r.OwnerId ownerId,
            Order__r.Order_Date__c orderDate,
            Order__r.Order_Type__c ordType,
            Order__r.Account__r.Secondary_Customer_Type__c secType,
            SUM(Total_Amount__c) sumTotal,
            COUNT(Id) orderItemCount
            FROM Order_Item__c
            WHERE Order__r.OwnerId IN :userIds
            AND Order__r.Order_Date__c IN :orderDates
            GROUP BY Order__r.OwnerId, Order__r.Order_Date__c, Order__r.Order_Type__c, Order__r.Account__r.Secondary_Customer_Type__c
        ]) {
            Id ownerId       = (Id)ar.get('ownerId');
            Date orderDate   = (Date)ar.get('orderDate');
            String orderType = (String)ar.get('ordType');
            String secType   = (String)ar.get('secType');
            
            Long orderItemCountLong = (Long)ar.get('orderItemCount');
            Decimal orderItemCount  = Decimal.valueOf(orderItemCountLong);
            Decimal sumTotal        = (Decimal)ar.get('sumTotal');
            
            String key = ownerId + '-' + orderDate;
            
            // Total Amount (cumulative)
            totalMap.put(key, (totalMap.containsKey(key) ? totalMap.get(key) : 0) + sumTotal);
            
            // Total Lines Sold (cumulative)
            totalLinesSoldMap.put(key, (totalLinesSoldMap.containsKey(key) ? totalLinesSoldMap.get(key) : 0) + orderItemCount);
            
            if (orderType == 'Primary Order') {
                // Primary Amount
                primaryMap.put(key, (primaryMap.containsKey(key) ? primaryMap.get(key) : 0) + sumTotal);
                // Primary Lines Sold
                totalLinesSoldPrimaryMap.put(key, (totalLinesSoldPrimaryMap.containsKey(key) ? totalLinesSoldPrimaryMap.get(key) : 0) + orderItemCount);
            } else if (orderType == 'Secondary Order') {
                // Secondary Amount
                secondaryMap.put(key, (secondaryMap.containsKey(key) ? secondaryMap.get(key) : 0) + sumTotal);
                
                // Secondary Lines Sold split into Sub Stockist vs Outlet
                if (secType == 'Sub Stockiest') {
                    totalLinesSoldSubStockiestMap.put(key, 
                                                      (totalLinesSoldSubStockiestMap.containsKey(key) ? totalLinesSoldSubStockiestMap.get(key) : 0) + orderItemCount
                                                     );
                } else {
                    totalLinesSoldOutletMap.put(key, 
                                                (totalLinesSoldOutletMap.containsKey(key) ? totalLinesSoldOutletMap.get(key) : 0) + orderItemCount
                                               );
                }
            }
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
            
            dl.TLSD__c                   = totalLinesSoldMap.containsKey(key) ? totalLinesSoldMap.get(key) : 0;
            dl.TLSD_Retailers_Outlets__c = totalLinesSoldOutletMap.containsKey(key) ? totalLinesSoldOutletMap.get(key) : 0;
            dl.TLSD_Sub_Stockist__c      = totalLinesSoldSubStockiestMap.containsKey(key) ? totalLinesSoldSubStockiestMap.get(key) : 0;    
            dl.TLSD_Primary__c           = totalLinesSoldPrimaryMap.containsKey(key) ? totalLinesSoldPrimaryMap.get(key) : 0;   
            
            logsToUpdate.add(dl);
        }
        
        if (!logsToUpdate.isEmpty()) {
            update logsToUpdate;
        }
    }
    
    public static void updateOwnerAndGrantAccessFromItems(List<Order__c> orders, Id originalUserId) {
        Map<Id, Id> orderToExecutiveMap = new Map<Id, Id>();
        
        for(Order__c ord : orders) {
            if(ord.Executive__c != null && ord.OwnerId != ord.Executive__c) {
                orderToExecutiveMap.put(ord.Id, ord.Executive__c);
            }
        }
        
        if(!orderToExecutiveMap.isEmpty()) {
            // Call future method to update owner and grant access
            updateOwnerAndGrantAccessFuture(orderToExecutiveMap, originalUserId);
        }
    }
    
    @future
    public static void updateOwnerAndGrantAccessFuture(Map<Id, Id> orderToExecutiveMap, Id originalUserId) {
        List<Order__c> ordersToUpdate = new List<Order__c>();
        List<Order__Share> sharesToCreate = new List<Order__Share>();
        
        // Step 1: Update Owner to Executive
        for(Id orderId : orderToExecutiveMap.keySet()) {
            ordersToUpdate.add(new Order__c(
                Id = orderId,
                OwnerId = orderToExecutiveMap.get(orderId)
            ));
        }
        
        if(!ordersToUpdate.isEmpty()) {
            try {
                update ordersToUpdate;
                System.debug('Successfully updated ' + ordersToUpdate.size() + ' order owners');
                
                // Step 2: Grant Read/Write access to original user (platform user)
                for(Id orderId : orderToExecutiveMap.keySet()) {
                    Order__Share orderShare = new Order__Share();
                    orderShare.ParentId = orderId;
                    orderShare.UserOrGroupId = originalUserId;
                    orderShare.AccessLevel = 'Edit'; // or 'Read' if you only need read access
                    orderShare.RowCause = Schema.Order__Share.RowCause.Manual;
                    
                    sharesToCreate.add(orderShare);
                }
                
                if(!sharesToCreate.isEmpty()) {
                    Database.SaveResult[] shareResults = Database.insert(sharesToCreate, false);
                    
                    for(Integer i = 0; i < shareResults.size(); i++) {
                        if(!shareResults[i].isSuccess()) {
                            System.debug('Error creating share for order: ' + sharesToCreate[i].ParentId);
                            System.debug('Error: ' + shareResults[i].getErrors()[0].getMessage());
                        } else {
                            System.debug('Successfully granted access to user for order: ' + sharesToCreate[i].ParentId);
                        }
                    }
                }
                
            } catch(Exception e) {
                System.debug('Error in updateOwnerAndGrantAccessFuture: ' + e.getMessage());
                System.debug('Stack Trace: ' + e.getStackTraceString());
            }
        }
    }
    
}