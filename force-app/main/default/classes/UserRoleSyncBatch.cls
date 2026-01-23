global class UserRoleSyncBatch implements Database.Batchable<sObject> {
    
    // Start method: Defines the query to fetch UserRole records
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator('SELECT Id, Name FROM UserRole');
    }

    // Execute method: Processes each batch of records
    global void execute(Database.BatchableContext BC, List<UserRole> roleList) {
        List<Role__c> customRoles = new List<Role__c>();

        for (UserRole ur : roleList) {
            Role__c customRole = new Role__c();
            customRole.Name = ur.Name;
            customRole.Role_Id__c = ur.Id;
            customRoles.add(customRole);
        }

        if (!customRoles.isEmpty()) {
            insert customRoles;
        }
    }

    // Finish method: Executes after all batches are processed
    global void finish(Database.BatchableContext BC) {
        // Optional: Implement any post-processing logic here
    }
}