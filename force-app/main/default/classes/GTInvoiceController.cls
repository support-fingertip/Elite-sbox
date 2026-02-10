public without sharing class GTInvoiceController {

    public Id recid { get; set; }
    public DistributorWrapper wrapper { get; set; }
    public string finalAmtinWords {get;set;}
    public List<InvoiceItemWapper> invoiceItemList { get; set; }
    public Decimal totalQuantity { get; set; }
    public Decimal totalAmount { get; set; }
    
    public Decimal totalQtyinCases { get; set; }
    public Decimal totalQtyinkg { get; set; }
    public Decimal totalTaxableAmount { get; set; }
    
    public Decimal totalCgstAmount { get; set; }
    public Decimal totalSgstAmount { get; set; }
    public Decimal totalIgstAmount{ get; set; }
    
    public boolean isStateMatching{ get; set; }
    
    public GTInvoiceController(ApexPages.StandardController controller) {
 
        recid = ApexPages.currentPage().getParameters().get('id');
        NumberTOWordConvertion nwcObj = new NumberTOWordConvertion();
        wrapper = new DistributorWrapper();

        if (recid == null) return;

        Secondary_Invoice__c secInv = [
            SELECT Store__c,Name,Invoice_Date__c,Order__r.Order_Date__c,Order__r.Name,Order__c,Order__r.Owner_Name__c,
            Order__r.Beat_Name__c,Customer__c,Order__r.Executive_Employee_Code__c,Delivery_remarks__c,Remarks__c
            FROM Secondary_Invoice__c
            WHERE Id = :recid
            LIMIT 1
        ];
        wrapper.dealerExecutiveName = secInv.Order__c != null ? secInv.Order__r.Owner_Name__c :'';
        wrapper.beatName = secInv.Order__c != null ?  secInv.Order__r.Beat_Name__c : '';
        wrapper.executiveCode = secInv.Order__c != null ?  secInv.Order__r.Executive_Employee_Code__c : '';
        wrapper.packingRemarks = secInv.Remarks__c != null ?  secInv.Remarks__c : '';
        wrapper.delivaryRemarks =  secInv.Delivery_remarks__c != null ?  secInv.Delivery_remarks__c : ''; 
        
        Account distributor = [
            SELECT Name,
                   State__c, District__c, Street__c, Building_Name__c,
                   City_Town__c, Land_Mark__c, Door_No__c, Pincode__c,
                   GST_Number__c, Primary_Phone_Number__c, Email_ID__c
            FROM Account
            WHERE Id = :secInv.Store__c
            LIMIT 1
        ];
         isStateMatching = true;


        // Build address
        List<String> addressParts = new List<String>();
        if (String.isNotBlank(distributor.Door_No__c)) addressParts.add(distributor.Door_No__c);
        if (String.isNotBlank(distributor.Building_Name__c)) addressParts.add(distributor.Building_Name__c);
        if (String.isNotBlank(distributor.Street__c)) addressParts.add(distributor.Street__c);
        if (String.isNotBlank(distributor.Land_Mark__c)) addressParts.add(distributor.Land_Mark__c);
        if (String.isNotBlank(distributor.City_Town__c)) addressParts.add(distributor.City_Town__c);
        if (String.isNotBlank(distributor.District__c)) addressParts.add(distributor.District__c);
        if (String.isNotBlank(distributor.State__c)) addressParts.add(distributor.State__c);
        if (String.isNotBlank(distributor.Pincode__c)) addressParts.add(distributor.Pincode__c);

        wrapper.distributorName = distributor.Name;
        wrapper.distributorAddress = String.join(addressParts, ', ');
        wrapper.distributorPhone = distributor.Primary_Phone_Number__c;
        wrapper.distributorEmail = distributor.Email_ID__c;
        wrapper.distributoGst = distributor.GST_Number__c;
        
        wrapper.invoiceNo = secInv.Name;
        wrapper.invoiceDate = secInv.Invoice_Date__c != null ? DateTime.newInstance( secInv.Invoice_Date__c,  Time.newInstance(0, 0, 0, 0) ).format('dd/MM/yyyy'): '';
        
        wrapper.poDate = secInv.Order__r.Order_Date__c != null ? DateTime.newInstance( secInv.Order__r.Order_Date__c, Time.newInstance(0, 0, 0, 0)  ).format('dd/MM/yyyy'): '';
        wrapper.poNo = secInv.Order__c != null ? secInv.Order__r.Name : '';
        
        Account dealer =[ SELECT Name,
                         State__c, District__c, Street__c, Building_Name__c,
                         City_Town__c, Land_Mark__c, Door_No__c, Pincode__c,
                         GST_Number__c, Primary_Phone_Number__c, Email_ID__c
                         FROM Account
                         WHERE Id = :secInv.Customer__c
                         LIMIT 1
                        ];
        
        
        isStateMatching = distributor.State__c!= null && dealer.State__c!= null && distributor.State__c == dealer.State__c ? true : false;
            
         // Build address
        List<String> dealerAddressParts = new List<String>();
        if (String.isNotBlank(dealer.Door_No__c)) dealerAddressParts.add(dealer.Door_No__c);
        if (String.isNotBlank(dealer.Building_Name__c)) dealerAddressParts.add(dealer.Building_Name__c);
        if (String.isNotBlank(dealer.Street__c)) dealerAddressParts.add(dealer.Street__c);
        if (String.isNotBlank(dealer.Land_Mark__c)) dealerAddressParts.add(dealer.Land_Mark__c);
        if (String.isNotBlank(dealer.City_Town__c)) dealerAddressParts.add(dealer.City_Town__c);
        if (String.isNotBlank(dealer.District__c)) dealerAddressParts.add(dealer.District__c);
        if (String.isNotBlank(dealer.State__c)) dealerAddressParts.add(dealer.State__c);
        if (String.isNotBlank(dealer.Pincode__c)) dealerAddressParts.add(dealer.Pincode__c);
        
        wrapper.dealerName = dealer.Name;
        wrapper.dealerAddress = String.join(dealerAddressParts, ', ');
        wrapper.dealerPhone = dealer.GST_Number__c;
        wrapper.dealerGst = dealer.GST_Number__c;
        
        list<Secondary_Invoice_Item__c> secondaryInvItem = [select Id,Name,Product__c,Product_Name__c,SKU_Code__c,Tax_Percent__c,Tax_Amount__c,
                                                            Quantity__c,Unit_Price__c,MRP__c,Quantity_in_Kgs__c,HSN_Code__c,
                                                            Qty_in_Cases__c,Taxable_Amount__c,Total_Amount__c from Secondary_Invoice_Item__c 
                                                            where Secondary_Invoice__c =:secInv.Id];
        
        invoiceItemList = new List<InvoiceItemWapper>();

        
        Decimal totalQuantityval = 0;
        Decimal totalAmountval = 0;
        
        Decimal totalQtyinCasesval = 0;
        Decimal totalQtyinkgval = 0;
        Decimal totalTaxableAmountval = 0;
        
        Decimal totalCgstAmountval = 0;
        Decimal totalSgstAmountval = 0;
        Decimal totalIgstAmountval = 0;
        
        Integer i = 1;
        
        for (Secondary_Invoice_Item__c invItem : secondaryInvItem) {
            InvoiceItemWapper oItem = new InvoiceItemWapper();
            
            oItem.index = i++;
            oItem.skuName = invItem.Product_Name__c;
            oItem.skuCode = invItem.SKU_Code__c;
            oItem.hsnCode = invItem.HSN_Code__c != null ? invItem.HSN_Code__c : '';
            
            oItem.quantity = invItem.Quantity__c != null ? invItem.Quantity__c : 0;
            oItem.unitPrice = invItem.Unit_Price__c != null ? invItem.Unit_Price__c : 0;
            oItem.mrp = invItem.MRP__c != null ? invItem.MRP__c : 0;
            oItem.qtyinCases = invItem.Qty_in_Cases__c != null ? invItem.Qty_in_Cases__c : 0;
            oItem.qtyinKg = invItem.Quantity_in_Kgs__c != null ? invItem.Quantity_in_Kgs__c : 0;
            oItem.taxableAmount = invItem.Taxable_Amount__c != null ? invItem.Taxable_Amount__c : 0;
            oItem.totalAmount = invItem.Total_Amount__c != null ? invItem.Total_Amount__c : 0;
            
            totalQuantityval += oItem.quantity;
            totalAmountval += oItem.totalAmount;
            
            totalQtyinCasesval  += oItem.qtyinCases;
            totalQtyinkgval  += oItem.qtyinKg;
            totalTaxableAmountval  += oItem.taxableAmount;
            
            oItem.cgstPecentage = 0;
            oItem.sgstPercenate =0;
            oItem.sgstAmount =0;
            oItem.cgstAmount = 0;
            oItem.igstPercenate =0;
            oItem.igstAmount = 0;
            if(isStateMatching)
            {
                oItem.cgstPecentage = invItem.Tax_Percent__c != null ? invItem.Tax_Percent__c/2 : 0;
                oItem.sgstPercenate = invItem.Tax_Percent__c != null ? invItem.Tax_Percent__c/2 : 0;
                
                oItem.sgstAmount = invItem.Tax_Amount__c != null ? invItem.Tax_Amount__c/2 : 0;
                oItem.cgstAmount = invItem.Tax_Amount__c != null ? invItem.Tax_Amount__c/2 : 0;
            }
            else
            {
                oItem.igstPercenate = invItem.Tax_Percent__c != null ? invItem.Tax_Percent__c : 0;
                oItem.igstAmount = invItem.Tax_Amount__c != null ? invItem.Tax_Amount__c : 0;
                
            }
            

            totalCgstAmountval  += oItem.cgstAmount;
            totalSgstAmountval  += oItem.sgstAmount;
            totalIgstAmountval  += oItem.igstAmount;
            
            invoiceItemList.add(oItem);
        }
        
        totalQuantity = totalQuantityval;
        totalAmount = totalAmountval;
        
        totalQtyinCases = totalQtyinCasesval;
        totalQtyinkg = totalQtyinkgval;
        totalTaxableAmount = totalTaxableAmountval;

        totalIgstAmount = totalIgstAmountval;
        totalSgstAmount = totalSgstAmountval;
        totalCgstAmount = totalCgstAmountval;

        finalAmtinWords = nwcObj.getNumberTOWordConvertion(totalAmount);
        
        
    }
    
    // Wrapper class
    public class DistributorWrapper {
        public String distributorName { get; set; }
        public String distributorAddress { get; set; }
        public String distributorPhone { get; set; }
        public String distributorEmail { get; set; }
        public String distributoGst { get; set; }
        
        public String invoiceNo { get; set; } 
        public String invoiceDate { get; set; } 
        public String poDate { get; set; } 
        public String poNo { get; set; } 
        
        public String dealerName { get; set; } 
        public String dealerAddress { get; set; } 
        public String dealerPhone { get; set; } 
        public String dealerGst { get; set; } 
        public String dealerExecutiveName { get; set; } 
        public String executiveCode { get; set; } 
        public String beatName { get; set; } 
        public String packingRemarks { get; set; } 
        public String delivaryRemarks { get; set; } 
    }
    
    public class InvoiceItemWapper {
        public Decimal index { get; set; }
        public String skuName { get; set; }
        public String skuCode { get; set; }
        public String hsnCode { get; set; }
        public Decimal mrp { get; set; }
        public Decimal qtyinCases { get; set; }
        public Decimal qtyinKg { get; set; }
        public Decimal taxableAmount { get; set; }
        public Decimal quantity { get; set; }
        public Decimal unitPrice { get; set; }
        public Decimal taxpercent { get; set; }
        public Decimal taxAmount { get; set; }
        public Decimal totalAmount { get; set; }
        public Decimal cgstPecentage { get; set; }
        public Decimal sgstPercenate { get; set; }
        public Decimal igstPercenate { get; set; }
        public Decimal cgstAmount { get; set; }
        public Decimal sgstAmount { get; set; }
        public Decimal igstAmount { get; set; }
        
    }
}