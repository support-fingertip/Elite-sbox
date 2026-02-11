public class EODReportPdfController {
    public Id recid { get; set; }
    public Date filterDate { get; set; }
    public List<OrderWapper> secondaryOItemList { get; set;} 
    public List<OrderWapper> primaryOItemList { get; set; }
    public List<CollectionWapper> collectionList { get; set; }
    public List<OrderWapper> orderfulfilmentList { get; set; }
    
    
    public Decimal totalPrimaryPjpQuantity {get;set;}
    public Decimal totalPrimaryNonPjpQuantity {get;set;}
    public Decimal totalPrimaryQuantity {get;set;}
    public Decimal totalPrimaryAmount {get;set;}
    
    public Decimal totalSecondaryPjpQuantity {get;set;}
    public Decimal totalSecondaryNonPjpQuantity {get;set;}
    public Decimal totalSecondaryQuantity {get;set;}
    public Decimal totalSecondaryAmount {get;set;}
    public string ownerName { get; set; }
    public string ownerEmployeeCode { get; set; }
    
    public Decimal totalCalls {get;set;}
    public Decimal productiveCalls {get;set;}
    public Decimal newCalls {get;set;}
    public Decimal totalSoldQuantityforTodayInKgs {get;set;}
    public Decimal totalOrderforToday {get;set;}
    
    public string beatSwitchHistory {get;set;}
    public string todaysBEAT {get;set;}
    public string workedBEAT {get;set;}
    public Decimal totalOutletsInTodaysBEAT {get;set;}
    public Decimal totalNOTVisitedOutlets {get;set;}
    
    public String tomorrowsBEAT {get;set;}
    public Decimal totalOutletsinTomorrowsBEAT {get;set;}
    public String tomorrowBeatLabl {get;set;}
    public String totalOutletsinTomorrowsBEATlebel {get;set;} 
    
    
    public Decimal todayCollectionAmount {get;set;}
    public String attendanceTime {get;set;}
    public String startCallTime {get;set;}
    public String endCalTime {get;set;}
    public String eodTime {get;set;}
    public Decimal totalDistanceCovered {get;set;}
    public Decimal totalDistanceCoveredOdometer {get;set;}
    
    public Decimal totalCollectionAmount {get;set;}    
    public Decimal totalOrderfulfilmemtQuantity {get;set;}    
    
    public Boolean hasPrimaryOrders { get; set; }
    public Boolean hasSecondaryOrders { get; set; }
    public Boolean hasCollections { get; set; }
    public Boolean hasorderfulfilments { get; set; }
    
    public Decimal nonPJPCalls { get; set; }
    public Decimal nonPJPProductiveCalls { get; set; }
    public Decimal nonPJPtotalSoldQuantityforTodayInKgs { get; set; }
    public Decimal nonPJPtotalOrderforToday { get; set; }
    
    public Decimal pjpCalls { get; set; }
    public Decimal pjpProductiveCalls { get; set; }
    
    public EODReportPdfController(ApexPages.StandardController controller) { 
        recid = ApexPages.currentPage().getParameters().get('id');
        String dateParam = ApexPages.currentPage().getParameters().get('date');
        Date filterDate;
        if (String.isNotBlank(dateParam)) {
            filterDate = Date.valueOf(dateParam); // expects 'yyyy-MM-dd'
        } else {
            filterDate = Date.today();
        }
    
        list<Daily_Log__c> dailyLog = [SELECT Id, OwnerId,
                                       Start_time__c, First_Visit_Time__c, Last_Visit_Time__c, End_Time__c, Effective_Man_Hours__c, Market_Hours__c,
                                       Assigned_Beat__r.Name, Current_Beat__r.Name, Beat_Switch_History__c,
                                       Distributor_Name__c, Distributor_Id__c, Calls_Made__c, Total_Visits__c, Prouctive_Calls_Made__c, Total_Productive_Calls__c,
                                       Total_Non_Productive_Calls__c, New_Calls__c, Distance_Travelled_by_Odometer__c, Distance_Travelled__c, TLSD__c,
                                       Total_Outlets__c, Total_Order_Amount__c, Primary_Order_Amount__c, Secondary_Order_Amont__c, TLSD_Retailers_Outlets__c,
                                       TLSD_Sub_Stockist__c, TLSD_Primary__c, Lines_Per_OL__c, TPut_Per_OL__c, Normal_Call__c, Telephonic_Call__c,Outlets_Not_Visited__c
                                       ,First_Visit_Time1__c,Last_Visit_Time1__c,Owner.Name
                                       FROM Daily_Log__c  
                                       WHERE OwnerId  =: recid 
                                       AND CreatedDate = Today];
        
        //system.debug('dailyLog=========>'+dailyLog);
        if (!dailyLog.isEmpty()) {
            Daily_Log__c log = dailyLog[0];
            ownerName = dailyLog[0].Owner.Name;
            totalCalls             = log.Total_Visits__c != null ? log.Total_Visits__c : 0;
            productiveCalls        = log.Total_Productive_Calls__c != null ? log.Total_Productive_Calls__c : 0;
            pjpCalls               = log.Total_Visits__c != null ? log.Total_Visits__c : 0;
            pjpProductiveCalls     = log.Total_Productive_Calls__c != null ? log.Total_Productive_Calls__c : 0;
            
            newCalls               = log.New_Calls__c != null ? log.New_Calls__c : 0;
            totalOrderforToday     = log.Total_Order_Amount__c != null ? log.Total_Order_Amount__c : 0;
            
            todaysBEAT             = log.Assigned_Beat__r != null ? log.Assigned_Beat__r.Name : '';
            workedBEAT             = log.Current_Beat__r != null ? log.Current_Beat__r.Name : '';
            beatSwitchHistory      = log.Beat_Switch_History__c != null ? log.Beat_Switch_History__c : '';
            totalOutletsInTodaysBEAT = log.Total_Outlets__c != null ? log.Total_Outlets__c : 0;
            totalNOTVisitedOutlets = log.Outlets_Not_Visited__c != null ? log.Outlets_Not_Visited__c : 0;
            
            attendanceTime         = log.Start_time__c;
            startCallTime          = log.First_Visit_Time1__c;
            endCalTime             = log.Last_Visit_Time1__c;
            eodTime                = log.End_Time__c;
            totalDistanceCovered   = log.Distance_Travelled__c;   
            totalDistanceCoveredOdometer = log.Distance_Travelled_by_Odometer__c;   
        } 
        else {
            // default values if no Daily_Log__c found
            totalCalls = productiveCalls = newCalls = totalOrderforToday = pjpProductiveCalls = pjpCalls = totalDistanceCoveredOdometer = 0;
            todaysBEAT = workedBEAT = beatSwitchHistory = '';
            totalOutletsInTodaysBEAT = totalNOTVisitedOutlets = 0;
            attendanceTime = startCallTime = endCalTime = eodTime = null;
        }
        
        
        //==============
		//PJP
		//==============
        List<PJP_Item__c> PJPItem = [
            SELECT Id, Date__c, Beat__r.Name, Beat__r.Beat_Outlet_Count__c 
            FROM PJP_Item__c 
            WHERE PJP__r.OwnerId = :recid
            AND Date__c > Today
            LIMIT 1
        ];
        if (!PJPItem.isEmpty()) {
            tomorrowBeatLabl = '1.Next Day\'s BEAT (' + String.valueOf(PJPItem[0].Date__c) + ') :'; 
            totalOutletsinTomorrowsBEATlebel ='2.Total Outlets in Next Day\'s BEAT (' + String.valueOf(PJPItem[0].Date__c) + ') :'; 
            tomorrowsBEAT = PJPItem[0].Beat__r != null ? PJPItem[0].Beat__r.Name : '';
            totalOutletsinTomorrowsBEAT =  PJPItem[0].Beat__r != null ? PJPItem[0].Beat__r.Beat_Outlet_Count__c : 0;
        }
        else {
            tomorrowBeatLabl = '1.Next Day\'s BEAT : ';
            totalOutletsinTomorrowsBEATlebel = '2.Total Outlets in Next Day\'s BEAT :';
        }
        
        //==============
        //Collections
        //==============
        List<AggregateResult> groupedResults = [
            SELECT Mode_of_Payment__c mode, SUM(Amount_Received__c) totalAmt
            FROM Collection_Item__c
            WHERE OwnerId =:recid and CreatedDate = Today
            GROUP BY Mode_of_Payment__c
        ];
        decimal totalCollectionAmt = 0;
        List<CollectionWapper> colItemList = new List<CollectionWapper>();
        Integer cidx = 1;
        for (AggregateResult ar : groupedResults) {
            decimal amount = (Decimal) ar.get('totalAmt');
            CollectionWapper wrap = new CollectionWapper();
            wrap.index = cidx++;
            wrap.transactionMode = (String) ar.get('mode');
            wrap.amount = amount;
            totalCollectionAmt += amount;   
            colItemList.add(wrap);
        }
        totalCollectionAmount = totalCollectionAmt;
        collectionList = colItemList;
        hasCollections = !colItemList.isEmpty();
        
        //==============
        //Order Items
        //==============
        // Fetch related order Items
        List<Order_Item__c> orderItemList = [
            SELECT Id,Name,	Product__r.Name,Quantity__c,Unit_price__c,Tax_Percent__c,Tax__c,Total_Amount__c,Order__r.Order_Date__c,Order__r.Order_Type__c,
            Order__r.Account__r.Name,Order__r.Owner_Name__c,Order__r.Name,Order__r.Expected_Delivery_Date__c,Order__r.Delivery_To__c,Tax_Amount__c,NET_WEIGHT__c,
            Order__r.PJP_Non_PJP_Order_Type__c,Product__r.Product_Group__c,Product__c,Order__r.Visit__C
            FROM Order_Item__c WHERE Order__r.OwnerId = :recid AND Order__r.Order_Date__c = Today AND Order__r.Status__c != 'Rejected'
        ];
        //NON PJP Order Created without visit
        Set<Id> nonPjpOrderIds = new Set<Id>();


        if (!orderItemList.isEmpty()) {
           
            // Maps for grouping products
            Map<String, OrderWapper> primaryMap   = new Map<String, OrderWapper>();
            Map<String, OrderWapper> secondaryMap = new Map<String, OrderWapper>();
            decimal totalqty = 0;
            for (Order_Item__c orderItem : orderItemList) {
                String productName = orderItem.Product__r.Name;
                String orderType   = orderItem.Order__r.Order_Type__c;
                String pdpOrderType   = orderItem.Order__r.PJP_Non_PJP_Order_Type__c ;
                String category = orderItem.Product__c != null ?  orderItem.Product__r.Product_Group__c : '';
                
                // Decide which map to use
                OrderWapper oItem;
                if (orderType == 'Primary Order') {
                    oItem = primaryMap.containsKey(productName) ? primaryMap.get(productName) : new OrderWapper();
                } else if (orderType == 'Secondary Order') {
                    oItem = secondaryMap.containsKey(productName) ? secondaryMap.get(productName) : new OrderWapper();
                } else {
                    continue; // skip if order type not relevant
                }
                
                // Initialize if new wrapper
                if (oItem.skuName == null) {
                    oItem.skuName        = productName;
                    oItem.category       = category; 
                    oItem.pjpQuantity    = 0;
                    oItem.nonPJPQuantity = 0;
                    oItem.totalQuantity  = 0;
                    oItem.totalAmount    = 0;
                }
                
                // Quantity
                Decimal qty = (orderItem.NET_WEIGHT__c != null ? orderItem.NET_WEIGHT__c : 0);
                //Amount 
                Decimal amt = (orderItem.Total_Amount__c != null ? orderItem.Total_Amount__c : 0);
                
                
                totalqty += qty;
                // Split PDP vs Non-PDP
                if (pdpOrderType == 'PJP Order') {
                    oItem.pjpQuantity += qty;                     
                } else if (pdpOrderType == 'Non PJP Order') {
                    oItem.nonPJPQuantity += qty;
                    
                    //Total Non PJP Summary
                    nonPjpOrderIds.add(orderItem.Order__c); // track unique order
                }
                
                // Always add to total
                oItem.totalQuantity += qty;
                
                // Amount
                oItem.totalAmount += amt;
                
                // Put back in map
                if (orderType == 'Primary Order') {
                    primaryMap.put(productName, oItem);
                } else if (orderType == 'Secondary Order') {
                    secondaryMap.put(productName, oItem);
                }
            }
            totalSoldQuantityforTodayInKgs = totalqty;
            
            decimal totalPrimaryPjpQty = 0;
            decimal totalPrimaryNonPjpQty = 0 ;
            decimal totalPrimaryQty = 0 ;
            decimal totalPrimaryAmt = 0 ;
            decimal totalSecondaryPjpQty= 0;
            decimal totalSecondaryNonPjpQty = 0;
            decimal totalSecondaryQty = 0;
            decimal totalSecondaryAmt = 0;
            
            // Convert maps → lists
            Integer primaryIndex = 1;
            primaryOItemList = new List<OrderWapper>();
            for (OrderWapper ow : primaryMap.values()) {
                ow.index = primaryIndex++;
                primaryOItemList.add(ow);
                totalPrimaryPjpQty += ow.pjpQuantity;
                totalPrimaryNonPjpQty += ow.nonPJPQuantity;
                totalPrimaryQty += ow.totalQuantity;
                totalPrimaryAmt += ow.totalAmount;
            }
            totalPrimaryPjpQuantity = totalPrimaryPjpQty;
            totalPrimaryNonPjpQuantity = totalPrimaryNonPjpQty;
            totalPrimaryQuantity = totalPrimaryQty ;
            totalPrimaryAmount =  totalPrimaryAmt;
            hasPrimaryOrders = !primaryOItemList.isEmpty();
            
            
            Integer secondaryIndex = 1;
            secondaryOItemList = new List<OrderWapper>();
            for (OrderWapper ow : secondaryMap.values()) {
                ow.index = secondaryIndex++;
                secondaryOItemList.add(ow);
                totalSecondaryPjpQty += ow.pjpQuantity;
                totalSecondaryNonPjpQty += ow.nonPJPQuantity;
                totalSecondaryQty += ow.totalQuantity;
                totalSecondaryAmt += ow.totalAmount;
            }
            totalSecondaryPjpQuantity = totalSecondaryPjpQty;
            totalSecondaryNonPjpQuantity = totalSecondaryNonPjpQty;
            totalSecondaryQuantity = totalSecondaryQty ;
            totalSecondaryAmount =  totalSecondaryAmt;
            hasSecondaryOrders = !secondaryOItemList.isEmpty();
        }
        
        decimal nonPJPOrdersSize = !nonPjpOrderIds.isEmpty() ? nonPjpOrderIds.size() : 0;
        totalCalls+= nonPJPOrdersSize;
        productiveCalls+= nonPJPOrdersSize;
        
        //NON-PJP Calls
        nonPJPCalls = nonPJPOrdersSize;
        nonPJPProductiveCalls = nonPJPOrdersSize;

        //==============
        //Order fulfilment Itens
        //==============
        List<Order_Item__c> orderfilmemtItems = [
            SELECT Id,Name,	Product__r.Name,Product__r.Product_Group__c,Product__c,Delivered_Net_Weight__c
            FROM Order_Item__c WHERE Order__r.OwnerId = :recid AND Order__r.Orderfulfilment_Date__c = Today
        ];
        hasorderfulfilments = !orderfilmemtItems.isEmpty();
        if (!orderfilmemtItems.isEmpty()) {
            Map<String, OrderWapper> olderFulfilmentMap   = new Map<String, OrderWapper>();
            decimal orderfulfilmentqty = 0;
            Integer idx = 1;
            for (Order_Item__c orderItem : orderfilmemtItems) {
                String productName = orderItem.Product__r.Name;
                String category = orderItem.Product__c != null ?  orderItem.Product__r.Product_Group__c : '';
                // Decide which map to use
                OrderWapper oItem;
                oItem = olderFulfilmentMap.containsKey(productName) ? olderFulfilmentMap.get(productName) : new OrderWapper();
                // Initialize if new wrapper
                if (oItem.skuName == null) {
                    oItem.skuName        = productName;
                    oItem.category       = category; 
                    oItem.totalQuantity  = 0;
                    oItem.index          = idx++; 
                }
                // Quantity
                Decimal qty = (orderItem.Delivered_Net_Weight__c != null ? orderItem.Delivered_Net_Weight__c : 0);
                oItem.totalQuantity = qty;
                orderfulfilmentqty += qty;
                olderFulfilmentMap.put(productName, oItem);
            }
            totalOrderfulfilmemtQuantity = orderfulfilmentqty;
           
            orderfulfilmentList = new List<OrderWapper>(olderFulfilmentMap.values());
        }
    }
    
    public class OrderWapper
    {
        public Decimal index { get; set; }
        public String skuName { get; set; }
        public String category { get; set; }
        public Decimal pjpQuantity { get; set; }
        public Decimal nonPJPQuantity { get; set; }
        public Decimal totalQuantity { get; set; }
        public Decimal totalAmount { get; set; }
    }
    
    public class CollectionWapper
    {
        public Decimal index { get; set; }
        public String transactionMode { get; set; }
        public Decimal amount { get; set; }
    }
    
}