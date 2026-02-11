public class EmployeeReplacementBatch implements Database.Batchable<sObject>, Database.Stateful {

    // For one user only (old → new)
    private String oldUserId;
    private String newUserId;
    
    // For one Employee only (old → new)
    private String oldEmpId;
    private String newEmpId;
    private String newEmployeeName;
    private String newEmployeeCode;

    // Data containers for all steps
    List<Product_Mapping__c> oldMappings;
    List<Employee_Customer_Assignment__c> EmployeeDSMCustomerAssignment;
    List<Child_beat__c> oldBeats;
    List<Calendar_beat__c> pjps;

    public EmployeeReplacementBatch(String oldUserId, String newUserId, String oldEmpId , String newEmpId,String newEmployeeName, String newEmployeeCode){
        this.oldUserId = oldUserId;
        this.newUserId = newUserId;
        
        this.oldEmpId = oldEmpId;
        this.newEmpId = newEmpId;
        this.newEmployeeName = newEmployeeName;
        this.newEmployeeCode = newEmployeeCode;
    }

    // ---------------- START -----------------
    public Database.QueryLocator start(Database.BatchableContext bc){

        // Load all required data at once
        oldMappings = [
            SELECT Id, Exectuive__c, Primary_Customer__c, Sub_Stockiest__c, Customer__c, Chanel__c,
                Area__c, PDP_Name__c, PDP_Day__c, Parent_Depot__c, Child_Depot__c, Payment_Term__c, 
                Credit_Description__c, Inco_Terms__c, Order_Type__c, Distribution_Channel__c, 
                Sales_Office__c, Division__c, Customer_Type__c, Secondary_Customer_Type__c
            FROM Product_Mapping__c
            WHERE Exectuive__c = :oldUserId
        ];

        EmployeeDSMCustomerAssignment = [
            SELECT Id, Customer__c, Executive__c
            FROM Employee_Customer_Assignment__c 
            WHERE Executive__c = :oldUserId
        ];

        oldBeats = [
            SELECT Id, Name, Primary_Customer__c, Sub_Stockist__c, Order_Number__c, OwnerId, Beat_Type__c, Active__c,
                (SELECT Id, Account__c, Order_Number__c, Active__c FROM Junction_Beats__r)
            FROM Child_beat__c
            WHERE OwnerId = :oldUserId
        ];

        pjps = [
            SELECT Id, Name, User__c, Active__c, Start_Month__c, Next_Start_Date__c, Recurring_Frequency__c
            FROM Calendar_beat__c
            WHERE User__c = :oldUserId
        ];

        // Dummy query to make batch run
        return Database.getQueryLocator('SELECT Id FROM User WHERE Id = \'' + oldUserId + '\'');
    }

    // ---------------- EXECUTE -----------------
    public void execute(Database.BatchableContext bc, List<sObject> scope){

        cloneProductMappings();
        cloneBeats();
        clonePJP();

        // Step 4: Approver replacement (Async Queueable)
        System.enqueueJob(new ApproverReplacementQueue(new Map<String, String>{ oldUserId => newUserId },new Set<String>{ oldUserId }));
        
        // Step 5: User role reassignment (Async)
        updateUserRoleHierarchy(new Map<String, String>{ oldUserId => newUserId });
    }
    
    // ---------------- FINISH -----------------
    public void finish(Database.BatchableContext bc){
        // Mark new employee flag
        Employee__c newEmp = new Employee__c(
            Id = newEmpId,
            Cloning_is_Completed__c = true
        );
        
        // Mark old employee replaced
        Employee__c oldEmp = new Employee__c(
            Id = oldEmpId,
            Is_Employee_Replaced__c = true,
            Employee_Replaced_With_Name__c = newEmployeeName
        );
        
        update new List<Employee__c>{ newEmp, oldEmp };
            
            userProfileLWC.shareAccountAccess(newEmpId,'Employee');
        
        string body = 'Employee Name : ' + newEmployeeName + 
            '\nEmployee Code : ' + newEmployeeCode;
        CustomNotificationType notificationType = [
            SELECT Id 
            FROM CustomNotificationType 
            WHERE DeveloperName = 'EmployeeReplacement' 
            LIMIT 1
        ];
        string title = 'Employee access (Beat, PJP, Product Mappings) successfully transferred.';
        CustomNotificationService.notificationSend(
            title, 
            newEmpId,
            body, 
            new Set<String>{    UserInfo.getUserId()}, 
            notificationType.Id
        );
    }

    // ---------------- METHODS -----------------
    private void cloneProductMappings(){
        List<Product_Mapping__c> clonedPrimaryMappings = new List<Product_Mapping__c>();
        List<Product_Mapping__c> clonedSubstockiestMappings = new List<Product_Mapping__c>();
        List<Product_Mapping__c> clonedSecondaryMappings = new List<Product_Mapping__c>();
        
        //Product mapping Mappings
        for (Product_Mapping__c oldMap : oldMappings) {
            String newExecutiveId = newUserId;
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
        for(Employee_Customer_Assignment__c oldMap: EmployeeDSMCustomerAssignment)
        {
            String newExecutiveId = newUserId;
            if (String.isNotBlank(newExecutiveId)) {
                Employee_Customer_Assignment__c newMap = new Employee_Customer_Assignment__c();
                newMap.Customer__c = oldMap.Customer__c;
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
        
    }
    
    private void cloneBeats(){
        List<Child_beat__c> clonedBeats = new List<Child_beat__c>();
        Map<Id, Id> oldBeatIdToNewBeatIdMap = new Map<Id, Id>(); // to map old -> new beat Ids
        
        // Prepare Child_beat__c clones
        for (Child_beat__c oldBeat : oldBeats) {
            String newOwnerId = newUserId;
            if (String.isNotBlank(newOwnerId)) {
                Child_beat__c newBeat = new Child_beat__c();
                newBeat.Name = oldBeat.Name;
                newBeat.Primary_Customer__c = oldBeat.Primary_Customer__c;
                newBeat.Sub_Stockist__c = oldBeat.Sub_Stockist__c;
                newBeat.Order_Number__c = oldBeat.Order_Number__c;
                newBeat.Beat_Type__c =  oldBeat.Beat_Type__c;
                newBeat.OwnerId = newOwnerId;
                newBeat.Old_Beat_Id_Back_End_Purpose__c = oldBeat.Id;
                newBeat.Cloned_From_Employee_Replacement__c = true;
                newBeat.Active__c =  oldBeat.Active__c ;
                clonedBeats.add(newBeat);
            }
        }
        
        // Insert all cloned beats first to get their Ids
        if (!clonedBeats.isEmpty()) {
            database.insert(clonedBeats,false);
            
            // Map old beat to new beat Id
            for (Child_beat__c inserted : clonedBeats) {
                if (String.isNotBlank(inserted.Old_Beat_Id_Back_End_Purpose__c)) {
                    oldBeatIdToNewBeatIdMap.put(Id.valueOf(inserted.Old_Beat_Id_Back_End_Purpose__c), inserted.Id);
                }
            }
        }
        
        // Clone Junction_Beats__c records using the mapped beat Ids
        List<Junction_Beat__c> junctionsToInsert = new List<Junction_Beat__c>();
        for (Child_beat__c oldBeat : oldBeats) {
            Id newBeatId = oldBeatIdToNewBeatIdMap.get(oldBeat.Id);
            
            for (Junction_Beat__c jb : oldBeat.Junction_Beats__r) {
                Junction_Beat__c newJb = new Junction_Beat__c();
                newJb.Child_Beat__c = newBeatId;
                newJb.Account__c = jb.Account__c;
                newJb.Order_Number__c = jb.Order_Number__c;
                newJb.Active__c = jb.Active__c;
                newJb.Cloned_From_Employee_Replacement__c = true;
                
                junctionsToInsert.add(newJb);
            }
        }
        
        if (!junctionsToInsert.isEmpty()) {
            database.insert(junctionsToInsert,false);
        }
        
    }

    private void clonePJP(){
        list<Calendar_beat__c> NewPJPToInsert = new  list<Calendar_beat__c> ();
        for (Calendar_beat__c Oldpjp : pjps) {
            String newExecutiveId = newUserId;
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
    }
    
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
}