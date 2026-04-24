public class PriceBookTriggerHandler {

    public static void handle(List<Price_Book__c> newRecords, Map<Id, Price_Book__c> oldMap) {
        // Collect Price Books where Customer__c changed or is newly set
        List<Price_Book__c> relevantPriceBooks = new List<Price_Book__c>();

        for (Price_Book__c pb : newRecords) {
            Price_Book__c oldPb = oldMap != null ? oldMap.get(pb.Id) : null;

            Boolean isInsert = (oldPb == null);
            Boolean customerChanged = (!isInsert && pb.Customer__c != oldPb.Customer__c);

            if (pb.Customer__c != null && (isInsert || customerChanged)) {
                relevantPriceBooks.add(pb);
            }
        }

        if (relevantPriceBooks.isEmpty()) return;

        sharePriceBooksWithPartners(relevantPriceBooks);
    }

    public static void sharePriceBooksWithPartners(List<Price_Book__c> priceBooks) {
        // Step 1: Collect Customer (Store/Distributor) Account Ids
        Set<Id> storeAccountIds = new Set<Id>();
        for (Price_Book__c pb : priceBooks) {
            if (pb.Customer__c != null) {
                storeAccountIds.add(pb.Customer__c);
            }
        }

        // Step 2: Find active Partner Community users linked to those accounts
        List<User> partnerUsers = [
            SELECT Id, Contact.AccountId
            FROM User
            WHERE Contact.AccountId IN :storeAccountIds
            AND IsActive = true
            AND Profile.UserLicense.Name = 'Partner Community'
        ];

        if (partnerUsers.isEmpty()) return;

        // Step 3: Map AccountId -> Partner User Ids
        Map<Id, List<Id>> accountToUserIds = new Map<Id, List<Id>>();
        for (User u : partnerUsers) {
            Id accId = u.Contact.AccountId;
            if (!accountToUserIds.containsKey(accId)) {
                accountToUserIds.put(accId, new List<Id>());
            }
            accountToUserIds.get(accId).add(u.Id);
        }

        // Step 4: Build Price_Book__Share records
        List<Price_Book__Share> sharesToInsert = new List<Price_Book__Share>();

        for (Price_Book__c pb : priceBooks) {
            List<Id> userIds = accountToUserIds.get(pb.Customer__c);
            if (userIds == null) continue;

            for (Id userId : userIds) {
                sharesToInsert.add(new Price_Book__Share(
                    ParentId    = pb.Id,
                    UserOrGroupId = userId,
                    AccessLevel = 'Read',       // adjust to 'Edit' if needed
                    RowCause    = Schema.Price_Book__Share.RowCause.Manual
                ));
            }
        }

        if (!sharesToInsert.isEmpty()) {
            // Use Database.insert to avoid duplicate share errors
            Database.SaveResult[] results = Database.insert(sharesToInsert, false);
            for (Database.SaveResult sr : results) {
                if (!sr.isSuccess()) {
                    for (Database.Error err : sr.getErrors()) {
                        // DUPLICATE_VALUE is expected and safe to ignore
                        if (err.getStatusCode() != StatusCode.DUPLICATE_VALUE) {
                            System.debug('PriceBook Share Error: ' + err.getMessage());
                        }
                    }
                }
            }
        }
    }
}