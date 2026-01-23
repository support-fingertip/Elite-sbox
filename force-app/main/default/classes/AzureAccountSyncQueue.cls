public class AzureAccountSyncQueue  implements Queueable, Database.AllowsCallouts {

    private Id accountId;
    private boolean iscreation;

    public AzureAccountSyncQueue(Id accId,boolean isNew) {
        this.accountId = accId;
        this.iscreation = isNew;
    }

    public void execute(QueueableContext qc) {
        Account acc = [
            SELECT Id, Name, Customer_Status__c, ERP_Check__c,By_Pass_Validation__c
            FROM Account
            WHERE Id = :accountId
        ];

        PostHandler.accPost(acc,iscreation);
    }
}