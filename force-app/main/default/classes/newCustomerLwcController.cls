public with sharing class newCustomerLwcController {
    //New Account Creation
    @AuraEnabled
    public static DataBox getAllData(string accountId) {
        DataBox db = new DataBox();
        string userId = UserInfo.getUserId();
        user userRecord =  [SELECT Id,Name,isAdmin__c,Profile.Name,Sales_Channel__c,Territory__c,Territory_Name__c FROM User WHERE Id = :userId limit 1];
        string profileNameValue = userRecord.Profile.Name;
        db.profileName =  profileNameValue;
        db.RecordTypeList = newCustomerLwcController.getAvailableRecordTypes();
        db.parentDeportList = GetPicklistValues.extractPicklistValues('Product_Mapping__c','Parent_Depot__c');
        db.currentUserRecord = userRecord;
        db.paymentTypeList =GetPicklistValues.extractPicklistValues('Product_Mapping__c','Payment_Type__c'); 
        db.incotermList = GetPicklistValues.extractPicklistValues('Product_Mapping__c','Inco_Terms__c');  
        db.paymemtTermList = GetPicklistValues.extractPicklistValues('Product_Mapping__c','Payment_Term__c'); 
        db.divisionList = GetPicklistValues.extractPicklistValues('Product_Mapping__c','Division__c'); 
        db.distributonChannelList = GetPicklistValues.extractPicklistValues('Product_Mapping__c','Distribution_Channel__c'); 
        db.salesOfficeList = GetPicklistValues.extractPicklistValues('Product_Mapping__c','Sales_Office__c'); 
        db.orderTypeList = GetPicklistValues.extractPicklistValues('Product_Mapping__c','Order_Type__c'); 
        db.pdpDayList = GetPicklistValues.extractPicklistValues('Product_Mapping__c','PDP_Day__c'); 
        
        db.parentDeportChildDeportMap = getDependentMap(new Product_Mapping__c(), 'Parent_Depot__c', 'Child_Depot__c');
        db.paymentTermCreditDescriptionMap = getDependentMap(new Product_Mapping__c(), 'Payment_Term__c', 'Credit_Description__c');
        db.paymenttypeToOrdertypeMap = getDependentMap(new Account(), 'Payment_Type__c', 'Order_Type__c');
        
        Set<ID> UserIds = RoleHeirarchyUtility.getUsersUnderRoleHierarchy(userId); 
        db.userList = [select Id,Name,Employee_Code__c,ManagerId,Manager.ManagerId,Profile.Name,Sales_Channel__c,Is_SSA_DSM__c,Territory_Name__c,
                       Territory__c from User where id in:UserIds and isactive = true];
        Map<Id, List<String>> userIdToSalesChannelsMap = new Map<Id, List<String>>();
        for (User u : db.userList) {
            List<String> channels = String.isNotBlank(u.Sales_Channel__c)
                ? u.Sales_Channel__c.split(';')
                : new List<String>();
            
            userIdToSalesChannelsMap.put(u.Id, channels);
        }
        db.userIdToSalesChannelsMap = userIdToSalesChannelsMap;
        db.areaList = [select Id,Name,Sales_Channel__c from Area__c];
        list<Account> primaryCustomers =  [select Id,Name,SAP_Customer_Code__c,Customer_Code__c,Primary_Customer_Type__c from Account where
                                           Customer_Type__c ='Primary Customer' and 
                                           (Customer_Status__c ='Active' OR Customer_Status__c ='Activation Pending') ];
        set<Id> primaryCustomerIds  = new set<Id>();
        Map<Id, Account> customerIdToAccount = new Map<Id, Account>();
        for(Account acc : primaryCustomers)
        {
            primaryCustomerIds.add(acc.Id);
            customerIdToAccount.put(acc.Id,acc);
        }
        
        
        /**----------Exectutive wise Primary Customers ----------**/
        Map<Id, Set<Id>> executiveToCustomerIds = new Map<Id, Set<Id>>();
       
        list<Product_Mapping__c> primaryMappings = [select Id,Customer__c,Exectuive__c from Product_Mapping__c where Customer__c =:primaryCustomerIds limit 50000];
        for (Product_Mapping__c pm : primaryMappings) {
            if (pm.Exectuive__c != null && pm.Customer__c != null) {
                // Map executive to Set of unique customer Ids
                if (!executiveToCustomerIds.containsKey(pm.Exectuive__c)) {
                    executiveToCustomerIds.put(pm.Exectuive__c, new Set<Id>());
                }
                executiveToCustomerIds.get(pm.Exectuive__c).add(pm.Customer__c);
            }
        }
        //For DSM and SSA Customers will be assigned in New Object
        list<Employee_Customer_Assignment__c> primayCustomerDsmAssignments = [
            Select Id,Name,Executive__c,Employee__c,Customer__c from Employee_Customer_Assignment__c
            where Customer__c =:primaryCustomerIds  limit 50000
        ];
        for (Employee_Customer_Assignment__c epm : primayCustomerDsmAssignments) {
            
            if (epm.Executive__c != null && epm.Customer__c != null) {
                // Map executive to Set of unique customer Ids
                if (!executiveToCustomerIds.containsKey(epm.Executive__c)) {
                    executiveToCustomerIds.put(epm.Executive__c, new Set<Id>());
                }
                executiveToCustomerIds.get(epm.Executive__c).add(epm.Customer__c);
            }
        }
        
        
        Map<Id, List<Account>> executiveWiseAccounts = new Map<Id, List<Account>>();
        for (Id executiveId : executiveToCustomerIds.keySet()) {
            List<Account> accounts = new List<Account>();
            for (Id accId : executiveToCustomerIds.get(executiveId)) {
                accounts.add(customerIdToAccount.get(accId));
            }
            executiveWiseAccounts.put(executiveId, accounts);
        }
        db.executiveWiseAccounts = executiveWiseAccounts;

        
        /**---------- All Secoudary Customer---------**/
        list<Account> subStockiests = [select Id from Account where Secondary_Customer_Type__c ='Sub Stockiest'];

        list<Product_Mapping__c> AllSubStockiestMappings  = [
            SELECT Customer__c,Customer__r.Name,Customer__r.Customer_Code__c,Primary_Customer__c,Exectuive__c FROM Product_Mapping__c WHERE
            Customer__r.Customer_Type__c = 'Secondary Customer' And Customer__c IN:subStockiests  And Primary_Customer__c  IN :primaryCustomerIds
            ORDER BY CreatedDate ];
        
        Map<Id, List<Account>> primaryToSubStockiestMap = new Map<Id, List<Account>>();
        Map<Id, Set<Id>> primaryToSubStockiestIds = new Map<Id, Set<Id>>();
        Map<Id, List<Id>> executiveToSubStockiestIds = new Map<Id, List<Id>>();
        
        for (Product_Mapping__c pm : AllSubStockiestMappings) {
            Id primaryId = pm.Primary_Customer__c;
            Account subStockist = pm.Customer__r;
            
            if (primaryId == null || subStockist == null) continue;
            
            // Initialize map and set if not already
            if (!primaryToSubStockiestMap.containsKey(primaryId)) {
                primaryToSubStockiestMap.put(primaryId, new List<Account>());
                primaryToSubStockiestIds.put(primaryId, new Set<Id>());
            }
            
            // Check uniqueness
            if (!primaryToSubStockiestIds.get(primaryId).contains(subStockist.Id)) {
                primaryToSubStockiestMap.get(primaryId).add(subStockist);
                primaryToSubStockiestIds.get(primaryId).add(subStockist.Id);
            }
            
            //Executive wise Sub Stockiests
            if (!executiveToSubStockiestIds.containsKey(pm.Exectuive__c)) {
                executiveToSubStockiestIds.put(pm.Exectuive__c, new List<Id>());
            }
            executiveToSubStockiestIds.get(pm.Exectuive__c).add(pm.Customer__c);
        }
        db.executiveToSubStockiestIds = executiveToSubStockiestIds;
        //system.debug('primaryToSubStockiestMap'+primaryToSubStockiestMap);

        db.primaryToSubStockiestMap = primaryToSubStockiestMap;
        db.primaryCustomerList = primaryCustomers;
        
        
        db.OTPVerificationSkipCustomerTypes = label.OTPVerificationSkipCustomerTypes;
        db.OTPVerificationSkipSalesChannels = label.CNN_Skip_Sales_Channels;
        
        
        db.employeeAccess = [select Id,Edit_Credit_Information__c,Map_Executive_In_Product_Mapping__c from Employee_Creation_Access__mdt
                            where 	Label =:profileNameValue];
        db.orderTypeDependencyList = [SELECT Sales_Channel__c, Payment_Type__c, Division__c, Order_Type__c FROM Order_Type_Dependency__mdt];
        
        if(accountId != null && accountId != '')
        {
            db.customerType = [select id,Customer_Type__c from Account where Id =:accountId limit 1].Customer_Type__c; 
            db.currentAccount = [select id,Customer_Type__c,Payment_Type__c,Secondary_Customer_Type__c from Account where Id =:accountId limit 1];

            db.productMappingList = [select Id,Name,Customer__c,Customer__r.Customer_Type__c,PDP_Name__c,PDP_Day__c,	Parent_Depot__c,Executive_Name__c,Exectuive__c,
                                     Child_Depot__c,Chanel__c,Area_Name__c,Area__c,Area__r.Name, Credit_Terms__c, Credit_Limit__c,Payment_Type__c,Exectuive__r.Name,
                                     Payment_Term__c,Credit_Description__c,Inco_Terms__c,Primary_Customer_Name__c,Primary_Customer__c,Primary_Customer__r.Name,
                                     Sub_Stockiest__r.Name,Primary_Customer_Type__c,
                                     Order_Type__c,Distribution_Channel__c,Sales_Office__c, Division__c,Sub_Stockiest__c,Sub_Stockiest_Name__c
                                     from Product_Mapping__c where Customer__c =:accountId order by createdDate];
        }
        
        List<Id> substockistIds = executiveToSubStockiestIds.containsKey(userId) ? executiveToSubStockiestIds.get(userId) : new List<Id>();
        
        db.beatList = [select Id,Name,Sub_Stockist__c,Primary_Customer__c,Sub_Stockiest_Name__c,Primary_Customer_Name__c,
                       Primary_Customer_Type__c,Beat_Type__c,Owner_Name__c,OwnerId from Child_beat__c where OwnerId =: userId
                       AND (
                           (Primary_Customer__c IN :primaryCustomerIds AND Sub_Stockist__c = null)
                           OR
                           (Sub_Stockist__c IN :substockistIds AND Primary_Customer__c IN :primaryCustomerIds)
                           OR
                           (Primary_Customer__c = null AND Sub_Stockist__c = null)                           
                       )
                      ];
        
       
        return db;
    }
    @AuraEnabled
    public static List<RecordType> getAvailableRecordTypes() {
        // Get all record types for the Account object
        Map<String, Schema.RecordTypeInfo> recordTypeMap = Schema.getGlobalDescribe().get('Account')
            .getDescribe().getRecordTypeInfosByName();
        
        List<RecordType> availableRecordTypes = new List<RecordType>();
        
        for (Schema.RecordTypeInfo rtInfo : recordTypeMap.values()) {
            if (rtInfo.isAvailable() && !rtInfo.isMaster()) { // Only include record types available for the current user
                availableRecordTypes.add(new RecordType(Id = rtInfo.getRecordTypeId(), Name = rtInfo.getName()));
            }
        }
        return availableRecordTypes;
    }
    @AuraEnabled
    public static boolean sendOtp(string mobileNo,string OTP) {
        if (String.isNotBlank(mobileNo)) {
            return SMSAPIService.sendSMS(mobileNo, OTP);
        }
        return false;
    }
    @AuraEnabled
    public static String validateFileUpload(String uniqueFileId, String customerType,boolean customerPremises) {
        // Define required suffixes based on customer type
        List<String> requiredSuffixes = new List<String>();
        if (customerType == 'Primary Customer') {
            List<String> allSuffixes = new List<String>{
                'Store-Image', 'Pan-Card', 'Aadar-Card', 'Commercial-Certificate', 'GST-Certificate', 'Cheque-Copy'
                    };
                        
            if (!customerPremises) {
                Integer indexToRemove = allSuffixes.indexOf('Store-Image');
                if (indexToRemove != -1) {
                    allSuffixes.remove(indexToRemove);
                }
            }
            
            requiredSuffixes.addAll(allSuffixes);
        }
        else if (customerType == 'Secondary Customer') {
            requiredSuffixes.add('Store-Image');
        } else {
            return 'Invalid Customer Type';
        }
        
        // Query ContentDocuments using Description (mapped to unique ID)
        List<ContentDocument> uploadedDocs =  [SELECT Id, Title, FileType,SystemModStamp FROM ContentDocument 
                                               WHERE Id IN (SELECT ContentDocumentId FROM ContentVersion WHERE Description = :uniqueFileId)
                                               AND ContentAssetId = null]; 
        
        // Track which suffixes are found
        Set<String> foundSuffixes = new Set<String>();
        
        for (ContentDocument doc : uploadedDocs) {
            for (String suffix : requiredSuffixes) {
                if (doc.Title != null && doc.Title.endsWith(suffix)) {
                    foundSuffixes.add(suffix);
                    break; // No need to check other suffixes for this doc
                }
            }
        }

        
        // Identify missing suffixes
        List<String> missing = new List<String>();
        for (String suffix : requiredSuffixes) {
            if (!foundSuffixes.contains(suffix)) {
                missing.add(suffix);
            }
        }
        
        return missing.isEmpty() ? 'Success' : String.join(missing, ', ');
    }
    @AuraEnabled
    public static DataBox dupicationCheck(Account accountData) {
        DataBox db = new DataBox();
        db.accountName = '';
        db.duplicateFound = false;
        list<Account> duplicateAccount = [select Id ,Name,Primary_Phone_Number__c from Account where Primary_Phone_Number__c =:
                                          accountData.Primary_Phone_Number__c and Customer_Type__c =: accountData.Customer_Type__c limit 1];
        if(!duplicateAccount.isEmpty())
        {
            db.accountName = duplicateAccount[0].Name;
            db.duplicateFound = true;
        }
        return db;
        
    }
    
	//Save Data    
    @AuraEnabled
    public static string saveData(Account accountData, List<Product_Mapping__c> productMappingList) {
       
        Boolean shouldSubmitForApproval = true;
        
        if (accountData.Customer_Type__c == 'Secondary Customer') {
            User currentUser = [
                SELECT Secondary_Customer_Approver_1__c, Secondary_Customer_Approver_2__c 
                FROM User 
                WHERE Id = :UserInfo.getUserId()
                LIMIT 1
            ];
            
            Boolean hasApprover = 
                currentUser.Secondary_Customer_Approver_1__c != null || 
                currentUser.Secondary_Customer_Approver_2__c != null;
            
            if (!hasApprover) {
                accountData.Customer_Status__c = 'Active';
                accountData.Approval_Status__c = 'Level 2 Approved';
                shouldSubmitForApproval = false;
            }
        }
        
        // Insert Account
        insert accountData;
            
        // Upsert Product Mappings with reference to Account
        if (productMappingList != null && !productMappingList.isEmpty()) {
            for (Product_Mapping__c pm : productMappingList) {
                pm.Customer__c = accountData.Id;
            }

            database.upsert(productMappingList,false);
            
            
            List<Junction_Beat__c> newJunctionBeats = new List<Junction_Beat__c>();
            if (accountData.Beat__c != null) {
                // Query the latest order number per Beat
                List<Child_beat__c> beatList = [
                    SELECT Id, 
                    (SELECT Id, Name, Order_Number__c 
                     FROM Junction_Beats__r
                     ORDER BY Order_Number__c DESC 
                     LIMIT 1) 
                    FROM Child_beat__c 
                    WHERE Id  =: accountData.Beat__c
                ];
                
                for (Child_beat__c cb : beatList) {
                    Decimal highestOrder = 0;
                    
                    if (!cb.Junction_Beats__r.isEmpty()) {
                        Junction_Beat__c latestBeatItem = cb.Junction_Beats__r[0];
                        highestOrder = latestBeatItem.Order_Number__c != null ? latestBeatItem.Order_Number__c : 0;
                    }
                  
                    // Create new beat item with incremented order number
                    Junction_Beat__c newItem = new Junction_Beat__c();
                    newItem.Child_Beat__c = cb.Id;
                    newItem.BeatFromAccount__c = true;
                    newItem.Account__c = accountData.Id;
                    newItem.Order_Number__c = highestOrder + 1;
                    newJunctionBeats.add(newItem);  
                }
                
                if (!newJunctionBeats.isEmpty()) {
                    database.insert(newJunctionBeats,false);
                }
            }
            
            
            //Auto Mapping the secondary customeer st users who has the primary mapping
            if (accountData.Customer_Type__c == 'Secondary Customer') {
                MappingHelper.saveAutoMappingData(accountData,productMappingList);
            }
			//database.insert(productMappingToInsert,false);
        }
        
        // Submit for approval if needed
        if (shouldSubmitForApproval) {
            try {
                Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                req.setComments('Submitting for Approval');
                req.setObjectId(accountData.Id);
                
                Approval.ProcessResult result = Approval.process(req);
                if (!result.isSuccess()) {
                    System.debug('Approval submission failed: ' + result.getErrors()[0].getMessage());
                }
            } catch (Exception e) {
                System.debug('Approval submission exception: ' + e.getMessage());
                // throw new AuraHandledException('Approval error: ' + e.getMessage());
            }
        }
        
        return accountData.Id; 
    }
    @AuraEnabled
    public static void saveProductData(List<Product_Mapping__c> productMappingList, list<String> deleteProductMappingList) {
        if(!deleteProductMappingList.isEmpty())
        {
            list<Product_Mapping__c> lstProductMapping = [select Id from Product_Mapping__c where Id IN:deleteProductMappingList];
            if(!lstProductMapping.isEmpty()){
                delete lstProductMapping;
            }
        }
        system.debug('productMappingList'+productMappingList.size());
        upsert productMappingList;
    } 
    
    //To get dependent picklist and picklist values
    @AuraEnabled
    public static Map<String, Map<String, String>> getDependentMap(SObject objDetail, String contrFieldApiName, String depFieldApiName) {
        System.debug('Fetching dependent picklist values...');
        
        Map<String, Map<String, String>> objResults = new Map<String, Map<String, String>>();
        
        Schema.sObjectType objType = objDetail.getSObjectType();
        if (objType == null) return objResults;
        
        Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();
        if (!objFieldMap.containsKey(contrFieldApiName) || !objFieldMap.containsKey(depFieldApiName)) return objResults;
        
        Schema.SObjectField ctrlField = objFieldMap.get(contrFieldApiName);
        Schema.SObjectField depField = objFieldMap.get(depFieldApiName);
        
        List<Schema.PicklistEntry> ctrlEntries = ctrlField.getDescribe().getPicklistValues();
        List<PicklistEntryWrapper> depEntries = wrapPicklistEntries(depField.getDescribe().getPicklistValues());
        
        List<String> ctrlValues = new List<String>();
        for (Schema.PicklistEntry ple : ctrlEntries) {
            String label = ple.getLabel();
            String value = ple.getValue();
            objResults.put(value, new Map<String, String>());
            ctrlValues.add(value);
        }
        
        Integer index = 0;
        for (PicklistEntryWrapper depEntry : depEntries) {
            String depLabel = depEntry.label;
            String depValue = depEntry.value;
            String validForBits = base64ToBits(depEntry.validFor);
            
            for (Integer i = 0; i < validForBits.length(); i++) {
                if (validForBits.mid(i, 1) == '1') {
                    objResults.get(ctrlValues.get(i)).put(depLabel, depValue);
                }
            }
        }
 
        
        return objResults;
    }
    public static List<Map<String, String>> extractPicklistValues(String objectName, String fieldName) {
        // Get the global describe map
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        
        // Check if the object exists
        if (!schemaMap.containsKey(objectName)) {
            return new List<Map<String, String>>();
        }
        
        Schema.DescribeSObjectResult objDescribe = schemaMap.get(objectName).getDescribe();
        Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
        
        // Check if the field exists in the object
        if (!fieldMap.containsKey(fieldName)) {
            return new List<Map<String, String>>();
        }
        
        Schema.DescribeFieldResult fieldResult = fieldMap.get(fieldName).getDescribe();
        List<Map<String, String>> picklistValues = new List<Map<String, String>>();
        
        if (fieldResult != null && fieldResult.getType() == Schema.DisplayType.Picklist) {
            for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
                picklistValues.add(new Map<String, String>{
                    'label' => entry.getLabel(),
                        'value' => entry.getValue()
                        });
            }
        }
        return picklistValues;
    }
    public static String base64ToBits(String validFor) {
        if (String.isEmpty(validFor)) return '';
        String validForBits = '';

        for (Integer i = 0; i < validFor.length(); i++) {
            Integer val = base64Chars.indexOf(validFor.mid(i, 1));
            validForBits += decimalToBinary(val).leftPad(6, '0');
        }
        return validForBits;
    }
    public static final String base64Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    public static String decimalToBinary(Integer val) {
        String bits = '';
        while (val > 0) {
            bits = String.valueOf(Math.mod(val, 2)) + bits;
            val = val / 2;
        }
        return bits;
    }
    public static List<PicklistEntryWrapper> wrapPicklistEntries(List<Schema.PicklistEntry> PLEs) {
        return (List<PicklistEntryWrapper>) JSON.deserialize(JSON.serialize(PLEs), List<PicklistEntryWrapper>.class);
    }
    public class PicklistEntryWrapper {
        public String label {get;set;}
        public String value {get;set;}
        public String validFor {get;set;}
    }
    public class DataBox
    {
        @AuraEnabled public string profileName;
        @AuraEnabled public List<RecordType> RecordTypeList;
        @AuraEnabled public List<Map<String, String>> parentDeportList = new List<Map<String, String>> ();
        @AuraEnabled public Map<Id, List<String>> userIdToSalesChannelsMap = new Map<Id, List<String>> ();
        
        @AuraEnabled public List<Map<String, String>> creditTermList = new List<Map<String, String>> ();
        @AuraEnabled public List<Map<String, String>> chanelList = new List<Map<String, String>> ();
        @AuraEnabled public List<Map<String, String>> paymentTypeList = new List<Map<String, String>> ();
        @AuraEnabled public List<Map<String, String>> incotermList = new List<Map<String, String>> ();
        @AuraEnabled public List<Map<String, String>> paymemtTermList = new List<Map<String, String>> ();
        @AuraEnabled public Map<String, Map<String, String>> parentDeportChildDeportMap = new  Map<String, Map<String, String>>();
        @AuraEnabled public Map<String, Map<String, String>> paymentTermCreditDescriptionMap = new  Map<String, Map<String, String>>();
        @AuraEnabled public Map<String, Map<String, String>> paymenttypeToOrdertypeMap = new  Map<String, Map<String, String>>();
        @AuraEnabled public List<User> userList;
        @AuraEnabled public List<Area__c> areaList;
        //@AuraEnabled public List<PDP__c> PDPList;
        //@AuraEnabled public Map<Id, List<PDP__c>> areaToPDPMap = new Map<Id, List<PDP__c>>();
        @AuraEnabled public List<Product_Mapping__c> productMappingList;
        @AuraEnabled public Map<Id, List<Account>> primaryToSubStockiestMap = new Map<Id, List<Account>>();
        @AuraEnabled public List<Account> primaryCustomerList;
        @AuraEnabled public User currentUserRecord;
        @AuraEnabled public string customerType;
        @AuraEnabled public string accountName;
        @AuraEnabled public boolean duplicateFound ;
        @AuraEnabled public string OTPVerificationSkipCustomerTypes;
        @AuraEnabled public string OTPVerificationSkipSalesChannels;
        @AuraEnabled public Account currentAccount;
        @AuraEnabled public List<Map<String, String>> divisionList = new List<Map<String, String>> ();
        @AuraEnabled public List<Map<String, String>> distributonChannelList = new List<Map<String, String>> ();
        @AuraEnabled public List<Map<String, String>> orderTypeList = new List<Map<String, String>> ();
        @AuraEnabled public List<Map<String, String>> salesOfficeList = new List<Map<String, String>> ();
        @AuraEnabled public Employee_Creation_Access__mdt employeeAccess = new Employee_Creation_Access__mdt ();
        @AuraEnabled public List<Map<String, String>> pdpDayList = new List<Map<String, String>> ();
        @AuraEnabled public List<Child_beat__c> beatList = new List<Child_beat__c> ();
        @AuraEnabled public Map<Id, List<Account>> executiveWiseAccounts = new Map<Id, List<Account>>();
        @AuraEnabled public Map<Id, List<Id>> executiveToSubStockiestIds = new Map<Id, List<Id>>();
        @AuraEnabled public List<Order_Type_Dependency__mdt> orderTypeDependencyList = new List<Order_Type_Dependency__mdt> ();
    }
    
}