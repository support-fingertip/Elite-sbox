public class AzureAccountSyncQueue  implements Queueable, Database.AllowsCallouts {

    private Id accountId;
    private boolean isupdation;

    public AzureAccountSyncQueue(Id accId,boolean isupdation) {
        this.accountId = accId;
        this.isupdation = isupdation;
    }

    public void execute(QueueableContext qc) {
        Account acc = [
            SELECT Id, Name, Customer_Status__c, ERP_Check__c,By_Pass_Validation__c
            FROM Account
            WHERE Id = :accountId
        ];

        PostHandler.accPost(acc,isupdation);
    }
}