public class OrderPdfController {
    public Id recid { get; set; }
    public List<OrderWapper> oItemList { get; set; }
    public String customerName { get; set; }
    public String orderNo { get; set; }
    public String orderDate { get; set; }
    public String deliveredTo { get; set; }
    public String expectedDelivaryDate { get; set; }
    public Decimal totalQuantity { get; set; }
    public Decimal totalAmount { get; set; }
    public String ownerName { get; set; }
    public string finalAmtinWords {get;set;}
    public string companyName {get;set;}
    public string companyAddress {get;set;}
    
    
    public OrderPdfController(ApexPages.StandardController controller) { 
        recid = ApexPages.currentPage().getParameters().get('id');
        NumberTOWordConvertion nwcObj = new NumberTOWordConvertion();
        // Fetch related order Items
        List<Order_Item__c> orderItemList = [
            SELECT Id,Name,	Product__r.Name,Quantity__c,Unit_price__c,Tax_Percent__c,Tax__c,Total_Amount__c,Order__r.Order_Date__c,
            Order__r.Account__r.Name,Order__r.Owner_Name__c,Order__r.Name,Order__r.Expected_Delivery_Date__c,	Order__r.Delivery_To__c,Tax_Amount__c,
            Order__r.Company_Address__c,Order__r.Company_Name__c FROM Order_Item__c WHERE Order__c = :recid
        ];
        
        oItemList = new List<OrderWapper>();
        totalQuantity = 0.0;
        totalAmount = 0.0;
        
        if (!orderItemList.isEmpty()) {
            // Populate header-level fields from the first record
            customerName = orderItemList[0].Order__r.Account__r.Name;
            orderNo = orderItemList[0].Order__r.Name;
            companyName = orderItemList[0].order__r.Company_Name__c;
            companyAddress = orderItemList[0].Order__r.Company_Address__c;
            ApexPages.currentPage().getHeaders()
                .put('Content-Disposition', 'attachment; filename="' + orderNo + '.pdf"');
            deliveredTo = orderItemList[0].Order__r.Delivery_To__c;
            if (orderItemList[0].Order__r.Order_Date__c != null) {
                Date myDate = orderItemList[0].Order__r.Order_Date__c;
                DateTime myDT = DateTime.newInstance(myDate.year(), myDate.month(), myDate.day());
                orderDate = myDT.format('MMMM dd, yyyy');
            } else {
                orderDate = '';
            }
            
            if (orderItemList[0].Order__r.Expected_Delivery_Date__c != null) {
                Date myDate = orderItemList[0].Order__r.Expected_Delivery_Date__c;
                DateTime myDT = DateTime.newInstance(myDate.year(), myDate.month(), myDate.day());
                expectedDelivaryDate = myDT.format('MMMM dd, yyyy');
            } else {
                expectedDelivaryDate = '';
            }
            
            
            
            
            ownerName =  orderItemList[0].Order__r.Owner_Name__c;
            integer i = 1;
            for (Order_Item__c orderItem : orderItemList) {
                OrderWapper oItem = new OrderWapper();
                oItem.index = i++;
                oItem.skuName = orderItem.Product__r.Name;
                oItem.quantity = orderItem.Quantity__c;
                oItem.unitPrice = orderItem.Unit_price__c;
                oItem.taxpercent = orderItem.Tax__c;
                oItem.taxAmount = orderItem.Tax_Amount__c;
                
                oItem.totalAmount = orderItem.Total_Amount__c;
                if(orderItem.Quantity__c != null)
                {
                    totalQuantity += orderItem.Quantity__c;
                }
                if(orderItem.Total_Amount__c != null )
                {
                    totalAmount += orderItem.Total_Amount__c;
                }
                oItemList.add(oItem);
            }
            finalAmtinWords = nwcObj.getNumberTOWordConvertion(totalAmount);
        }
    }
    
    public class OrderWapper {
        public Decimal index { get; set; }
        public String skuName { get; set; }
        public Decimal quantity { get; set; }
        public Decimal unitPrice { get; set; }
        public Decimal taxpercent { get; set; }
        public Decimal taxAmount { get; set; }
        public Decimal totalAmount { get; set; }
        
    }
}