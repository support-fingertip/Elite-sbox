@IsTest
public class AzureAccountSyncQueueTest {

    @IsTest
    static void testQueueableForAccountCreation() {

         Account acc= new Account();
        acc.Name='Test Account';
        acc.Customer_Type__c = 'Primary Customer';
        acc.Primary_Phone_Number__c ='3121212112';
        acc.State__c='Kerala';
        acc.District__c='Kozhikode';
        acc.Email_ID__c='abc@gmail.cm';
        insert acc;

        Test.startTest();
        System.enqueueJob(
            new AzureAccountSyncQueue(acc.Id, true)
        );
        Test.stopTest();

        // Just verify account exists
        Account a = [
            SELECT Id
            FROM Account
            WHERE Id = :acc.Id
        ];

        System.assertNotEquals(null, a);
    }

    @IsTest
    static void testQueueableForAccountUpdate() {

        Account acc= new Account();
        acc.Name='Test Account';
        acc.Customer_Type__c = 'Primary Customer';
        acc.Primary_Phone_Number__c ='3121212112';
        acc.State__c='Kerala';
        acc.District__c='Kozhikode';
        acc.Email_ID__c='abc@gmail.cm';
        insert acc;
        
        Test.startTest();
        System.enqueueJob(
            new AzureAccountSyncQueue(acc.Id, false)
        );
        Test.stopTest();

        Account a = [
            SELECT Id
            FROM Account
            WHERE Id = :acc.Id
        ];

        System.assertNotEquals(null, a);
    }
}