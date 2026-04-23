public class GRNNotificationQueueable implements Queueable,  Database.AllowsCallouts  {

    private Id grnId;
    private Id primaryCustomerId;

    public GRNNotificationQueueable(Id grnId, Id primaryCustomerId) {
        this.grnId = grnId;
        this.primaryCustomerId = primaryCustomerId;
    }

    public void execute(QueueableContext ctx) {
        system.debug('GRN Notification1');
        if (grnId == null || primaryCustomerId == null) return;
        system.debug('GRN Notification2');
        Set<Id> execIds = new Set<Id>();
        for (Product_Mapping__c pm : [
            SELECT Exectuive__c
            FROM Product_Mapping__c
            WHERE Customer__c = :primaryCustomerId AND Exectuive__c != null
        ]) {
            execIds.add(pm.Exectuive__c);
        }
        system.debug('GRN Notification3');
        if (execIds.isEmpty()) return;

        Set<String> toAddresses = new Set<String>();
        for (User u : [
            SELECT Email, Manager.Email
            FROM User
            WHERE Id IN :execIds AND IsActive = true
        ]) {
            if (u.Email != null) toAddresses.add(u.Email);
            if (u.Manager != null && u.Manager.Email != null) toAddresses.add(u.Manager.Email);
        }
        if (toAddresses.isEmpty()) return;
        system.debug('GRN Notification4');
        List<Goods_Received_Note__c> grnList = [
            SELECT Id, Name FROM Goods_Received_Note__c WHERE Id = :grnId LIMIT 1
        ];
        if (grnList.isEmpty()) return;
        Goods_Received_Note__c grn = grnList[0];

        PageReference pdfPage = Page.GRNPdf;
        pdfPage.getParameters().put('id', grnId);
        Blob pdfBlob = Test.isRunningTest()
            ? Blob.valueOf('Test PDF content')
            : pdfPage.getContentAsPDF();

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new List<String>(toAddresses));
        // Set sender using Org-Wide Email Address (Name = "System Admin Email")
        OrgWideEmailAddress owea = [
            SELECT Id 
            FROM OrgWideEmailAddress 
            WHERE DisplayName = 'Elite Admin' // or use Address = 'admin@yourdomain.com'
            LIMIT 1
        ];
        mail.setOrgWideEmailAddressId(owea.Id);
        mail.setSubject('GRN Created: ' + grn.Name);
        mail.setPlainTextBody(
            'A Goods Received Note (' + grn.Name + ') has been created. ' +
            'Please find the details in the attached PDF.\n\nRegards,\nELITE FOODS PRIVATE LIMITED'
        );

        Messaging.EmailFileAttachment att = new Messaging.EmailFileAttachment();
        att.setFileName('GRN_' + grn.Name + '.pdf');
        att.setBody(pdfBlob);
        att.setContentType('application/pdf');
        mail.setFileAttachments(new Messaging.EmailFileAttachment[] { att });


        if (!Test.isRunningTest()) {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }
}