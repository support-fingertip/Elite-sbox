public with sharing class VisitFormController {

    /* GET PRIMARY CUSTOMERS (Accounts) */
    @AuraEnabled(cacheable=true)
    public static List<Account> getPrimaryCustomers(){

        return [
            SELECT Id, Name
            FROM Account
            ORDER BY Name
            LIMIT 200
        ];

    }


    /* SAVE VISIT FORM */
    @AuraEnabled
    public static Id saveVisitForm(

        String primaryCustomerId,
        String productCategory,
        String productGroup,
        String competitorName,
        String competitorProduct,
        String competitorRemarks,
        String generalRemarks

    ){

        Visit_Form__c visit = new Visit_Form__c();

       visit.Primary_Customer__c = (Id)primaryCustomerId;
        visit.Product__c = productCategory;
        visit.Product_Group__c = productGroup;
        visit.Competitor_Name__c = competitorName;
        visit.Competitor_Product__c = competitorProduct;
        visit.Competitor_Remarks__c = competitorRemarks;
        visit.General_Remarks__c = generalRemarks;

        insert visit;

        return visit.Id;

    }

}