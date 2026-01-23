public class AccountTriggerHandler {
    private static Set<String> sapAdminUserIds;
    private static Set<String> systemAdminUserIds;
    
    public static void beforeInsert(List<Account> newAccounts) {
        Map<Id, User> userMap = new Map<Id, User>([SELECT Id, Name, RSM__c, ASM_TSM__c,Primary_Customer_Approver_3_Credit_Dept__c,
                                                   Primary_Customer_Approver_1__c,Primary_Customer_Approver_2__c,
                                                   Secondary_Customer_Approver_1__c,Secondary_Customer_Approver_2__c FROM User]);
        List<RecordType> recordTypes = [SELECT Id, Name,SobjectType  FROM RecordType where SobjectType ='Account'];
        Map<String, String> recordTypeMap = new Map<String, String>();
        
        for (RecordType rec : recordTypes) {
            recordTypeMap.put(rec.Name,rec.Id);
        }
        string AdminUserProfleName = Label.Admin_User_Profile_Name;
        user adminUser = [select Id,Name from User where profile.Name =:AdminUserProfleName limit 1];
        
        
        for(Account acc: newAccounts)
        {
            if(acc.Customer_Type__c != null)
            {
                if (recordTypeMap.containsKey(acc.Customer_Type__c)) {
                    acc.RecordTypeId = recordTypeMap.get(acc.Customer_Type__c);
                }
            }
            if(userMap.containsKey(acc.OwnerId))
            {
                User us = userMap.get(acc.OwnerId);
                //Primary Customer Approval 
                if(acc.Customer_Type__c == 'Primary Customer')
                {
                    if(us.Primary_Customer_Approver_2__c != null)
                    {
                        acc.RSM__c =us.Primary_Customer_Approver_2__c;
                    }
                    if(us.Primary_Customer_Approver_1__c != null)
                    {
                        acc.ASM_TSM__c =us.Primary_Customer_Approver_1__c;
                    }
                    if(us.Primary_Customer_Approver_3_Credit_Dept__c != null)
                    {
                        acc.Primary_Customer_Approver_L3_Credit__c = us.Primary_Customer_Approver_3_Credit_Dept__c;
                    }
                }
                //For Secoundary Customer Approval
                else
                {
                    if(us.Secondary_Customer_Approver_1__c != null)
                    {
                        acc.ASM_TSM__c =us.Secondary_Customer_Approver_1__c;
                    }
                    if(us.Secondary_Customer_Approver_2__c != null)
                    {
                        acc.RSM__c =us.Secondary_Customer_Approver_2__c;
                    }
                    
                    
                }
                
                
            }
            if(adminUser != null)
            {
                acc.OwnerId = adminUser.Id;
            }
            
            if(acc.Customer_Status__c == 'Active')
            {
                acc.Customer_Activation_Date__c = system.now();
            }
        }
        
        
    }
    public static void afterInsert(List<Account> newAccounts) {
        Set<String> uniqueFileIds = new Set<String>();
        Map<String, Id> accountIdMap = new Map<String, Id>();
        Set<String> OwnerIds = new Set<String>();
        
        set<String> BeatIds = new set<String>();
        Map<String,String> customerBeatMap = new Map<String,String>();      
        Set<Id> userIds = new Set<Id>();
        // Collect all unique file IDs from new accounts
        for (Account acc : newAccounts) {
            if (acc.UniqueFileId__c != null) {
                uniqueFileIds.add(acc.UniqueFileId__c);
                accountIdMap.put(acc.UniqueFileId__c, acc.Id);
            }
            
            userIds.add(acc.CreatedById);
        }
        
        if (!uniqueFileIds.isEmpty()) {
            // Query files with matching unique IDs
            List<ContentDocument> files = [
                SELECT Id, Description 
                FROM ContentDocument 
                WHERE Description IN :uniqueFileIds
            ];
            system.debug('files'+files);
            
            List<ContentDocumentLink> fileLinks = new List<ContentDocumentLink>();
            // Link each file to the correct account
            for (ContentDocument file : files) {
                if (accountIdMap.containsKey(file.Description)) {
                    ContentDocumentLink link = new ContentDocumentLink();
                    link.ContentDocumentId = file.Id;
                    link.LinkedEntityId = accountIdMap.get(file.Description);
                    link.ShareType = 'V';
                    link.Visibility = 'AllUsers';
                    fileLinks.add(link);
                }
            }
            
            if (!fileLinks.isEmpty()) {
                insert fileLinks;
            }
        }
        
        if (!userIds.isEmpty()) {
            updateCustomerCount(userIds);
        }
    }
    
    public static void updateCustomerCount(Set<Id> userIds)
    {
        // Maps with userId → count of accounts created today
        Map<Id, Integer> accountCountMap = new Map<Id, Integer>();
        
        for (AggregateResult ar : [
            SELECT CreatedById createdById,
            COUNT(Id) accountCount
            FROM Account
            WHERE CreatedById IN :userIds
            AND CreatedDate = TODAY
            GROUP BY CreatedById
        ]) {
            Id createdById = (Id) ar.get('createdById');
            Integer accountCount = (Integer) ar.get('accountCount');
            accountCountMap.put(
                createdById,
                (accountCountMap.containsKey(createdById) ? accountCountMap.get(createdById) : 0) + accountCount
            );
        }
        
        // Query daily logs for those users
        List<Daily_Log__c> dailyLogs = [
            SELECT Id, OwnerId, Date__c
            FROM Daily_Log__c
            WHERE OwnerId IN :userIds
            AND Date__c = TODAY
        ];
        
        List<Daily_Log__c> logsToUpdate = new List<Daily_Log__c>();
        for (Daily_Log__c dl : dailyLogs) {
            dl.New_Calls__c = accountCountMap.get(dl.OwnerId) != null
                ? accountCountMap.get(dl.OwnerId)
                : 0;
            logsToUpdate.add(dl);
        }
        
        if (!logsToUpdate.isEmpty()) {
            update logsToUpdate;
        } 
    }
    
    public static void beforeUpdate(List<Account> newAccounts, Map<Id, Account> oldAccountMap) {
        List<RecordType> recordTypes = [SELECT Id, Name,SobjectType  FROM RecordType where SobjectType ='Account'];
        Map<Id, String> recordTypeMap = new Map<Id, String>();
        
        for (RecordType rec : recordTypes) {
            recordTypeMap.put(rec.Id, rec.Name);
        }
        
        Set<Id> primaryCustomerIds = new Set<Id>();
        Set<Id> inactivePrimaryIds = new Set<Id>();
        
        for (Account acc : newAccounts)
        {
            if (acc.RecordTypeId != oldAccountMap.get(acc.Id).RecordTypeId) 
            {
                if (recordTypeMap.containsKey(acc.RecordTypeId)) {
                    acc.Customer_Type__c = recordTypeMap.get(acc.RecordTypeId);
                }
            }
            
            if (acc.Customer_Type__c == 'Secondary Customer' &&
                acc.Approval_Status__c != oldAccountMap.get(acc.Id).Approval_Status__c &&
                acc.Approval_Status__c == 'Level 2 Approved' &&
                (acc.High_Margin__c == null || acc.High_Margin__c == '')) 
            {
                
                acc.addError('Please fill in the High Margin for the Secondary Customer before approval. Customer Name: ' + acc.Name);
            }
            
            if (acc.Customer_Type__c == 'Primary Customer' &&
                acc.Approval_Status__c != oldAccountMap.get(acc.Id).Approval_Status__c && acc.Approval_Status__c == 'Credit Dept. Approved') 
            {
                
                primaryCustomerIds.add(acc.Id);
            }
            
            if(acc.Customer_Status__c != oldAccountMap.get(acc.Id).Customer_Status__c && acc.Customer_Status__c == 'Inactive')
            {
                inactivePrimaryIds.add(acc.Id);
                acc.Customer_Inactivation_Date__c = system.now();
            }
            if(acc.Customer_Status__c != oldAccountMap.get(acc.Id).Customer_Status__c && acc.Customer_Status__c == 'Active')
            {
                acc.Customer_Activation_Date__c = system.now();
            }
        }
        
        if (!primaryCustomerIds.isEmpty()) {
            List<Product_Mapping__c> productMappingList = [
                SELECT Id, Name, Customer__c, Payment_Type__c, Payment_Term__c, Credit_Description__c, Inco_Terms__c
                FROM Product_Mapping__c
                WHERE Customer__c IN :primaryCustomerIds
            ];
            
            // Group by Customer for error messages
            Map<Id, List<Product_Mapping__c>> customerToMappings = new Map<Id, List<Product_Mapping__c>>();
            for (Product_Mapping__c mapping : productMappingList) {
                if (!customerToMappings.containsKey(mapping.Customer__c)) {
                    customerToMappings.put(mapping.Customer__c, new List<Product_Mapping__c>());
                }
                customerToMappings.get(mapping.Customer__c).add(mapping);
            }
            
            for (Account acc : newAccounts) {
                if (primaryCustomerIds.contains(acc.Id) && (acc.Payment_Type__c == 'Credit' || acc.Payment_Type__c == null) ) {
                    Boolean hasError = false;
                    if(acc.Payment_Type__c == null)
                    {
                        acc.addError('Please fill the Payment Type before approving the Primary Customer. Customer Name: ' + acc.Name);
                        hasError = true;
                    }
                    // Check if Credit Limit is missing
                    else if ((acc.Credit_Limit__c == null || acc.Credit_Limit__c == 0 )&& acc.Payment_Type__c == 'Credit') {
                        acc.addError('Please fill the Credit Limit on customer. before approving the Primary Customer. Customer Name: ' + acc.Name);
                        hasError = true;
                    }
                    
                    // Check product mapping only if Credit Limit is present
                    if (!hasError) {
                        if (customerToMappings.containsKey(acc.Id)) {
                            for (Product_Mapping__c mapping : customerToMappings.get(acc.Id)) {
                                if (acc.Payment_Type__c == 'Credit' && (mapping.Payment_Term__c == null ||  mapping.Inco_Terms__c == null)) {
                                    acc.addError('Please fill the Payment Term and Incoterms on Product Mapping before approving the Primary Customer. Customer Name: ' + acc.Name);
                                    break;
                                }
                            }
                        } 
                    }
                }
            }
            
        }
        
        if (!inactivePrimaryIds.isEmpty()) {
            List<Daily_Log__c> todaysDailyLogList = [
                SELECT Id, Owner_Name__c, CurrentBeat_Primary_Customer_Id__c, Current_Beat_Substockiest__c
                FROM Daily_Log__c
                WHERE (CurrentBeat_Primary_Customer_Id__c IN :inactivePrimaryIds 
                       OR Current_Beat_Substockiest__c IN :inactivePrimaryIds)
                AND CreatedDate = TODAY
            ];
            
            list<Visit__c> lstVisits = [select Id,Name,Account1__c,Owner_Name__c from Visit__c where CreatedDate = today and Status__c = 'In Progress'
                                        and Account1__c IN:inactivePrimaryIds ];
            
            Map<Id, String> currentBeatCustomersWithOwners = new Map<Id, String>();
            
            for (Daily_Log__c dl : todaysDailyLogList) {
                if (dl.CurrentBeat_Primary_Customer_Id__c != null) {
                    currentBeatCustomersWithOwners.put(dl.CurrentBeat_Primary_Customer_Id__c, dl.Owner_Name__c);
                }
                if (dl.Current_Beat_Substockiest__c != null) {
                    currentBeatCustomersWithOwners.put(dl.Current_Beat_Substockiest__c, dl.Owner_Name__c);
                }
            }
            Map<Id, String> currentVisitCustomersWithOwners = new Map<Id, String>();
            for(Visit__c vs: lstVisits)
            {
                currentVisitCustomersWithOwners.put(vs.Account1__c, vs.Owner_Name__c);                
            }
            
            if (!currentBeatCustomersWithOwners.isEmpty() || !currentVisitCustomersWithOwners.isEmpty()) {
                for (Account acc : newAccounts) {
                    if (currentBeatCustomersWithOwners.containsKey(acc.Id)) {
                        String ownerName = currentBeatCustomersWithOwners.get(acc.Id);
                        acc.addError('You cannot deactivate this customer because this customer beat is currently being worked on by ' + ownerName + '.');
                    }
                    else if(currentVisitCustomersWithOwners.containsKey(acc.Id))
                    {
                        String ownerName = currentVisitCustomersWithOwners.get(acc.Id);
                        acc.addError('You cannot deactivate this customer because there is a In Progress vist by' + ownerName + '.');
                    }
                }
            }
        }
        
    }
    
    public static void afterUpdate(List<Account> newAccounts, Map<Id, Account> oldAccountMap) {
        system.debug('acc afterUpdate>>'+newAccounts[0].ERP_Check__c+' >>'+newAccounts[0].ERP_Update__c);
        loadAdminUsers();   
        //In future multiple users comes due to that we getting all users
        /*       List<User> adminUsers = [SELECT Id FROM User WHERE Profile.Name = 'SAP Admin' AND IsActive = true];
        Set<String> sapAdminUserIds = new Set<String>();
        for (User u : adminUsers) {
        sapAdminUserIds.add(u.Id);
        }
        List<User> systemAdminUsers = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true limit 1];
        Set<String> systemadminUserIds = new Set<String>();
        for (User u : systemAdminUsers) {
        systemadminUserIds.add(u.Id);
        }*/
        
        Map<String, String> oldPrimaryCustomerToNewMap = new Map<String, String>();
        Map<String, String> oldSubStockiestToNewSubStockiestMap = new Map<String, String>();
        set<Id> accountIdToSendNotification = new set<Id>();
        for (Account acc : newAccounts) {
            Account oldAcc = oldAccountMap.get(acc.Id);
            
            // Notification for approval to SAP Admin
            if (!sapAdminUserIds.isEmpty() && acc.Approval_Status__c != oldAcc.Approval_Status__c
                && acc.Approval_Status__c == 'Credit Dept. Approved') {
                    
                    String body = 'Primary Phone Number: ' + acc.Primary_Phone_Number__c + 
                        '\nCustomer Code : ' + acc.Customer_Code__c;
                    String title = acc.Name + ' ' + acc.Customer_Type__c + ' has been Approved by Credit Department';
                    accountIdToSendNotification.add(acc.Id);
                    GenericNotificationCenter.notificationSend(title, acc.Id, body, sapAdminUserIds);
                }
            
            
            if(!systemadminUserIds.isEmpty() && oldAcc.SAP_Customer_Code__c == null && acc.SAP_Customer_Code__c != null
               && acc.Customer_Status__c != 'Active')
            {
                String body = 'Primary Phone Number: ' + acc.Primary_Phone_Number__c + 
                    '\nSAP Code: ' + acc.SAP_Customer_Code__c;
                String title = acc.Name + ' (' + acc.Customer_Type__c + ') has been created in SAP. Please proceed with customer activation.';
                
                GenericNotificationCenter.notificationSend(title, acc.Id, body, systemadminUserIds);
            }
            Boolean isLastOrderChanged = acc.Last_Order__c != oldAcc.Last_Order__c;
            //send the data to azure : integration            
            if ((acc.Customer_Status__c == 'Active' || (acc.Customer_Status__c != oldAcc.Customer_Status__c && acc.Customer_Status__c == 'Inactive' ))
                && AccountTriggerRecursion.skipAzureCall==false && !isLastOrderChanged) {// acc.Customer_Status__c != oldAcc.Customer_Status__c && acc.Customer_Type__c == 'Primary Customer'
                   
                
                    system.debug('accounttriggerhandler 341:-acc.Customer_Status__c'+acc.Customer_Status__c); 
                    //   PostHandler.accPost(acc);
                    System.enqueueJob(new AzureAccountSyncQueue(acc.Id,acc.ERP_Check__c));
                    
                    
                }
            
        }
        
        if(!accountIdToSendNotification.isEmpty() && label.EnableCreditApprovalEmail == 'True')
        {
            SendEmailNotificationToBillingTeam.sendDocuments(accountIdToSendNotification);
        }
        
    }
    
    public static void afterDelete(List<Account> oldAccounts)
    {
        Set<Id> userIds = new Set<Id>();
        for (Account acc : oldAccounts) {
            userIds.add(acc.CreatedById);
        }
        if (!userIds.isEmpty()) {
            updateCustomerCount(userIds);
        }
    }
    
    private static void loadAdminUsers() {
        
        if (sapAdminUserIds == null) {
            sapAdminUserIds = new Set<String>();
            
            for (User u : [
                SELECT Id FROM User WHERE Profile.Name = 'SAP Admin' AND IsActive = true
            ]) {
                sapAdminUserIds.add(u.Id);
            }
        }
        
        if (systemAdminUserIds == null) {
            systemAdminUserIds = new Set<String>();
            
            for (User u : [
                SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true
            ]) {
                systemAdminUserIds.add(u.Id);
            }
        }
    }
    
}