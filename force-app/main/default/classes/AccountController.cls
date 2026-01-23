public with sharing class AccountController {
    @AuraEnabled(cacheable=true)
    public static List<Account> getAccounts(id recordId) {
        return [SELECT Id, Name, Industry, Phone,BillingStreet, BillingCity, BillingState, BillingPostalCode,Customer_Type__c,Primary_Phone_Number__c, BillingCountry,GeoLocation__Latitude__s,
                    GeoLocation__Longitude__s FROM Account where id =: recordId];
    }
}