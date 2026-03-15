public with sharing class ProductGalleryController {
    @AuraEnabled(cacheable=true)
    public static List<Product__c> getGalleryProducts() {
        Id accountId;
        List<User> partnerUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()];
        if (partnerUser.size() > 0 && partnerUser[0].ContactId != null) {
            List<Contact> contact = [SELECT AccountId FROM Contact WHERE Id = :partnerUser[0].ContactId LIMIT 1];
            if (contact.size() > 0 && contact[0].AccountId != null) {
                accountId = contact[0].AccountId;
            }
        }
        if (accountId == null) {
            return new List<Product__c>();
        }
        return beatPlannerlwc.getProducts(accountId, 'Primary Customer');
    }
}