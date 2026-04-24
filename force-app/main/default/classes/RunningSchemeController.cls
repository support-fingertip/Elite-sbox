public without sharing class RunningSchemeController {

    public class SchemeWrapper {
        @AuraEnabled public String schemeId;
        @AuraEnabled public String schemeName;
        @AuraEnabled public String description;
        @AuraEnabled public Date startDate;
        @AuraEnabled public Date endDate;
        @AuraEnabled public List<BuyProductWrapper> products;
    }

    public class BuyProductWrapper {
        @AuraEnabled public String buyProductId;
        @AuraEnabled public String productName;
        @AuraEnabled public String secondaryCustomerCategory;
        @AuraEnabled public String schemeType;
        @AuraEnabled public String schemeText;

        // Free Quantity fields
        @AuraEnabled public Decimal minQty;
        @AuraEnabled public Decimal buyQuantity;

        // Sale Value Discount fields
        @AuraEnabled public Decimal saleValueThreshold;
        @AuraEnabled public Decimal saleValueDiscount;

        // Per Quantity Off fields
        @AuraEnabled public Decimal perQtyThreshold;
        @AuraEnabled public Decimal discount;
    }
    
    @AuraEnabled
    public static List<SchemeWrapper> getRunningSchemes(String dateFilter, String fromDate, String toDate) {
        Date startRange;
        Date endRange;
        Date today = Date.today();
        Integer currentYear  = today.year();
        Integer currentMonth = today.month();
        
        if (dateFilter == 'current') {
            startRange = Date.newInstance(currentYear, currentMonth, 1);
            endRange   = startRange.addMonths(1).addDays(-1);
        } else if (dateFilter == 'previous') {
            Date firstOfCurrent = Date.newInstance(currentYear, currentMonth, 1);
            startRange = firstOfCurrent.addMonths(-1);
            endRange   = firstOfCurrent.addDays(-1);
        } else if (dateFilter == 'custom' && fromDate != null && toDate != null) {
            startRange = Date.valueOf(fromDate);
            endRange   = Date.valueOf(toDate);
        } else {
            startRange = Date.newInstance(currentYear, currentMonth, 1);
            endRange   = startRange.addMonths(1).addDays(-1);
        }
        
        
        Id accountId;
        List<User> partnerUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()];
        if(partnerUser.size() >0){
            List<Contact> contact = [SELECT AccountId FROM Contact WHERE Id = :partnerUser[0].ContactId LIMIT 1];
            accountId = contact[0].AccountId;
        }
        
        Account acc;
        Set<String> accountSalesChannels = new Set<String>();
        List<Account> accList = [
            SELECT Id, 
            Sales_Channel__c
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];
        if (!accList.isEmpty()) {
            acc = accList[0];
            // Parse comma-separated Sales_Channel__c from Account
            if (String.isNotBlank(acc.Sales_Channel__c)) {
                for (String ch : acc.Sales_Channel__c.split(',')) {
                    accountSalesChannels.add(ch.trim().toLowerCase());
                }
            }
        }
        
        List<Buy_Product__c> buyProducts = [
            SELECT Id,
            Product__r.Name,
            Secondary_Customer_Category__c,
            Scheme_Type__c,
            Scheme__c,
            Scheme__r.Name,
            Scheme__r.Description__c,
            Scheme__r.Scheme_Start_Date__c,
            Scheme__r.Scheme_End_Date__c,
            Min__c,
            Buy_Quantity__c,
            Sale_Value_Threshold__c,
            Sale_Value__c,
            Discount__c
            FROM Buy_Product__c
            WHERE Scheme__r.Scheme_Start_Date__c <= :endRange
            AND Scheme__r.Scheme_End_Date__c   >= :startRange
            AND Scheme_Type__c IN ('Free Quantity', 'Sale Value Discount', 'Per Quantity Off')
            AND Sales_Channel__c IN :accountSalesChannels
            ORDER BY Scheme__r.Name, Scheme_Type__c
        ];
        
        // Group by Scheme
        Map<String, SchemeWrapper> schemeMap = new Map<String, SchemeWrapper>();
        
        for (Buy_Product__c bp : buyProducts) {
            String schemeId = bp.Scheme__c;
            
            if (!schemeMap.containsKey(schemeId)) {
                SchemeWrapper sw  = new SchemeWrapper();
                sw.schemeId       = schemeId;
                sw.schemeName     = bp.Scheme__r.Name;
                sw.description    = bp.Scheme__r.Description__c;
                sw.startDate      = bp.Scheme__r.Scheme_Start_Date__c;
                sw.endDate        = bp.Scheme__r.Scheme_End_Date__c;
                sw.products       = new List<BuyProductWrapper>();
                schemeMap.put(schemeId, sw);
            }
            
            BuyProductWrapper bpw      = new BuyProductWrapper();
            bpw.buyProductId           = bp.Id;
            bpw.productName            = bp.Product__r.Name;
            bpw.secondaryCustomerCategory = bp.Secondary_Customer_Category__c;
            bpw.schemeType             = bp.Scheme_Type__c;
            
            if (bp.Scheme_Type__c == 'Free Quantity') {
                bpw.minQty       = bp.Min__c;
                bpw.buyQuantity  = bp.Buy_Quantity__c;
                bpw.schemeText   = 'Buy ' + formatQty(bp.Min__c) + ' Quantity, Get Free '
                    + formatQty(bp.Buy_Quantity__c) + ' Quantity';
                
            } else if (bp.Scheme_Type__c == 'Sale Value Discount') {
                bpw.saleValueThreshold = bp.Sale_Value_Threshold__c;
                bpw.saleValueDiscount  = bp.Sale_Value__c;
                bpw.schemeText         = 'Buy Sale Value of ₹' + formatAmount(bp.Sale_Value_Threshold__c)
                    + ', Get ' + formatQty(bp.Sale_Value__c) + '% Discount on Sale Value';
                
            } else if (bp.Scheme_Type__c == 'Per Quantity Off') {
                bpw.perQtyThreshold = bp.Sale_Value_Threshold__c;
                bpw.discount        = bp.Discount__c;
                bpw.schemeText      = 'Buy ' + formatQty(bp.Sale_Value_Threshold__c)
                    + ' Quantity, Get ₹' + formatAmount(bp.Discount__c) + ' Off per Quantity';
            }
            
            schemeMap.get(schemeId).products.add(bpw);
        }
        
        return schemeMap.values();
    }
    
    private static String formatQty(Decimal val) {
        if (val == null) return '0';
        return val.stripTrailingZeros().toPlainString();
    }
    
    private static String formatAmount(Decimal val) {
        if (val == null) return '0';
        return val.setScale(2).toPlainString();
    }
}