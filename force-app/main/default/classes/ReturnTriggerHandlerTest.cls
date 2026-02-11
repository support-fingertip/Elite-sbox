@isTest
public class ReturnTriggerHandlerTest {
 
    @isTest
    static void testAfterInsert() {
              // Insert the test records
        Test.startTest();
        // Create test data
        List<Return__c> testCollections = new List<Return__c>();
        
        // Add a few Return__c records with unique file IDs
        for (Integer i = 0; i < 5; i++) {
            testCollections.add(new Return__c(
                UniqueFileId__c = 'FileId_' + i,
                OwnerId = UserInfo.getUserId()
            ));
        }
        
        List<Return__c> testCollections1 = new List<Return__c>();
        
        // Add a few Return__c records with unique file IDs
        for (Integer i = 0; i < 5; i++) {
            testCollections1.add(new Return__c(
                UniqueFileId__c = 'FileId_' + i,
                OwnerId = UserInfo.getUserId()
            ));
        }
        insert testCollections1;
        
  
        insert testCollections;
        daily_log__c daily = new Daily_log__c();
        daily.OwnerId = UserInfo.getUserId();
        insert daily;
        
        delete testCollections1;
        Test.stopTest();
        
       
        //List<Collection__c> insertedCollections = [SELECT Id, UniqueFileId__c FROM Collection__c];
        //System.assertEquals(5, insertedCollections.size(), 'Five collections should be inserted.');
    }
}