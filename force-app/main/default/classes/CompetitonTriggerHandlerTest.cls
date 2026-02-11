@isTest
public class CompetitonTriggerHandlerTest {
    
    @isTest
    static void testAfterInsertWithMatchingFiles() {
        // Get the ContentDocumentIds for our test files
        List<ContentVersion> insertedFiles = [SELECT Id, ContentDocumentId FROM ContentVersion];
        Map<String, Id> fileDescriptionToContentDocId = new Map<String, Id>();
        for(ContentVersion cv : insertedFiles) {
            // Update descriptions to match our test pattern
            cv.Description = cv.Title.contains('1') ? 'FILE123' : 'FILE456';
            fileDescriptionToContentDocId.put(cv.Description, cv.ContentDocumentId);
        }
        update insertedFiles;
        
        // Create test competitions with matching UniqueFileIds
        List<Competition__c> testCompetitions = new List<Competition__c>{
            new Competition__c(
                UniqueFileId__c = 'FILE123'
            ),
            new Competition__c(
                UniqueFileId__c = 'FILE456'
            )
        };
        
      
        
        Test.startTest();
        insert testCompetitions;
        Test.stopTest();
      
    }
    

}