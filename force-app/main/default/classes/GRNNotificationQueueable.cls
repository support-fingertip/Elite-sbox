public with sharing class GRNNotificationQueueable implements Queueable, Database.AllowsCallouts {
    
    private Id grnId;
    private Id primaryCustomerId;
    
    public GRNNotificationQueueable(Id grnId, Id primaryCustomerId) {
        this.grnId = grnId;
        this.primaryCustomerId = primaryCustomerId;
    }
    
    public void execute(QueueableContext ctx) {
        System.debug('### GRN Notify: START grnId=' + grnId + ' customerId=' + primaryCustomerId);
        
        if (grnId == null || primaryCustomerId == null) {
            System.debug('### GRN Notify: NULL ids — exit');
            return;
        }
        
        // Step 1: Get executive Ids from Product_Mapping__c
        Set<Id> execIds = new Set<Id>();
        for (Product_Mapping__c pm : [
            SELECT Exectuive__c
            FROM Product_Mapping__c
            WHERE Customer__c = :primaryCustomerId AND Exectuive__c != null
        ]) {
            execIds.add(pm.Exectuive__c);
        }
        System.debug('### GRN Notify: execIds=' + execIds);
        
        // Step 2: Get Account details + Sales_Channel__c
        Account acc;
        Set<String> accountSalesChannels = new Set<String>();
        List<Account> accList = [
            SELECT Id, Name, SAP_Customer_Code__c, Primary_Customer_Type__c,
            Email_ID__c, Primary_Phone_Number__c,
            State__c, District__c, Land_Mark__c, Street__c,
            Sales_Channel__c
            FROM Account
            WHERE Id = :primaryCustomerId
            LIMIT 1
        ];
        if (!accList.isEmpty()) {
            acc = accList[0];
            // Parse comma-separated Sales_Channel__c from Account
            if (String.isNotBlank(acc.Sales_Channel__c)) {
                for (String ch : acc.Sales_Channel__c.split(',')) {
                    accountSalesChannels.add(ch.trim().toLowerCase());
                }
            }
        }
        System.debug('### GRN Notify: accountSalesChannels=' + accountSalesChannels);
        
        // Step 3: Build recipient email set
        Set<String> toAddresses = new Set<String>();
        
        // 3a: TSE + their managers (from Product_Mapping__c)
        if (!execIds.isEmpty()) {
            for (User u : [
                SELECT Email, Manager.Email
                FROM User
                WHERE Id IN :execIds AND IsActive = true
            ]) {
                if (u.Email != null) toAddresses.add(u.Email);
                if (u.Manager != null && u.Manager.Email != null) toAddresses.add(u.Manager.Email);
            }
        }
        
        // 3b: Credit Department profile users (no Sales_Channel__c filter)
        for (User u : [
            SELECT Email
            FROM User
            WHERE Profile.Name = 'Credit Department'
            AND IsActive = true
            AND Email != null
        ]) {
            toAddresses.add(u.Email);
        }
        System.debug('### GRN Notify: After Credit Dept, toAddresses count=' + toAddresses.size());
        
        // 3c: Logistics Team profile users filtered by Sales_Channel__c
        // User.Sales_Channel__c is semicolon-separated — we fetch all active logistics users
        // and filter in Apex since SOQL can't do partial string matching across both formats
        if (!accountSalesChannels.isEmpty()) {
            for (User u : [
                SELECT Email, Sales_Channel__c
                FROM User
                WHERE Profile.Name = 'Logistics Team'
                AND IsActive = true
                AND Email != null
                AND Sales_Channel__c != null
            ]) {
                // Parse semicolon-separated Sales_Channel__c from User
                for (String userChannel : u.Sales_Channel__c.split(';')) {
                    if (accountSalesChannels.contains(userChannel.trim().toLowerCase())) {
                        toAddresses.add(u.Email);
                        break; // matched — no need to check remaining channels
                    }
                }
            }
        }
        System.debug('### GRN Notify: After Logistics Team, toAddresses count=' + toAddresses.size());
        
        if (toAddresses.isEmpty()) {
            System.debug('### GRN Notify: No email addresses found — exit');
            return;
        }
        
        // Step 4: Get GRN record
        List<Goods_Received_Note__c> grnList = [
            SELECT Id, Name FROM Goods_Received_Note__c WHERE Id = :grnId LIMIT 1
        ];
        if (grnList.isEmpty()) {
            System.debug('### GRN Notify: GRN not found — exit');
            return;
        }
        Goods_Received_Note__c grn = grnList[0];
        
        // Step 5: Generate PDF
        Blob pdfBlob;
        try {
            PageReference pdfPage = Page.GRNPdf;
            pdfPage.getParameters().put('id', grnId);
            pdfPage.getParameters().put('customerId', primaryCustomerId);
            pdfBlob = Test.isRunningTest()
                ? Blob.valueOf('Test PDF content')
                : pdfPage.getContentAsPDF();
            System.debug('### GRN Notify: PDF generated, size=' + pdfBlob.size());
        } catch (Exception e) {
            System.debug('### GRN Notify: PDF generation failed — ' + e.getMessage());
            return;
        }
        
        // Step 6: Get Org-Wide Email Address
        List<OrgWideEmailAddress> oweaList = [
            SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'Elite Admin' LIMIT 1
        ];
        if (oweaList.isEmpty()) {
            System.debug('### GRN Notify: OrgWideEmailAddress not found — exit');
            return;
        }
        
        // Step 7: Build and send email
        String custName = (acc != null && acc.Name != null) ? acc.Name : '';
        String sapCode  = (acc != null && acc.SAP_Customer_Code__c != null) ? acc.SAP_Customer_Code__c : '';
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new List<String>(toAddresses));
        mail.setOrgWideEmailAddressId(oweaList[0].Id);
        mail.setSubject('GRN Created: ' + grn.Name
                        + ' | Customer: ' + custName
                        + (String.isNotBlank(sapCode) ? ' (SAP Code: ' + sapCode + ')' : ''));
        
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
        
        try {
            if (!Test.isRunningTest()) {
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                System.debug('### GRN Notify: Email sent to ' + toAddresses);
            }
        } catch (Exception e) {
            System.debug('### GRN Notify: Email send failed — ' + e.getMessage());
        }
    }
    private static String safe(String v) { return String.isBlank(v) ? '-' : v; }
}