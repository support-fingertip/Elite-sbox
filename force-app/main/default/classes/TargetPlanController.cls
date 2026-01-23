public class TargetPlanController {
    public class Databox{ 
        @AuraEnabled
        public list<Product_Category__c> productCategoryList = new list<Product_Category__c>();
        @AuraEnabled
        public list<Selling_Category__c> sellingCategoryList = new list<Selling_Category__c>();
        @AuraEnabled
        public list<Product__c> productList = new list<Product__c>();
        @AuraEnabled
        public list<Region__c> regionList = new list<Region__c>();
        @AuraEnabled
        public list<Division__c> divisionList = new list<Division__c>();
        @AuraEnabled
        public List<Map<String, String>> incentiveType = new List<Map<String, String>> ();
        @AuraEnabled
        public List<Map<String, String>> targetType = new List<Map<String, String>> ();
        @AuraEnabled
        public List<Map<String, String>> accountType = new List<Map<String, String>> ();

        @AuraEnabled
        public Map<String, Map<String, String>> targetTypeObjectMap = new  Map<String, Map<String, String>>();
        @AuraEnabled
        public Map<String, Map<String, String>> formulaObjectMap = new  Map<String, Map<String, String>>();
        @AuraEnabled
        public Map<String, Map<String, String>> objectFieldMap = new  Map<String, Map<String, String>>();
        
        @AuraEnabled
        public Target_Plan__c targetPlan = new Target_Plan__c();
        @AuraEnabled
        public list<Target_Logic__c> targetLogicList = new list<Target_Logic__c>();
        @AuraEnabled
        public list<Incentive_Slab__c> incentiveSlabList = new list<Incentive_Slab__c>();
        @AuraEnabled
        public String recordAction = '';
        @AuraEnabled
        public String recordId = '';
        @AuraEnabled
        public String recordName = '';
    }

    @AuraEnabled
    public static Databox getAllData(string recordId) {
        Map<String, Object> picklistData = new Map<String, Object>();
		Databox dx = new Databox();
        dx.productCategoryList = [select Id,Name from Product_Category__c where Active__c = true];
        dx.productList = [select Id,Name,Product_Category1__c from Product__c where Is_Active__c = true];
        dx.regionList = [select Id,Name from Region__c where Active__c = true];
        dx.sellingCategoryList = [select Id,Name from Selling_Category__c];
        dx.divisionList = [select Id,Name from Division__c where Active__c = true];
        dx.incentiveType = extractPicklistValues('Target_Plan__c','Incentive_Type__c');
        dx.targetType = extractPicklistValues('Target_Logic__c','Target_Type__c');
        dx.accountType = extractPicklistValues('Target_Logic__c','Account_Type__c');
       
        // Fetch dependent picklist values (Formula → Object, Object → Field)
        dx.targetTypeObjectMap =  getDependentMap(new Target_Logic__c(), 'Target_Type__c', 'Formula__c');
        dx.formulaObjectMap = getDependentMap(new Target_Logic__c(), 'Formula__c', 'Object__c');
        dx.objectFieldMap = getDependentMap(new Target_Logic__c(), 'Object__c', 'Field__c');
        
        if(recordId != null && recordId != '')
        {
        	dx.targetPlan = [select Id,Name,Region__c,Division__c,Active__c,Incentive_Type__c from Target_Plan__c where Id =:recordId];
            dx.targetLogicList = [select Id,Name,Target_Type__c,Formula__c,Object__c,Field__c,Weightage__c,max_incentive__c,
                                  Account_Type__c,Product_Category__c,Product_Category__r.Name,Product__c,Product__r.Name,
                                  Target_Plan__c,Selling_Category__c,Selling_Category__r.Name
                                  from Target_Logic__c where Target_Plan__c =:recordId];
            dx.incentiveSlabList = [select Id,Name,Achievement_From__c,Achievement_To__c,Incentive_Percentage__c,
                                    Incentive_Amount__c,Target_Plan__c from Incentive_Slab__c where Target_Plan__c =:recordId];
        }
        
        return dx;      
    }
    
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
    

    private static List<Map<String, String>> extractPicklistValues(String objectName, String fieldName) {
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

    private static final String base64Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    public static String decimalToBinary(Integer val) {
        String bits = '';
        while (val > 0) {
            bits = String.valueOf(Math.mod(val, 2)) + bits;
            val = val / 2;
        }
        return bits;
    }

    private static List<PicklistEntryWrapper> wrapPicklistEntries(List<Schema.PicklistEntry> PLEs) {
        return (List<PicklistEntryWrapper>) JSON.deserialize(JSON.serialize(PLEs), List<PicklistEntryWrapper>.class);
    }

    public class PicklistEntryWrapper {
        public String label {get;set;}
        public String value {get;set;}
        public String validFor {get;set;}
    }
    
    @AuraEnabled
    public static Databox saveData(Target_Plan__c targetPlan, List<Target_Logic__c> targetLogicList, List<Incentive_Slab__c> slabs, List<string> deleteLogicsList, List<string> deleteSlabsList) {
        try {
            Databox dx = new Databox();
            
            // 1. Same Region, Division, Incentive Type – Allow only one target plan
            List<Target_Plan__c> existingTargetPlan = [
                SELECT Id, Name 
                FROM Target_Plan__c 
                WHERE Region__c = :targetPlan.Region__c 
                AND Division__c = :targetPlan.Division__c
                AND Incentive_Type__c = :targetPlan.Incentive_Type__c
                AND Id != :targetPlan.Id
                LIMIT 1
            ];
            
            if (!existingTargetPlan.isEmpty()) {
                dx.recordId = null;
                dx.recordName = existingTargetPlan[0].Name;
                dx.recordAction = 'Duplicate';
                return dx;
            }
            
            // 2. One active target plan for one Region-Division combination
            if (targetPlan.Active__c) {
                List<Target_Plan__c> activeTargetPlans = [
                    SELECT Id, Name 
                    FROM Target_Plan__c 
                    WHERE Region__c = :targetPlan.Region__c 
                    AND Division__c = :targetPlan.Division__c
                    AND Active__c = true
                    AND Id != :targetPlan.Id
                    LIMIT 1
                ];
                if (!activeTargetPlans.isEmpty()) {
                    dx.recordId = null;
                    dx.recordName = activeTargetPlans[0].Name;
                    dx.recordAction = 'Cannot Activate';
                    return dx;
                }
            }
            
            // 3. Prevent deactivation if connected Target Items exist
            if (targetPlan.Active__c == false && targetPlan.Id != null) {
                 Period__c per = [select id, Start_Date__c, End_Date__c  from Period__c where Start_Date__c <= TODAY and End_Date__c>= TODAY];
                List<Target_Logic__c> existingTargetLogics = [
                    SELECT Id, (SELECT Id FROM Target_Items__r where Target__r.Period__c =:per.Id) 
                    FROM Target_Logic__c 
                    WHERE Target_Plan__c = :targetPlan.Id
                ];
                
                for (Target_Logic__c logic : existingTargetLogics) {
                    if (logic.Target_Items__r != null && !logic.Target_Items__r.isEmpty()) {
                        dx.recordId = null;
                        dx.recordName = targetPlan.Name;
                        dx.recordAction = 'Cannot Deactivate';
                        return dx;
                    }
                }
            }
            
            // Delete Target Logics and Slabs
            if (!deleteLogicsList.isEmpty()) {
                List<Target_Logic__c> delLogicsList = [
                    SELECT Id, Name 
                    FROM Target_Logic__c 
                    WHERE Id IN :deleteLogicsList
                ];
                delete delLogicsList;
            }
            
            if (!deleteSlabsList.isEmpty()) {
                List<Incentive_Slab__c> delSlabsList = [
                    SELECT Id, Name 
                    FROM Incentive_Slab__c 
                    WHERE Id IN :deleteSlabsList
                ];
                delete delSlabsList;
            }
            
            // Insert or Update Target Plan
            upsert targetPlan;
            
            // Associate Target Plan ID with Target Logics
            for (Target_Logic__c logic : targetLogicList) {
                logic.Target_Plan__c = targetPlan.Id;
            }
            
            // Associate Target Plan ID with Incentive Slabs
            for (Incentive_Slab__c slab : slabs) {
                slab.Target_Plan__c = targetPlan.Id;
            }
            
            // Insert or Update Logics and Slabs
            if (!targetLogicList.isEmpty()) {
                upsert targetLogicList;
            }
            if (!slabs.isEmpty()) {
                upsert slabs;
            }
            
            dx.recordAction = 'Record Created Successfully';
            dx.recordId = targetPlan.Id;
            dx.recordName = targetPlan.Name;
            return dx;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error while saving data: ' + e.getMessage());
        }
    }

    
}