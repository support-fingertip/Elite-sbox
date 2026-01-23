public class StatusPathController 
{
    public class dataBox{ 
        @AuraEnabled
        public string RatingVal {get; set;}
        @AuraEnabled
        public list<string> picklistValues  {get; set;}
        @AuraEnabled
        public list<string> LostpicklistValues  {get; set;}
        @AuraEnabled
        public list<string> LeadStatuspicklistValues  {get; set;}
        @AuraEnabled
        public list<user> userlist  {get; set;}
       /* @AuraEnabled
        public list<Add_users__c> AddUserList  {get; set;}*/
        @AuraEnabled
        public Lead__c LeadRec  {get; set;}
        
    }
   
    
   
    @AuraEnabled
    public static dataBox getAllData(string recordId) {
        dataBox dbs= new dataBox();
        dbs.RatingVal=  [select Id,Rating__C from Lead__C where id=:recordId limit 1 ].Rating__c;
        
        String objectName = 'Lead__c';
        String fieldName = 'Rating__c';
        List<String> picklistValues = new List<String>();
        Schema.DescribeSObjectResult objectDescribe = Schema.getGlobalDescribe().get(objectName).getDescribe();
        Schema.DescribeFieldResult fieldDescribe = objectDescribe.fields.getMap().get(fieldName).getDescribe();
        system.debug('fieldDescribe'+fieldDescribe);
        List<Schema.PicklistEntry> picklistEntries = fieldDescribe.getPicklistValues();
        for (Schema.PicklistEntry entry : picklistEntries) {
            picklistValues.add(entry.getLabel());
        }
        dbs.picklistValues=picklistValues;
        
        String objectName1 = 'Lead__c';
        String fieldName1 = 'Lost_Reasons__c';
        List<String> picklistValues1 = new List<String>();
        Schema.DescribeSObjectResult objectDescribe1 = Schema.getGlobalDescribe().get(objectName1).getDescribe();
        Schema.DescribeFieldResult fieldDescribe1 = objectDescribe.fields.getMap().get(fieldName1).getDescribe();
        system.debug('fieldDescribe'+fieldDescribe1);
        
        List<Schema.PicklistEntry> picklistEntries1 = fieldDescribe1.getPicklistValues();
        for (Schema.PicklistEntry entry : picklistEntries1)
        {
            picklistValues1.add(entry.getLabel());
        }
        dbs.LostpicklistValues=picklistValues1;
        
        String objectName2 = 'Lead__c';
        String fieldName2 = 'Lead_Status__c';
        List<String> picklistValues2 = new List<String>();
        Schema.DescribeSObjectResult objectDescribe2 = Schema.getGlobalDescribe().get(objectName2).getDescribe();
        Schema.DescribeFieldResult fieldDescribe2 = objectDescribe.fields.getMap().get(fieldName2).getDescribe();
        system.debug('fieldDescribe'+fieldDescribe2);
        
        List<Schema.PicklistEntry> picklistEntries2 = fieldDescribe2.getPicklistValues();
        for (Schema.PicklistEntry entry : picklistEntries2)
        {
            picklistValues2.add(entry.getLabel());
        }
 
        dbs.LeadStatuspicklistValues=picklistValues2;
            
        dbs.userlist =  [select Id,Name from User order by Name];
        //dbs.AddUserList = [SELECT Id, Name, Lead__c, UserId__c FROM Add_users__c WHERE Lead__c =:recordId LIMIT 5];
        dbs.LeadRec = [SELECT Id, Name,Lead_Status__c,Approval_Status__c,Followup_Date__c,Lost_to_competitor_Name__c, Other_reason__c,Lost_Reasons__c from Lead__c where id=:recordId LIMIT 1];
        return dbs;
    }
    @AuraEnabled
    public static void MarkStatusAPex(string recordId, string currentStep) {
        lead__c ld = new lead__c();
        ld.id=recordId;
        ld.Lead_Status__c=currentStep;
        update ld;
       
    }
 	@AuraEnabled
    public static string SaveRatingpop(string Rating,string LeadId, Date FollowUpDate) {
        
        try {
            
            lead__c ld = new lead__c();
            ld.id=LeadId;
            if(Rating == null || Rating == '')
                Rating='Cold';
            ld.Rating__c=Rating;
            if(FollowUpDate != null)
                ld.Followup_Date__c=FollowUpDate;
            ld.Lead_Status__c='Follow Up';
            update ld;
            
            
            return 'Successfull';
        } catch (DmlException e) {
            System.debug('Upsert failed.');
            System.debug('Error: ' + e.getMessage());
            return e.getMessage() + 'unsuccessful';
        }
    }
    @AuraEnabled
    public static string Savelostpop(string OtherReason, String lostReason, string LostToCompetitorName, string LeadId){
        try {
            lead__c ld = new lead__c();
            ld.id=LeadId;
            ld.Lost_Reasons__c=lostReason;
            if(OtherReason != null && OtherReason != '')
            {
                ld.Other_reason__c=OtherReason;
            }
            if(LostToCompetitorName != null && LostToCompetitorName != '')
            {
                ld.Lost_to_competitor_Name__c = LostToCompetitorName;
            }
            ld.Lead_Status__c='Closed Lost';
            update ld;
            return 'Successfull';
        } catch (DmlException e) {
            System.debug('Upsert failed.');
            System.debug('Error: ' + e.getMessage());
            return e.getMessage() + 'unsuccessful';
        }
    }
    @AuraEnabled
    public static Lead__c RatingValue(string recordId) 
    {
        Lead__c ld = [select Id,Rating__C,Followup_Date__c from Lead__C where id=:recordId limit 1 ];
        return ld;
    }
    @AuraEnabled
    public static Lead__c LeadRecord(string recordId) 
    {
        Lead__c ld =[SELECT Id, Name,Lead_Status__c,Lost_to_competitor_Name__c, Other_reason__c,Lost_Reasons__c from Lead__c where id=:recordId LIMIT 1];
        return ld;
    }
    
}