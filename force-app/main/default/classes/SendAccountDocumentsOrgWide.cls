public with sharing class SendAccountDocumentsOrgWide {
    
    // Main public method: pass Account Id and recipient email
    public static void sendDocuments(Id accountId, String toEmail) {
        if (accountId == null || String.isBlank(toEmail)) {
            throw new AuraHandledException('Account Id and To Email must be provided.');
        }
        
        // 1) Get Org-Wide Email Address (ensure this address exists and is verified)
        List<OrgWideEmailAddress> oweas = [
            SELECT Id, Address, DisplayName 
            FROM OrgWideEmailAddress
            WHERE Address = : '	durgaprasadrgukt99@gmail.com'
            LIMIT 1
        ];
        if (oweas.isEmpty()) {
            throw new AuraHandledException('Org-Wide Email Address not found or not verified.');
        }
        OrgWideEmailAddress owea = oweas[0];

        // 2) Query ContentDocumentLink for files attached to the account
        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId, ContentDocument.LatestPublishedVersionId, 
                   ContentDocument.Title, ContentDocument.FileExtension
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :accountId
        ];

        if (links.isEmpty()) {
            throw new AuraHandledException('No files found for this Account.');
        }

        // 3) Build email attachments from ContentVersion (latest published version)
        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
        for (ContentDocumentLink l : links) {
            Id versionId = l.ContentDocument.LatestPublishedVersionId;
            if (versionId == null) continue;
            ContentVersion ver = [
                SELECT Title, VersionData, FileExtension, ContentSize
                FROM ContentVersion
                WHERE Id = :versionId
                LIMIT 1
            ];
            // Skip overly large files to avoid email size issues
            if (ver.ContentSize != null && ver.ContentSize > 10 * 1024 * 1024) {
                continue;
            }
            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            String filename = ver.Title;
            if (!String.isBlank(ver.FileExtension)) filename += '.' + ver.FileExtension;
            efa.setFileName(filename);
            efa.setBody(ver.VersionData);
            attachments.add(efa);
        }

        if (attachments.isEmpty()) {
            throw new AuraHandledException('There are files but none could be attached (e.g., too large).');
        }

        // 4) Prepare and send email using Org-Wide Email Address
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] { toEmail });
        mail.setSubject('Documents for Account: ' + accountId);
        mail.setPlainTextBody('Please find attached the files related to this Account.');
        mail.setOrgWideEmailAddressId(owea.Id);
        mail.setFileAttachments(attachments);

        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        } catch (Exception e) {
            throw new AuraHandledException('Failed to send email: ' + e.getMessage());
        }
    }
}