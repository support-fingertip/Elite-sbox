public class CustomSharingService {
    public static void shareRecords(String objectType,Map<Id, List<Id>> recordToUserMap, String accessLevel) {
        if ( recordToUserMap.isEmpty() || String.isEmpty(objectType) || String.isEmpty(accessLevel)) {
            return;
        }
        List<SObject> shareRecords = new List<SObject>();
        Schema.SObjectType shareSObjectType = Schema.getGlobalDescribe().get(objectType);
        
        for (Id recordId : recordToUserMap.keySet()) {
            for (Id userId : recordToUserMap.get(recordId)) {
                SObject shareRecord = shareSObjectType.newSObject();
                if(objectType =='AccountShare')
                {
                    shareRecord.put('AccountId', recordId);
                    shareRecord.put('AccountAccessLevel', accessLevel);
                    shareRecord.put('OpportunityAccessLevel', accessLevel);
                }
                else
                {
                    shareRecord.put('ParentId', recordId);
                    shareRecord.put('AccessLevel', accessLevel);
                }
                shareRecord.put('UserOrGroupId', userId);
                
                shareRecords.add(shareRecord);
            }
        }
        
        if (!shareRecords.isEmpty()) {
            Database.insert(shareRecords, false);
        }
        
    }
    
    public static void linkFilesToRecords(Set<String> uniqueFileIds, Map<String, Id> recordIdMap) {
        if (uniqueFileIds == null || uniqueFileIds.isEmpty()) {
            return;
        }
        
        List<ContentDocument> files = [
            SELECT Id, Description 
            FROM ContentDocument 
            WHERE Description IN :uniqueFileIds
        ];
        if(!files.isEmpty())
        {
            Map<Id, Id> fileToRecordMap = new Map<Id, Id>();
            for (ContentDocument file : files) {
                if (recordIdMap.containsKey(file.Description)) {
                    fileToRecordMap.put(file.Id, recordIdMap.get(file.Description));
                }
            }
            
            // Query existing ContentDocumentLinks to avoid duplicates
            List<ContentDocumentLink> existingLinks = [
                SELECT ContentDocumentId, LinkedEntityId 
                FROM ContentDocumentLink 
                WHERE ContentDocumentId IN :fileToRecordMap.keySet()
                AND LinkedEntityId IN :fileToRecordMap.values()
            ];
            
            Set<String> existingPairs = new Set<String>();
            for (ContentDocumentLink link : existingLinks) {
                existingPairs.add(link.ContentDocumentId + '-' + link.LinkedEntityId);
            }
            
            List<ContentDocumentLink> fileLinksToInsert = new List<ContentDocumentLink>();
            
            for (ContentDocument file : files) {
                Id linkedEntityId = recordIdMap.get(file.Description);
                String pairKey = file.Id + '-' + linkedEntityId;
                if (!existingPairs.contains(pairKey)) {
                    fileLinksToInsert.add(new ContentDocumentLink(
                        ContentDocumentId = file.Id,
                        LinkedEntityId = linkedEntityId,
                        ShareType = 'V',
                        Visibility = 'AllUsers'
                    ));
                }
            }
            
            if (!fileLinksToInsert.isEmpty()) {
                database.insert(fileLinksToInsert,false);
            }
        }
        
        
    }
    
    //Account Sharing
    public static AccountShare buildAccountShare(Id accountId, Id userId) {
        return new AccountShare(
            AccountId = accountId,
            UserOrGroupId = userId,
            AccountAccessLevel = 'Edit',
            OpportunityAccessLevel = 'Read',
            CaseAccessLevel = 'Read',
            RowCause = Schema.AccountShare.RowCause.Manual
        );
    }
    
    public static void shareAccounts(List<AccountShare> shares) {
        if (!shares.isEmpty()) {
            List<Database.SaveResult> results = Database.insert(shares, false);
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    for (Database.Error err : results[i].getErrors()) {
                        System.debug('Error inserting account share for AccountId: ' + shares[i].AccountId +
                            ', UserOrGroupId: ' + shares[i].UserOrGroupId + ' - ' + err.getStatusCode() + ': ' + err.getMessage());
                    }
                }
            }
        }
    }
    
    //Remove Sharing
    public static void removeAccountSharesWithMap(Map<Id, List<Id>> accountToUsersToRemove) {
        if (accountToUsersToRemove == null || accountToUsersToRemove.isEmpty()) return;
        
        Set<Id> accountIds = accountToUsersToRemove.keySet();
        Set<Id> allUserIds = new Set<Id>();
        for (List<Id> users : accountToUsersToRemove.values()) {
            allUserIds.addAll(users);
        }
        
        List<AccountShare> sharesToDelete = [
            SELECT Id, AccountId, UserOrGroupId
            FROM AccountShare
            WHERE AccountId IN :accountIds
            AND UserOrGroupId IN :allUserIds
            AND RowCause NOT IN ('Owner', 'ImplicitParent', 'Rule')
        ];
        
        List<AccountShare> validSharesToDelete = new List<AccountShare>();
        for (AccountShare share : sharesToDelete) {
            if (accountToUsersToRemove.containsKey(share.AccountId) &&
                accountToUsersToRemove.get(share.AccountId).contains(share.UserOrGroupId)) {
                    validSharesToDelete.add(share);
                }
        }
        
        if (!validSharesToDelete.isEmpty()) {
            try {
                delete validSharesToDelete;
            } catch (Exception e) {
                System.debug('Error deleting account shares: ' + e.getMessage());
            }
        }
    }
    
    
    //Remove Account sharing Based on Pair
    public static void removeAccountWithPairShares(Set<Id> accountIds, Set<Id> userIds, Set<String> pairsToRemove) {
        List<AccountShare> allShares = [
            SELECT Id, AccountId, UserOrGroupId
            FROM AccountShare
            WHERE AccountId IN :accountIds
            AND UserOrGroupId IN :userIds
            AND RowCause NOT IN ('Owner', 'ImplicitParent', 'Rule')
        ];
        
        List<AccountShare> sharesToDelete = new List<AccountShare>();
        
        for (AccountShare share : allShares) {
            String key = share.AccountId + '_' + share.UserOrGroupId;
            if (pairsToRemove.contains(key)) {
                sharesToDelete.add(share);
            }
        }
        
        if (!sharesToDelete.isEmpty()) {
            delete sharesToDelete;
        }
    }
    
    
    
   
    /**--------------------------------Employee Replacement--------------------------------------**/
    public static void employeeReplacement(Map<String, String> OldEmployeewithNewEmployeeMap) {
        if (OldEmployeewithNewEmployeeMap == null || OldEmployeewithNewEmployeeMap.isEmpty()) return;
        
        Set<String> oldUserIds = OldEmployeewithNewEmployeeMap.keySet();
        
        /**---------- Step 1:Product Mappings ----------------**/
        List<Product_Mapping__c> oldMappings = [
            SELECT Exectuive__c, Primary_Customer__c, Sub_Stockiest__c, Customer__c, Chanel__c,
            Area__c, PDP_Name__c, PDP_Day__c, Parent_Depot__c, Child_Depot__c, Payment_Term__c, 
            Credit_Description__c, Inco_Terms__c, Order_Type__c, Distribution_Channel__c, 
            Sales_Office__c, Division__c,Customer_Type__c,Secondary_Customer_Type__c
            FROM Product_Mapping__c
            WHERE Exectuive__c IN :oldUserIds
        ];
        
        List<Product_Mapping__c> clonedMappings = new List<Product_Mapping__c>();
  
        
        List<Product_Mapping__c> clonedPrimaryMappings = new List<Product_Mapping__c>();
        List<Product_Mapping__c> clonedSubstockiestMappings = new List<Product_Mapping__c>();
        List<Product_Mapping__c> clonedSecondaryMappings = new List<Product_Mapping__c>();
        
        //Product mapping Mappings
        for (Product_Mapping__c oldMap : oldMappings) {
            String newExecutiveId = OldEmployeewithNewEmployeeMap.get(oldMap.Exectuive__c);
            if (String.isNotBlank(newExecutiveId)) {
                Product_Mapping__c newMap = new Product_Mapping__c();
                // Clone field values
                newMap.Exectuive__c = newExecutiveId;
                newMap.Primary_Customer__c = oldMap.Primary_Customer__c;
                newMap.Sub_Stockiest__c = oldMap.Sub_Stockiest__c;
                newMap.Customer__c = oldMap.Customer__c;
                newMap.Chanel__c = oldMap.Chanel__c;
                newMap.Area__c = oldMap.Area__c;
                newMap.PDP_Name__c = oldMap.PDP_Name__c;
                newMap.PDP_Day__c = oldMap.PDP_Day__c;
                newMap.Parent_Depot__c = oldMap.Parent_Depot__c;
                newMap.Child_Depot__c = oldMap.Child_Depot__c;
                newMap.Payment_Term__c = oldMap.Payment_Term__c;
                newMap.Credit_Description__c = oldMap.Credit_Description__c;
                newMap.Inco_Terms__c = oldMap.Inco_Terms__c;
                newMap.Order_Type__c = oldMap.Order_Type__c;
                newMap.Distribution_Channel__c = oldMap.Distribution_Channel__c;
                newMap.Sales_Office__c = oldMap.Sales_Office__c;
                newMap.Division__c = oldMap.Division__c;
                newMap.Cloned_From_Employee_Replacement__c = true;
                
                if (oldMap.Customer_Type__c == 'Primary Customer') {
                    clonedPrimaryMappings.add(newMap);
                } else if (oldMap.Customer_Type__c == 'Secondary Customer' && oldMap.Secondary_Customer_Type__c == 'Sub Stockiest') {
                    clonedSubstockiestMappings.add(newMap);
                } else if (oldMap.Customer_Type__c == 'Secondary Customer' &&  oldMap.Secondary_Customer_Type__c != 'Sub Stockiest') {
                    clonedSecondaryMappings.add(newMap);
                }
                
            }
        }
        
        //Primary Mappings
        if (!clonedPrimaryMappings.isEmpty()) {
            database.insert(clonedPrimaryMappings,false);
        }
                
        //Primary Customer DSM Mappings
        List<Employee_Customer_Assignment__c> clonedDSMPrimaryMappings = new List<Employee_Customer_Assignment__c>();
        list<Employee_Customer_Assignment__c> EmployeeDSMCustomerAssignment = [select Id,Name,Employee__c,Executive__c,Customer__c
                                                                               from Employee_Customer_Assignment__c where Executive__c =:oldUserIds ];
        for(Employee_Customer_Assignment__c oldMap: EmployeeDSMCustomerAssignment)
        {
            String newExecutiveId = OldEmployeewithNewEmployeeMap.get(oldMap.Executive__c);
            if (String.isNotBlank(newExecutiveId)) {
                Employee_Customer_Assignment__c newMap = new Employee_Customer_Assignment__c();
                newMap.Customer__c = oldMap.Customer__c;
                newMap.Cloned_From_Employee_Replacement__c = true;
                newMap.Executive__c = newExecutiveId;
                clonedDSMPrimaryMappings.add(newMap);
            }
        }
        if (!clonedDSMPrimaryMappings.isEmpty()) {
            database.insert(clonedDSMPrimaryMappings,false);
        }

        
        //Sub stockiest Mappings
        if (!clonedSubstockiestMappings.isEmpty()) {
            database.insert(clonedSubstockiestMappings,false);
        }
        
        //Retailers mappings
        if (!clonedSecondaryMappings.isEmpty()) {
            database.insert(clonedSecondaryMappings,false);
        }
        
        
        
        /**-----------Step 2: Beat and Beat Items Cloning -------------**/
        Database.executeBatch(new BeatCloneBatch(OldEmployeewithNewEmployeeMap), 50);
        
        
        /**--------------Step 3: PJP Cloning------------ **/
        list<Calendar_beat__c> OldPJPList = [select Id,Name,User__c,Active__c,Start_Month__c,Next_Start_Date__c,Recurring_Frequency__c from Calendar_beat__c where User__c IN :oldUserIds ];
        
        list<Calendar_beat__c> NewPJPToInsert = new  list<Calendar_beat__c> ();
        for (Calendar_beat__c Oldpjp : OldPJPList) {
            String newExecutiveId = OldEmployeewithNewEmployeeMap.get(Oldpjp.User__c);
            if (String.isNotBlank(newExecutiveId)) {
                Calendar_beat__c newPJP = new  Calendar_beat__c();
                newPJP.User__c = newExecutiveId;
                newPJP.Active__c = true;
                newPJP.Cloned_From_Employee_Replacement__c = true;
                newPJP.Start_Month__c = Oldpjp.Start_Month__c;
                newPJP.Next_Start_Date__c = Oldpjp.Next_Start_Date__c;
                newPJP.Recurring_Frequency__c = Oldpjp.Recurring_Frequency__c;
                NewPJPToInsert.add(newPJP);
            }
        }
        if (!NewPJPToInsert.isEmpty()) {
            database.insert(NewPJPToInsert,false);
        }
        
        /**--------------Step 4: Approvers Replacement-----------**/
        System.enqueueJob(new ApproverReplacementQueue(OldEmployeewithNewEmployeeMap, oldUserIds));

        /**-------------Step 5: update subordinate user roles--------------**/
        
        if (!OldEmployeewithNewEmployeeMap.isEmpty()) {
            // Async call to avoid mixed DML
            updateUserRoleHierarchy(OldEmployeewithNewEmployeeMap);
        }
        
    }
    

    
    @future
    public static void updateUserRoleHierarchy(Map<String, String> OldEmployeewithNewEmployeeMap) {
        Set<String> oldUserIds = OldEmployeewithNewEmployeeMap.keySet();
                // Step 1: Get old and new user role mappings
        Map<Id, Id> oldToNewUserRoleMap = new Map<Id, Id>();
        
        List<User> userList = [SELECT Id, UserRoleId FROM User  WHERE Id IN :oldUserIds OR Id IN :OldEmployeewithNewEmployeeMap.values()];
        
        Map<Id, Id> userIdToRoleId = new Map<Id, Id>();
        for (User u : userList) {
            if (u.UserRoleId != null) {
                userIdToRoleId.put(u.Id, u.UserRoleId);
            }
        }
        
        for (Id oldUserId : oldUserIds) {
            Id oldRoleId = userIdToRoleId.get(oldUserId);
            Id newUserId = OldEmployeewithNewEmployeeMap.get(oldUserId);
            Id newRoleId = userIdToRoleId.get(newUserId);
            
            if (oldRoleId != null && newRoleId != null) {
                oldToNewUserRoleMap.put(oldRoleId, newRoleId);
            }
        }
        
        // Step 2: Find subordinate roles and update their parent role
        List<UserRole> subordinateRolesToUpdate = [
            SELECT Id, Name, ParentRoleId 
            FROM UserRole 
            WHERE ParentRoleId IN :oldToNewUserRoleMap.keySet()
        ];
        
        for (UserRole ur : subordinateRolesToUpdate) {
            if(oldToNewUserRoleMap.containsKey(ur.ParentRoleId))
            {
                ur.ParentRoleId = oldToNewUserRoleMap.get(ur.ParentRoleId);
            }
        }
        
        if (!subordinateRolesToUpdate.isEmpty()) {
            database.update(subordinateRolesToUpdate,false);
        }
        
    }
    /**--------------------------------Employee Transfer (in-place)-----------------------------**
     * Transfers all records of an old user to a new user WITHOUT cloning.
     * Updates existing Product Mappings, Employee Customer Assignments, Beats, and PJPs in place.
     * Child_beat__c.User__c AND Child_beat__c.OwnerId are both updated to the new user.
     * Junction_Beat__c is ControlledByParent, so its ownership follows automatically.
     */
    public static void employeeTransfer(Map<String, String> oldToNewUserMap) {
        if (oldToNewUserMap == null || oldToNewUserMap.isEmpty()) return;

        Set<String> oldUserIds = oldToNewUserMap.keySet();

        /**---------- Step 1: Transfer Product Mappings ----------**/
        List<Product_Mapping__c> mappingsToTransfer = [
            SELECT Id, Exectuive__c
            FROM Product_Mapping__c
            WHERE Exectuive__c IN :oldUserIds
        ];
        for (Product_Mapping__c pm : mappingsToTransfer) {
            String newExecutiveId = oldToNewUserMap.get(pm.Exectuive__c);
            if (String.isNotBlank(newExecutiveId)) {
                pm.Exectuive__c = newExecutiveId;
            }
        }
        if (!mappingsToTransfer.isEmpty()) {
            System.debug('Employee Transfer - Updating ' + mappingsToTransfer.size() + ' Product Mappings');
            List<Database.SaveResult> pmResults = Database.update(mappingsToTransfer, false);
            for (Integer i = 0; i < pmResults.size(); i++) {
                if (!pmResults[i].isSuccess()) {
                    for (Database.Error err : pmResults[i].getErrors()) {
                        System.debug('Employee Transfer Error - Product Mapping Id: ' + mappingsToTransfer[i].Id + ' - ' + err.getStatusCode() + ': ' + err.getMessage());
                    }
                }
            }
        }

        /**---------- Step 2: Transfer Employee Customer Assignments ----------**/
        List<Employee_Customer_Assignment__c> assignmentsToTransfer = [
            SELECT Id, Executive__c
            FROM Employee_Customer_Assignment__c
            WHERE Executive__c IN :oldUserIds
        ];
        for (Employee_Customer_Assignment__c eca : assignmentsToTransfer) {
            String newExecutiveId = oldToNewUserMap.get(eca.Executive__c);
            if (String.isNotBlank(newExecutiveId)) {
                eca.Executive__c = newExecutiveId;
            }
        }
        if (!assignmentsToTransfer.isEmpty()) {
            System.debug('Employee Transfer - Updating ' + assignmentsToTransfer.size() + ' Employee Customer Assignments');
            List<Database.SaveResult> ecaResults = Database.update(assignmentsToTransfer, false);
            for (Integer i = 0; i < ecaResults.size(); i++) {
                if (!ecaResults[i].isSuccess()) {
                    for (Database.Error err : ecaResults[i].getErrors()) {
                        System.debug('Employee Transfer Error - Assignment Id: ' + assignmentsToTransfer[i].Id + ' - ' + err.getStatusCode() + ': ' + err.getMessage());
                    }
                }
            }
        }

        /**---------- Step 3: Transfer Beats (User__c + OwnerId) ----------**/
        List<Child_beat__c> beatsToTransfer = [
            SELECT Id, User__c, OwnerId
            FROM Child_beat__c
            WHERE OwnerId IN :oldUserIds OR User__c IN :oldUserIds
        ];
        for (Child_beat__c beat : beatsToTransfer) {
            String newUserId = null;
            if (beat.OwnerId != null && oldToNewUserMap.containsKey(beat.OwnerId)) {
                newUserId = oldToNewUserMap.get(beat.OwnerId);
            } else if (beat.User__c != null && oldToNewUserMap.containsKey(beat.User__c)) {
                newUserId = oldToNewUserMap.get(beat.User__c);
            }
            if (String.isNotBlank(newUserId)) {
                beat.User__c = newUserId;
                beat.OwnerId = newUserId;
            }
        }
        if (!beatsToTransfer.isEmpty()) {
            System.debug('Employee Transfer - Updating ' + beatsToTransfer.size() + ' Beats');
            List<Database.SaveResult> beatResults = Database.update(beatsToTransfer, false);
            for (Integer i = 0; i < beatResults.size(); i++) {
                if (!beatResults[i].isSuccess()) {
                    for (Database.Error err : beatResults[i].getErrors()) {
                        System.debug('Employee Transfer Error - Beat Id: ' + beatsToTransfer[i].Id + ' - ' + err.getStatusCode() + ': ' + err.getMessage());
                    }
                }
            }
        }

        /**---------- Step 4: Transfer PJPs (Calendar Beats) ----------**/
        // PJPTrigger only syncs OwnerId <- User__c on before insert, not on
        // update, so we must explicitly set both fields when transferring.
        List<Calendar_beat__c> pjpsToTransfer = [
            SELECT Id, User__c, OwnerId
            FROM Calendar_beat__c
            WHERE User__c IN :oldUserIds OR OwnerId IN :oldUserIds
        ];
        for (Calendar_beat__c pjp : pjpsToTransfer) {
            String newUserId = null;
            if (pjp.OwnerId != null && oldToNewUserMap.containsKey(pjp.OwnerId)) {
                newUserId = oldToNewUserMap.get(pjp.OwnerId);
            } else if (pjp.User__c != null && oldToNewUserMap.containsKey(pjp.User__c)) {
                newUserId = oldToNewUserMap.get(pjp.User__c);
            }
            if (String.isNotBlank(newUserId)) {
                pjp.User__c = newUserId;
                pjp.OwnerId = newUserId;
            }
        }
        if (!pjpsToTransfer.isEmpty()) {
            System.debug('Employee Transfer - Updating ' + pjpsToTransfer.size() + ' PJPs');
            List<Database.SaveResult> pjpResults = Database.update(pjpsToTransfer, false);
            for (Integer i = 0; i < pjpResults.size(); i++) {
                if (!pjpResults[i].isSuccess()) {
                    for (Database.Error err : pjpResults[i].getErrors()) {
                        System.debug('Employee Transfer Error - PJP Id: ' + pjpsToTransfer[i].Id + ' - ' + err.getStatusCode() + ': ' + err.getMessage());
                    }
                }
            }
        }

        /**---------- Step 5: Approvers Replacement ----------**/
        System.enqueueJob(new ApproverReplacementQueue(oldToNewUserMap, oldUserIds));

        /**---------- Step 6: User Role Hierarchy Update ----------**/
        updateUserRoleHierarchy(oldToNewUserMap);
    }

    /**-----------------------------Customer Replacement-----------------------------------------**/
    public static void customerReplacement(Map<String, String> oldPrimaryCustomerToNewMap, Map<String, String> oldSubStockiestToNewSubStockiestMap) {

        // Step 1: Product Mapping Transfer (update existing records instead of cloning)
        List<Product_Mapping__c> mappingsToUpdate = new List<Product_Mapping__c>();

        //Primary Customer Replacement
        if (!oldPrimaryCustomerToNewMap.isEmpty()) {
            Set<String> oldCustomerIdStrings = oldPrimaryCustomerToNewMap.keySet();

            // Fetch mappings where Customer__c or Primary_Customer__c match replaced customers
            List<Product_Mapping__c> allMappings = [
                SELECT Id, Customer__c, Primary_Customer__c, Sub_Stockiest__c, Customer_Type__c, Secondary_Customer_Type__c
                FROM Product_Mapping__c
                WHERE Customer__c IN :oldCustomerIdStrings OR Primary_Customer__c IN :oldCustomerIdStrings
            ];

            // Transfer Primary Customer mappings and Secondary Customer mappings to new customer
            for (Product_Mapping__c pm : allMappings) {
                Boolean changed = false;

                // Primary Customer: update Customer__c to new customer
                if (pm.Customer__c != null && oldPrimaryCustomerToNewMap.containsKey(pm.Customer__c) && pm.Customer_Type__c == 'Primary Customer') {
                    pm.Customer__c = oldPrimaryCustomerToNewMap.get(pm.Customer__c);
                    pm.Customer_Id__c = pm.Customer__c;
                    changed = true;
                }

                // Secondary Customers: update Primary_Customer__c to new primary customer
                if (pm.Primary_Customer__c != null && oldPrimaryCustomerToNewMap.containsKey(pm.Primary_Customer__c) && pm.Customer_Type__c == 'Secondary Customer') {
                    pm.Primary_Customer__c = oldPrimaryCustomerToNewMap.get(pm.Primary_Customer__c);
                    pm.Primary_Customer_Id__c = pm.Primary_Customer__c;
                    changed = true;
                }

                if (changed) {
                    mappingsToUpdate.add(pm);
                }
            }

            // Transfer Employee Customer Assignments to new customer
            List<Employee_Customer_Assignment__c> employeeAssignments = [
                SELECT Id, Customer__c
                FROM Employee_Customer_Assignment__c WHERE Customer__c IN :oldCustomerIdStrings
            ];
            List<Employee_Customer_Assignment__c> assignmentsToUpdate = new List<Employee_Customer_Assignment__c>();
            for (Employee_Customer_Assignment__c eca : employeeAssignments) {
                if (eca.Customer__c != null && oldPrimaryCustomerToNewMap.containsKey(eca.Customer__c)) {
                    eca.Customer__c = oldPrimaryCustomerToNewMap.get(eca.Customer__c);
                    eca.Customer_Id__c = eca.Customer__c;
                    assignmentsToUpdate.add(eca);
                }
            }

            // Update Employee Customer Assignments
            if (!assignmentsToUpdate.isEmpty()) {
                System.debug('Customer Transfer - Updating ' + assignmentsToUpdate.size() + ' Employee Customer Assignments');
                List<Database.SaveResult> ecaResults = database.update(assignmentsToUpdate, false);
                for (Integer i = 0; i < ecaResults.size(); i++) {
                    if (!ecaResults[i].isSuccess()) {
                        for (Database.Error err : ecaResults[i].getErrors()) {
                            System.debug('Customer Transfer Error - Assignment Id: ' + assignmentsToUpdate[i].Id + ' - ' + err.getStatusCode() + ': ' + err.getMessage());
                        }
                    }
                }
            }

            // Update Product Mappings
            if (!mappingsToUpdate.isEmpty()) {
                System.debug('Customer Transfer - Updating ' + mappingsToUpdate.size() + ' Product Mappings');
                List<Database.SaveResult> pmResults = database.update(mappingsToUpdate, false);
                for (Integer i = 0; i < pmResults.size(); i++) {
                    if (!pmResults[i].isSuccess()) {
                        for (Database.Error err : pmResults[i].getErrors()) {
                            System.debug('Customer Transfer Error - Mapping Id: ' + mappingsToUpdate[i].Id + ' - ' + err.getStatusCode() + ': ' + err.getMessage());
                        }
                    }
                }
            }
        }

        //Sub Stockiest Replacement
        Map<String, String> subStockiestToPrimaryMap = new Map<String, String>();
        List<Product_Mapping__c> subMappingsToUpdate = new List<Product_Mapping__c>();
        if (!oldSubStockiestToNewSubStockiestMap.isEmpty()) {

            List<String> newSubStockiestIds = oldSubStockiestToNewSubStockiestMap.values();
            Set<String> oldSubStockiestIds = oldSubStockiestToNewSubStockiestMap.keySet();

            // Step 1: Get Primary Customers for new Sub Stockists
            List<Product_Mapping__c> mappingsForNewSubs = [
                SELECT Primary_Customer__c, Sub_Stockiest__c, Customer__c
                FROM Product_Mapping__c
                WHERE Customer__c IN :newSubStockiestIds
                AND Secondary_Customer_Type__c = 'Sub Stockiest'
            ];

            for (Product_Mapping__c pm : mappingsForNewSubs) {
                if (pm.Customer__c != null && pm.Primary_Customer__c != null) {
                    subStockiestToPrimaryMap.put(pm.Customer__c, pm.Primary_Customer__c);
                }
            }

            // Step 2: Query existing mappings for Sub Stockists
            List<Product_Mapping__c> oldSubMappings = [
                SELECT Id, Customer__c, Sub_Stockiest__c, Primary_Customer__c, Customer_Type__c, Secondary_Customer_Type__c
                FROM Product_Mapping__c
                WHERE Customer__c IN :oldSubStockiestIds OR Sub_Stockiest__c IN :oldSubStockiestIds
            ];

            // Transfer Sub Stockist mappings to new customer
            for (Product_Mapping__c pm : oldSubMappings) {
                Boolean changed = false;

                // Case 1: Customer is the Sub Stockist itself
                if (pm.Customer__c != null && oldSubStockiestToNewSubStockiestMap.containsKey(pm.Customer__c) &&
                    pm.Customer_Type__c == 'Secondary Customer' && pm.Secondary_Customer_Type__c == 'Sub Stockiest') {
                    pm.Customer__c = oldSubStockiestToNewSubStockiestMap.get(pm.Customer__c);
                    pm.Customer_Id__c = pm.Customer__c;
                    changed = true;
                }

                // Case 2: Sub Stockist Retailers - update Sub_Stockiest__c and Primary_Customer__c
                if (pm.Sub_Stockiest__c != null && oldSubStockiestToNewSubStockiestMap.containsKey(pm.Sub_Stockiest__c)
                    && pm.Customer_Type__c == 'Secondary Customer' && pm.Secondary_Customer_Type__c != 'Sub Stockiest') {
                    String newSubStockiest = oldSubStockiestToNewSubStockiestMap.get(pm.Sub_Stockiest__c);
                    String newPrimary = subStockiestToPrimaryMap.get(newSubStockiest);

                    if (String.isNotBlank(newPrimary)) {
                        pm.Sub_Stockiest__c = newSubStockiest;
                        pm.Sub_Stockiest_Id__c = pm.Sub_Stockiest__c;
                        pm.Primary_Customer__c = newPrimary;
                        pm.Primary_Customer_Id__c = pm.Primary_Customer__c;
                        changed = true;
                    }
                }

                if (changed) {
                    subMappingsToUpdate.add(pm);
                }
            }

            // Update Sub Stockist mappings
            if (!subMappingsToUpdate.isEmpty()) {
                System.debug('Customer Transfer - Updating ' + subMappingsToUpdate.size() + ' Sub Stockist Mappings');
                List<Database.SaveResult> subResults = database.update(subMappingsToUpdate, false);
                for (Integer i = 0; i < subResults.size(); i++) {
                    if (!subResults[i].isSuccess()) {
                        for (Database.Error err : subResults[i].getErrors()) {
                            System.debug('Customer Transfer Error - Sub Mapping Id: ' + subMappingsToUpdate[i].Id + ' - ' + err.getStatusCode() + ': ' + err.getMessage());
                        }
                    }
                }
            }
        }
        
        
        // Step 2: Beat Transfer (update existing beats instead of cloning)
        Set<String> affectedPrimaryIds = oldPrimaryCustomerToNewMap.keySet();
        Set<String> affectedSubStockiestIds = oldSubStockiestToNewSubStockiestMap.keySet();

        List<Child_beat__c> oldBeats = [
            SELECT Id, Name, Primary_Customer__c, Sub_Stockist__c, Order_Number__c, OwnerId,Beat_Type__c,Active__c
            FROM Child_beat__c
            WHERE (Primary_Customer__c IN :affectedPrimaryIds
            OR Sub_Stockist__c IN :affectedSubStockiestIds)
            AND Active__c = true
        ];
        System.debug('Beat Transfer - Queried beats count: ' + oldBeats.size());

        List<Child_beat__c> beatsToUpdate = new List<Child_beat__c>();

        for (Child_beat__c beat : oldBeats) {
            Boolean changed = false;

            if (beat.Primary_Customer__c != null && oldPrimaryCustomerToNewMap.containsKey(beat.Primary_Customer__c)) {
                System.debug('Beat Transfer - Updating Primary_Customer__c on beat: ' + beat.Id + ' from ' + beat.Primary_Customer__c + ' to ' + oldPrimaryCustomerToNewMap.get(beat.Primary_Customer__c));
                beat.Primary_Customer__c = oldPrimaryCustomerToNewMap.get(beat.Primary_Customer__c);
                changed = true;
            }

            if (beat.Sub_Stockist__c != null && oldSubStockiestToNewSubStockiestMap.containsKey(beat.Sub_Stockist__c)) {
                String newSubStockiest = oldSubStockiestToNewSubStockiestMap.get(beat.Sub_Stockist__c);
                beat.Sub_Stockist__c = newSubStockiest;
                String mappedPrimary = subStockiestToPrimaryMap.get(newSubStockiest);
                if (mappedPrimary != null) {
                    beat.Primary_Customer__c = mappedPrimary;
                }
                changed = true;
            }

            if (changed) beatsToUpdate.add(beat);
        }

        System.debug('Beat Transfer - Beats to update count: ' + beatsToUpdate.size());
        if (!beatsToUpdate.isEmpty()) {
            List<Database.SaveResult> beatResults = database.update(beatsToUpdate, false);
            for (Integer i = 0; i < beatResults.size(); i++) {
                if (!beatResults[i].isSuccess()) {
                    for (Database.Error err : beatResults[i].getErrors()) {
                        System.debug('Beat Transfer Error - Beat Id: ' + beatsToUpdate[i].Id + ' - ' + err.getStatusCode() + ': ' + err.getMessage());
                    }
                }
            }
        }
        
    }
    
    // Reusable helper method to clone mapping
    public static Product_Mapping__c cloneMapping(Product_Mapping__c oldMap) {
        Product_Mapping__c newMap = new Product_Mapping__c();
        newMap.Exectuive__c = oldMap.Exectuive__c;
        newMap.Primary_Customer__c = oldMap.Primary_Customer__c;
        newMap.Sub_Stockiest__c = oldMap.Sub_Stockiest__c;
        newMap.Customer__c = oldMap.Customer__c;
        newMap.Chanel__c = oldMap.Chanel__c;
        newMap.Area__c = oldMap.Area__c;
        newMap.PDP_Name__c = oldMap.PDP_Name__c;
        newMap.PDP_Day__c = oldMap.PDP_Day__c;
        newMap.Parent_Depot__c = oldMap.Parent_Depot__c;
        newMap.Child_Depot__c = oldMap.Child_Depot__c;
        newMap.Payment_Term__c = oldMap.Payment_Term__c;
        newMap.Credit_Description__c = oldMap.Credit_Description__c;
        newMap.Inco_Terms__c = oldMap.Inco_Terms__c;
        newMap.Order_Type__c = oldMap.Order_Type__c;
        newMap.Distribution_Channel__c = oldMap.Distribution_Channel__c;
        newMap.Sales_Office__c = oldMap.Sales_Office__c;
        newMap.Division__c = oldMap.Division__c;
        return newMap;
    }
    
    public static void shareCustomerAccessToHierarchy(Id deactivatedUserId) {
        // Find the reporting manager of the deactivated user via Employee__c
        List<Employee__c> empList = [SELECT Id, Reporting_Manager__c FROM Employee__c WHERE User__c = :deactivatedUserId LIMIT 1];
        if (empList.isEmpty() || empList[0].Reporting_Manager__c == null) return;

        Id managerId = empList[0].Reporting_Manager__c;

        // Get all accounts accessible by the deactivated user via AccountShare
        List<AccountShare> existingShares = [
            SELECT AccountId FROM AccountShare
            WHERE UserOrGroupId = :deactivatedUserId
            AND RowCause = :Schema.AccountShare.RowCause.Manual
        ];

        Set<Id> accountIds = new Set<Id>();
        for (AccountShare share : existingShares) {
            accountIds.add(share.AccountId);
        }

        // Also get accounts from Employee_Customer_Assignment__c
        for (Employee_Customer_Assignment__c eca : [SELECT Customer__c FROM Employee_Customer_Assignment__c WHERE Executive__c = :deactivatedUserId]) {
            accountIds.add(eca.Customer__c);
        }

        // Also get accounts from Product_Mapping__c
        for (Product_Mapping__c pm : [SELECT Customer__c FROM Product_Mapping__c WHERE Exectuive__c = :deactivatedUserId]) {
            accountIds.add(pm.Customer__c);
        }

        if (accountIds.isEmpty()) return;

        // Create AccountShare records for the reporting manager
        List<AccountShare> sharesToInsert = new List<AccountShare>();
        Set<Id> existingAccountIds = new Set<Id>();
        for (AccountShare s : [SELECT AccountId FROM AccountShare WHERE AccountId IN :accountIds AND UserOrGroupId = :managerId]) {
            existingAccountIds.add(s.AccountId);
        }

        for (Id accId : accountIds) {
            if (!existingAccountIds.contains(accId)) {
                sharesToInsert.add(buildAccountShare(accId, managerId));
            }
        }

        if (!sharesToInsert.isEmpty()) {
            Database.insert(sharesToInsert, false);
        }
    }

    public static void deleteEmployeeOldClonedAssignments(set<Id> userIds)
    {
        list<Product_Mapping__c> clonedProductMappingToDelete = [select Id from Product_Mapping__c where Exectuive__c IN :userIds and
                                                                Cloned_From_Employee_Replacement__c = true];
        delete clonedProductMappingToDelete;
        
        list<Junction_Beat__c> clonedBeatItemsToDelete = [select Id from Junction_Beat__c WHERE 
                                                          Beat_OwnerId__c IN :userIds and Cloned_From_Employee_Replacement__c = true];
        delete clonedBeatItemsToDelete;
        
        List<Child_beat__c> clonedBeatToDelete = [
            SELECT Name, Primary_Customer__c, Sub_Stockist__c, Order_Number__c, OwnerId,
            (SELECT Account__c, Order_Number__c FROM Junction_Beats__r)
            FROM Child_beat__c
            WHERE OwnerId IN :userIds and Cloned_From_Employee_Replacement__c = true
        ];
        delete clonedBeatToDelete;
        
        list<Calendar_beat__c> clonedPJPToDelete = [select Id from Calendar_beat__c where User__c  IN :userIds and Cloned_From_Employee_Replacement__c = true];
        delete clonedPJPToDelete;
        
        
    }
    
    
}