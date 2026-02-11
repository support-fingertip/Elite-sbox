/****************************************************************
* Class Name : SchemeLwc
* Company : Fingertipplus
* Created Date : 17-03-2025
* @description : This class handles scheme data
* @author : Abhinav Singh
* Used By : - schemeDataPage
* Change Log:
* -----------------------------------------------------------------------------
* Ver | Author | Date | Description
* -----------------------------------------------------------------------------
* 1.0 | Abhinav Singh|  17-03-2025 | Initial version
* -----------------------------------------------------------------------------
******************************************************************/
public class SchemeLwc {
    
    public class userData {
        @AuraEnabled public List<product__c> allProducts { get; set; }
        @AuraEnabled public List<Product_Category__c> allProductsCat { get; set; }
        @AuraEnabled public List<String> salesChannelPicklist {get;set;}
        @AuraEnabled public List<Exclude_Line_Item__c> excId { get; set; }
        @AuraEnabled public Exclude_Product__c excData { get; set; }
        @AuraEnabled public Scheme__c scheme { get; set; }
        @AuraEnabled public List<Buy_Product__c> buyPro { get; set; }
        @AuraEnabled public List<Category__c> allCategory { get; set; }
        @AuraEnabled public ListView ListViewDetails { get; set; }
        @AuraEnabled public List<Division__c> division { get; set; }
        @AuraEnabled public List<Map<String, String>> formattedAreaData { get; set; }
        @AuraEnabled public List<Map<String, String>> formattedRegionData { get; set; }
        
        @AuraEnabled public List<RegionWrapper> region { get; set; }
        @AuraEnabled public List<AccountWrapper> acc { get; set; }
        @AuraEnabled public List<AreaWrapper> area { get; set; }
        
        public userData() {
            region = new List<RegionWrapper>();
            acc = new List<AccountWrapper>();
            area = new List<AreaWrapper>();
            
        }
    }
    public class RegionWrapper {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public Boolean isMapped { get; set; }
        @AuraEnabled public String mappingId { get; set; }
        
        public RegionWrapper(String id, String name, Boolean isMapped, String mappingId) {
            this.id = id;
            this.name = name;
            this.isMapped = isMapped;
            this.mappingId = mappingId;
        }
    }
    
    public class AccountWrapper {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public Boolean isMapped { get; set; }
        @AuraEnabled public String mappingId { get; set; }
        @AuraEnabled public String region { get; set; }
        @AuraEnabled public String area { get; set; }
        
        public AccountWrapper(String id, String name, Boolean isMapped, String mappingId,string region,string area) {
            this.id = id;
            this.name = name;
            this.isMapped = isMapped;
            this.mappingId = mappingId;
            this.region = region;
            this.area = area;
        }
    }
    
    public class AreaWrapper {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public Boolean isMapped { get; set; }
        @AuraEnabled public String mappingId { get; set; }
        
        public AreaWrapper(String id, String name, Boolean isMapped, String mappingId) {
            this.id = id;
            this.name = name;
            this.isMapped = isMapped;
            this.mappingId = mappingId;
        }
    }
    
    //Getting all the data while loading the page
    @AuraEnabled
    public Static userData getAllProduct(string recordId){
        userData dt = new userData();
        system.debug(recordId);
        List<String> paymentTypeValues = new List<String>();
        Schema.DescribeFieldResult fieldResult = Product__c.Channel__c.getDescribe();
        
        for (Schema.PicklistEntry picklistEntry : fieldResult.getPicklistValues()) {
            paymentTypeValues.add(picklistEntry.getLabel());
        }
        dt.salesChannelPicklist = paymentTypeValues;
        dt.allProductsCat =[Select Id,Name from Product_Category__c];
        dt.allCategory = [SELECT id,name from Category__c];
        List<ListView> listViewRecords = [SELECT Id FROM ListView WHERE SObjectType = 'Scheme__c' AND Name = :'All' LIMIT 1];
        dt.ListViewDetails = (!listViewRecords.isEmpty()) ? listViewRecords[0]: null;
        if(recordId != null){
            dt.scheme = [select id,name,Applies_to__c,Scheme_End_Date__c,Scheme_Start_Date__c,Scheme_Type__c,
                         IsActive__c,Product_Category__c,Product_Category__r.Name ,Description__c
                         from Scheme__c 
                         where id =: recordId];
            dt.buyPro = [select id,name,Sales_Channel__c,Scheme_Type__c,Sale_Value_Threshold__c,Scheme__c,Buy_Quantity__c,Buy_Value__c,Offer_Percent__c,Offer_Quantity__c,
                         Offer_Value__c,Min__c,Max__c,Product__c,Product__r.Name,Category__c,Category__r.Name,Discount__c,
                         Per_Kg__c,Sale_Value__c
                         from Buy_Product__c where 
                         Scheme__c =: recordId];
            dt.allProducts = [SELECT Id, Name, Channel__c,SKU_Code__c FROM Product__c WHERE Is_Active__c = true];
            List<Exclude_Product__c> excPro = [select id from Exclude_Product__c where Scheme__c =: recordId Limit 1];
            if(!excPro.isEmpty()){
                List<Exclude_Line_Item__c> excItem = [Select id,Product__c,Category__c from Exclude_Line_Item__c where Exclude_Product__c =: excPro[0].Id];
                dt.excId = excItem;
                dt.excData = excPro[0];
            }
        }	
        return dt;
    }
    
    //Getting product by product category id
    @AuraEnabled
    public static userData getAllProductById(String salesChannel) {
        userData dt = new userData();
        List<Sales_Channel_To_SKU__c> channels = [SELECT Id, Name, SKU__c,Delivery_Plant__c FROM Sales_Channel_To_SKU__c WHERE Sales_Channel__c  =:salesChannel];
        Set<Id> productIds = new Set<Id>();
        for (Sales_Channel_To_SKU__c channel : channels) {
            productIds.add(channel.SKU__c);
        }
        if (!productIds.isEmpty()) {
            dt.allProducts = [Select Id,Name from Product__c where Is_Active__c = true and Id in: productIds];
        }
        //dt.allProducts = Database.query(query);
        return dt;
    }
    
    //Saving scheme and product to buy
    @AuraEnabled
    public static Id saveData(
        List<Buy_Product__c> ProductBuy,
        Scheme__c schemeDta,
        String proCatId,
        String excProCatId,
        String excludedId
    ) {
        if (schemeDta == null || ProductBuy == null || ProductBuy.isEmpty()) {
            throw new AuraHandledException('Invalid input: Scheme data or Product list is missing.');
        }
        
        try {
            // Insert or update the Scheme record
            upsert schemeDta;
            
            // Handle exclude product update if necessary
            if (proCatId == excProCatId && excludedId != null) {
                Exclude_Product__c ex = new Exclude_Product__c();
                ex.Id = excludedId;
                ex.Scheme__c = schemeDta.Id;
                update ex;
            }
            
            // Assign the Scheme ID and additional fields to all Buy_Product__c records
            for (Buy_Product__c pro : ProductBuy) {
                pro.Scheme__c = schemeDta.Id;
                
                // ✅ Set Sales Channel and Scheme Type (new fields)
                if (String.isBlank(pro.Sales_Channel__c) || String.isBlank(pro.Scheme_Type__c)) {
                    throw new AuraHandledException('Each product must have a Sales Channel and Scheme Type.');
                }
            }
            
            // ✅ Upsert Buy_Product__c records
            Database.upsert(ProductBuy, false); // false = partial success disabled
            
            return schemeDta.Id;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error saving data: ' + e.getMessage());
        }
    }
    
    
    //Saveing exclude product
    @AuraEnabled
    public static userData saveExclude(String prodCatId, List<Exclude_Line_Item__c> exc, String exId, List<String> deleteId) {
        // Delete records if deleteId is not empty
        userData dt = new userData();
        if (!deleteId.isEmpty()) {
            List<Exclude_Line_Item__c> recordsToDelete = [SELECT Id FROM Exclude_Line_Item__c WHERE Id IN :deleteId];
            if (!recordsToDelete.isEmpty()) {
                delete recordsToDelete;
            }
        }
        
        if (exc.isEmpty()) {
            Exclude_Product__c excPro = [select id from Exclude_Product__c where Id =: exId Limit 1];
            List<Exclude_Line_Item__c> excItem = [Select id,Product__c,Category__c from Exclude_Line_Item__c where Exclude_Product__c =: excPro.Id];
            dt.excId = excItem;
            dt.excData = excPro;
            return dt;
        }
        system.debug('prodCatId :'+prodCatId);
        // Upsert Exclude_Product__c record
        Exclude_Product__c ex = new Exclude_Product__c(
            Id = exId,
            Product_Category__c = prodCatId != '' ? prodCatId : null
        );
        upsert ex;
        
        // Associate line items with the newly inserted/upserted Exclude_Product__c
        for (Exclude_Line_Item__c e : exc) {
            e.Exclude_Product__c = ex.Id;
        }
        upsert exc;
        Exclude_Product__c excPro = [select id from Exclude_Product__c where Id =: ex.id Limit 1];
        List<Exclude_Line_Item__c> excItem = [Select id,Product__c from Exclude_Line_Item__c where Exclude_Product__c =: excPro.Id];
        dt.excId = excItem;
        dt.excData = excPro;
        return dt;
    }
    
    @AuraEnabled
    public static userData mapRegion(String proId, String schemeId, Boolean isRegion, Boolean isCustomer, Boolean isArea) {
        userData dt = new userData();
        
        // Fetch Mapping records related to the scheme
        List<Mapping__c> mappings = [SELECT Id, Name, Area__c, Account__c, Region__c FROM Mapping__c WHERE Scheme__c = :schemeId];
        
        // Create lookup maps
        Map<Id, String> regionMap = new Map<Id, String>();
        Map<Id, String> accountMap = new Map<Id, String>();
        Map<Id, String> areaMap = new Map<Id, String>();
        
        for (Mapping__c m : mappings) {
            if (m.Region__c != null) regionMap.put(m.Region__c, m.Id);
            if (m.Account__c != null) accountMap.put(m.Account__c, m.Id);
            if (m.Area__c != null) areaMap.put(m.Area__c, m.Id);
        }
        
        // Process Region Data
        if (isRegion) {
            for (Region__c r : [SELECT Id, Name FROM Region__c]) {
                Boolean isMapped = regionMap.containsKey(r.Id);
                dt.region.add(new RegionWrapper(r.Id, r.Name, isMapped, isMapped ? regionMap.get(r.Id) : ''));
            }
        }
        
        // Process Account Data
        if (isCustomer) {
            List<Map<String, String>> formattedAreaData = new List<Map<String, String>>();
            List<Map<String, String>> formattedRegionData = new List<Map<String, String>>();
            Map<String, String> allOptionsales = new Map<String, String>();
            allOptionsales.put('label', 'All');
            allOptionsales.put('value', 'All');
            formattedAreaData.add(allOptionsales);
            formattedRegionData.add(allOptionsales);
            for (Account a : [SELECT Id, Name,Area__c, Region__c FROM Account]) {
                if(a.Area__c != null ){
                    Map<String, String> dataMap = new Map<String, String>();
                    dataMap.put('label', a.Area__c);
                    dataMap.put('value', a.Area__c);
                    formattedAreaData.add(dataMap);
                }
                if(a.Region__c != null ){
                    Map<String, String> dataMap = new Map<String, String>();
                    dataMap.put('label', a.Region__c);
                    dataMap.put('value', a.Region__c);
                    formattedRegionData.add(dataMap);
                }
                Boolean isMapped = accountMap.containsKey(a.Id);
                dt.acc.add(new AccountWrapper(a.Id, a.Name, isMapped, isMapped ? accountMap.get(a.Id) : '', a.Region__c,a.Area__c));
            }
            dt.formattedAreaData = formattedAreaData;
            dt.formattedRegionData = formattedRegionData;
        }
        
        // Process Area Data
        if (isArea) {
            for (Area__c ar : [SELECT Id, Name FROM Area__c]) {
                Boolean isMapped = areaMap.containsKey(ar.Id);
                dt.area.add(new AreaWrapper(ar.Id, ar.Name, isMapped, isMapped ? areaMap.get(ar.Id) : ''));
            }
        }
        
        return dt;
    }
    
    //saving the map
    @AuraEnabled
    public static void saveMapping(List<Mapping__c> mapping, String schemeId, List<String> deleteData) {
        // Delete only if there are IDs present in deleteData
        if (!deleteData.isEmpty()) {
            List<Mapping__c> recordsToDelete = [SELECT Id FROM Mapping__c WHERE Id IN :deleteData];
            if (!recordsToDelete.isEmpty()) {
                delete recordsToDelete;
            }
        }
        
        // Upsert the provided mapping records
        if (!mapping.isEmpty()) {
            upsert mapping;
        }
    }
    
    
    
}