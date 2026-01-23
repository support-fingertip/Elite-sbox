@isTest
public class AreaTriggerTest {
    
    @isTest
    static void testAfterInsertTrigger() {
        
        Area__c area = new Area__c(
            Name = 'Test Area'
         );
        insert area;
        Area__c insertedArea = [SELECT Id, Territory_Code__c, Territory_Code_Text__c FROM Area__c WHERE Id = :area.Id];
        
        
    }
}