public without sharing class SecondaryCreditNoteSharingHandler {

    public static void handleAfterInsert(List<Secondary_Credit_Note__c> newCreditNotes) {
        shareCustomerAccountsWithDistributorUsers(newCreditNotes);
    }

    public static void handleAfterUpdate(List<Secondary_Credit_Note__c> newCreditNotes, Map<Id, Secondary_Credit_Note__c> oldMap) {
        List<Secondary_Credit_Note__c> creditNotesToProcess = new List<Secondary_Credit_Note__c>();
        for (Secondary_Credit_Note__c cn : newCreditNotes) {
            Secondary_Credit_Note__c oldCn = oldMap.get(cn.Id);
            if (cn.Distributor__c != oldCn.Distributor__c || cn.Customer__c != oldCn.Customer__c) {
                creditNotesToProcess.add(cn);
            }
        }
        if (!creditNotesToProcess.isEmpty()) {
            shareCustomerAccountsWithDistributorUsers(creditNotesToProcess);
        }
    }

    public static void shareCustomerAccountsWithDistributorUsers(List<Secondary_Credit_Note__c> creditNotes) {
        Set<Id> distributorAccountIds = new Set<Id>();
        Set<Id> customerAccountIds = new Set<Id>();

        for (Secondary_Credit_Note__c cn : creditNotes) {
            if (cn.Distributor__c != null && cn.Customer__c != null) {
                distributorAccountIds.add(cn.Distributor__c);
                customerAccountIds.add(cn.Customer__c);
            }
        }

        if (distributorAccountIds.isEmpty() || customerAccountIds.isEmpty()) {
            return;
        }

        // Find Partner Community Users linked to Distributor Accounts
        List<User> partnerUsers = [
            SELECT Id, Contact.AccountId
            FROM User
            WHERE Contact.AccountId IN :distributorAccountIds
            AND IsActive = true
            AND Profile.UserLicense.Name = 'Partner Community'
        ];

        if (partnerUsers.isEmpty()) {
            return;
        }

        // Build map: Distributor Account Id -> List of Partner User Ids
        Map<Id, List<Id>> distributorToUserIds = new Map<Id, List<Id>>();
        Set<Id> allPartnerUserIds = new Set<Id>();
        for (User u : partnerUsers) {
            Id distributorId = u.Contact.AccountId;
            if (!distributorToUserIds.containsKey(distributorId)) {
                distributorToUserIds.put(distributorId, new List<Id>());
            }
            distributorToUserIds.get(distributorId).add(u.Id);
            allPartnerUserIds.add(u.Id);
        }

        // Build map: Customer Account Id -> Set of Partner User Ids who need access
        Map<Id, Set<Id>> customerToUserIds = new Map<Id, Set<Id>>();
        for (Secondary_Credit_Note__c cn : creditNotes) {
            if (cn.Distributor__c != null && cn.Customer__c != null && distributorToUserIds.containsKey(cn.Distributor__c)) {
                if (!customerToUserIds.containsKey(cn.Customer__c)) {
                    customerToUserIds.put(cn.Customer__c, new Set<Id>());
                }
                customerToUserIds.get(cn.Customer__c).addAll(distributorToUserIds.get(cn.Distributor__c));
            }
        }

        if (customerToUserIds.isEmpty()) {
            return;
        }

        // Query existing AccountShare to avoid duplicates
        Set<String> existingShareKeys = new Set<String>();
        List<AccountShare> existingShares = [
            SELECT AccountId, UserOrGroupId
            FROM AccountShare
            WHERE AccountId IN :customerToUserIds.keySet()
            AND UserOrGroupId IN :allPartnerUserIds
            AND RowCause = 'Manual'
        ];
        for (AccountShare s : existingShares) {
            existingShareKeys.add(s.AccountId + '-' + s.UserOrGroupId);
        }

        // Create new AccountShare records
        List<AccountShare> newShares = new List<AccountShare>();
        for (Id customerId : customerToUserIds.keySet()) {
            for (Id userId : customerToUserIds.get(customerId)) {
                String shareKey = customerId + '-' + userId;
                if (!existingShareKeys.contains(shareKey)) {
                    newShares.add(new AccountShare(
                        AccountId = customerId,
                        UserOrGroupId = userId,
                        AccountAccessLevel = 'Read',
                        OpportunityAccessLevel = 'None',
                        CaseAccessLevel = 'None',
                        RowCause = Schema.AccountShare.RowCause.Manual
                    ));
                    existingShareKeys.add(shareKey);
                }
            }
        }

        if (!newShares.isEmpty()) {
            List<Database.SaveResult> results = Database.insert(newShares, false);
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    for (Database.Error err : results[i].getErrors()) {
                        System.debug('SecondaryCreditNoteSharingHandler - Error sharing Customer Account ' +
                            newShares[i].AccountId + ' with User ' + newShares[i].UserOrGroupId +
                            ': ' + err.getStatusCode() + ' - ' + err.getMessage());
                    }
                }
            }
        }
    }
}