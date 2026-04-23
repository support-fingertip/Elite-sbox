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

        Account acc;
        List<Account> accList = [
            SELECT Id, Name, SAP_Customer_Code__c, Primary_Customer_Type__c,
                   Email_ID__c, Primary_Phone_Number__c,
                   State__c, District__c, Land_Mark__c, Street__c
            FROM Account
            WHERE Id = :primaryCustomerId
            LIMIT 1
        ];
        if (!accList.isEmpty()) acc = accList[0];

        PageReference pdfPage = Page.GRNPdf;
        pdfPage.getParameters().put('id', grnId);
        pdfPage.getParameters().put('customerId', primaryCustomerId);
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

        String custName = (acc != null && acc.Name != null) ? acc.Name : '';
        String sapCode  = (acc != null && acc.SAP_Customer_Code__c != null) ? acc.SAP_Customer_Code__c : '';
        mail.setSubject('GRN Created: ' + grn.Name
            + ' | Customer: ' + custName
            + (String.isNotBlank(sapCode) ? ' (SAP: ' + sapCode + ')' : ''));

        String body =
            'A Goods Received Note (' + grn.Name + ') has been created.\n\n' +
            'Customer Details:\n' +
            'Customer Name        : ' + safe(acc != null ? acc.Name : null) + '\n' +
            'SAP Code             : ' + safe(acc != null ? acc.SAP_Customer_Code__c : null) + '\n' +
            'Primary Customer Type: ' + safe(acc != null ? acc.Primary_Customer_Type__c : null) + '\n' +
            'Email                : ' + safe(acc != null ? acc.Email_ID__c : null) + '\n' +
            'Phone                : ' + safe(acc != null ? acc.Primary_Phone_Number__c : null) + '\n' +
            'State                : ' + safe(acc != null ? acc.State__c : null) + '\n' +
            'District             : ' + safe(acc != null ? acc.District__c : null) + '\n' +
            'Land Mark            : ' + safe(acc != null ? acc.Land_Mark__c : null) + '\n' +
            'Street               : ' + safe(acc != null ? acc.Street__c : null) + '\n\n' +
            'Please find the details in the attached PDF.\n\nRegards,\nELITE FOODS PRIVATE LIMITED';
        mail.setPlainTextBody(body);

        Messaging.EmailFileAttachment att = new Messaging.EmailFileAttachment();
        att.setFileName('GRN_' + grn.Name + '.pdf');
        att.setBody(pdfBlob);
        att.setContentType('application/pdf');
        mail.setFileAttachments(new Messaging.EmailFileAttachment[] { att });


        if (!Test.isRunningTest()) {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }

    private static String safe(String v) { return String.isBlank(v) ? '-' : v; }
}