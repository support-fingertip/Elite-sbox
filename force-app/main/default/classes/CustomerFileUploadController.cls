public class CustomerFileUploadController {
    public class DataBox
    {
        @AuraEnabled public string profileName;
        @AuraEnabled public string customerType;
        @AuraEnabled public boolean customerPremises;
    }
    @auraEnabled
    public static DataBox getCustomerType(String recordId)
    {
        DataBox db = new DataBox();
        string userId = UserInfo.getUserId();
        user userRecord =  [SELECT Id,Name, Profile.Name,Sales_Channel__c FROM User WHERE Id = :userId limit 1];
        db.profileName =  userRecord.Profile.Name;
        Account acc = [select Customer_Type__c,On_Customer_Premises__c from Account where Id =:recordId];
        db.customerType = acc.Customer_Type__c; 
        db.customerPremises = acc.On_Customer_Premises__c;
        return db; 
    }
    @AuraEnabled  
    public static List<ContentDocument> getFiles(String recordId,String filterName,string uniqueId){ 
        System.debug('here==>toload'+filterName+'recordId'+recordId);
        ID filter = recordId;
        filterName='%'+filterName;
        if(uniqueId !=  null && uniqueId != '')
        {
            return [SELECT Id, Title, FileType,SystemModStamp FROM ContentDocument 
                    WHERE Id IN (SELECT ContentDocumentId FROM ContentVersion WHERE Description = :uniqueId)
                    AND ContentAssetId = null and Title like :filterName]; 
        }
        else
        {
            List<ContentDocumentLink> cdlList = [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId=:filter];                         
            Set<Id> documentIds = new Set<Id>(); 
            
            for(ContentDocumentLink cdl:cdlList){  
                documentIds.add(cdl.ContentDocumentId);  
            }   
            system.debug('documentIds'+documentIds);
            return [SELECT Id, Title, SystemModStamp FROM ContentDocument WHERE Id IN :documentIds and Title like :filterName];    
        } 
    } 
    
    @AuraEnabled
    public static Map<String, List<ContentDocument>> getFilesBatch(String recordId, List<String> filterNames, String uniqueId) {
        Map<String, List<ContentDocument>> resultMap = new Map<String, List<ContentDocument>>();
        Set<Id> documentIds = new Set<Id>();
        Map<String, String> filterLikeMap = new Map<String, String>();
        
        for (String name : filterNames) {
            filterLikeMap.put(name, '%' + name);
            resultMap.put(name, new List<ContentDocument>());
        }
        
        if (String.isNotBlank(uniqueId)) {
            List<ContentDocument> docs = [
                SELECT Id, Title, FileType, SystemModStamp 
                FROM ContentDocument 
                WHERE Id IN (SELECT ContentDocumentId FROM ContentVersion WHERE Description = :uniqueId)
                AND ContentAssetId = null
            ];
            
            for (ContentDocument doc : docs) {
                for (String filterName : filterNames) {
                    if (doc.Title != null && doc.Title.endsWith(filterName)) {
                        resultMap.get(filterName).add(doc);
                    }
                }
            }
        } else {
            List<ContentDocumentLink> links = [
                SELECT ContentDocumentId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId = :recordId
            ];
            
            for (ContentDocumentLink link : links) {
                documentIds.add(link.ContentDocumentId);
            }
            
            List<ContentDocument> docs = [
                SELECT Id, Title, SystemModStamp 
                FROM ContentDocument 
                WHERE Id IN :documentIds
            ];
            
            for (ContentDocument doc : docs) {
                for (String filterName : filterNames) {
                    if (doc.Title != null && doc.Title.endsWith(filterName)) {
                        resultMap.get(filterName).add(doc);
                    }
                }
            }
        }
        
        return resultMap;
    }

    
    
    
    @AuraEnabled  
    public static void deleteFile(String contentDocumentId){ 
        delete [SELECT Id from ContentDocument WHERE Id = :contentDocumentId];       
    }  
    @AuraEnabled
    public static void updateDocument(String prefixName,List<String> idList, string uniqueId){
        System.debug('here to Update with '+prefixName);
        List<ContentDocument> cdlList = [SELECT Id, Title FROM ContentDocument WHERE Id=:idList]; 
        for(integer i=0;i<cdlList.size();i++){
            cdlList[i].Title+='-'+prefixName;
        }
        update cdlList; 
        
        list<ContentVersion> versionlist = [SELECT Id, Title,Description FROM ContentVersion WHERE ContentDocumentId IN :idList ORDER BY CreatedDate];
        if(uniqueId != null && uniqueId != '')
        {
            for(integer i=0;i<versionlist.size();i++){
                versionlist[i].Description = uniqueId;
            }
            update versionlist;
        }
    
        
    }
    @AuraEnabled  
    public static List<ContentDocument> getFilesAll(String recordId,String filterName){ 
        System.debug('here==>toload'+filterName+'recordId'+recordId);
        list<ContentDocument> listContentDocAll= new  list<ContentDocument>(); 
        ID filter = recordId;
        string[] filterArray = filterName.split(',');
        
        List<ContentDocumentLink> cdlList = [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId=:filter];
        Set<Id> documentIds = new Set<Id>(); 
        
        for(ContentDocumentLink cdl:cdlList){  
            documentIds.add(cdl.ContentDocumentId);  
        }   
        system.debug('documentIds'+documentIds);
        for(integer i=0;i<filterArray.size();i++){
            filterName='%'+filterArray[i]+'%';
            list<ContentDocument> listContentDoc =[SELECT Id, Title, SystemModStamp FROM ContentDocument WHERE Id IN :documentIds and Title like :filterName];
            listContentDocAll.addAll(listContentDoc);
            
        }
        return  listContentDocAll;       
    } 
}