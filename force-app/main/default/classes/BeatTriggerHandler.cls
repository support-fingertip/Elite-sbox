/*
*********************************************************
Apex Class Name    : BeatTriggerHandler
Created Date       : JUL 28, 2025
@description       : This class is used to handle logics for Beat Trigger
@author            : Mayuri Patel
Modification Log:
Ver 	Date 			Author 			Modification
1.0 	28-07-2025 		Mayuri Patel 	Initial Version
*********************************************************
*/
public without sharing class BeatTriggerHandler {
    
    public static void handleValidations(List<Child_beat__c> beats){
        
        Set<Id> exeIds = new Set<Id>();
        Set<Id> primaryCustomerIds = new Set<Id>();
        Set<Id> subStockiestCustomerIds = new Set<Id>();
        Set<Id> allRelatedUserIds = new Set<Id>();
        Set<Id> primaryBeatIds = new Set<Id>(); 
        
        Set<Id> exeIdsToRunValidations = new Set<Id>(); 
        
        for(Child_beat__c beat: beats){
            system.debug('entered beat');
            exeIds.add(beat.OwnerId);
            if(beat.Beat_Type__c == 'Secondary'){
                if(!beat.Payroll_Employee__c)allRelatedUserIds.add(beat.Manager_Id__c);
                if (beat.Primary_Customer__c != null) primaryCustomerIds.add(beat.Primary_Customer__c);
                if (beat.Sub_Stockist__c != null) subStockiestCustomerIds.add(beat.Sub_Stockist__c);
            }
            else if(beat.Beat_Type__c == 'Primary')
            {
                if(beat.Id != null) primaryBeatIds.add(beat.Id);   
            }
            
            if(beat.Cloned_From_Employee_Replacement__c == false && beat.Cloned_From_Customer_Deactivation__c == false)
            {
                exeIdsToRunValidations.add(beat.OwnerId);
            }
        }
        
        
        if(!exeIdsToRunValidations.isEmpty())
        {
            //--------------------------
            // Step 1: Getting Primary Beat Items
            // -------------------------
            Map<Id,Set<Id>> beatWithPrimaryCustomer = new Map<Id,Set<Id>> ();
            Map<Id,String> primaryIdWithSAPCode = new Map<Id,String> ();
            
            if(!primaryBeatIds.isEmpty())
            {
                list<Junction_Beat__c> beatItems = [select Id,Account__c,Code_Primary_Customer__c,Child_beat__c from Junction_Beat__c where Child_beat__c IN:primaryBeatIds];
                for(Junction_Beat__c btItem: beatItems)
                {
                    if(!beatWithPrimaryCustomer.containsKey(btItem.Child_beat__c))
                    {
                        beatWithPrimaryCustomer.put(btItem.Child_beat__c, new Set<Id>());
                    }
                    beatWithPrimaryCustomer.get(btItem.Child_beat__c).add(btItem.Account__c);
                    if (btItem.Account__c != null) primaryCustomerIds.add(btItem.Account__c); 
                    if (btItem.Account__c != null) primaryIdWithSAPCode.put(btItem.Account__c,btItem.Code_Primary_Customer__c);
                }
                
            }
            
            //--------------------------
            //Step 2: Getting Manager Wise Suborindates
            //--------------------------
            Map<Id, Set<Id>> userWithSubordinates = RoleHeirarchyUtility.getManagerWithSubordinates(exeIds);
            for (Id managerId : userWithSubordinates.keySet()) {
                allRelatedUserIds.add(managerId);
                allRelatedUserIds.addAll(userWithSubordinates.get(managerId)); 
            }
            
            //--------------------------
            // Step 3: Fetch Primary Customer Mappings (using both Exectuive__c and Employee__c)
            // ------------------------
            Map<Id, Set<Id>> userToPrimaryCustomers = new Map<Id, Set<Id>>();
            List<Product_Mapping__c> primaryMappings = [ SELECT Id, Customer__c, Exectuive__c, Employee__c
                                                        FROM Product_Mapping__c WHERE Customer_Type__c = 'Primary Customer' 
                                                        AND (Exectuive__c IN :allRelatedUserIds) AND Customer__c IN: primaryCustomerIds
                                                        limit 50000
                                                       ];
            for (Product_Mapping__c pm : primaryMappings) {
                if (!userToPrimaryCustomers.containsKey(pm.Exectuive__c)) { userToPrimaryCustomers.put(pm.Exectuive__c, new Set<Id>()); }
                userToPrimaryCustomers.get(pm.Exectuive__c).add(pm.Customer__c);
            }
            
            list<Employee_Customer_Assignment__c> primayCustomerDsmAssignments = [
                Select Id,Name,Executive__c,Employee__c,Customer__c from Employee_Customer_Assignment__c
                where (Executive__c IN :allRelatedUserIds) AND Customer__c IN:primaryCustomerIds limit 50000
            ];
            for (Employee_Customer_Assignment__c epm : primayCustomerDsmAssignments) {
                if (!userToPrimaryCustomers.containsKey(epm.Executive__c)) { userToPrimaryCustomers.put(epm.Executive__c, new Set<Id>()); }
                userToPrimaryCustomers.get(epm.Executive__c).add(epm.Customer__c);
            }
            
            
            //--------------------------
            // Step 4.1: Fetch Sub Stockiest mappings similarly
            // ---------------------
            Map<Id, Set<Id>> userToSubStockistCustomers = new Map<Id, Set<Id>>();
            List<Product_Mapping__c> subStockiestMappings = [
                SELECT Id, Customer__c, Exectuive__c, Employee__c FROM Product_Mapping__c
                WHERE Secondary_Customer_Type__c = 'Sub Stockiest' AND (Exectuive__c IN :allRelatedUserIds) AND Customer__c IN:subStockiestCustomerIds  limit 50000
            ];
            for (Product_Mapping__c pm : subStockiestMappings) {
                if (!userToSubStockistCustomers.containsKey(pm.Exectuive__c)) { userToSubStockistCustomers.put(pm.Exectuive__c, new Set<Id>()); }
                userToSubStockistCustomers.get(pm.Exectuive__c).add(pm.Customer__c);
            }
            
            List<Product_Mapping__c> mapsToCreate = new List<Product_Mapping__c>();
            List<Employee_Customer_Assignment__c> DSMmapsToCreate = new List<Employee_Customer_Assignment__c>();
            
            //---------------------------
            //Setp 5: Validating Customer Assignment
            //--------------------------
            for(Child_beat__c beat: beats){
                if (beat.Beat_Type__c == 'Secondary') {
                    Boolean found = false;
                    if (beat.Primary_Customer__c != null) {
                        Set<Id> primaryCustomers = userToPrimaryCustomers.get(beat.OwnerId);
                        system.debug(beat.Payroll_Employee__c);
                        system.debug(beat.Manager_Id__c);
                        
                        if (primaryCustomers == null || !primaryCustomers.contains(beat.Primary_Customer__c)) {
                            
                            
                            if(userWithSubordinates.containsKey(beat.OwnerId))
                            {
                                Set<Id> subordinateUserIds = userWithSubordinates.get(beat.OwnerId);
                                System.debug('Subordinates11: ' + subordinateUserIds);
                                for (Id subUserId : subordinateUserIds) {
                                    if (userToPrimaryCustomers.containsKey(subUserId) && userToPrimaryCustomers.get(subUserId).contains(beat.Primary_Customer__c)) {
                                        found = true;
                                        break;
                                    }
                                }
                            }
                            if (!found) {
                                system.debug(beat.Payroll_Employee__c);                               
                                if(!beat.Payroll_Employee__c && userToPrimaryCustomers.containsKey(beat.Manager_Id__c)){
                                    Employee_Customer_Assignment__c dsmnewMap = new Employee_Customer_Assignment__c();
                                    dsmnewMap.Customer__c = beat.Primary_Customer__c;
                                    dsmnewMap.Executive__c = beat.OwnerId;
                                    
                                    DSMmapsToCreate.add(dsmnewMap);
                                    found = true;
                                }
                                else{
                                    beat.addError('Primary Customer is not yet mapped to this Executive or their subordinates for Beat ID: ' + beat.Beat_Id_Text__c + ').');
                                    continue;
                                }
                                
                            }
                            
                        }
                    } 
                    if (beat.Sub_Stockist__c != null && found) {
                        
                        Product_Mapping__c newMap = new Product_Mapping__c();
                        newMap.Customer__c = beat.Sub_Stockist__c;
                        newMap.Primary_Customer__c = beat.Primary_Customer__c;
                        newMap.Exectuive__c = beat.OwnerId;
                        
                        mapsToCreate.add(newMap);
                        
                    }
                }
                if (beat.Beat_Type__c == 'Primary') {
                    //IF Primary Customer existed then only it will enter
                    if (beatWithPrimaryCustomer.containsKey(beat.Id)) {
                        
                        Set<Id> primaryWithAccess = userToPrimaryCustomers.get(beat.OwnerId);
                        Set<Id> primaryCustomersTocheckAccess = beatWithPrimaryCustomer.get(beat.Id);
                        system.debug('primaryCustomersTocheckAccess-------->'+primaryCustomersTocheckAccess);
                        // Step 1: Assume all are missing
                        Set<Id> missingCustomers = new Set<Id>(primaryCustomersTocheckAccess);
                        
                        // Step 2: Remove ones Owner already has
                        if (primaryWithAccess != null) { missingCustomers.removeAll(primaryWithAccess);}
                        
                        // Step 3: If still missing, check subordinates’ access
                        if (!missingCustomers.isEmpty() && userWithSubordinates.containsKey(beat.OwnerId)) {
                            Set<Id> subordinateUserIds = userWithSubordinates.get(beat.OwnerId);
                            
                            for (Id subUserId : subordinateUserIds) {
                                if (userToPrimaryCustomers.containsKey(subUserId)) {
                                    // Get what this subordinate can access
                                    Set<Id> subAccess = userToPrimaryCustomers.get(subUserId);
                                    // Remove those from missing
                                    missingCustomers.removeAll(subAccess);
                                    
                                    // Early exit if nothing left missing
                                    if (missingCustomers.isEmpty()) { break; }
                                }
                            }
                        }
                        
                        if (!missingCustomers.isEmpty()) {
                            List<String> missingStrList = new List<String>();
                            for (Id custId : missingCustomers) {
                                if(primaryIdWithSAPCode.containsKey(custId))
                                {
                                    string customerCode = primaryIdWithSAPCode.get(custId);
                                    missingStrList.add(customerCode);
                                }
                            }
                            String missingStr = String.join(missingStrList, ', ');
                            
                            beat.addError('User ' + beat.Owner_Employee_Code__c + ' (and subordinates) do not have access to required primary customers: ' + missingStr );
                        }
                        
                    }
                }
                
            }
            
            //---------------------------
            //Step 6: Creating New Mappings
            //---------------------------
            if(!DSMmapsToCreate.isEmpty()){
                try{
                    insert DSMmapsToCreate;                
                }
                catch(Exception ex){
                    ExceptionHandler.addLog(ex, String.valueof(DSMmapsToCreate), 'BeatTriggerHandler.handleValidations');
                }
            }
            
            if(!mapsToCreate.isEmpty()){
                try{
                    insert mapsToCreate;                
                }
                catch(Exception ex){
                    ExceptionHandler.addLog(ex, String.valueof(mapsToCreate), 'BeatTriggerHandler.handleValidations');
                }
            }
        }
        
    }
    
    public static void createSecMappings(List<Child_beat__c> beats){
        
        List<Junction_Beat__c> items = [select Id,Name,Child_Beat__c,Account__c,Beat_Primary_Customer__c,Beat_Substockiest__c,Beat_OwnerId__c,
                                        Payroll_Employee__c,Beat_Type__c
                                        from Junction_Beat__c where Child_Beat__c IN :beats];
        
         List<Product_Mapping__c> mapsToCreate = new List<Product_Mapping__c>();
         List<Employee_Customer_Assignment__c> DSMmapsToCreate = new List<Employee_Customer_Assignment__c>();
        
        for(Junction_Beat__c item: items){
             if(item.Account__c != null){
                 if(item.Beat_Type__c == 'Primary'){
                     Employee_Customer_Assignment__c dsmnewMap = new Employee_Customer_Assignment__c();
                     dsmnewMap.Customer__c = item.Beat_Primary_Customer__c;
                     dsmnewMap.Executive__c = item.Beat_OwnerId__c;
                     
                     DSMmapsToCreate.add(dsmnewMap);
                 }
                 else{
                     Product_Mapping__c newMap = new Product_Mapping__c();
                     newMap.Customer__c = item.Account__c;
                     newMap.Primary_Customer__c = item.Beat_Primary_Customer__c;
                     newMap.Sub_Stockiest__c = item.Beat_Substockiest__c;
                     newMap.Exectuive__c = item.Beat_OwnerId__c;
                     mapsToCreate.add(newMap);
                 }
            }
        }
        
         if(!DSMmapsToCreate.isEmpty()){
            try{
				insert DSMmapsToCreate;                
            }
            catch(Exception ex){
                ExceptionHandler.addLog(ex, String.valueof(DSMmapsToCreate), 'BeatTriggerHandler.handleValidations');
            }
        }
        
        if(!mapsToCreate.isEmpty()){
            try{
				insert mapsToCreate;                
            }
            catch(Exception ex){
                ExceptionHandler.addLog(ex, String.valueof(mapsToCreate), 'BeatTriggerHandler.createSecMappings');
            }
        }
        
    }
    
}