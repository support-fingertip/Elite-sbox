/****************************************************************
* Class Name : salesStrategyLwc
* Company : Fingertipplus
* Created Date : 24-03-2025
* @description : This class handles sales strategy data
* @author : Abhinav Singh
* Used By : - salesStrategy
* Change Log:
* -----------------------------------------------------------------------------
* Ver | Author | Date | Description
* -----------------------------------------------------------------------------
* 1.0 | Abhinav Singh|  24-03-2025 | Initial version
* -----------------------------------------------------------------------------
******************************************************************/
public class SalesStrategyLwc {
    
    public class SalesData {
        @AuraEnabled public ListView ListViewDetails { get; set; }
        @AuraEnabled public List<Map<String, Object>> salesRegionData { get; set; }
        @AuraEnabled public List<Map<String, Object>> salesProductCategoryData { get; set; }
        @AuraEnabled public List<Map<String, Object>> salesProductData { get; set; }
        @AuraEnabled public List<Map<String, Object>> salesCustomerData { get; set; }
        @AuraEnabled public List<Map<String, Object>> salesAreaData { get; set; }
        @AuraEnabled public List<Map<String, Object>> salesAllProductData { get; set; }
        @AuraEnabled public  List<String> customerType { get; set; }
        @AuraEnabled public  List<Region__c> region { get; set; }
        @AuraEnabled public Sales_Strategy__c salesRegion {get;  set;}
    }
    
    @AuraEnabled
    public static SalesData getAllData(String recordId) {
        SalesData dt = new SalesData();
        dt.salesRegionData = new List<Map<String, Object>>();
        dt.salesAllProductData = new List<Map<String, Object>>();
        dt.salesProductCategoryData = new List<Map<String, Object>>();
        dt.salesProductData = new List<Map<String, Object>>();
        dt.salesCustomerData = new List<Map<String, Object>>();
        dt.salesAreaData = new List<Map<String, Object>>();
        
        // Fetch ListView Details
        List<ListView> listViewRecords = [SELECT Id FROM ListView WHERE SObjectType = 'Sales_Strategy__c' AND Name = 'All' LIMIT 1];
        dt.ListViewDetails = (!listViewRecords.isEmpty()) ? listViewRecords[0] : null;
        
        // Fetch all required data
        List<Region__c> regions = [SELECT Id, Name FROM Region__c];
        List<Product_Category__c> productCategories = [SELECT Id, Name FROM Product_Category__c];
        List<Product__c> products = [SELECT Id, Name, Product_Category1__c FROM Product__c];
        List<Account> customers = [SELECT Id, Name FROM Account];
        List<Area__c> areas = [SELECT Id, Name FROM Area__c];
        dt.region = regions;
        if (recordId != null) {
            
            dt.salesRegion = [select id,name,Customer_type__c from Sales_Strategy__c where id =: recordId];
            List<Sales_Product_Category__c> salesProductCategories = [SELECT Id, Product_Category__c, Product_Category__r.Name 
                                                                      FROM Sales_Product_Category__c 
                                                                      WHERE Sales_Strategy__c = :recordId];
            
            List<Sales_Product__c> salesProducts = [SELECT Id, Product__c, Product__r.Name, 
                                                    Product_Category__c, Product_Category__r.Name 
                                                    FROM Sales_Product__c 
                                                    WHERE Sales_Strategy__c = :recordId];
            
            List<Sales_Customer__c> salesCustomers = [SELECT Id, Customer__c, Customer__r.Name 
                                                      FROM Sales_Customer__c 
                                                      WHERE Sales_Strategy__c = :recordId];
            
            List<Sales_Area__c> salesAreas = [SELECT Id, Area__c, Area__r.Name 
                                              FROM Sales_Area__c 
                                              WHERE Sales_Strategy__c = :recordId];
            
         
            
            // Process Product Category Data
            Map<Id, Sales_Product_Category__c> salesProductCategoryMap = new Map<Id, Sales_Product_Category__c>();
            for (Sales_Product_Category__c spc : salesProductCategories) {
                salesProductCategoryMap.put(spc.Product_Category__c, spc);
            }
            
            List<String> idsProCat = new List<String>();
            List<String> idsPro = new List<String>();
            for (Product_Category__c pc : productCategories) {
                Boolean isSaved = salesProductCategoryMap.containsKey(pc.Id);
                string ids;
                if(isSaved){
                    idsPro.add(pc.Id); 
                    ids = salesProductCategoryMap.get(pc.Id).Id;
                }
                else
                    ids = '';
                dt.salesProductCategoryData.add(new Map<String, Object>{
                    'salesProductCategories' => ids,
                        'isSaveDt' => isSaved,
                        'productCategoryId' => pc.Id,
                        'productCategoryName' => pc.Name,
                        'Id' => pc.Id
                        });
            }
            
            // Process Product Data
            Map<Id, Sales_Product__c> salesProductMap = new Map<Id, Sales_Product__c>();
            for (Sales_Product__c sp : salesProducts) {
                salesProductMap.put(sp.Product__c, sp);
            }
             
            for (Product__c product : products) {
                Boolean isSaved = salesProductMap.containsKey(product.Id);
                string ids;
                if(isSaved){
                    ids = salesProductMap.get(product.Id).Id;
                    idsProCat.add(product.Product_Category1__c); 
                }
                else
                    ids = '';
                dt.salesAllProductData.add(new Map<String, Object>{
                    'salesProducts' => ids,
                        'isSaveDt' => isSaved,
                        'productId' => product.Id,
                        'productName' => product.Name,
                        'productCategoryId' => product.Product_Category1__c,
                        'Id' => product.id
                        });
            }
            if(!idsProCat.isEmpty()){
                for (Map<String, Object> productData : dt.salesAllProductData) {
                    if (productData.containsKey('productCategoryId') && idsProCat.contains((String)productData.get('productCategoryId'))) {
                        dt.salesProductData.add(productData);
                    }
                }
            }else{
                for (Map<String, Object> productData : dt.salesAllProductData) {
                    if (productData.containsKey('productCategoryId') && idsPro.contains((String) productData.get('productCategoryId'))) {
                        dt.salesProductData.add(productData);
                    }
                }
            }
            
            // Process Customer Data
            Map<Id, Sales_Customer__c> salesCustomerMap = new Map<Id, Sales_Customer__c>();
            for (Sales_Customer__c sc : salesCustomers) {
                salesCustomerMap.put(sc.Customer__c, sc);
            }
            
            for (Account customer : customers) {
                Boolean isSaved = salesCustomerMap.containsKey(customer.Id);
                string ids;
                if(isSaved)
                    ids = salesCustomerMap.get(customer.Id).Id;
                else
                    ids = '';
                dt.salesCustomerData.add(new Map<String, Object>{
                    'salesCustomers' => ids,
                        'isSaveDt' => isSaved,
                        'customerId' => customer.Id,
                        'customerName' => customer.Name,
                        'Id' => customer.id
                        });
            }
            
            // Process Area Data
            Map<Id, Sales_Area__c> salesAreaMap = new Map<Id, Sales_Area__c>();
            for (Sales_Area__c sa : salesAreas) {
                salesAreaMap.put(sa.Area__c, sa);
            }
            
            for (Area__c area : areas) {
                Boolean isSaved = salesAreaMap.containsKey(area.Id);
                string ids;
                if(isSaved)
                    ids = salesAreaMap.get(area.Id).Id;
                else
                    ids = '';
                dt.salesAreaData.add(new Map<String, Object>{
                    'salesAreas' => ids,
                        'isSaveDt' => isSaved,
                        'areaId' => area.Id,
                        'areaName' => area.Name,
                        'Id' => area.id
                        });
            }
            
        } else {
            
            
            for (Product_Category__c pc : productCategories) {
                dt.salesProductCategoryData.add(new Map<String, Object>{
                    'salesProductCategories' => '',
                        'isSaveDt' => false,
                        'productCategoryId' => pc.Id,
                        'productCategoryName' => pc.Name,
                        'Id' => pc.Id
                        });
            }
            
            for (Product__c product : products) {
                dt.salesAllProductData.add(new Map<String, Object>{
                    'salesProducts' => '',
                        'isSaveDt' => false,
                        'productId' => product.Id,
                        'productName' => product.Name,
                        'productCategoryId' => product.Product_Category1__c,
                        'Id' => product.Id
                        });
            }
            
            for (Account customer : customers) {
                dt.salesCustomerData.add(new Map<String, Object>{
                    'salesCustomers' => '',
                        'isSaveDt' => false,
                        'customerId' => customer.Id,
                        'customerName' => customer.Name,
                        'Id' => customer.Id
                        });
            }
            
            for (Area__c area : areas) {
                dt.salesAreaData.add(new Map<String, Object>{
                    'salesAreas' => '',
                        'isSaveDt' => false,
                        'areaId' => area.Id,
                        'areaName' => area.Name,
                        'Id' => area.Id
                        });
            }
        }
        dt.customerType = userProfileLWC.getPicklistValues('Sales_Strategy__c', 'Customer_type__c');
        return dt;
    }
    
    @AuraEnabled
    public static String saveData(
        Id recordId,
        Sales_Strategy__c sales,
        List<Sales_Product_Category__c> proCat,
        List<Sales_Product__c> pro,
        List<Sales_Customer__c> cust,
        List<Sales_Area__c> area,
        List<String> proCatDel,
        List<String> proDel,
        List<String> custDel,
        List<String> areaDel
    ) {
        try {
            // Insert or update Sales Strategy record
            // Sales_Strategy__c sales = new Sales_Strategy__c();
            if (recordId != null) {
                sales.Id = recordId;
            }
            upsert sales;
            
            // Map to store category relationships
            Map<String, Id> categoryMap = new Map<String, Id>();
            for (Sales_Product_Category__c category : proCat) {
                category.Sales_Strategy__c = sales.Id;
            }
            upsert proCat;
            
            for (Sales_Product_Category__c category : proCat) {
                categoryMap.put(category.Product_Category__c, category.Id);
            }
            
            // Assign correct Sales_Product_Category__c Ids
            for (Sales_Product__c product : pro) {
                if (categoryMap.containsKey(product.Product_Category__c)) {
                    product.Sales_Product_Category__c = categoryMap.get(product.Product_Category__c);
                }
                product.Sales_Strategy__c = sales.Id;
            }
            
            for (Sales_Customer__c customer : cust) {
                customer.Sales_Strategy__c = sales.Id;
            }
            
            for (Sales_Area__c areaItem : area) {
                areaItem.Sales_Strategy__c = sales.Id;
            }
            
            // Perform bulk DML operations
            if (!cust.isEmpty()) {
                upsert cust;
            }
            if (!pro.isEmpty()) {
                upsert pro;
            }
            if (!proCat.isEmpty()) {
                upsert proCat;
            }
            if (!area.isEmpty()) {
                upsert area;
            }
            
            // Handle deletions
            if (!proCatDel.isEmpty()) {
                delete [SELECT Id FROM Sales_Product_Category__c WHERE Id IN :proCatDel];
            }
            if (!proDel.isEmpty()) {
                delete [SELECT Id FROM Sales_Product__c WHERE Id IN :proDel];
            }
            if (!custDel.isEmpty()) {
                delete [SELECT Id FROM Sales_Customer__c WHERE Id IN :custDel];
            }
            if (!areaDel.isEmpty()) {
                delete [SELECT Id FROM Sales_Area__c WHERE Id IN :areaDel];
            }
            
            return sales.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }
}