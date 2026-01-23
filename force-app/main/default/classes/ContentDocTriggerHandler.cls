public class ContentDocTriggerHandler 
{
    public static void beforeDelete(list<ContentDocument> contentDocumentsList)
    {
        Schema.DescribeSObjectResult inv = Account.sObjectType.getDescribe();
        String accKeyPrefix = inv.getKeyPrefix();
        List<Id> contentDocId = new List<Id>();
        Map<Id, Id> contDocLinkedMap = new Map<Id, Id>();
        String profileName = [SELECT Profile.Name  FROM User  WHERE Id = :UserInfo.getUserId()  LIMIT 1].Profile.Name;
        if (profileName != 'System Administrator') {
            
            for(ContentDocument con : contentDocumentsList){
                contentDocId.add(con.Id);
            }
            
            for(ContentDocumentLink cdl : [SELECT ContentDocumentId, LinkedEntityId FROM
                                           ContentDocumentLink WHERE ContentDocumentId IN : contentDocId]){
                contDocLinkedMap.put(cdl.ContentDocumentId, cdl.LinkedEntityId);
            }
            
            for(ContentDocument cdoc : contentDocumentsList){
                if(accKeyPrefix == String.valueOf(contDocLinkedMap.get(cdoc.Id)).left(3)){
                   // cdoc.adderror('You are not allowed to delete files related to Account.');
                } 
            }
            
        }
    }
    
}