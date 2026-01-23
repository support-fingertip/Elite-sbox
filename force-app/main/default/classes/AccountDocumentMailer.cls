public with sharing class AccountDocumentMailer {

    // Method to send all documents of an Account via email
    public static void sendAccountDocuments(Id accountId, String toEmail) {

        // 1) Get Org-Wide Email Address safely
        List<OrgWideEmailAddress> oweaList = [
            SELECT Id, Address 
            FROM OrgWideEmailAddress 
            WHERE Address = 'durgaprasadrgukt99@gmail.com'
        ];

        OrgWideEmailAddress owea;

        if (oweaList.isEmpty()) {
            System.debug('Org-Wide Email Address not found or not verified. Using current user as sender.');
            owea = null; // fallback: use default sender
        } else {
            owea = oweaList[0];
        }

        // 2) Query all ContentDocumentLinks for this Account
        List<ContentDocumentLink> docLinks = [
            SELECT ContentDocumentId 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :accountId
        ];

        if (docLinks.isEmpty()) {
            System.debug('No documents found for Account: ' + accountId);
            return;
        }

        // 3) Collect ContentDocument Ids
        Set<Id> docIds = new Set<Id>();
        for (ContentDocumentLink link : docLinks) {
            docIds.add(link.ContentDocumentId);
        }

        // 4) Query only the latest version of each document
        List<ContentVersion> contentVersions = [
            SELECT Id, Title, VersionData 
            FROM ContentVersion 
            WHERE ContentDocumentId IN :docIds
            AND IsLatest = true
        ];

        if (contentVersions.isEmpty()) {
            System.debug('No ContentVersions found for Account: ' + accountId);
            return;
        }

        // 5) Prepare Email Attachments with unique filenames
        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
        Set<String> fileNames = new Set<String>();
        Integer counter = 1;

        for (ContentVersion cv : contentVersions) {
            String fileName = cv.Title;

            // Make filename unique if duplicate exists
            while (fileNames.contains(fileName)) {
                fileName = cv.Title + '_' + counter;
                counter++;
            }

            fileNames.add(fileName);

            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            efa.setFileName(fileName);
            efa.setBody(cv.VersionData);
            attachments.add(efa);
        }

        // 6) Create the email
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[] { toEmail });
        email.setSubject('Documents for Account: ' + accountId);
        email.setPlainTextBody('Please find the attached documents.');
        email.setFileAttachments(attachments);

        // 7) Use Org-Wide Email if available
        if (owea != null) {
            email.setOrgWideEmailAddressId(owea.Id);
        }

        // 8) Set sender as current user if Org-Wide Email not available
        email.setTargetObjectId(UserInfo.getUserId()); 
        email.setSaveAsActivity(false); // optional

        // 9) Send the email
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        System.debug('Email sent successfully to ' + toEmail);
    }
}