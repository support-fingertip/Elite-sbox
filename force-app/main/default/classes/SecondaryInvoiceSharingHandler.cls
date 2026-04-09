public without sharing class SecondaryInvoiceSharingHandler {

    public static void handleAfterInsert(List<Secondary_Invoice__c> newInvoices) {
        shareCustomerAccountsWithDistributorUsers(newInvoices);
    }

    public static void handleAfterUpdate(List<Secondary_Invoice__c> newInvoices, Map<Id, Secondary_Invoice__c> oldMap) {
        List<Secondary_Invoice__c> invoicesToProcess = new List<Secondary_Invoice__c>();
        for (Secondary_Invoice__c inv : newInvoices) {
            Secondary_Invoice__c oldInv = oldMap.get(inv.Id);
            if (inv.Store__c != oldInv.Store__c || inv.Customer__c != oldInv.Customer__c) {
                invoicesToProcess.add(inv);
            }
        }
        if (!invoicesToProcess.isEmpty()) {
            shareCustomerAccountsWithDistributorUsers(invoicesToProcess);
        }
    }

    public static void shareCustomerAccountsWithDistributorUsers(List<Secondary_Invoice__c> invoices) {
        Set<Id> storeAccountIds = new Set<Id>();
        Set<Id> customerAccountIds = new Set<Id>();

        for (Secondary_Invoice__c inv : invoices) {
            if (inv.Store__c != null && inv.Customer__c != null) {
                storeAccountIds.add(inv.Store__c);
                customerAccountIds.add(inv.Customer__c);
            }
        }

        if (storeAccountIds.isEmpty() || customerAccountIds.isEmpty()) {
            return;
        }

        // Find Partner Community Users linked to Distributor (Store) Accounts
        List<User> partnerUsers = [
            SELECT Id, Contact.AccountId
            FROM User
            WHERE Contact.AccountId IN :storeAccountIds
            AND IsActive = true
            AND Profile.UserLicense.Name = 'Partner Community'
        ];

        if (partnerUsers.isEmpty()) {
            return;
        }

        // Build map: Store Account Id -> List of Partner User Ids
        Map<Id, List<Id>> storeToUserIds = new Map<Id, List<Id>>();
        Set<Id> allPartnerUserIds = new Set<Id>();
        for (User u : partnerUsers) {
            Id storeId = u.Contact.AccountId;
            if (!storeToUserIds.containsKey(storeId)) {
                storeToUserIds.put(storeId, new List<Id>());
            }
            storeToUserIds.get(storeId).add(u.Id);
            allPartnerUserIds.add(u.Id);
        }

        // Build map: Customer Account Id -> Set of Partner User Ids who need access
        Map<Id, Set<Id>> customerToUserIds = new Map<Id, Set<Id>>();
        for (Secondary_Invoice__c inv : invoices) {
            if (inv.Store__c != null && inv.Customer__c != null && storeToUserIds.containsKey(inv.Store__c)) {
                if (!customerToUserIds.containsKey(inv.Customer__c)) {
                    customerToUserIds.put(inv.Customer__c, new Set<Id>());
                }
                customerToUserIds.get(inv.Customer__c).addAll(storeToUserIds.get(inv.Store__c));
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
                        System.debug('SecondaryInvoiceSharingHandler - Error sharing Customer Account ' +
                            newShares[i].AccountId + ' with User ' + newShares[i].UserOrGroupId +
                            ': ' + err.getStatusCode() + ' - ' + err.getMessage());
                    }
                }
            }
        }
    }
}