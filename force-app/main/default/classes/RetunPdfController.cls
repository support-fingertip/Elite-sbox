public class RetunPdfController {
    public Id recid { get; set; }
    public List<ReturnWapper> rtnItemList { get; set; }
    public String customerName { get; set; }
    public String returnNo { get; set; }
    public String returnDate { get; set; }
    public Decimal totalQuantity { get; set; }
    public Decimal totalAmount { get; set; }
    public String ownerName { get; set; }
    public string finalAmtinWords {get;set;}
    
    
    public RetunPdfController(ApexPages.StandardController controller) { 
        recid = ApexPages.currentPage().getParameters().get('id');
         NumberTOWordConvertion nwcObj = new NumberTOWordConvertion();
        // Fetch related return Items
        List<Return_Item__c> returnItemList = [
            SELECT Id, SKU__c, SKU__r.Name, UOM__c, Unit_Price__c, Total_Amount__c,
            Reason_For_Return__c, Quantity__c, Batch_Number__c,Return__r.Owner_Name__c,
            Return__r.Customer__r.Name, Return__r.Return_Date__c, Return__r.Name
            FROM Return_Item__c
            WHERE Return__c = :recid
        ];
        
        rtnItemList = new List<ReturnWapper>();
        totalQuantity = 0.0;
        totalAmount = 0.0;
        
        if (!returnItemList.isEmpty()) {
            // Populate header-level fields from the first record
            customerName = returnItemList[0].Return__r.Customer__r.Name;
            returnNo = returnItemList[0].Return__r.Name;
            if (returnItemList[0].Return__r.Return_Date__c != null) {
                Date myDate = returnItemList[0].Return__r.Return_Date__c;
                DateTime myDT = DateTime.newInstance(myDate.year(), myDate.month(), myDate.day());
                returnDate = myDT.format('MMMM dd, yyyy');
            } else {
                returnDate = '';
            }
            ownerName =  returnItemList[0].Return__r.Owner_Name__c;
            integer i = 1;
            for (Return_Item__c rtnItem : returnItemList) {
                ReturnWapper rItem = new ReturnWapper();
                rItem.index = i++;
                rItem.skuName = rtnItem.SKU__r.Name;
                rItem.quantity = rtnItem.Quantity__c;
                rItem.batchno = rtnItem.Batch_Number__c;
                rItem.returnReason = rtnItem.Reason_For_Return__c;
                rItem.uom = rtnItem.UOM__c;
                rItem.unitPrice = rtnItem.Unit_Price__c;
                rItem.totalAmount = rtnItem.Total_Amount__c;
                if(rtnItem.Quantity__c != null)
                {
                       totalQuantity += rtnItem.Quantity__c;
                }
                if(rtnItem.Total_Amount__c != null )
                {
                    totalAmount += rtnItem.Total_Amount__c;
                }
             
                
                
                rtnItemList.add(rItem);
            }
            finalAmtinWords = nwcObj.getNumberTOWordConvertion(totalAmount);
        }
    }
    
    public class ReturnWapper {
        public String skuName { get; set; }
        public Decimal quantity { get; set; }
        public String batchno { get; set; }
        public String returnReason { get; set; }
        public String uom { get; set; }
        public Decimal unitPrice { get; set; }
        public Decimal totalAmount { get; set; }
        public Decimal index { get; set; }
    }
}