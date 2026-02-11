public without sharing class CustomDuplicationService {
    public class DataBox
    {
        @AuraEnabled public string accountName;
        @AuraEnabled public boolean duplicateFound ;
    }
    @AuraEnabled
    public static DataBox dupicationCheck(Account accountData) {
        DataBox db = new DataBox();
        db.accountName = '';
        db.duplicateFound = false;
        
        List<Account> duplicateAccount = [
            SELECT Id, Name, Primary_Phone_Number__c 
            FROM Account 
            WHERE Primary_Phone_Number__c = :accountData.Primary_Phone_Number__c 
            AND Customer_Type__c = :accountData.Customer_Type__c 
            LIMIT 1
        ];
        
        if (!duplicateAccount.isEmpty()) {
            db.accountName = duplicateAccount[0].Name;
            db.duplicateFound = true;
        }
        
        return db;
    }
}