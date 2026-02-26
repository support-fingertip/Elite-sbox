public with sharing class VisitFormController {

    // =========================================================
    // GET PRIMARY CUSTOMERS
    // =========================================================
    @AuraEnabled(cacheable=true)
    public static List<Account> getPrimaryCustomers() {
        return [
            SELECT Id, Name
            FROM Account
            WHERE ParentId = null
            ORDER BY Name
            LIMIT 30
        ];
    }

    // =========================================================
    // GET SECONDARY CUSTOMERS
    // =========================================================
    @AuraEnabled(cacheable=true)
    public static List<Account> getSecondaryCustomers(Id primaryCustomerId) {
        if(primaryCustomerId == null) {
            return new List<Account>();
        }
        return [
            SELECT Id, Name
            FROM Account
            WHERE ParentId = :primaryCustomerId
            ORDER BY Name
        ];
    }

 
    // =========================================================
    // GET ALLOWED PRODUCTS BASED ON EMPLOYEE CATEGORY
    // =========================================================
    @AuraEnabled(cacheable=true)
    public static Map<String, List<String>> getAllowedProducts() {
        Map<String, List<String>> result = new Map<String, List<String>>();
        Id userId = UserInfo.getUserId();
        List<User> empList = [
            SELECT Category__c
            FROM User
            WHERE id = :userId
            LIMIT 1
        ];
        List<Schema.PicklistEntry> categoryEntries = Visit_Form__c.Product_Categories__c.getDescribe().getPicklistValues();
        List<Schema.PicklistEntry> groupEntries = Visit_Form__c.Product_Group__c.getDescribe().getPicklistValues();
        if(empList.isEmpty() || String.isBlank(empList[0].Category__c)) {
            for(Schema.PicklistEntry categoryEntry : categoryEntries) {
                if(!categoryEntry.isActive()) continue;
                List<String> groups = new List<String>();
                for(Schema.PicklistEntry groupEntry : groupEntries) {
                    if(groupEntry.isActive()) {
                        groups.add(groupEntry.getValue());
                    }
                }
                result.put(categoryEntry.getValue(), groups);
            }
            return result;
        }
        Set<String> allowedCategories = new Set<String>(empList[0].Category__c.split(';'));
        for(Schema.PicklistEntry categoryEntry : categoryEntries) {
            if(!categoryEntry.isActive()) continue;
            if(allowedCategories.contains(categoryEntry.getValue())) {
                List<String> groups = new List<String>();
                for(Schema.PicklistEntry groupEntry : groupEntries) {
                    if(groupEntry.isActive()) {
                        groups.add(groupEntry.getValue());
                    }
                }
                result.put(categoryEntry.getValue(), groups);
            }
        }
        return result;
    }
    
    // =========================================================
    // SAVE EXISTING PRIMARY CUSTOMER VISIT
    // =========================================================
    @AuraEnabled
    public static Id savePrimaryVisit(Id primaryCustomerId, String productCategory, String productGroup, String competitorName,
        String competitorProduct, String competitorRemarks, String generalRemarks, String primaryImageBase64, String primaryImageName,
        String competitorImageBase64, String competitorImageName, Decimal latitude, Decimal longitude) {
        Visit_Form__c visit = new Visit_Form__c();
        visit.Primary_Customer__c = primaryCustomerId;
        visit.Product_Categories__c = productCategory;
        visit.Product_Group__c = productGroup;
        visit.Competitor_Name__c = competitorName;
        visit.Competitor_Product__c = competitorProduct;
        visit.Competitor_Remarks__c = competitorRemarks;
        visit.General_Remarks__c = generalRemarks;
        visit.Customer_Type__c = 'Existing Primary Customer';
        if (latitude != null && longitude != null) {
            visit.Geo_Location__Latitude__s = latitude;
            visit.Geo_Location__Longitude__s = longitude;
        }
        insert visit;
        List<ContentVersion> filesToInsert = new List<ContentVersion>();
        if (primaryImageBase64 != null) {
            filesToInsert.add(new ContentVersion(
                Title = primaryImageName,
                PathOnClient = primaryImageName,
                VersionData = EncodingUtil.base64Decode(primaryImageBase64),
                FirstPublishLocationId = visit.Id
            ));
        }
        if (competitorImageBase64 != null) {
            filesToInsert.add(new ContentVersion(
                Title = competitorImageName,
                PathOnClient = competitorImageName,
                VersionData = EncodingUtil.base64Decode(competitorImageBase64),
                FirstPublishLocationId = visit.Id
            ));
        }
        if (!filesToInsert.isEmpty()) {
            insert filesToInsert;
        }
        return visit.Id;
    }

    // =========================================================
    // SAVE EXISTING SECONDARY CUSTOMER VISIT
    // =========================================================
    @AuraEnabled
    public static Id saveSecondaryVisit(Id primaryCustomerId, Id secondaryCustomerId, String productCategory, String productGroup,
                                        String competitorName, String competitorProduct, String competitorRemarks, String generalRemarks,
                                        String customerImageBase64, String customerImageName,
                                        String competitorImageBase64, String competitorImageName, Decimal latitude, Decimal longitude) 
    {
        Visit_Form__c visit = new Visit_Form__c();
        visit.Primary_Customer__c = primaryCustomerId;
        visit.Secondary_Customer__c = secondaryCustomerId;
        visit.Product_Categories__c = productCategory;
        visit.Product_Group__c = productGroup;
        visit.Competitor_Name__c = competitorName;
        visit.Competitor_Product__c = competitorProduct;
        visit.Competitor_Remarks__c = competitorRemarks;
        visit.General_Remarks__c = generalRemarks;
        visit.Customer_Type__c = 'Existing Secondary Customer';
        visit.Visit_Type__c = null;
        if (latitude != null && longitude != null) {
            visit.Geo_Location__Latitude__s = latitude;
            visit.Geo_Location__Longitude__s = longitude;
        }
        insert visit;
        
        List<ContentVersion> filesToInsert = new List<ContentVersion>();
        if (customerImageBase64 != null) {
            filesToInsert.add(new ContentVersion(
                Title = customerImageName,
                PathOnClient = customerImageName,
                VersionData = EncodingUtil.base64Decode(customerImageBase64),
                FirstPublishLocationId = visit.Id
            ));
        }
        if (competitorImageBase64 != null) {
            filesToInsert.add(new ContentVersion(
                Title = competitorImageName,
                PathOnClient = competitorImageName,
                VersionData = EncodingUtil.base64Decode(competitorImageBase64),
                FirstPublishLocationId = visit.Id
            ));
        }
        if (!filesToInsert.isEmpty()) {
            insert filesToInsert;
        }
        
        
        return visit.Id;
    }

    // =========================================================
    // NEW PRIMARY CUSTOMER LOGIC
    // =========================================================
    @AuraEnabled
    public static Id saveNewPrimaryCustomerVisit(String primaryCustomerName, String businessType, String address, String state,
                                                 String district, String pinCode, String contactNumber, String productCategory,
                                                 String productGroup, String competitorName, String competitorProduct,
                                                 String competitorRemarks, String generalRemarks,
                                                 String customerImageBase64, String customerImageName, String competitorImageBase64,
                                                 String competitorImageName, Decimal latitude, Decimal longitude)
    {
        
        
        Visit_Form__c visit = new Visit_Form__c();
        visit.Primary_Customer_Name__c = primaryCustomerName;
        visit.Product_Categories__c = productCategory;
        visit.Product_Group__c = productGroup;
        visit.Competitor_Name__c = competitorName;
        visit.Competitor_Product__c = competitorProduct;
        visit.Competitor_Remarks__c = competitorRemarks;
        visit.General_Remarks__c = generalRemarks;
        visit.Address__c = address;
        visit.State__c = state;
        visit.District__c = district;
        visit.Pincode__c = pinCode;
        visit.Contact_Number__c = contactNumber;
        visit.Customer_Type__c = 'New Primary Customer';
        visit.Primary_Customer_Business_Type__c = businessType;
        if (latitude != null && longitude != null) {
            visit.Geo_Location__Latitude__s = latitude;
            visit.Geo_Location__Longitude__s = longitude;
        }
        insert visit;
         
        List<ContentVersion> filesToInsert = new List<ContentVersion>();
        if (customerImageBase64 != null) {
            filesToInsert.add(new ContentVersion(
                Title = customerImageName,
                PathOnClient = customerImageName,
                VersionData = EncodingUtil.base64Decode(customerImageBase64),
                FirstPublishLocationId = visit.Id
            ));
        }
        if (competitorImageBase64 != null) {
            filesToInsert.add(new ContentVersion(
                Title = competitorImageName,
                PathOnClient = competitorImageName,
                VersionData = EncodingUtil.base64Decode(competitorImageBase64),
                FirstPublishLocationId = visit.Id
            ));
        }
        if (!filesToInsert.isEmpty()) {
            insert filesToInsert;
        }
        
        
        
        
        return visit.Id;
    }

    // =========================================================
    // SAVE SUB STOCKIST – EXISTING MARKET EXPANSION
    // =========================================================
    @AuraEnabled
    public static Id saveSubStockistExistingMarketVisit(String subStockistName, String primaryCustomer, String address, String state,
                                                        String district, String pinCode, String contactNumber, String productCategory, String productGroup,
                                                        String competitorName, String competitorProduct, String competitorRemarks, String generalRemarks,
                                                        String customerImageBase64, String customerImageName, String competitorImageBase64,
                                                        String competitorImageName, Decimal latitude, Decimal longitude)
    {
        Visit_Form__c visit = new Visit_Form__c();
        visit.Sub_Stockiest_Name__c = subStockistName;
        visit.Primary_Customer__c = primaryCustomer;
        visit.Product_Categories__c = productCategory;
        visit.Product_Group__c = productGroup;
        visit.Competitor_Name__c = competitorName;
        visit.Competitor_Product__c = competitorProduct;
        visit.Competitor_Remarks__c = competitorRemarks;
        visit.General_Remarks__c = generalRemarks;
        visit.Address__c = address;
        visit.State__c = state;
        visit.District__c = district;
        visit.Pincode__c = pinCode;
        visit.Contact_Number__c = contactNumber;
        visit.Customer_Type__c = 'New Sub Stockiest';
        visit.Visit_Type__c = 'Existing Market Expansion';
        if (latitude != null && longitude != null) {
            visit.Geo_Location__Latitude__s = latitude;
            visit.Geo_Location__Longitude__s = longitude;
        }
        insert visit;
        
        List<ContentVersion> filesToInsert = new List<ContentVersion>();
        if (customerImageBase64 != null) {
            filesToInsert.add(new ContentVersion(
                Title = customerImageName,
                PathOnClient = customerImageName,
                VersionData = EncodingUtil.base64Decode(customerImageBase64),
                FirstPublishLocationId = visit.Id
            ));
        }
        if (competitorImageBase64 != null) {
            filesToInsert.add(new ContentVersion(
                Title = competitorImageName,
                PathOnClient = competitorImageName,
                VersionData = EncodingUtil.base64Decode(competitorImageBase64),
                FirstPublishLocationId = visit.Id
            ));
        }
        if (!filesToInsert.isEmpty()) {
            insert filesToInsert;
        }
        return visit.Id;
    }

    // =========================================================
    // SAVE OUTLET – NEW MARKET EXPANSION
    // =========================================================
    @AuraEnabled
    public static Id saveOutletNewMarket(String outletName, String customerBusinessType, String address, String state,
                                                        String district, String pinCode, String contactNumber, String productCategory, String productGroup,
                                                        String competitorName, String competitorProduct, String competitorRemarks, String generalRemarks,
                                                        String customerImageBase64, String customerImageName, String competitorImageBase64,
                                                        String competitorImageName, Decimal latitude, Decimal longitude)
    {
        Visit_Form__c visit = new Visit_Form__c();
        visit.Outlet_Name__c = outletName;
        visit.Secondary_Customer_Business_Type__c = customerBusinessType;
        visit.Product_Categories__c = productCategory;
        visit.Product_Group__c = productGroup;
        visit.Competitor_Name__c = competitorName;
        visit.Competitor_Product__c = competitorProduct;
        visit.Competitor_Remarks__c = competitorRemarks;
        visit.General_Remarks__c = generalRemarks;
        visit.Address__c = address;
        visit.State__c = state;
        visit.District__c = district;
        visit.Pincode__c = pinCode;
        visit.Contact_Number__c = contactNumber;
        visit.Customer_Type__c = 'New Outlet';
        visit.Visit_Type__c = 'New Market Expansion';
        if (latitude != null && longitude != null) {
            visit.Geo_Location__Latitude__s = latitude;
            visit.Geo_Location__Longitude__s = longitude;
        }
        insert visit;
        
        List<ContentVersion> filesToInsert = new List<ContentVersion>();
        if (customerImageBase64 != null) {
            filesToInsert.add(new ContentVersion(
                Title = customerImageName,
                PathOnClient = customerImageName,
                VersionData = EncodingUtil.base64Decode(customerImageBase64),
                FirstPublishLocationId = visit.Id
            ));
        }
        if (competitorImageBase64 != null) {
            filesToInsert.add(new ContentVersion(
                Title = competitorImageName,
                PathOnClient = competitorImageName,
                VersionData = EncodingUtil.base64Decode(competitorImageBase64),
                FirstPublishLocationId = visit.Id
            ));
        }
        if (!filesToInsert.isEmpty()) {
            insert filesToInsert;
        }
        return visit.Id;
    }

    // =========================================================
    // SAVE OUTLET – EXISTING MARKET EXPANSION
    // =========================================================
    @AuraEnabled
    public static Id saveOutletExistingMarket(String outletName,String primaryCustomer, String customerBusinessType, String address, String state,
                                              String district, String pinCode, String contactNumber, String productCategory, String productGroup,
                                              String competitorName, String competitorProduct, String competitorRemarks, String generalRemarks,
                                              String customerImageBase64, String customerImageName, String competitorImageBase64,
                                              String competitorImageName, Decimal latitude, Decimal longitude)
    {
        Visit_Form__c visit = new Visit_Form__c();
        visit.Outlet_Name__c = outletName;
        visit.Primary_Customer__c = primaryCustomer;
        visit.Secondary_Customer_Business_Type__c = customerBusinessType;
        visit.Product_Categories__c = productCategory;
        visit.Product_Group__c = productGroup;
        visit.Competitor_Name__c = competitorName;
        visit.Competitor_Product__c = competitorProduct;
        visit.Competitor_Remarks__c = competitorRemarks;
        visit.General_Remarks__c = generalRemarks;
        visit.Address__c = address;
        visit.State__c = state;
        visit.District__c = district;
        visit.Pincode__c = pinCode;
        visit.Contact_Number__c = contactNumber;
        visit.Customer_Type__c = 'New Outlet';
        visit.Visit_Type__c = 'Existing Market Expansion';
        if (latitude != null && longitude != null) {
            visit.Geo_Location__Latitude__s = latitude;
            visit.Geo_Location__Longitude__s = longitude;
        }
        insert visit;
        
        List<ContentVersion> filesToInsert = new List<ContentVersion>();
        if (customerImageBase64 != null) {
            filesToInsert.add(new ContentVersion(
                Title = customerImageName,
                PathOnClient = customerImageName,
                VersionData = EncodingUtil.base64Decode(customerImageBase64),
                FirstPublishLocationId = visit.Id
            ));
        }
        if (competitorImageBase64 != null) {
            filesToInsert.add(new ContentVersion(
                Title = competitorImageName,
                PathOnClient = competitorImageName,
                VersionData = EncodingUtil.base64Decode(competitorImageBase64),
                FirstPublishLocationId = visit.Id
            ));
        }
        if (!filesToInsert.isEmpty()) {
            insert filesToInsert;
        }
        return visit.Id;
    }

    // =========================================================
    // GET SECONDARY CUSTOMERS FROM PRODUCT MAPPING
    // =========================================================
    @AuraEnabled(cacheable=true)
    public static List<Account> getSecondaryCustomersFromProductMapping(Id primaryCustomerId) {
        if(primaryCustomerId == null) {
            return new List<Account>();
        }
        return [
            SELECT Id, Name
            FROM Account
            WHERE Id IN (
                SELECT Customer__c
                FROM Product_Mapping__c
                WHERE Primary_Customer__c = :primaryCustomerId
                AND Customer__c != null
            )
            ORDER BY Name
        ];
    }

    private static Map<String, List<String>> getAllPicklistProducts() {
        Map<String, List<String>> result = new Map<String, List<String>>();
        List<Schema.PicklistEntry> categoryEntries = Visit_Form__c.Product_Categories__c.getDescribe().getPicklistValues();
        List<Schema.PicklistEntry> groupEntries = Visit_Form__c.Product_Group__c.getDescribe().getPicklistValues();
        for(Schema.PicklistEntry categoryEntry : categoryEntries) {
            if(!categoryEntry.isActive()) continue;
            String category = categoryEntry.getValue();
            List<String> groups = new List<String>();
            for(Schema.PicklistEntry groupEntry : groupEntries) {
                if(groupEntry.isActive()) {
                    groups.add(groupEntry.getValue());
                }
            }
            result.put(category, groups);
        }
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static String getPrimaryCustomerBusinessType(Id primaryCustomerId) {
        if(primaryCustomerId == null) return null;
        Account acc = [
            SELECT Type
            FROM Account
            WHERE Id = :primaryCustomerId
            LIMIT 1
        ];
        return acc.Type;
    }

    // =========================================================
    // GET VISIT FIELD VALUES BASED ON UI SELECTION
    // =========================================================
    @AuraEnabled(cacheable=true)
    public static Map<String,String> getVisitFieldValues(String uiSelection, Id primaryCustomerId) {
        Map<String,String> result = new Map<String,String>();
        String customerType;
        String visitType;
        String businessType;
        if(uiSelection == 'Existing Primary Customer') {
            customerType = 'Existing Primary Customer';
            visitType = null;
        } else if(uiSelection == 'Existing Secondary Customer') {
            customerType = 'Existing Secondary Customer';
            visitType = null;
        } else if(uiSelection == 'New Primary Customer') {
            customerType = 'New Primary Customer';
            visitType = null;
        } else if(uiSelection == 'Sub Stockiest – Existing Market Expansion') {
            customerType = 'New Sub Stockiest';
            visitType = null;
        } else if(uiSelection == 'Outlet – New Market Expansion') {
            customerType = 'New Outlet';
            visitType = 'New Market Expansion';
        } else if(uiSelection == 'Outlet – Existing Market Expansion') {
            customerType = 'New Outlet';
            visitType = 'Existing Market Expansion';
        }
        if(primaryCustomerId != null) {
            Account acc = [
                SELECT Type
                FROM Account
                WHERE Id = :primaryCustomerId
                LIMIT 1
            ];
            businessType = acc.Type;
        }
        result.put('CustomerType', customerType);
        result.put('VisitType', visitType);
        result.put('BusinessType', businessType);
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static List<Account> searchSecondaryCustomers(Id primaryCustomerId, String searchTerm) {
        if(String.isBlank(searchTerm) || primaryCustomerId == null) {
            return new List<Account>();
        }
        return [
            SELECT Id, Name, Land_Mark__c, Street__c
            FROM Account
            WHERE Id IN (
                SELECT Customer__c
                FROM Product_Mapping__c
                WHERE Primary_Customer__c = :primaryCustomerId
                AND Customer__c != null
            )
            AND Name LIKE :('%' + searchTerm + '%')
            ORDER BY Name
            LIMIT 50
        ];
    }

      /**
     * Get today's Visit_Form__c records for the current user, with optional search
     */
    @AuraEnabled
    public static List<Visit_Form__c> getTodayVisitForms(String searchTerm) {
        String userId = UserInfo.getUserId();
        List<Visit_Form__c> results;
        if (String.isNotBlank(searchTerm)) {
            String likeClause = '%' + searchTerm + '%';
            results = [
                SELECT Id,Customer_Name__c,Customer_Type__c, Visit_Type__c, CreatedDate
                FROM Visit_Form__c
                WHERE CreatedById = :userId
                    AND CreatedDate = TODAY
                    AND Customer_Name__c LIKE :likeClause
                ORDER BY CreatedDate DESC
            ];
        } else {
            results = [
                SELECT Id,Customer_Name__c,Customer_Type__c, Visit_Type__c, CreatedDate
                FROM Visit_Form__c
                WHERE CreatedById = :userId
                    AND CreatedDate = TODAY
                ORDER BY CreatedDate DESC
            ];
        }
        return results;
    }

}