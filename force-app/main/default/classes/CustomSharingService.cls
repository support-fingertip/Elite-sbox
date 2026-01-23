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
            insert shareRecords;
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
            try {
                insert shares;
            } catch (Exception e) {
                System.debug('Error inserting account shares: ' + e.getMessage());
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
    /**-----------------------------Customer Replacement-----------------------------------------**/ 
    public static void customerReplacement(Map<String, String> oldPrimaryCustomerToNewMap, Map<String, String> oldSubStockiestToNewSubStockiestMap) {
        
        // Step 1: Product Mapping Cloning
        List<Product_Mapping__c> clonedMappings = new List<Product_Mapping__c>();
        
        String fields = 'Exectuive__c, Primary_Customer__c, Sub_Stockiest__c, Customer__c, Chanel__c,' +
            'Area__c, PDP_Name__c, PDP_Day__c, Parent_Depot__c, Child_Depot__c, Payment_Term__c,' +
            'Credit_Description__c, Inco_Terms__c, Order_Type__c, Distribution_Channel__c,' +
            'Sales_Office__c, Division__c,Customer_Type__c,Secondary_Customer_Type__c';
        
        //Primary Customer Replacement
        if (!oldPrimaryCustomerToNewMap.isEmpty()) {
            Set<String> oldCustomerIdStrings = oldPrimaryCustomerToNewMap.keySet();
            List<Id> oldCustomerIds = new List<Id>();
            
            for (String idStr : oldCustomerIdStrings) {
                if (Id.valueOf(idStr) != null) {
                    oldCustomerIds.add((Id)idStr);
                }
            }
            
            // Fetch mappings where Customer__c or Primary_Customer__c match replaced customers
            String query = 'SELECT ' + fields +
                ' FROM Product_Mapping__c ' +
                ' WHERE Customer__c IN :oldCustomerIdStrings OR Primary_Customer__c IN :oldCustomerIdStrings';
            
            List<Product_Mapping__c> allMappings = Database.query(query);
            List<Product_Mapping__c> clonedPrimaryMappings = new List<Product_Mapping__c>();
            
            // Exetives Productmapping for that primary customer
            for (Product_Mapping__c oldMap : allMappings) {
                Boolean isMapped = false;
                Product_Mapping__c newMap = cloneMapping(oldMap);
                if (oldMap.Customer__c != null && oldPrimaryCustomerToNewMap.containsKey(oldMap.Customer__c) && oldMap.Customer_Type__c == 'Primary Customer') 
                {
                    String newCustomer = oldPrimaryCustomerToNewMap.get(oldMap.Customer__c);
                    newMap.Customer__c = newCustomer;
                    newMap.Cloning_From_Customer_Deactivation__c = true;
                    clonedPrimaryMappings.add(newMap);
                }
            }
            
            
            
            
            List<Employee_Customer_Assignment__c> clonedDSMPrimaryMappings = new List<Employee_Customer_Assignment__c>();
            
            list<Employee_Customer_Assignment__c> EmployeeCustomerAssignment = [select Id,Name,Employee__c,Executive__c,Customer__c
                                                                               from Employee_Customer_Assignment__c where Customer__c =:oldCustomerIdStrings ];
            for(Employee_Customer_Assignment__c oldMap: EmployeeCustomerAssignment)
            {
                if (oldMap.Customer__c != null && oldPrimaryCustomerToNewMap.containsKey(oldMap.Customer__c)) {
                    Employee_Customer_Assignment__c newMap = new Employee_Customer_Assignment__c();
                    newMap.Customer__c = oldPrimaryCustomerToNewMap.get(oldMap.Customer__c);
                    newMap.Executive__c = oldMap.Executive__c;
                    newMap.Cloned_From_Customer_Deactivation__c = true;
                    newMap.Employee__c = oldMap.Employee__c;
                    clonedDSMPrimaryMappings.add(newMap);
                }
            }
            
               
            // Primary Mappings Cloning DSM
            if (!clonedDSMPrimaryMappings.isEmpty()) {
                database.insert(clonedDSMPrimaryMappings,false);
            }
            
            // Primary Mappings Cloning first 
            if (!clonedPrimaryMappings.isEmpty()) {
                database.insert(clonedPrimaryMappings,false);
            } 
            
            
            List<Product_Mapping__c> clonedRetailerMappings = new List<Product_Mapping__c>();
            //Reailers and Substociest cloning for the new primary customer   
            for (Product_Mapping__c oldMap : allMappings) {
                Product_Mapping__c newMap = cloneMapping(oldMap);
                if (oldMap.Primary_Customer__c != null && oldPrimaryCustomerToNewMap.containsKey(oldMap.Primary_Customer__c)
                   && oldMap.Customer_Type__c == 'Secondary Customer') {
                    String newPrimaryCustomer = oldPrimaryCustomerToNewMap.get(oldMap.Primary_Customer__c);
                    newMap.Primary_Customer__c = newPrimaryCustomer;
                    newMap.Cloning_From_Customer_Deactivation__c = true;
                    clonedRetailerMappings.add(newMap);
                }
            }
            
            
           
            // Primary Mappings Cloning
            if (!clonedRetailerMappings.isEmpty()) {
                database.insert(clonedRetailerMappings,false);
            }    
        }
        
        //Sub stociest Replacement
        Map<String, String> subStockiestToPrimaryMap = new Map<String, String>(); 
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
            
            // Step 2: Query old mappings for Sub Stockists
            List<Product_Mapping__c> oldSubMappings = Database.query(
                'SELECT ' + fields +
                ' FROM Product_Mapping__c ' +
                'WHERE Customer__c IN :oldSubStockiestIds ' +
                'OR Sub_Stockiest__c IN :oldSubStockiestIds'
            );
            
            // Case 1: Executive Product mapping (Customer is the Sub Stockist)
            List<Product_Mapping__c> clonedSubstockiestMappings = new List<Product_Mapping__c>();
            for (Product_Mapping__c oldMap : oldSubMappings) {
                Boolean isMapped = false;
                Product_Mapping__c newMap = cloneMapping(oldMap);
                if (oldMap.Customer__c != null && oldSubStockiestToNewSubStockiestMap.containsKey(oldMap.Customer__c) &&
                  oldMap.Customer_Type__c == 'Secondary Customer' &&  oldMap.Secondary_Customer_Type__c == 'Sub Stockiest') {
                    String newCustomer = oldSubStockiestToNewSubStockiestMap.get(oldMap.Customer__c);
                    newMap.Customer__c = newCustomer;
                    clonedSubstockiestMappings.add(newMap);
                }
            }
            
            //Substockiest Mapping insert
            if (!clonedSubstockiestMappings.isEmpty()) {
                database.insert(clonedSubstockiestMappings,false);
            }
            
            
            List<Product_Mapping__c> clonedSubstockiestReatilersMappings = new List<Product_Mapping__c>();
            for (Product_Mapping__c oldMap : oldSubMappings) {
                Boolean isMapped = false;
                Product_Mapping__c newMap = cloneMapping(oldMap);
                // Case 2: Sub Stockist Retailers
                if (oldMap.Sub_Stockiest__c != null && oldSubStockiestToNewSubStockiestMap.containsKey(oldMap.Sub_Stockiest__c)
                   && oldMap.Customer_Type__c == 'Secondary Customer' &&  oldMap.Secondary_Customer_Type__c != 'Sub Stockiest') {
                    String newSubStockiest = oldSubStockiestToNewSubStockiestMap.get(oldMap.Sub_Stockiest__c);
                    String newPrimary = subStockiestToPrimaryMap.get(newSubStockiest);
                    
                    if (String.isNotBlank(newPrimary)) {
                        newMap.Sub_Stockiest__c = newSubStockiest;
                        newMap.Primary_Customer__c = newPrimary;
                        newMap.Cloning_From_Customer_Deactivation__c = true;
                        clonedSubstockiestReatilersMappings.add(newMap);
                    }
                }
            }
            
            //Retailers under Substoiest
            if (!clonedSubstockiestReatilersMappings.isEmpty()) {
                database.insert(clonedSubstockiestReatilersMappings,false);
            }
        }
        
        
        // Step 2: Beat and Beat Items Replacement
        List<Child_beat__c> clonedBeats = new List<Child_beat__c>();
        Map<Id, Id> oldBeatIdToNewBeatIdMap = new Map<Id, Id>();
        
        Set<String> affectedPrimaryIds = oldPrimaryCustomerToNewMap.keySet();
        Set<String> affectedSubStockiestIds = oldSubStockiestToNewSubStockiestMap.keySet();
        
        List<Child_beat__c> oldBeats = [
            SELECT Id, Name, Primary_Customer__c, Sub_Stockist__c, Order_Number__c, OwnerId,Beat_Type__c,Active__c,
            (SELECT Account__c, Order_Number__c,Active__c FROM Junction_Beats__r)
            FROM Child_beat__c
            WHERE Primary_Customer__c IN :affectedPrimaryIds
            OR Sub_Stockist__c IN :affectedSubStockiestIds
        ];
        
        for (Child_beat__c oldBeat : oldBeats) {
            Id newPrimaryId;
            Id newSubStockiestId;
            
            // if this is a Primary customer replacement
            if (oldPrimaryCustomerToNewMap.containsKey(oldBeat.Primary_Customer__c)) {
                newPrimaryId = oldPrimaryCustomerToNewMap.get(oldBeat.Primary_Customer__c);
            }
            
            // if this is a Sub Stockist replacement
            if (oldSubStockiestToNewSubStockiestMap.containsKey(oldBeat.Sub_Stockist__c)) {
                newSubStockiestId = oldSubStockiestToNewSubStockiestMap.get(oldBeat.Sub_Stockist__c);
                
                // Lookup the new primary customer for this sub stockist (from Product Mappings)
                Id mappedPrimary = subStockiestToPrimaryMap.get(newSubStockiestId);
                if (mappedPrimary != null) {
                    newPrimaryId = mappedPrimary;
                }
            }
            if( newPrimaryId != null )
            {
                Child_beat__c newBeat = new Child_beat__c();
                newBeat.Name = oldBeat.Name;
                newBeat.Cloned_From_Customer_Deactivation__c = true;
                newBeat.Primary_Customer__c = newPrimaryId;
                newBeat.Sub_Stockist__c = newSubStockiestId != null ? newSubStockiestId : oldBeat.Sub_Stockist__c;
                newBeat.Order_Number__c = oldBeat.Order_Number__c;
                newBeat.Active__c =  oldBeat.Active__c ;
                newBeat.Beat_Type__c =  oldBeat.Beat_Type__c;
                newBeat.Old_Beat_Id_Back_End_Purpose__c = oldBeat.Id;//just for map creation
                newBeat.OwnerId = oldBeat.OwnerId;
                clonedBeats.add(newBeat);
            }
            
        }
        
        // Insert cloned beats
        if (!clonedBeats.isEmpty()) {
            database.insert(clonedBeats,false);
            
            // Map old beat to new beat Id
            for (Child_beat__c inserted : clonedBeats) {
                if (String.isNotBlank(inserted.Old_Beat_Id_Back_End_Purpose__c)) {
                    oldBeatIdToNewBeatIdMap.put(Id.valueOf(inserted.Old_Beat_Id_Back_End_Purpose__c), inserted.Id);
                }
            }
        }
        
        // Step 4: Clone Junction Beat records
        List<Junction_Beat__c> junctionsToInsert = new List<Junction_Beat__c>();
        
        for (Child_beat__c oldBeat : oldBeats) {
            Id newBeatId = oldBeatIdToNewBeatIdMap.get(oldBeat.Id);
            if (newBeatId == null) continue;
            
            for (Junction_Beat__c jb : oldBeat.Junction_Beats__r) {
                Junction_Beat__c newJb = new Junction_Beat__c();
                newJb.Child_Beat__c = newBeatId;
                newJb.Cloned_From_Customer_Deactivation__c = true;
                newJb.Account__c = jb.Account__c;
                newJb.Active__c = jb.Active__c;
                newJb.Order_Number__c = jb.Order_Number__c;
                junctionsToInsert.add(newJb);
            }
        }
        
        if (!junctionsToInsert.isEmpty()) {
            database.insert(junctionsToInsert,false);
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