public without sharing class BeatItemTriggerHandler 
{
    
    public static void handleSecValidations(List<Junction_Beat__c> beatItems){ 
        
        Set<Id> exeIds = new Set<Id>();
        Set<Id> primaryCustomerIds = new Set<Id>();
        Set<Id> subStockiestCustomerIds = new Set<Id>();
        
        for(Junction_Beat__c beat: beatItems){
            if( beat.Cloned_From_Employee_Replacement__c == false) exeIds.add(beat.Beat_OwnerId__c );
            if (beat.Beat_Primary_Customer__c != null &&  beat.Cloned_From_Employee_Replacement__c == false) primaryCustomerIds.add(beat.Beat_Primary_Customer__c);
            if (beat.Beat_Substockiest__c != null  &&  beat.Cloned_From_Employee_Replacement__c == false) subStockiestCustomerIds.add(beat.Beat_Substockiest__c);
            
        }
        
        if(!exeIds.isEmpty())
        {
            Map<Id, Set<Id>> userWithSubordinates = RoleHeirarchyUtility.getManagerWithSubordinates(exeIds);
            Set<Id> allRelatedUserIds = new Set<Id>();
            for (Id managerId : userWithSubordinates.keySet()) {
                allRelatedUserIds.add(managerId); // include manager themselves
                allRelatedUserIds.addAll(userWithSubordinates.get(managerId)); // include their subordinates
                //System.debug('Subordinates: ' + JSON.serialize(userWithSubordinates.get(managerId))); 
                
            }
            // Step 4: Fetch Primary Customer Mappings (using both Exectuive__c and Employee__c)
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
            
            system.debug('allRelatedUserIds:'+ allRelatedUserIds);
            system.debug('primaryCustomerIds:'+ primaryCustomerIds);
            list<Employee_Customer_Assignment__c> primayCustomerDsmAssignments = [
                Select Id,Name,Executive__c,Employee__c,Customer__c from Employee_Customer_Assignment__c
                where (Executive__c IN :allRelatedUserIds) AND Customer__c IN:primaryCustomerIds limit 50000
            ];
            for (Employee_Customer_Assignment__c epm : primayCustomerDsmAssignments) {
                if (!userToPrimaryCustomers.containsKey(epm.Executive__c)) { userToPrimaryCustomers.put(epm.Executive__c, new Set<Id>()); }
                userToPrimaryCustomers.get(epm.Executive__c).add(epm.Customer__c);
            }
            system.debug('primayCustomerDsmAssignments:'+ primayCustomerDsmAssignments);
            
            // Step 4.1: Fetch Sub Stockiest mappings similarly
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
            
            for(Junction_Beat__c beat: beatItems){
                Boolean found = false;
                if (beat.Beat_Primary_Customer__c != null) {
                    Set<Id> primaryCustomers = userToPrimaryCustomers.get(beat.Beat_OwnerId__c);
                    
                    system.debug(primaryCustomers);
                    
                    if (primaryCustomers == null || !primaryCustomers.contains(beat.Beat_Primary_Customer__c)) {
                        
                        
                        if(userWithSubordinates.containsKey(beat.Beat_OwnerId__c))
                        {
                            Set<Id> subordinateUserIds = userWithSubordinates.get(beat.Beat_OwnerId__c);
                            //System.debug('Subordinates11: ' + JSON.serialize(subordinateUserIds));
                            for (Id subUserId : subordinateUserIds) {
                                if (userToPrimaryCustomers.containsKey(subUserId) && userToPrimaryCustomers.get(subUserId).contains(beat.Beat_Primary_Customer__c)) {
                                    found = true;
                                    break;
                                }
                            }
                        }
                        if (!found) {
                            beat.addError('Primary Customer is not yet mapped to this Executive or their subordinates (Executive Code: ' + beat.Beat_Owner_Employee_Code__c + ', Primary Customer Code: ' + beat.Beat_Primary_Customer_Code__c + ').');
                            continue;
                        }
                        
                    }
                } 
                if (beat.Beat_Substockiest__c != null && found) {
                    Product_Mapping__c newMap = new Product_Mapping__c();
                    newMap.Customer__c = beat.Beat_Substockiest__c;
                    newMap.Primary_Customer__c = beat.Beat_Primary_Customer__c;
                    newMap.Exectuive__c = beat.Beat_OwnerId__c;
                    
                    mapsToCreate.add(newMap);
                    /* Set<Id> subStockiestCustomers = userToSubStockistCustomers.get(beat.Beat_OwnerId__c);
if (subStockiestCustomers == null || !subStockiestCustomers.contains(beat.Beat_Substockiest__c)) {
Set<Id> subordinateUserIds = userWithSubordinates.get(beat.Beat_OwnerId__c);
Boolean found = false;
if(userWithSubordinates.containsKey(beat.Beat_OwnerId__c))
{
for (Id subUserId : subordinateUserIds) {
if (userToSubStockistCustomers.containsKey(subUserId) && userToSubStockistCustomers.get(subUserId).contains(beat.Beat_Substockiest__c)) {
found = true;
break;
}
}
}

if (!found) {
beat.addError('Sub Stockiest is not yet mapped to this Executive (Executive Code: ' + beat.Beat_Owner_Employee_Code__c + ', Sub Stockiest Code: ' + beat.Beat_Sub_Stockist_Outlet_Code__c + ').');
continue;
}
}*/
                }
                
                if(beat.Account__c != null && !found){
                    Product_Mapping__c newMap = new Product_Mapping__c();
                    newMap.Customer__c = beat.Account__c;
                    newMap.Primary_Customer__c = beat.Beat_Primary_Customer__c;
                    newMap.Sub_Stockiest__c = beat.Beat_Substockiest__c;
                    newMap.Exectuive__c = beat.Beat_OwnerId__c;
                    mapsToCreate.add(newMap);
                }
                
            }
            
            
            if(!mapsToCreate.isEmpty()){
                try{
                    insert mapsToCreate;                
                }
                catch(Exception ex){
                    ExceptionHandler.addLog(ex, String.valueof(mapsToCreate), 'BeatItemTriggerHandler.handleSecValidations');
                }
            }
        }        
        
    }
    
    public static void handlePrimValidations(List<Junction_Beat__c> beatItems){
        
        Set<Id> exeIds = new Set<Id>();
        Set<Id> primaryCustomerIds = new Set<Id>();
        Set<Id> allRelatedUserIds = new Set<Id>();
        
        for(Junction_Beat__c beat: beatItems){
            if( beat.Cloned_From_Employee_Replacement__c == false) exeIds.add(beat.Beat_OwnerId__c);
            if(!beat.Payroll_Employee__c && beat.Cloned_From_Employee_Replacement__c == false)allRelatedUserIds.add(beat.Manager_Id__c);
            if (beat.Account__c != null && beat.Cloned_From_Employee_Replacement__c == false) primaryCustomerIds.add(beat.Account__c);
            
        }
        
        Map<Id, Set<Id>> userWithSubordinates = RoleHeirarchyUtility.getManagerWithSubordinates(exeIds);
        
        for (Id managerId : userWithSubordinates.keySet()) {
            allRelatedUserIds.add(managerId); // include manager themselves
            allRelatedUserIds.addAll(userWithSubordinates.get(managerId)); // include their subordinates
            //System.debug('Subordinates: ' + JSON.serialize(userWithSubordinates.get(managerId))); 
            
        }
        // Step 4: Fetch Primary Customer Mappings (using both Exectuive__c and Employee__c)
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
        
         List<Employee_Customer_Assignment__c> DSMmapsToCreate = new List<Employee_Customer_Assignment__c>();
       
        for(Junction_Beat__c beat: beatItems){
            if (beat.Account__c != null) {
                Set<Id> primaryCustomers = userToPrimaryCustomers.get(beat.Beat_OwnerId__c);
                
                if (primaryCustomers == null || !primaryCustomers.contains(beat.Account__c)) {
                    
                    Boolean found = false;
                    if(userWithSubordinates.containsKey(beat.Beat_OwnerId__c))
                    {
                        Set<Id> subordinateUserIds = userWithSubordinates.get(beat.Beat_OwnerId__c);
                        //System.debug('Subordinates11: ' + JSON.serialize(subordinateUserIds));
                        for (Id subUserId : subordinateUserIds) {
                            if (userToPrimaryCustomers.containsKey(subUserId) && userToPrimaryCustomers.get(subUserId).contains(beat.Account__c)) {
                                found = true;
                                break;
                            }
                        }
                    }
                    if (!found) {
                        if(!beat.Payroll_Employee__c && userToPrimaryCustomers.containsKey(beat.Manager_Id__c)){
                            Employee_Customer_Assignment__c dsmnewMap = new Employee_Customer_Assignment__c();
                            dsmnewMap.Customer__c = beat.Beat_Primary_Customer__c;
                            dsmnewMap.Executive__c = beat.Beat_OwnerId__c;
                            
                            DSMmapsToCreate.add(dsmnewMap);
                            found = true;
                        }
                        else{
                            beat.addError('Primary Customer is not yet mapped to this Executive or their subordinates (Executive Code: ' + beat.Beat_Owner_Employee_Code__c + ', Primary Customer Code: ' + beat.Account_Customer_Code__c + ').');
                            continue;
                        }
                        
                    }
                    
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
        
    }
    
    /* //To Create New Secondary Mapping Based on Beat
    public static void AfterInsert(list<Junction_Beat__c> newBeatItems)
    {
        set<Id> primaryCustomerIds = new set<Id>();
        set<Id> subStockiestIds = new set<Id>();
        for(Junction_Beat__c bt : newBeatItems)
        {
            if(bt.Beat_Type__c == 'Secondary')
            {
                primaryCustomerIds.add(bt.Beat_Primary_Customer__c);
                subStockiestIds.add(bt.Beat_Substockiest__c);
            }
        }
        
        //Outlet to primary customer mappings
        list<Product_Mapping__c> secondaryPrimaryMappings = [select Id,Name,Customer__c,Primary_Customer__c,Exectuive__c from Product_Mapping__c where
                                                      Primary_Customer__c IN:primaryCustomerIds ];
        
        //outlet to substockiest mappings
        list<Product_Mapping__c> secondarySubstockiestMappings = [select Id,Name,Customer__c,Primary_Customer__c,Exectuive__c,Sub_Stockiest__c from
                                                                  Product_Mapping__c where Sub_Stockiest__c IN:subStockiestIds ];
        
        
    }
     */
    

}