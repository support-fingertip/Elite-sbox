public without sharing class DMSPortalLwc
{
    //Graph Data
    @AuraEnabled
    public static GraphData getGraphData(){
        
        GraphData dt = new GraphData();
        dt.formattedUsersSales = salesData();
        dt.formattedUsersOrder = orderData();
        dt.graphlist = targetData();
        return dt;
    }
    @AuraEnabled
    public static List<Map<String, String>> salesData() {
        // Aggregate query to sum Grand_Total__c by month for the selected user
        List<AggregateResult> results = [
            SELECT CALENDAR_MONTH(Invoice_Date__c) month,CALENDAR_YEAR(Invoice_Date__c) year, SUM(Grand_Total__c) totalGrandTotal
            FROM Invoice__c WHERE Closed_Date__c = THIS_YEAR AND OwnerId =:UserInfo.getUserId()
            GROUP BY CALENDAR_MONTH(Invoice_Date__c), CALENDAR_YEAR(Invoice_Date__c)
            ORDER BY CALENDAR_YEAR(Invoice_Date__c) ASC, CALENDAR_MONTH(Invoice_Date__c) ASC
        ];
        
        Map<Integer, String> monthNames = new Map<Integer, String>{
            1 => 'JAN', 2 => 'FEB', 3 => 'MAR', 4 => 'APR', 5 => 'MAY', 6 => 'JUN', 
                7 => 'JUL', 8 => 'AUG', 9 => 'SEP', 10 => 'OCT', 11 => 'NOV', 12 => 'DEC'
                };
                    
                    List<Map<String, String>> formattedUsersSales = new List<Map<String, String>>();
        
        for (AggregateResult ar : results) {
            Integer monthNum = (Integer) ar.get('month'); 
            Integer yearNum = (Integer) ar.get('year');    
            Decimal total = (Decimal) ar.get('totalGrandTotal'); 
            
            Map<String, String> dataMap = new Map<String, String>{
                'monthName' => monthNames.get(monthNum) + ' - ' + String.valueOf(yearNum),
                    'totalGrandTotal' => String.valueOf(total)
                    };
                        
                        formattedUsersSales.add(dataMap);
        }
        
        System.debug('dt :' + formattedUsersSales);
        return formattedUsersSales;
    }
    @AuraEnabled
    public static List<Map<String, String>> orderData(){
        
        List<AggregateResult> results = [
            SELECT CALENDAR_MONTH(Order_Date__c) month, 
            CALENDAR_YEAR(Order_Date__c) year, 
            SUM(Grand_Total__c) totalGrandTotal
            FROM Order__c
            WHERE Order_Date__c = THIS_YEAR AND OwnerId =:UserInfo.getUserId()
            GROUP BY CALENDAR_MONTH(Order_Date__c), CALENDAR_YEAR(Order_Date__c)
            ORDER BY CALENDAR_YEAR(Order_Date__c) ASC, CALENDAR_MONTH(Order_Date__c) ASC
        ];
        
        Map<Integer, String> monthNames = new Map<Integer, String>{
            1 => 'JAN', 2 => 'FEB', 3 => 'MAR', 4 => 'APR', 5 => 'MAY', 6 => 'JUN', 
                7 => 'JUL', 8 => 'AUG', 9 => 'SEP', 10 => 'OCT', 11 => 'NOV', 12 => 'DEC'
                };
                    List<Map<String, String>> formattedUsersOrder = new List<Map<String, String>>();
        for (AggregateResult ar : results) {
            Integer monthNum = (Integer) ar.get('month');  
            Integer yearNum = (Integer) ar.get('year');    
            Decimal total = (Decimal) ar.get('totalGrandTotal'); 
            
            Map<String, String> dataMap = new Map<String, String>{
                'monthName' => monthNames.get(monthNum) + ' - ' + String.valueOf(yearNum),
                    'totalGrandTotal' => String.valueOf(total)
                    };
                        
                        formattedUsersOrder.add(dataMap);
        }
        
        return formattedUsersOrder;
    }
    @AuraEnabled
    public static List<kpi_graph_target> targetData() {
        List<Target__c> tarList = [SELECT Id, Name, Achieved_Percentage__c, Executive__c, Executive__r.Name, 
                                   Account__c, Actual__c, Target__c, Period__c, Period__r.Name
                                   FROM Target__c  
                                   WHERE CreatedDate = THIS_MONTH AND OwnerId =:UserInfo.getUserId()
                                   ORDER BY Achieved_Percentage__c DESC NULLS LAST 
                                   LIMIT 5000];
        
        List<kpi_graph_target> graphlist = new List<kpi_graph_target>();
        
        for (Target__c tr : tarList) {
            kpi_graph_target graph = new kpi_graph_target();
            graph.xAxis = tr.Period__r.Name;
            graph.actual = tr.Actual__c;
            graph.target = tr.Target__c;
            graphlist.add(graph);
        }
        
        return graphlist;
    }
    
    //Order Data
    @AuraEnabled
    public static DmsData allOrderData(String status, Date frmDate, Date toDate, String orderType) {
        DmsData dt = new DmsData();
        
        Id accountId;
        List<User> partnerUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()];
        if(partnerUser.size() >0){
            List<Contact> contact = [SELECT AccountId FROM Contact WHERE Id = :partnerUser[0].ContactId LIMIT 1];
            accountId = contact[0].AccountId;
        }
        
        // Build SOQL query for Order__c with Order_Items__r subquery
        String query = 'SELECT Id, Name, Account__c, Account__r.Name, Total_Quantity__c, Grand_Total__c, Order_Date__c, ' +
            '(SELECT Id, Name, Product__c, Product__r.Name, Quantity__c, Total_Amount__c, Tax_Amount__c, Tax_Percent__c, Unit_price__c FROM Order_Items__r) ' +
            'FROM Order__c ' +
            'WHERE Order_Date__c >= :frmDate AND Order_Date__c <= :toDate ' +
            'AND Account__c =: accountId ';
        
        if (status != 'All') {
            query += 'AND Order_Status__c = :status ';
        }
        
        query += 'ORDER BY CreatedDate DESC';
        List<Order__c> ord = Database.query(query);
        System.debug('Raw Orders Count: ' + ord.size());
        System.debug('Raw Orders: ' + ord);
        
        Set<Id> uniqueOrderIds = new Set<Id>();
        List<OrdData> ordDt = new List<OrdData>();
        
        for (Order__c o : ord) {
            if (uniqueOrderIds.contains(o.Id)) {
                System.debug('Duplicate Order Skipped: ' + o.Id + ' - ' + o.Name);
                continue;
            }
            uniqueOrderIds.add(o.Id);
            
            String formattedOrdDate = o.Order_Date__c != null 
                ? DateTime.newInstance(o.Order_Date__c.year(), o.Order_Date__c.month(), o.Order_Date__c.day()).format('dd/MM/yyyy') 
                : '';
            
            OrdData order = new OrdData();
            order.orderId = o.Id;
            order.orderNo = o.Name;
            order.quantity = o.Total_Quantity__c;
            order.orderDate = formattedOrdDate;
            order.amount = o.Grand_Total__c;
            order.customerId = o.Account__c;
            order.customerName = o.Account__r.Name;
            order.tax = 0;
            order.items = new List<Order_Item__c>(); // Use a custom wrapper for items
            
            for (Order_Item__c item : o.Order_Items__r) {
                Order_Item__c oi = new Order_Item__c();
                oi.Id = item.Id;
                oi.Product__c = item.Product__c;
                oi.Product_Name__c = item.Product__r.Name;
                oi.Quantity__c = item.Quantity__c;
                oi.Total_Amount__c = item.Total_Amount__c != null ?  item.Total_Amount__c  :0 ;
                oi.Tax_Amount__c = item.Tax_Amount__c != null ? item.Tax_Amount__c : 0;
                oi.Tax_Percent__c = item.Tax_Percent__c != null ?item.Tax_Percent__c : 0.0 ;  // Added Tax Percent
                oi.Unit_price__c = item.Unit_price__c!= null ?  item.Unit_price__c :0;    // Added Unit Price
                
                order.items.add(oi);
            }
            System.debug('Order ' + o.Name + ' has ' + order.items.size() + ' items: ' + order.items);
            
            ordDt.add(order);
        }
        
        System.debug('Processed Orders Count: ' + ordDt.size());
        System.debug('Processed Orders: ' + ordDt);
        
        dt.TotalOrderData = ordDt;
        dt.statusOptions = getStatusOptions('Order__c', 'Order_Status__c');
        return dt;
    }
    
    //Invoice Data
    @AuraEnabled(cacheable=true)
    public static DmsData allInvoiceData(String status, Date frmDate, Date toDate) {
        DmsData dt = new DmsData();
        List<Invoice__c> inv;
        
        Id accountId;
        List<User> partnerUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()];
        if(partnerUser.size() >0){
            List<Contact> contact = [SELECT AccountId FROM Contact WHERE Id = :partnerUser[0].ContactId LIMIT 1];
            accountId = contact[0].AccountId;
        }
        system.debug('frmDate '+frmDate+' toDate '+toDate);
        system.debug('statusstatus '+status);
        system.debug('accountIdaccountId '+accountId);
        List<Invoice__c> invList = [SELECT Id, Name, Store__c, Invoice_Date__c, isDisabled__c, Status__c, Total_Amount__c, Store__r.Name,
                                    Total_Quantity__c, Grand_Total__c, Total_Tax_Amount__c,Pending_Amount__c
                                    FROM Invoice__c];
        system.debug('invlItsinvlist '+invList);
        if (status == 'All') {
            inv = [
                SELECT Id, Name, Store__c, Invoice_Date__c, isDisabled__c, Status__c, Total_Amount__c, Store__r.Name,
                Total_Quantity__c, Grand_Total__c, Total_Tax_Amount__c,Pending_Amount__c,GRN_Status__c
                FROM Invoice__c
                where Store__c =: accountId
                AND Invoice_Date__c >= :frmDate
                AND Invoice_Date__c <= :toDate
                ORDER BY Invoice_Date__c DESC
            ];
        } else if(status == 'GRN Pending'){
            inv = [
                SELECT Id, Name, Store__c, Invoice_Date__c, isDisabled__c, Status__c, Total_Amount__c, Store__r.Name,
                Total_Quantity__c, Grand_Total__c, Total_Tax_Amount__c, Pending_Amount__c,GRN_Status__c
                FROM Invoice__c
                WHERE (GRN_Status__c = 'GRN Pending' OR GRN_Status__c ='')
                AND Invoice_Date__c >= :frmDate
                AND Invoice_Date__c <= :toDate
                AND Store__c =: accountId
                ORDER BY Invoice_Date__c DESC
            ];
        }else if(status =='GRN Completed'){
            inv = [
                SELECT Id, Name, Store__c, Invoice_Date__c, isDisabled__c, Status__c, Total_Amount__c, Store__r.Name,
                Total_Quantity__c, Grand_Total__c, Total_Tax_Amount__c, Pending_Amount__c,GRN_Status__c
                FROM Invoice__c
                WHERE (GRN_Status__c = 'GRN Completed')
                AND Invoice_Date__c >= :frmDate
                AND Invoice_Date__c <= :toDate
                AND Store__c =: accountId
                ORDER BY Invoice_Date__c DESC
            ];
        }
        
        List<InvData> invDt = new List<InvData>();
        for (Invoice__c i : inv) {
            String formattedDate = i.Invoice_Date__c != null
                ? DateTime.newInstance(i.Invoice_Date__c.year(), i.Invoice_Date__c.month(), i.Invoice_Date__c.day()).format('dd/MM/yyyy')
                : '';
            InvData inD = new InvData();
            inD.name = i.Name;
            inD.InvId = i.Id;
            inD.isDisabled = i.isDisabled__c;
            inD.InvDate = formattedDate;
            inD.accId = i.Store__c;
            inD.accName = i.Store__r != null ? i.Store__r.Name : '';
            inD.Amount = i.Grand_Total__c !=null ?i.Grand_Total__c : 0  ;
            inD.Status = i.Status__c;
            inD.tax = i.Total_Tax_Amount__c != null ?  i.Total_Tax_Amount__c : 0;
            inD.TotalQuantity = i.Total_Quantity__c != null ? i.Total_Quantity__c :0 ; 
            invDt.add(inD);
        }
        dt.TotalInvoiceData = invDt;
        dt.statusOptions = getStatusOptions('Invoice__c', 'GRN_Status__c');
        return dt;
    }
    public class Invoice_Item_Data {
        @AuraEnabled public Id Id;
        @AuraEnabled public String ItemName;
        @AuraEnabled public Decimal Quantity;
        @AuraEnabled public Decimal TaxAmount;
        @AuraEnabled public Decimal TotalAmount;
        @AuraEnabled public Decimal unitPrice;
    }   
    @AuraEnabled(cacheable=true)
    public static List<Invoice_Item_Data> getInvoiceItems(String invoiceId) {
        if (String.isBlank(invoiceId)) {
            return new List<Invoice_Item_Data>();
        }
        
        List<Invoice_Item__c> invItems = [
            SELECT Id, Product__r.Name, SKU__r.Name,Quantity__c,GST_Amount__c, Tax_Amount__c, Bill_Amount__c,Price_per_unit__c
            FROM Invoice_Item__c
            WHERE Invoice__c = :invoiceId
            ORDER BY Product__r.Name
        ];
        
        List<Invoice_Item_Data> itemDataList = new List<Invoice_Item_Data>();
        for (Invoice_Item__c item : invItems) {
            Invoice_Item_Data data = new Invoice_Item_Data();
            data.Id = item.Id;
            data.ItemName = item.SKU__r != null ? item.SKU__r.Name : '';
            data.Quantity = item.Quantity__c;
            data.TaxAmount = item.GST_Amount__c;
            data.TotalAmount = item.Bill_Amount__c ;
            data.unitPrice = item.Price_per_unit__c ;
            itemDataList.add(data);
        }
        return itemDataList;
    }
    
    //Primary Return Data
    @AuraEnabled
    public static DmsData allPrimaryReturnsData(Date frmDate, date toDate){
        DmsData dt = new DmsData();
        list<Primary_Return_Item__c> primaryRetunItems= [select Id,Name,Product__c,Product__r.Name,Primary_Return__r.Name,Primary_Return__c,
                                                         Date__c,Quantity__c,Primary_Return__r.Date__c from  Primary_Return_Item__c WHERE
                                                         Primary_Return__r.Date__c >= :frmDate AND  Primary_Return__r.Date__c <= :toDate ];
        
        
        
        List<PReturnData> PReturnDataList = new List<PReturnData>();
        for(Primary_Return_Item__c i:primaryRetunItems){
            date returnDate = i.Primary_Return__r.Date__c;
            String formattedOrdDate = returnDate != null ? DateTime.newInstance(returnDate.year(), returnDate.month(), returnDate.day()).format('dd/MM/yyyy') : '';
            PReturnData pRData = new PReturnData();
            pRData.productName = i.Product__r.Name;
            pRData.returnItemNo = i.Name;
            pRData.productId = i.Product__c;
            pRData.returnDate = formattedOrdDate;
            pRData.primaryReturnNo =i.Primary_Return__r.Name;
            pRData.primaryReturnId = i.Primary_Return__c ;
            pRData.quantity =  i.Quantity__c ;
            PReturnDataList.add(pRData);
        }
        dt.TotalPrimaryReturnDataData = PReturnDataList;
        return dt;
    }
    
    //newly added
    @AuraEnabled
    public static List<PrimaryReturnWrapper> getPrimaryReturns(Date frmDate, Date toDate) {
        Id accountId;
        List<User> partnerUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()];
        if(partnerUser.size() >0){
            List<Contact> contact = [SELECT AccountId FROM Contact WHERE Id = :partnerUser[0].ContactId LIMIT 1];
            accountId = contact[0].AccountId;
        }
        
        List<PrimaryReturnWrapper> results = new List<PrimaryReturnWrapper>();
        List<Return__c> returns = [
            SELECT Id, Name, Total_Quantity__c, Total_Amount__c, Return_Date__c
            FROM Return__c
            WHERE Return_Date__c >= :frmDate AND Return_Date__c <= :toDate and Customer__c =: accountId
            ORDER BY CreatedDate DESC
        ];
        
        for (Return__c ret : returns) {
            PrimaryReturnWrapper w = new PrimaryReturnWrapper();
            w.primaryReturnId = ret.Id;
            w.primaryReturnNo = ret.Name;
            w.totalQuantity = ret.Total_Quantity__c;
            w.totalAmount = ret.Total_Amount__c;
            w.returnDate = ret.Return_Date__c != null ? ret.Return_Date__c.format() : '';
            results.add(w);
        }
        return results;
    }
    
    // Fetch Primary Return Items by Primary Return Id
    @AuraEnabled
    public static List<Return_Item__c> getPrimaryReturnItems(Id primaryReturnId) {
        return [
            SELECT Id, SKU__r.Name, Unit_Price__c, Quantity__c, Reason_For_Return__c,Total_Amount__c
            FROM Return_Item__c
            WHERE Return__c = :primaryReturnId
        ];
    }
    
    // Wrapper for Primary Return Header
    public class PrimaryReturnWrapper {
        @AuraEnabled public Id primaryReturnId;
        @AuraEnabled public String primaryReturnNo;
        @AuraEnabled public Decimal totalQuantity;
        @AuraEnabled public Decimal totalAmount;
        @AuraEnabled public String returnDate;
    }
    
    @AuraEnabled
    public static DmsData allPaymentReceiptData(Date frmDate, Date toDate) {
        DmsData dt = new DmsData();
        Id accountId;
        List<User> partnerUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()];
        if(partnerUser.size() >0){
            List<Contact> contact = [SELECT AccountId FROM Contact WHERE Id = :partnerUser[0].ContactId LIMIT 1];
            accountId = contact[0].AccountId;
        }
        List<Collection_Item__c> paymentReceiptItems = [
            SELECT Id, Name, Invoice_Number__c, Collection__r.Name, 
            Collection__c, Amount_Received__c, Collection__r.Date__c
            FROM Collection_Item__c 
            WHERE Collection__r.Date__c >= :frmDate 
            AND Collection__r.Date__c <= :toDate and Collection__r.Customer__c =:accountId 
            ORDER BY CreatedDate DESC
        ];
        
        // Map to collect totals per Payment Receipt
        Map<Id, PaymentData> receiptMap = new Map<Id, PaymentData>();
        
        for (Collection_Item__c item : paymentReceiptItems) {
            Id receiptId = item.Collection__c;
            
            if (!receiptMap.containsKey(receiptId)) {
                Date paymentDate = item.Collection__r.Date__c;
                String formattedDate = paymentDate != null
                    ? DateTime.newInstance(paymentDate.year(), paymentDate.month(), paymentDate.day()).format('dd/MM/yyyy')
                    : '';
                
                PaymentData paymentData = new PaymentData();
                paymentData.paymenetId = receiptId;
                paymentData.paymenetNo = item.Collection__r.Name;
                paymentData.paymentDate = formattedDate;
                paymentData.Amount = 0;
                
                receiptMap.put(receiptId, paymentData);
            }
            
            // Add this item's amount to the total
            PaymentData existing = receiptMap.get(receiptId);
            existing.Amount += item.Amount_Received__c != null ? item.Amount_Received__c : 0;
        }
        
        dt.TotalPaymentData = receiptMap.values();
        return dt;
    }
    
    @AuraEnabled(cacheable=true)
    public static Collection_Item__c getPaymentReceiptDetails(Id receiptId) {
        return [
            SELECT Id, Name, Collection__r.Date__c, Amount_Received__c,Invoice_Number__c
            FROM Collection_Item__c
            WHERE Collection__c = :receiptId
            LIMIT 1
        ];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Collection_Item__c> getReceiptItems(Id receiptId) {
        return [
            SELECT Id, Name, Collection__r.Date__c, Amount_Received__c,Invoice_Number__c
            FROM Collection_Item__c
            WHERE Collection__c = :receiptId
        ];
    }
    
    //GRN Data
    @AuraEnabled
    public static DmsData allGRNData(Date frmDate, date toDate){
        DmsData dt = new DmsData();
        list<Goods_Received_Note_Item__c> GRNItems= [select Id,Name,Invoice_Item__c,Invoice_Item__r.Name,Goods_Received_Note__r.Name,
                                                     Goods_Received_Note__c,Received_Quantity__c,Invoiced_Quantity__c,Product__c,
                                                     Product__r.Name,Goods_Received_Note__r.Invoice__c,Goods_Received_Note__r.Invoice__r.Name,
                                                     Goods_Received_Note__r.GRN_Date__c  from  Goods_Received_Note_Item__c WHERE
                                                     Goods_Received_Note__r.GRN_Date__c >= :frmDate AND Goods_Received_Note__r.GRN_Date__c <= :toDate ];
        
        
        
        List<GRNData> GRNDataList = new List<GRNData>();
        for(Goods_Received_Note_Item__c i:GRNItems){
            date Dateval = i.Goods_Received_Note__r.GRN_Date__c;
            String formattedOrdDate = Dateval != null ? DateTime.newInstance(Dateval.year(),Dateval.month(),Dateval.day()).format('dd/MM/yyyy') : '';
            GRNData grnData = new GRNData();
            grnData.GRNItemName = i.Name;
            grnData.GRNItemId = i.Id;
            grnData.productName = i.Product__r.Name;
            grnData.productId = i.Product__c;
            grnData.invoiceItemNo = i.Invoice_Item__r.Name;
            grnData.invoiceItemId = i.Invoice_Item__c;
            grnData.invoiceNo = i.Goods_Received_Note__r.Invoice__r.Name;
            grnData.invoiceId =i.Goods_Received_Note__r.Invoice__c;
            grnData.GRNDate = formattedOrdDate;
            grnData.invoicedQuantity = i.Invoiced_Quantity__c ;
            grnData.receivedQuantity = i.Received_Quantity__c ;
            grnData.GRNName = i.Goods_Received_Note__r.Name ;
            grnData.GRNId = i.Goods_Received_Note__c ;
            GRNDataList.add(grnData);
        }
        dt.TotalGRNData = GRNDataList;
        return dt;
    }
    
    // newly added GRN
    @AuraEnabled(cacheable=true)
    public static List<Goods_Received_Note_Item__c> getGRNItems(Id grnId) {
        return [
            SELECT Id, Name, Invoice_Item__c, Invoice_Item__r.Name, Invoiced_Quantity__c, Product__c, Product__r.Name,
            Received_Nonsaleable_Quantity__c,Received_Saleable_Quantity__c FROM Goods_Received_Note_Item__c
            WHERE Goods_Received_Note__c = :grnId
            ORDER BY Name
        ];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Goods_Received_Note__c> getGRNList(Date frmDate, Date toDate) {
        return [
            SELECT Id, Name, Invoice__c, Invoice__r.Name, GRN_Date__c
            FROM Goods_Received_Note__c
            WHERE GRN_Date__c >= :frmDate
            AND GRN_Date__c <= :toDate
            ORDER BY Name DESC
        ];
    }
    
    
    //Claim Data
    @AuraEnabled
    public static DmsData allClaimData(Date frmDate, date toDate,string status){
        DmsData dt = new DmsData();
        List<Claim__c> claims = new List<Claim__c>();
        String query = 'SELECT Id, Name, Claim_Amount__c, Claim_Date__c, Customer__c, Customer__r.Name, Description__c, Status__c ' +
            'FROM Claim__c WHERE Claim_Date__c >= :frmDate AND Claim_Date__c <= :toDate ORDER BY Name DESC';
        
        if ( status != 'All' && status != '' && status != null) {
            query += ' AND Status__c = :status';
        }
        
        claims = Database.query(query);
        
        List<ClaimData> ClaimDataList = new List<ClaimData>();
        for(Claim__c i:claims){
            date Dateval = i.Claim_Date__c;
            String formattedOrdDate = Dateval != null ? DateTime.newInstance(Dateval.year(),Dateval.month(),Dateval.day()).format('dd/MM/yyyy') : '';
            ClaimData claimData = new ClaimData();
            claimData.claimName = i.Name;
            claimData.claimId = i.Id;
            claimData.customerName = i.Customer__r.Name;
            claimData.customerId = i.Customer__c;
            claimData.description = i.Description__c;
            claimData.claimDate = formattedOrdDate;
            claimData.claimAmount = i.Claim_Amount__c;
            claimData.status = i.Status__c;
            ClaimDataList.add(claimData);
        }
        dt.totalClaimData = ClaimDataList;
        dt.statusOptions = getStatusOptions('Claim__c', 'Status__c');
        return dt;
    }
    //Distributor Stock 
    @AuraEnabled
    public static DmsData allDistributorStockData(String productCategory) {
        DmsData dt = new DmsData();
        Id accountId;
        
        // Step 1: Find the Account Id of the current partner user
        List<User> partnerUser = [
            SELECT ContactId 
            FROM User 
            WHERE Id = :UserInfo.getUserId()
        ];
        if (partnerUser.size() > 0) {
            List<Contact> contact = [
                SELECT AccountId 
                FROM Contact 
                WHERE Id = :partnerUser[0].ContactId 
                LIMIT 1
            ];
            accountId = contact[0].AccountId;
        }
        
        // Step 2: Get all stock records for that distributor
        List<Distributor_Stock__c> allStockList = [
            SELECT Id, Name,Secondary_Invoice_Quantity__c,Primary_Return_Quantity__c,Secondary_Return_Quantity__c,
            Distributor__r.Name, Distributor__c, GRN_Quantity__c,Product__c, Product__r.Name,Available_Quantity__c,
            Product_Name__c FROM Distributor_Stock__c WHERE Distributor__c = :accountId
        ];
        
        // Step 3: Keep only the latest record per Product__c
        Map<String, Distributor_Stock__c> latestStockMap = new Map<String, Distributor_Stock__c>();
        for (Distributor_Stock__c stock : allStockList) {
            if (!latestStockMap.containsKey(stock.Product_Name__c)) {
                latestStockMap.put(stock.Product_Name__c, stock);
            }
        }
        
        // Step 4: Build response list
        List<DistributorStock> distributorStockDataList = new List<DistributorStock>();
        for (Distributor_Stock__c i : latestStockMap.values()) {
            DistributorStock stockData = new DistributorStock();
            stockData.stockName = i.Name;
            stockData.stockId = i.Id;
            stockData.customerName = i.Distributor__r.Name;
            stockData.customerId = i.Distributor__c;
            stockData.productName = i.Product__r.Name;
            stockData.productId = i.Product__c;
            stockData.GRNQuantity = i.GRN_Quantity__c;
            stockData.secoundryInvoiceQty = i.Secondary_Invoice_Quantity__c;
            stockData.primaryReturnQty = i.Primary_Return_Quantity__c;
            stockData.secoundaryReturnQty = i.Secondary_Return_Quantity__c;
            stockData.availableQuantity = i.Available_Quantity__c;
            distributorStockDataList.add(stockData);
        }
        
        dt.totalDistributorStockData = distributorStockDataList;
        return dt;
    }
    
    //Credit Notes
    @AuraEnabled
    public static DmsData allCreditNoteData(Date frmDate, date toDate,string status){
        DmsData dt = new DmsData();
        List<Credit_Note__c> creditNotesList = new List<Credit_Note__c>();
        String query = 'SELECT Id, Name,Claim__c,Claim__r.Name,	Credit_Date__c,Customer__c,Customer__r.Name,Status__c,'+
            'Primary_Return__c,Primary_Return__r.Name,Total_Credit_Amount__c '+
            'FROM Credit_Note__c WHERE Credit_Date__c >= :frmDate AND Credit_Date__c <= :toDate ';
        if (status != 'All' && status != '' && status != null) {
            query += ' AND Status__c = :status';
        }
        
        creditNotesList = Database.query(query);
        List<CreditNote> CreditNoteDataList = new List<CreditNote>();
        for(Credit_Note__c i:creditNotesList){
            date Dateval = i.Credit_Date__c;
            String formattedDate = Dateval != null ? DateTime.newInstance(Dateval.year(),Dateval.month(),Dateval.day()).format('dd/MM/yyyy') : '';
            CreditNote creditNote = new CreditNote();
            creditNote.creditNoteNo = i.Name;
            creditNote.creditNoteId = i.Id;
            creditNote.customerName = i.Customer__r.Name;
            creditNote.customerId = i.Customer__c;
            creditNote.claimNo = i.Claim__r.Name;
            creditNote.claimId = i.Claim__c;
            creditNote.primaryReturnNo = i.Primary_Return__c;
            creditNote.primaryReturnId = i.Primary_Return__r.Name;
            creditNote.creditDate =formattedDate;
            creditNote.status = i.Status__c;
            creditNote.creditAmount = i.Total_Credit_Amount__c;
            CreditNoteDataList.add(creditNote);
        }
        dt.totalCreditNoteData = CreditNoteDataList;
        dt.statusOptions = getStatusOptions('Credit_Note__c', 'Status__c');
        return dt;
    }
    
    //Secoundary Invoices
    @AuraEnabled
    public static DmsData allSecoundaryInvoiceData(String status,Date frmDate, date toDate){
        system.debug('status---'+status);
        DmsData dt = new DmsData();
        Id accountId;
        List<User> partnerUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()];
        if(partnerUser.size() >0){
            List<Contact> contact = [SELECT AccountId FROM Contact WHERE Id = :partnerUser[0].ContactId LIMIT 1];
            accountId = contact[0].AccountId;
        }
        List<Secondary_Invoice__c> inv = new List<Secondary_Invoice__c>();
        if (status == 'All' || status =='' || status == null) {
            inv = [
                SELECT Id, Name, Store__c, Invoice_Date__c, Status__c, Store__r.Name,Total_Quantity__c,Grand_Total__c,
                Total_Tax__c
                FROM Secondary_Invoice__c WHERE Invoice_Date__c >= :frmDate  AND Invoice_Date__c <= :toDate AND Store__c =: accountId ORDER BY Name DESC
            ];
        }
        else {
            inv = [
                SELECT Id, Name, Store__c, Invoice_Date__c, Status__c,Store__r.Name,Total_Quantity__c,Grand_Total__c,
                Total_Tax__c FROM Secondary_Invoice__c WHERE  Status__c = :status  AND Invoice_Date__c >= :frmDate 
                AND Invoice_Date__c <= :toDate
                AND Store__c =: accountId
                ORDER BY Name DESC
            ];
        }
        
        
        
        List<SecInvData> invDt = new List<SecInvData>();
        for(Secondary_Invoice__c i:inv){
            String formattedOrdDate = i.Invoice_Date__c != null ? DateTime.newInstance(i.Invoice_Date__c.year(), i.Invoice_Date__c.month(), i.Invoice_Date__c.day()).format('dd/MM/yyyy') : '';
            SecInvData inD = new SecInvData();
            inD.name = i.Name;
            inD.InvId = i.Id;
            inD.InvDate = formattedOrdDate;
            inD.accId = i.Store__c ;
            inD.accName =  i.Store__r.Name ;
            inD.Amount = i.Grand_Total__c;
            inD.Status = i.Status__c;
            inD.tax = i.Total_Tax__c;
            inD.Quantity = i.Total_Quantity__c;
            invDt.add(inD);
        }
        dt.totalSecoundaryInvoiceData = invDt;
        dt.statusOptions = getStatusOptions('Secondary_Invoice__c', 'Status__c');
        return dt;
    }
    @AuraEnabled
    public static List<Secondary_Invoice_Item__c> getSecondaryInvoiceItems(Id invoiceId) {
        return [
            SELECT Product__r.Name, Quantity__c, Tax_Amount__c, Unit_Price__c, Total_Amount__c,Tax_Percent__c,Store__r.Name
            FROM Secondary_Invoice_Item__c
            WHERE Secondary_Invoice__c = :invoiceId
            ORDER BY Name DESC
        ];
    }
    
    
    //Secoundary Return Data
    @AuraEnabled
    public static DmsData allSecoundaryReturnsData(Date frmDate, Date toDate){
        DmsData dt = new DmsData();
        Id accountId;
        List<User> partnerUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()];
        if(partnerUser.size() >0){
            List<Contact> contact = [SELECT AccountId FROM Contact WHERE Id = :partnerUser[0].ContactId LIMIT 1];
            accountId = contact[0].AccountId;
        }
        // Fetch Secondary Returns with customer and amount, ordered by return date in descending order
        List<Return__c> secondaryReturns = [
            SELECT Id, Name, Total_Quantity__c,Customer__r.Name, Total_Amount__c, Return_Date__c
            FROM Return__c 
            WHERE Return_Date__c >= :frmDate 
            AND Return_Date__c <= :toDate
            AND Distributor__c =: accountId And Customer_Type__c = 'Secondary Customer'
            ORDER BY Name DESC
        ];
        
        // Remove duplicates (based on Secondary Return ID)
        Map<Id, Return__c> uniqueReturnsMap = new Map<Id, Return__c>();
        for (Return__c sr : secondaryReturns) {
            uniqueReturnsMap.put(sr.Id, sr);  // Store unique records in the map using ID as the key
        }
        
        // Create a list to hold the unique records
        List<SReturnData> SReturnDataList = new List<SReturnData>();
        for (Return__c sr : uniqueReturnsMap.values()) {
            SReturnData sRData = new SReturnData();
            
            // Format the return date
            Date returnDate = sr.Return_Date__c;
            String formattedOrdDate = returnDate != null ? DateTime.newInstance(returnDate.year(), returnDate.month(), returnDate.day()).format('dd/MM/yyyy') : '';
            
            // Map values from the Secondary Return to SReturnData
            sRData.secoundaryReturnNo = sr.Name;
            sRData.secoundaryReturnId = sr.Id;
            sRData.totalAmount = sr.Total_Amount__c != null ? sr.Total_Amount__c : 0;
            sRData.quantity = sr.Total_Quantity__c != null ? sr.Total_Quantity__c : 0;
            sRData.returnDate = formattedOrdDate;
            
            // Map customer name
            sRData.secondaryCustomer = sr.Customer__r != null ? sr.Customer__r.Name : '';
            
            // Add the mapped data to the list
            SReturnDataList.add(sRData);
        }
        
        dt.totalSecoundaryReturnData = SReturnDataList;
        return dt;
    }
    
    @AuraEnabled
    public static List<Return_Item__c> getSecondaryReturnItems(Id secondaryReturnId) {
        system.debug(secondaryReturnId);
        return [
            SELECT Id, SKU__r.Name, UOM__c,unit_price__c, Quantity__c, Reason_For_Return__c,Total_Amount__c
            FROM Return_Item__c
            WHERE Return__c = :secondaryReturnId
        ];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Secondary_Retrun__c> getSecondaryReturnItemList(Date frmDate, Date toDate) {
        return [
            SELECT Id,Name,Total_Amount__c,Total_Quantity__c,Secondary_Return_Date__c,Secondary_Customer__r.Name
            FROM Secondary_Retrun__c
            WHERE Secondary_Return_Date__c >= :frmDate
            AND Secondary_Return_Date__c <= :toDate
            ORDER BY Secondary_Return_Date__c DESC
        ];
    }
    
    //Get GRN Data
    @AuraEnabled
    public static list<Invoice_item__c> getGRNData(String invoiceId){
        list<Invoice_item__c> invoiceItems = [select Id,Name,Quantity__c,Product__c,Product__r.Name
                                              from Invoice_item__c where Invoice__c=:invoiceId];
        return invoiceItems;
    }
    
    //Get picklist values
    public static List<Map<String, String>> getStatusOptions(String objectName, String fieldName) {
        List<Map<String, String>> statusOptions = new List<Map<String, String>>();
        
        // Add "All" option
        Map<String, String> allOption = new Map<String, String>();
        allOption.put('label', 'All');
        allOption.put('value', 'All');
        statusOptions.add(allOption);
        
        // Get picklist values dynamically
        List<String> picklistValues = getPicklistValues(objectName, fieldName);
        
        for (String value : picklistValues) {
            Map<String, String> option = new Map<String, String>();
            option.put('label', value);
            option.put('value', value);
            statusOptions.add(option);
        }
        
        return statusOptions;
    }
    public static List<String> getPicklistValues(String objectName, String fieldName) {
        List<String> picklistValues = new List<String>();
        
        // Describe the object
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        
        // Describe the field
        Schema.DescribeFieldResult fieldDescribe = objDescribe.fields.getMap().get(fieldName).getDescribe();
        
        // Get picklist values
        for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
            picklistValues.add(entry.getLabel());
        }
        return picklistValues;
    }
    
    @AuraEnabled
    public static Id createPaymentWithItems(List<Payment_Receipt_Item__c> selectedinvoicesList, Decimal totalAmount) {
        
        system.debug('selectedinvoicesList'+ selectedinvoicesList);
        // 1. Create Payment Receipt
        Payment_Receipt__c receipt = new Payment_Receipt__c(
            Total_Amount__c = totalAmount,
            Payment_Date__c = Date.today()
        );
        insert receipt;
        
        List<Invoice__c> invoicesToUpdate = new List<Invoice__c>();
        // 2. Create Payment Receipt Items
        List<Payment_Receipt_Item__c> itemList = new List<Payment_Receipt_Item__c>();
        for (Payment_Receipt_Item__c inv : selectedinvoicesList) {
            inv.Payment_Receipt__c = receipt.Id;
            invoicesToUpdate.add(new Invoice__c(
                Id = inv.Invoice__c,
                Status__c = 'Paid'
            ));
        }
        
        
        insert selectedinvoicesList;
        update invoicesToUpdate;
        
        return receipt.Id;
        
    }
    
    
    @AuraEnabled
    public static Id createGRN(Id invoiceId, List<Goods_Received_Note_Item__c> items) {
        
        Id accountId;
        List<User> partnerUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()];
        if(partnerUser.size() >0){
            List<Contact> contact = [SELECT AccountId FROM Contact WHERE Id = :partnerUser[0].ContactId LIMIT 1];
            accountId = contact[0].AccountId;
        }
        system.debug(items);
        if (invoiceId == null || items == null || items.isEmpty()) {
            throw new AuraHandledException('Invoice and item list must be provided.');
        }
        
        // Step 1: Create GRN parent record
        Goods_Received_Note__c grn = new Goods_Received_Note__c(Invoice__c = invoiceId,	GRN_Date__c = System.today());
        insert grn;
        
        invoice__c inv =  new invoice__c();
        inv.Id = invoiceId;
        inv.GRN_Status__c = 'GRN Completed';
        update inv;
        
        
        
        // Step 3: Create a set of keys for existing stocks (accountId_productId)
        Set<String> keySet = new Set<String>();
        for (Goods_Received_Note_Item__c item : items) {
            String key = accountId + '_' + item.SKU_Name__c;
            keySet.add(key);
        }
        
        // Step 4: Query existing stock records using formula field
        Map<String, Distributor_Stock__c> existingStockMap = new Map<String, Distributor_Stock__c>();
        for (Distributor_Stock__c stock : [
            SELECT Id, Product__c, Distributor__c, DistributorWithProduct__c
            FROM Distributor_Stock__c
            WHERE DistributorWithProduct__c IN :keySet
        ]) {
            existingStockMap.put(stock.DistributorWithProduct__c, stock);
        }
        
        // Step 5: Create new stock records where necessary
        List<Distributor_Stock__c> newStocks = new List<Distributor_Stock__c>();
        for (Goods_Received_Note_Item__c item : items) {
            item.Goods_Received_Note__c = grn.Id;
            
            String key = accountId + '_' + item.SKU_Name__c;
            if (existingStockMap.containsKey(key)) { 
                item.Distributor_Stock__c = existingStockMap.get(key).Id;
            } else {
                Distributor_Stock__c newStock = new Distributor_Stock__c(
                    Product__c = item.Product__c,
                    Distributor__c = accountId 
                );
                newStocks.add(newStock);
                existingStockMap.put(key, newStock); // Store for later use
            }
        }
        
        if (!newStocks.isEmpty()) {
            insert newStocks;
            for (Distributor_Stock__c stock : newStocks) {
                String key = stock.Distributor__c + '_' + stock.Product_Name__c;
                existingStockMap.put(key, stock);
            }
            
            for (Goods_Received_Note_Item__c item : items) {
                String key = accountId + '_' + item.SKU_Name__c;
                item.Distributor_Stock__c = existingStockMap.get(key).Id;
            }
        }
        
        // Step 6: Insert GRN items
        insert items;
        
        // Step 7: Return GRN ID
        return grn.Id;
    }
    
    // Optional: fetch invoices and their line items for LWC display
    @AuraEnabled(cacheable=true)
    public static List<Invoice__c> getInvoicesByIds(List<Id> invoiceIds) {
        if (invoiceIds == null || invoiceIds.isEmpty()) {
            return new List<Invoice__c>();
        }
        
        return [
            SELECT Id, Name, Invoice_No__c, Store__r.Name,
            (SELECT Id, Name, Quantity__c, SKU__r.Name, SKU__c FROM Invoice_line_items__r where Pending_Quantity__c > 0)
            FROM Invoice__c
            WHERE Id IN :invoiceIds
        ];
    }
    
    @AuraEnabled
    public static Id savePrimaryReturn(List<Primary_Return_Item__c> items,Decimal TotalAmount,Decimal TotalQuantity) {
        system.debug(items);
        if (items == null || items.isEmpty()) {
            throw new AuraHandledException('item list must be provided.');
        }
        
        // Step 1: Create Primary Return parent record
        Primary_Return__c primaryReturn = new Primary_Return__c(Date__c = System.today(),Total_Amount__c=TotalAmount,Total_Quantity__c=TotalQuantity);
        insert primaryReturn;
        
        // Step 2: Get current user's Contact and Account
        User currentUser = [SELECT Contact_Id__c FROM User WHERE Id = :UserInfo.getUserId()];
        if (currentUser.Contact_Id__c == null) {
            throw new AuraHandledException('User is not linked to any Contact.');
        }
        
        Contact con = [SELECT AccountId FROM Contact WHERE Id = :currentUser.Contact_Id__c];
        if (con.AccountId == null) {
            throw new AuraHandledException('Contact is not linked to any Account.');
        }
        
        Id accountId = con.AccountId;
        
        // Step 3: Create a set of keys for existing stocks (accountId_productId)
        Set<String> keySet = new Set<String>();
        for (Primary_Return_Item__c item : items) {
            String key = accountId + '_' + item.Product__c;
            keySet.add(key);
        }
        
        // Step 4: Query existing stock records using formula field
        Map<String, Distributor_Stock__c> existingStockMap = new Map<String, Distributor_Stock__c>();
        for (Distributor_Stock__c stock : [
            SELECT Id, Product__c, Distributor__c, DistributorWithProduct__c
            FROM Distributor_Stock__c
            WHERE DistributorWithProduct__c IN :keySet
        ]) {
            existingStockMap.put(stock.DistributorWithProduct__c, stock);
        }
        
        // Step 5: Create new stock records where necessary
        List<Distributor_Stock__c> newStocks = new List<Distributor_Stock__c>();
        for (Primary_Return_Item__c item : items) {
            item.Primary_Return__c = primaryReturn.Id;
            
            String key = accountId + '_' + item.Product__c;
            if (existingStockMap.containsKey(key)) {
                item.Distributor_Stock__c = existingStockMap.get(key).Id;
            } else {
                Distributor_Stock__c newStock = new Distributor_Stock__c(
                    Product__c = item.Product__c,
                    Distributor__c = accountId
                );
                newStocks.add(newStock);
                existingStockMap.put(key, newStock); // Store for later use
            }
        }
        
        if (!newStocks.isEmpty()) {
            insert newStocks;
            for (Distributor_Stock__c stock : newStocks) {
                String key = stock.Distributor__c + '_' + stock.Product__c;
                existingStockMap.put(key, stock);
            }
            
            for (Primary_Return_Item__c item : items) {
                String key = accountId + '_' + item.Product__c;
                item.Distributor_Stock__c = existingStockMap.get(key).Id;
            }
        }
        
        // Step 6: Insert Primary Return items
        insert items;
        
        // Step 7: Return Primary Return ID
        return primaryReturn.Id;
    }
    
    // Fetch all products for search
    @AuraEnabled(cacheable=true)
    public static secondaryReturnData getAllProducts() {
        secondaryReturnData dt = new secondaryReturnData();
        Id accountId;
        List<User> partnerUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()];
        if(partnerUser.size() >0){
            List<Contact> contact = [SELECT AccountId FROM Contact WHERE Id = :partnerUser[0].ContactId LIMIT 1];
            accountId = contact[0].AccountId;
        }
        
        Set<String> channelSet = new Set<String>();
        List<Product_Mapping__c> prodMappingsFromPrimary = [SELECT Chanel__c, Customer__c 
                                                            FROM Product_Mapping__c  where Customer__c = :accountId];
        // Populate channelSet and primaryCustomerIds
        for(Product_Mapping__c prodMap : prodMappingsFromPrimary) {
            if (prodMap.Chanel__c != null) {
                channelSet.add(prodMap.Chanel__c);
            }
        }
        List<Product__c> products = new List<Product__c>();
        if (!channelSet.isEmpty()) {
            Set<String> productIds = new Set<String>();
            List<Sales_Channel_To_SKU__c> channels = [SELECT Id, Name, SKU__r.Name,SKU__c,Delivery_Plant__c,Sales_Channel__c
                                                      FROM Sales_Channel_To_SKU__c WHERE Sales_Channel__c IN :channelSet
                                                      and SKU__r.Is_Active__c = true];
            map<String,String> skuNameToSkuId = new map<String,String>();
            for (Sales_Channel_To_SKU__c channel : channels) {
                productIds.add(channel.SKU__r.Name);
                skuNameToSkuId.put(channel.SKU__r.Name,channel.SKU__c);
            }
            
            
            dt.productsList = [
                SELECT Id, Name, Channel__c, Product_Category_Name__c, Product_Category1__c,
                Product_Category1__r.Name, List_Price__c, MRP__c, Tax_Percent__c,
                Tax_Class__c, CreatedDate, UOM__c, Selling_Category__c,
                (SELECT Id, Unit_Price__c, MRP__c, UOM__c, Customer__c, 
                 Customer_Type__c, Region__c, Secondary_Customer_Category__c
                 FROM Price_Books__r where Customer_Type__c ='Secondary Customer' and Sales_Channel__c IN: channelSet)
                FROM Product__c  WHERE Is_Active__c = true AND Id IN :skuNameToSkuId.values()
                ORDER BY Channel__c ASC
            ];
            
            
        }
        dt.resonForReturn = extractPicklistValues('Return_Item__c', 'Reason_For_Return__c');
        dt.uom = extractPicklistValues('Return_Item__c', 'UOM__c');
        return dt;
        
    }
    
    
    
    @AuraEnabled
    public static void saveClaims(List<Claim__c> claimData) {
        
        Id accountId;
        List<User> partnerUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()];
        if(partnerUser.size() >0){
            List<Contact> contact = [SELECT AccountId FROM Contact WHERE Id = :partnerUser[0].ContactId LIMIT 1];
            accountId = contact[0].AccountId;
        }
        System.debug('>>> claimData: ' + JSON.serialize(claimData));
        if (claimData == null || claimData.isEmpty()) {
            throw new AuraHandledException('No claim data provided.');
        }
        
        List<Claim__c> claimsToInsert = new List<Claim__c>();
        for (Claim__c wrapper : claimData) {
            wrapper.Status__c = 'New';
            wrapper.Claim_Date__c = Date.today();
            wrapper.Customer__c = accountId;
        }
        
        insert claimData;
    }
    
    @AuraEnabled
    public static Id saveSecondaryReturn( List<Return_Item__c> items, Decimal totalAmount, Decimal totalQuantity,Id customerId) {
        if (items == null || items.isEmpty()) {
            throw new AuraHandledException('Item list must be provided.');
        }
        
        Id accountId;
        List<User> partnerUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()];
        if(partnerUser.size() >0){
            List<Contact> contact = [SELECT AccountId FROM Contact WHERE Id = :partnerUser[0].ContactId LIMIT 1];
            accountId = contact[0].AccountId;
        }
        
        
        // Create parent record and include customerId
        Return__c secReturn = new Return__c(
            Total_Amount__c = totalAmount,
            Total_Quantity__c = totalQuantity,
            Customer__c = customerId,
            Return_Date__c = system.today()
        );
        insert secReturn;
        
        for(Return_Item__c rtnitem : items)
        {
            rtnitem.Return__c = secReturn.Id;
        }
        
        
        // Step 6: Insert items
        insert items;
        
        // Step 7: Return parent ID
        return secReturn.Id;
    }
    @AuraEnabled(cacheable=true)
    public static List<Account> getAllAccounts() {
        return [
            SELECT Id, Name
            FROM Account
            WHERE Customer_Type__c = 'Secondary Customer'
            ORDER BY Name ASC
            LIMIT 50000
        ];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Account> searchCustomers(String searchKey) {
        
        if (String.isBlank(searchKey)) {
            return new List<Account>();
        }
        
        
        Id accountId;
        List<User> partnerUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()];
        if(partnerUser.size() >0){
            List<Contact> contact = [SELECT AccountId FROM Contact WHERE Id = :partnerUser[0].ContactId LIMIT 1];
            accountId = contact[0].AccountId;
        }
        
        
        
        
        list<Product_Mapping__c> mappinglist =  [
            SELECT Customer__c,Secondary_Customer_Name__c
            FROM Product_Mapping__c
            WHERE Primary_Customer__c = :accountId
            AND Customer_Type__c = 'Secondary Customer'
            AND Secondary_Customer_Name__c   LIKE :('%' + searchKey + '%')
            AND Customer__c != null
            ORDER BY Name
            LIMIT 20
        ]; 
        set<Id> CustomerIds = new set<Id>();
        for(Product_Mapping__c pm: mappinglist)
        {
            CustomerIds.add(pm.Customer__c);
        }
        
        return [
            select Id,Name from Account where Id IN: CustomerIds
        ]; 
        
        
    }
    
    
    
    @AuraEnabled
    public static DmsData getSecondaryOrders(String status,Date frmDate, Date toDate,string orderType){
        Id accountId;
        List<User> partnerUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()];
        if(partnerUser.size() >0){
            List<Contact> contact = [SELECT AccountId FROM Contact WHERE Id = :partnerUser[0].ContactId LIMIT 1];
            accountId = contact[0].AccountId;
        }
        DmsData dt = new DmsData();
        List<Order__c> ord =  [
            SELECT Id, Name,Account__c,Account__r.Name, Total_Quantity__c, Grand_Total__c, Order_Date__c
            FROM Order__c where Distributor__c =:accountId and Order_Date__c >= :frmDate AND Order_Date__c <= :toDate
        ]; 
        system.debug('ord----->'+ord);
        
        List<OrdData> ordDt = new List<OrdData>();
        for(Order__c o:ord){
            date orderDate = o.Order_Date__c;
            String formattedOrdDate =  orderDate!= null ? DateTime.newInstance(orderDate.year(), orderDate.month(),orderDate.day()).format('dd/MM/yyyy') : '';
            OrdData order = new OrdData();
            order.orderId=o.Id;
            order.orderNo = o.Name;
            order.quantity = o.Total_Quantity__c;
            order.orderDate = formattedOrdDate;
            order.amount = o.Grand_Total__c;
            order.customerId = o.Account__c;
            order.customerName = o.Account__r.Name;
            ordDt.add(order);
        } 
        
        dt.TotalOrderData = ordDt;
        dt.statusOptions = getStatusOptions('Order__c', 'Order_Status__c');
        return dt;
    }
    
    // Method to fetch order items for selected orders
    @AuraEnabled
    public static List<Map<String, Object>> getOrderItems(List<Id> orderIds) {
        List<Map<String, Object>> response = new List<Map<String, Object>>();
        
        Id accountId;
        User u = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        if (u.ContactId != null) {
            accountId = [
                SELECT AccountId FROM Contact WHERE Id = :u.ContactId LIMIT 1
            ].AccountId;
        }
        
        List<Order_Item__c> ordList = [
            SELECT Id, Name, Product__c, Product__r.Name,
            Quantity__c, Unit_Price__c,
            Tax_Percent__c, Tax_Amount__c, Total_Amount1__c
            FROM Order_Item__c
            WHERE Order__c IN :orderIds
        ];
        
        Set<String> productNames = new Set<String>();
        for (Order_Item__c oi : ordList) {
            if (oi.Product__r.Name != null) {
                productNames.add(oi.Product__r.Name);
            }
        }
        
        Map<String, Decimal> stockMap = new Map<String, Decimal>();
        for (Distributor_Stock__c ds : [
            SELECT Product_Name__c, Available_Quantity__c
            FROM Distributor_Stock__c
            WHERE Distributor__c = :accountId
            AND Product_Name__c IN :productNames
        ]) {
            stockMap.put(ds.Product_Name__c, ds.Available_Quantity__c);
        }
        
        for (Order_Item__c item : ordList) {
            Map<String, Object> row = new Map<String, Object>();
            
            Decimal qty = item.Quantity__c != null ? item.Quantity__c : 0;
            Decimal price = item.Unit_Price__c != null ? item.Unit_Price__c : 0;
            Decimal taxPer = item.Tax_Percent__c != null ? item.Tax_Percent__c : 0;
            
            Decimal taxAmt = (price * qty * taxPer) / 100;
            Decimal totalAmt = (price * qty) + taxAmt;
            
            row.put('OrderItemId', item.Id);
            row.put('ItemName', item.Name);
            row.put('ProductId', item.Product__c);
            row.put('ProductName', item.Product__r.Name);
            row.put('Quantity', qty);
            row.put('UnitPrice', price);
            row.put('TaxPercent', taxPer);
            row.put('TaxAmount', taxAmt);
            row.put('TotalAmount', totalAmt);
            row.put(
                'availableQuantity',
                stockMap.containsKey(item.Product__r.Name)
                ? stockMap.get(item.Product__r.Name)
                : 0
            );
            
            response.add(row);
        }
        return response;
    }
    
    @AuraEnabled
    public static Id saveSecondaryInvoice(List<Secondary_Invoice__c> invoices, List<Secondary_Invoice_Item__c> items) {
        Id accountId;
        List<User> partnerUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()];
        if(partnerUser.size() >0){
            List<Contact> contact = [SELECT AccountId FROM Contact WHERE Id = :partnerUser[0].ContactId LIMIT 1];
            accountId = contact[0].AccountId;
        }
        
        if (invoices == null || invoices.isEmpty()) {
            throw new AuraHandledException('At least one invoice must be provided.');
        }
        
        if (items == null || items.isEmpty()) {
            throw new AuraHandledException('At least one invoice item must be provided.');
        }
        
        for(Secondary_Invoice__c secInv : invoices){
            secInv.Customer__c = secInv.Store__c;
            secInv.Store__c = accountId;
        }
        // Insert the parent invoice(s)
        insert invoices;
        
        // Assuming only one parent invoice is being sent
        Id parentInvoiceId = invoices[0].Id;
        
        // Step 1: Get current user's Contact and Account
        
        
        // Step 2: Build keys for stock lookup
        Set<String> keySet = new Set<String>();
        for (Secondary_Invoice_Item__c item : items) {
            String key = accountId + '_' + item.Product_Name__c;
            keySet.add(key);
        }
        
        // Step 3: Load existing stocks
        Map<String, Distributor_Stock__c> existingStockMap = new Map<String, Distributor_Stock__c>();
        for (Distributor_Stock__c stock : [
            SELECT Id, Product__c, Distributor__c, DistributorWithProduct__c
            FROM Distributor_Stock__c
            WHERE DistributorWithProduct__c IN :keySet
        ]) {
            existingStockMap.put(stock.DistributorWithProduct__c, stock);
        }
        
        // Step 4: Create new stock records if needed
        List<Distributor_Stock__c> newStocks = new List<Distributor_Stock__c>();
        for (Secondary_Invoice_Item__c item : items) {
            item.Secondary_Invoice__c = parentInvoiceId;
            
            // Check if stock exists, else create new stock
            String key = accountId + '_' + item.Product_Name__c;
            if (existingStockMap.containsKey(key)) {
                item.Distributor_Stock__c = existingStockMap.get(key).Id;
            } else {
                Distributor_Stock__c newStock = new Distributor_Stock__c(
                    Product__c = item.Product__c,
                    Distributor__c = accountId
                );
                newStocks.add(newStock);
                existingStockMap.put(key, newStock);
            }
        }
        
        // Step 5: Insert new stocks if any
        if (!newStocks.isEmpty()) {
            insert newStocks;
            for (Distributor_Stock__c stock : newStocks) {
                String key = stock.Distributor__c + '_' + stock.Product_Name__c;
                existingStockMap.put(key, stock);
            }
            
            // Update Distributor Stock reference in items
            for (Secondary_Invoice_Item__c item : items) {
                String key = accountId + '_' + item.Product__c;
                item.Distributor_Stock__c = existingStockMap.get(key).Id;
                
            }
        }
        
        // Step 6: Insert invoice items
        insert items;
        
        // Step 7: Return parent invoice ID
        return parentInvoiceId;
    }
    
    // Fetch active products (renamed to avoid conflict)
    @AuraEnabled(cacheable=true)
    public static List<ProductWrapper> getActiveProducts() {
        List<Product__c> products = [
            SELECT Id, Name, List_Price__c, Product_Category1__r.Name, Tax_Percent__c, Is_Active__c
            FROM Product__c
            WHERE Is_Active__c = TRUE
        ];
        
        List<ProductWrapper> wrappers = new List<ProductWrapper>();
        for (Product__c p : products) {
            wrappers.add(new ProductWrapper(p));
        }
        return wrappers;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getProductCategories() {
        List<Product_Category__c> categoryRecords = [SELECT Name FROM Product_Category__c];
        List<String> categories = new List<String>();
        
        for (Product_Category__c cat : categoryRecords) {
            categories.add(cat.Name);
        }
        
        return categories;
    }
    
    @AuraEnabled
    public static String savePrimaryOrder(Order__c order, List<Order_Item__c> items) {
        System.debug('===== Incoming Order Data =====');
        System.debug(JSON.serializePretty(order));
        
        System.debug('===== Incoming Order Items =====');
        System.debug(JSON.serialize(items));
        
        if (items == null || items.isEmpty()) {
            throw new AuraHandledException('No order items provided.');
        }
        
        User currentUser = [SELECT Contact_Id__c FROM User WHERE Id = :UserInfo.getUserId()];
        if (currentUser.Contact_Id__c == null) {
            throw new AuraHandledException('User is not linked to any Contact.');
        }
        
        Contact con = [SELECT AccountId FROM Contact WHERE Id = :currentUser.Contact_Id__c];
        if (con.AccountId == null) {
            throw new AuraHandledException('Contact is not linked to any Account.');
        }
        
        order.Account__c = con.AccountId;
        order.Visit_for__c = 'Primary Customer';
        
        if (order.Order_Date__c == null) {
            order.Order_Date__c = System.today();
        }
        
        insert order;
        
        Set<Id> productIds = new Set<Id>();
        for (Order_Item__c item : items) {
            productIds.add(item.Product__c);
        }
        
        Map<Id, Product__c> productMap = new Map<Id, Product__c>(
            [SELECT Id, List_Price__c, Product_Category__c FROM Product__c WHERE Id IN :productIds]
        );
        
        List<Order_Item__c> orderItemsToInsert = new List<Order_Item__c>();
        for (Order_Item__c item : items) {
            Product__c prod = productMap.get(item.Product__c);
            Decimal unitPrice = prod.List_Price__c != null ? prod.List_Price__c : 0;
            
            // Default tax percent to 18 if null on item
            Decimal taxPercent = item.Tax_Percent__c != null ? item.Tax_Percent__c : 18;
            Decimal taxAmount = (unitPrice * item.Quantity__c * taxPercent) / 100;
            Decimal totalAmount = (item.Quantity__c * unitPrice) + taxAmount;
            
            orderItemsToInsert.add(new Order_Item__c(
                Order__c = order.Id,
                Product__c = item.Product__c,
                Quantity__c = item.Quantity__c,
                Product_Category__c = prod.Product_Category__c,
                Unit_Price__c = unitPrice,
                Total_Amount__c = totalAmount,
                Tax_Percent__c = taxPercent,
                Tax_Amount__c = taxAmount
            ));
        }
        
        insert orderItemsToInsert;
        
        // Return the order ID for use in LWC
        return order.Id;
    }
    
    @AuraEnabled
    public static List<User> getUsers(String searchKey, String status) {
        
        //----------------------------------------------------
        //Get logged-in user's AccountId (Partner scenario)
        //----------------------------------------------------
        
        
        Id accountId;
        User u = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        if (u.ContactId != null) {
            accountId = [
                SELECT AccountId FROM Contact WHERE Id = :u.ContactId LIMIT 1
            ].AccountId;
        }
        
        System.debug('Resolved AccountId: ' + accountId);
        
        if (accountId == null) {
            System.debug('No AccountId found. Returning empty list.');
            return new List<User>();
        }
        
        //----------------------------------------------------
        //Get Executive Users from Employee_Customer_Assignment__c
        //----------------------------------------------------
        List<Employee_Customer_Assignment__c> assignments = [
            SELECT Executive__c
            FROM Employee_Customer_Assignment__c
            WHERE Customer__c = :accountId
            AND Executive__c != null
        ];
        
        System.debug('Assignments Found: ' + assignments.size());
        
        Set<Id> executiveUserIds = new Set<Id>();
        for (Employee_Customer_Assignment__c eca : assignments) {
            executiveUserIds.add(eca.Executive__c);
        }
        
        System.debug('Executive User IDs: ' + executiveUserIds);
        
        if (executiveUserIds.isEmpty()) {
            System.debug('No Executives mapped. Returning empty list.');
            return new List<User>();
        }
        
        /*----------------------------------------------------
Build User Query
----------------------------------------------------*/
        String baseQuery =
            'SELECT Id, Name, Username,Executive_Name__c, Email, IsActive, CreatedDate,Manager_Name__c,Profile.Name ' +
            'FROM User WHERE Id IN :executiveUserIds';
        
        // Status filter
        if (status == 'Active') {
            baseQuery += ' AND IsActive = true';
        } else if (status == 'Inactive') {
            baseQuery += ' AND IsActive = false';
        }
        
        // Search filter
        if (String.isNotBlank(searchKey)) {
            String esc = String.escapeSingleQuotes(searchKey);
            baseQuery +=
                ' AND (Name LIKE \'%' + esc + '%\' ' +
                ' OR Email LIKE \'%' + esc + '%\')';
        }
        
        baseQuery += ' ORDER BY Name';
        
        System.debug('Final SOQL: ' + baseQuery);
        
        /*----------------------------------------------------
Execute Query
----------------------------------------------------*/
        List<User> users = Database.query(baseQuery);
        
        System.debug('Final User Count: ' + users.size());
        System.debug('===== UserListController.getUsers END =====');
        
        return users;
    }
    
    /**Helper Methods **/  
    private static List<Map<String, String>> extractPicklistValues(String objectName, String fieldName) {
        // Get the global describe map
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        
        // Check if the object exists
        if (!schemaMap.containsKey(objectName)) {
            return new List<Map<String, String>>();
        }
        
        Schema.DescribeSObjectResult objDescribe = schemaMap.get(objectName).getDescribe();
        Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
        
        // Check if the field exists in the object
        if (!fieldMap.containsKey(fieldName)) {
            return new List<Map<String, String>>();
        }
        
        Schema.DescribeFieldResult fieldResult = fieldMap.get(fieldName).getDescribe();
        List<Map<String, String>> picklistValues = new List<Map<String, String>>();
        
        if (fieldResult != null && fieldResult.getType() == Schema.DisplayType.Picklist) {
            for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
                picklistValues.add(new Map<String, String>{
                    'label' => entry.getLabel(),
                        'value' => entry.getValue()
                        });
            }
        }
        return picklistValues;
    }
    
    
    @AuraEnabled(cacheable=true)
    public static ReturnAccData getSecondaryCustomers() {
        
        ReturnAccData rt = new ReturnAccData();
        
        // Get Logged-in User's Account 
        Id accountId;
        List<User> partnerUser = [
            SELECT ContactId 
            FROM User 
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];

        if (!partnerUser.isEmpty() && partnerUser[0].ContactId != null) {
            List<Contact> contacts = [
                SELECT AccountId 
                FROM Contact 
                WHERE Id = :partnerUser[0].ContactId
                LIMIT 1
            ];
            if (!contacts.isEmpty()) {
                accountId = contacts[0].AccountId;
            }
        }

        // Safety check
        if (accountId == null) {
            return rt;
        }

        // Get Beat Mappings
        List<Junction_Beat__c> beatItems = [
            SELECT Account__c, Child_beat__r.Name
            FROM Junction_Beat__c
            WHERE Primary_Customer_Record_Id__c = :accountId
        ];
        
        Map<Id, Set<String>> outletToBeatNames = new Map<Id, Set<String>>();
        
        for (Junction_Beat__c bt : beatItems) {
            if (!outletToBeatNames.containsKey(bt.Account__c)) {
                outletToBeatNames.put(bt.Account__c, new Set<String>());
            }
            outletToBeatNames.get(bt.Account__c).add(bt.Child_beat__r.Name);
        }


        // Get Product Mappings 
        List<Product_Mapping__c> mappings = [
            SELECT Customer__c,
            Secondary_Customer_Outlet_Id__c,
            Secondary_Customer_Customer_Code__c,
            Customer__r.Name,
            Customer__r.State__c,
            Customer__r.District__c,
            Customer__r.Primary_Phone_Number__c,
            Customer__r.Secondary_Customer_Type__c,
            Primary_Customer__r.Name,
            Customer__r.Secondary_Customer_Category__c,
            Customer__r.Customer_Status__c,
            Sub_Stockiest__r.Name
            FROM Product_Mapping__c
            WHERE Primary_Customer__c = :accountId
            AND Is_Executive_Active__c = true
        ];

        //Deduplication 
        Set<Id> processedCustomerIds = new Set<Id>();
        Set<Id> subStockiestCustomers = new Set<Id>();

        List<AccData> uniqueSecondaryCustomers = new List<AccData>();
        Integer serialNo = 1;
        for (Product_Mapping__c pm : mappings) {

            if (pm.Customer__c == null || processedCustomerIds.contains(pm.Customer__c)) {
                continue;
            }

            processedCustomerIds.add(pm.Customer__c);

            if (pm.Customer__r.Secondary_Customer_Type__c == 'Sub Stockiest') {
                subStockiestCustomers.add(pm.Customer__c);
            }

            AccData d = new AccData();
            d.recordId = pm.Customer__c;
            d.sNumber = serialNo++; 
            d.secondaryCustomerId = pm.Customer__c;
            d.secondaryCustomerName = pm.Customer__r.Name;
            d.secondaryCustomerOutletId = pm.Secondary_Customer_Outlet_Id__c;
            d.secondaryCustomerCode = pm.Secondary_Customer_Customer_Code__c;
            d.primaryPhoneNumber = pm.Customer__r.Primary_Phone_Number__c;
            d.state = pm.Customer__r.State__c;
            d.district = pm.Customer__r.District__c;
            d.primaryCustomerName = pm.Primary_Customer__r.Name;
            d.subStockiestName = pm.Sub_Stockiest__r != null ? pm.Sub_Stockiest__r.Name : '';
            d.subStockiestName = pm.Sub_Stockiest__r != null ? pm.Sub_Stockiest__r.Name : '';
            d.customerType =  pm.Customer__r.Secondary_Customer_Type__c;
            d.customerCategory =  pm.Customer__r.Secondary_Customer_Category__c;
            d.status = pm.Customer__r.Customer_Status__c;
            d.beatName = outletToBeatNames.containsKey(pm.Customer__c)
                ? String.join(new List<String>(outletToBeatNames.get(pm.Customer__c)), ';')
                : '';

            uniqueSecondaryCustomers.add(d);
        }

        rt.customerData = uniqueSecondaryCustomers;
        rt.subStockiestCount = subStockiestCustomers.size();
        rt.totalCustomersCount = processedCustomerIds.size();
        rt.secondaryCustomerCount = rt.totalCustomersCount - rt.subStockiestCount;

        return rt;
    }
    
 
    
    @AuraEnabled
    public static String getInvoicePdfUrl(Id recordId) {
        return '/apex/GTInvoice?id=' + recordId;
    }

    /* ================= WRAPPERS ================= */
    public class ReturnAccData {
        @AuraEnabled public List<AccData> customerData;
        @AuraEnabled public Decimal secondaryCustomerCount;
        @AuraEnabled public Decimal subStockiestCount;
        @AuraEnabled public Decimal totalCustomersCount;
    }

    public class AccData {
        @AuraEnabled public String recordId;
        @AuraEnabled public String secondaryCustomerId;
        @AuraEnabled public String secondaryCustomerName;
        @AuraEnabled public String secondaryCustomerOutletId;
        @AuraEnabled public String secondaryCustomerCode;
        @AuraEnabled public String primaryPhoneNumber;
        @AuraEnabled public String primaryCustomerName;
        @AuraEnabled public String subStockiestName;
        @AuraEnabled public String state;
        @AuraEnabled public String district;
        @AuraEnabled public String beatName;
        @AuraEnabled public Integer sNumber; 
        @AuraEnabled public String status;
        @AuraEnabled public String customerType;
        @AuraEnabled public String customerCategory;
    }

    
    
    //==================================
    //   Wrapper Classes
    //=================================
    public class secondaryReturnData {
        @AuraEnabled public List<Product__c> productsList;
        @AuraEnabled public List<Map<String, String>> resonForReturn = new List<Map<String, String>> ();
        @AuraEnabled public List<Map<String, String>> uom = new List<Map<String, String>> ();
    }
    public class GRN_Item_Wrapper {
        @AuraEnabled public Id invoiceItemId;
        @AuraEnabled public Id productId;
        @AuraEnabled public Decimal invoicedQty;
        @AuraEnabled public Decimal receivedQty;
    }
    public class DmsData{
        @AuraEnabled public List<ordData> TotalOrderData;
        @AuraEnabled public List<InvData> TotalInvoiceData;
        @AuraEnabled public List<Map<String, String>> statusOptions;
        @AuraEnabled public List<PReturnData> TotalPrimaryReturnDataData; 
        @AuraEnabled public List<PaymentData> TotalPaymentData; 
        @AuraEnabled public List<GRNData> TotalGRNData; 
        @AuraEnabled public List<ClaimData> totalClaimData; 
        @AuraEnabled public List<DistributorStock> totalDistributorStockData; 
        @AuraEnabled public List<Product_Category__c> productCategories;
        @AuraEnabled public List<CreditNote> totalCreditNoteData;
        @AuraEnabled public List<SecInvData> totalSecoundaryInvoiceData;
        @AuraEnabled public List<SReturnData> totalSecoundaryReturnData;
        @AuraEnabled public String orderItemId;//added newly can remove
    }
    public class OrdData {
        @AuraEnabled public String itemName;
        @AuraEnabled public String productId;
        @AuraEnabled public String orderItemName;
        @AuraEnabled public String orderItemId;
        @AuraEnabled public String orderNo;
        @AuraEnabled public String orderId;
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public String orderDate;
        @AuraEnabled public Decimal amount;
        @AuraEnabled public Decimal tax;
        @AuraEnabled public String customerId;
        @AuraEnabled public String customerName;
        @AuraEnabled public List<Order_Item__c> items;//added newly can remove
    }
    public class InvData {
        @AuraEnabled public String name;
        @AuraEnabled public String InvDate;
        @AuraEnabled public String accId;
        @AuraEnabled public String accName;
        @AuraEnabled public Decimal Amount;
        @AuraEnabled public String InvId;
        @AuraEnabled public String Status;
        @AuraEnabled public decimal tax;
        @AuraEnabled public boolean isDisabled;
        @AuraEnabled public boolean selected = false;
        @AuraEnabled public Decimal TotalQuantity;  // <-- Add this line
    }
    public class PReturnData {
        @AuraEnabled public String productName;
        @AuraEnabled public String returnItemNo;
        @AuraEnabled public String productId;
        @AuraEnabled public String primaryReturnNo;
        @AuraEnabled public String primaryReturnId;
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public String returnDate;
    }
    public class PaymentData {
        @AuraEnabled public String paymenetItemNo;
        @AuraEnabled public String paymenetItemId;
        @AuraEnabled public String paymenetNo;
        @AuraEnabled public String paymenetId;
        @AuraEnabled public String invoiceNo;
        @AuraEnabled public String invoiceId;
        @AuraEnabled public String paymentDate;
        @AuraEnabled public Decimal Amount;
    }
    public class GRNData {
        @AuraEnabled public String GRNItemName;
        @AuraEnabled public String GRNItemId;
        @AuraEnabled public String invoiceNo;
        @AuraEnabled public String invoiceId;
        @AuraEnabled public String productName;
        @AuraEnabled public String productId;
        @AuraEnabled public String invoiceItemNo;
        @AuraEnabled public String invoiceItemId;
        @AuraEnabled public String GRNDate;
        @AuraEnabled public decimal invoicedQuantity;
        @AuraEnabled public decimal receivedQuantity;
        @AuraEnabled public String GRNName;
        @AuraEnabled public String GRNId;
    }
    public class ClaimData {
        @AuraEnabled public String claimName;
        @AuraEnabled public String claimId;
        @AuraEnabled public String customerName;
        @AuraEnabled public String customerId;
        @AuraEnabled public String description;
        @AuraEnabled public String claimDate;
        @AuraEnabled public String status;
        @AuraEnabled public decimal claimAmount;
    }
    public class DistributorStock{
        @AuraEnabled public String stockName;
        @AuraEnabled public String stockId;
        @AuraEnabled public String customerName;
        @AuraEnabled public String customerId;
        @AuraEnabled public String productName;
        @AuraEnabled public String productId;
        @AuraEnabled public String stockUOM;
        @AuraEnabled public Date stockDate;
        @AuraEnabled public decimal GRNQuantity;
        @AuraEnabled public decimal primaryReturnQty;
        @AuraEnabled public decimal secoundryInvoiceQty;
        @AuraEnabled public decimal secoundaryReturnQty;
        @AuraEnabled public decimal availableQuantity;
    }
    public class CreditNote{
        @AuraEnabled public String creditNoteNo;
        @AuraEnabled public String creditNoteId;
        @AuraEnabled public String customerName;
        @AuraEnabled public String customerId;
        @AuraEnabled public String claimNo;
        @AuraEnabled public String claimId;
        @AuraEnabled public String primaryReturnNo;
        @AuraEnabled public String primaryReturnId;
        @AuraEnabled public String creditDate;
        @AuraEnabled public String status;
        @AuraEnabled public decimal creditAmount;
    }
    public class SecInvData {
        @AuraEnabled public String name;
        @AuraEnabled public String InvDate;
        @AuraEnabled public String accId;
        @AuraEnabled public String accName;
        @AuraEnabled public Decimal Amount;
        @AuraEnabled public String InvId;
        @AuraEnabled public String Status;
        @AuraEnabled public decimal tax;
        @AuraEnabled public decimal Quantity;
        @AuraEnabled public boolean selected = false;
    }
    public class SReturnData {
        @AuraEnabled public String productName;
        @AuraEnabled public String returnItemNo;
        @AuraEnabled public String productId;
        @AuraEnabled public String secoundaryReturnNo;
        @AuraEnabled public String secoundaryReturnId;
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public String returnDate;
        // Added customer and amount fields
        @AuraEnabled public String secondaryCustomer;  // Secondary customer name
        @AuraEnabled public Decimal totalAmount;  // Total amount of the secondary return
    }
    public class GraphData {
        @AuraEnabled public List<Map<String, String>> formattedUsersOrder { get; set; }
        @AuraEnabled public List<Map<String, String>> formattedUsersSales { get; set; }
        @AuraEnabled public List<kpi_graph_target> graphlist;
    }
    public class kpi_graph_target {
        @AuraEnabled
        public decimal target;
        @AuraEnabled
        public decimal actual;
        @AuraEnabled
        public String xAxis;
        
    }
    public class ProductWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public Decimal price;
        @AuraEnabled public String category;
        
        public ProductWrapper(Product__c p) {
            id = p.Id;
            name = p.Name;
            price = p.List_Price__c;
            category = p.Product_Category1__r.Name;
        }
    }
    public class OrderItemWrapper {
        @AuraEnabled public String productId;
        @AuraEnabled public Integer quantity;
        
    }
}