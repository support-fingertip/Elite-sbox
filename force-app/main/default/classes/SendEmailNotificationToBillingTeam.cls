public without sharing class SendEmailNotificationToBillingTeam {

    public static void sendDocuments(Set<Id> accountIds) {
        String toEmail = Label.creditApprovalEmail;

        if (accountIds == null || accountIds.isEmpty() || String.isBlank(toEmail)) {
            throw new AuraHandledException('Account Id(s) and To Email must be provided.');
        }

        // Get Org-Wide Email Address (must be verified)
        OrgWideEmailAddress owea = [
            SELECT Id, Address, DisplayName
            FROM OrgWideEmailAddress
            WHERE DisplayName = 'Billing Email Address'
            LIMIT 1
        ];

        // Fetch Account details
        Map<Id, Account> accountMap = new Map<Id, Account>(
            [SELECT Id, Name, Customer_Code__c, Primary_Customer_Type__c, 
                    Primary_Customer_Business_Type__c, State__c, District__c,
                    Approval_Status__c, Primary_Phone_Number__c, Payment_Type__c, Credit_Limit__c, Sales_Channel__c,
                    PAN_Number__c, Aadhaar_No__c, Door_No__c, Building_Name__c, Land_Mark__c, City_Town__c, Pincode__c, Street__c
             FROM Account
             WHERE Id IN :accountIds]
        );

        // Fetch Product Mapping
        List<Product_Mapping__c> lstProductMapping = [
            SELECT Customer__c, Credit_Description__c
            FROM Product_Mapping__c
            WHERE Customer__c IN :accountIds
        ];

        Map<Id, String> customerCreditMap = new Map<Id, String>();
        for (Product_Mapping__c pm : lstProductMapping) {
            if (customerCreditMap.containsKey(pm.Customer__c)) {
                customerCreditMap.put(pm.Customer__c, customerCreditMap.get(pm.Customer__c) + ', ' + pm.Credit_Description__c);
            } else {
                customerCreditMap.put(pm.Customer__c, pm.Credit_Description__c);
            }
        }

        // Fetch related files
        List<ContentDocumentLink> links = [
            SELECT LinkedEntityId, ContentDocumentId,
                   ContentDocument.LatestPublishedVersionId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :accountIds
        ];

        Map<Id, List<Id>> accountToVersionIds = new Map<Id, List<Id>>();
        Set<Id> versionIds = new Set<Id>();

        for (ContentDocumentLink link : links) {
            if (link.LinkedEntityId != null && link.ContentDocument.LatestPublishedVersionId != null) {
                versionIds.add(link.ContentDocument.LatestPublishedVersionId);
                if (!accountToVersionIds.containsKey(link.LinkedEntityId)) {
                    accountToVersionIds.put(link.LinkedEntityId, new List<Id>());
                }
                accountToVersionIds.get(link.LinkedEntityId).add(link.ContentDocument.LatestPublishedVersionId);
            }
        }

        // Query all ContentVersions
        Map<Id, ContentVersion> versionMap = new Map<Id, ContentVersion>(
            [SELECT Id, Title, FileExtension
             FROM ContentVersion
             WHERE Id IN :versionIds]
        );

        // Prepare emails
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (Id accId : accountIds) {
            Account acc = accountMap.get(accId);
            if (acc == null) continue;

            String creditDescription = customerCreditMap.get(accId);
            List<String> fileLinks = new List<String>();

            // Create public links for files
            if (accountToVersionIds.containsKey(accId)) {
                for (Id verId : accountToVersionIds.get(accId)) {
                    ContentVersion ver = versionMap.get(verId);
                    if (ver == null) continue;

                    // Check for existing public distribution
                    List<ContentDistribution> existingDist = [
                        SELECT Id, DistributionPublicUrl
                        FROM ContentDistribution
                        WHERE ContentVersionId = :ver.Id
                        LIMIT 1
                    ];

                    String publicUrl;
                    if (!existingDist.isEmpty() && !String.isBlank(existingDist[0].DistributionPublicUrl)) {
                        publicUrl = existingDist[0].DistributionPublicUrl;
                    } else {
                        
                        // Safely trim title to max 80 characters
                        String distName = ver.Title;
                        if (distName != null && distName.length() > 70) {
                            distName = distName.substring(0, 70);
                        }
                        
                        // Create new distribution (public link)
                        ContentDistribution dist = new ContentDistribution(
                            Name = distName,
                            ContentVersionId = ver.Id,
                            PreferencesAllowOriginalDownload = true
                        );
                        
                        insert dist;
                        
           

                        // Query back to get the actual public URL
                        dist = [
                            SELECT Id, DistributionPublicUrl
                            FROM ContentDistribution
                            WHERE Id = :dist.Id
                            LIMIT 1
                        ];
                        publicUrl = dist.DistributionPublicUrl;
                    }

                    // Safely trim title to max 80 characters
                    String title = ver.Title;
                    if (title != null && title.length() > 70) {
                        title = title.substring(0, 70);
                    }
                    
                    // Add link to list
                    String fileName = title;
                    if (!String.isBlank(ver.FileExtension)) {
                        fileName += '.' + ver.FileExtension;
                    }
                    fileLinks.add('<a href="' + publicUrl + '" target="_blank">' + fileName + '</a>');
                }
            }

            // Build HTML Email Body
            String body = ''
                + '<html><body>'
                + '<p>Dear Sabu Jose,</p>'
                + '<p>Customer has been approved by the Credit Department.<br/>'
                + 'Please find the customer details and document links below.</p>'
                + '<table border="1" cellpadding="6" cellspacing="0" style="border-collapse:collapse;">'
                + '<tr><td><b>Customer Name</b></td><td>' + safe(acc.Name) + '</td></tr>'
                + '<tr><td><b>Customer Code</b></td><td>' + safe(acc.Customer_Code__c) + '</td></tr>'
                + '<tr><td><b>Primary Customer Type</b></td><td>' + safe(acc.Primary_Customer_Type__c) + '</td></tr>'
                + '<tr><td><b>Primary Business Type</b></td><td>' + safe(acc.Primary_Customer_Business_Type__c) + '</td></tr>'
                + '<tr><td><b>Primary Phone Number</b></td><td>' + safe(acc.Primary_Phone_Number__c) + '</td></tr>'
                + '<tr><td><b>PAN Number</b></td><td>' + safe(acc.PAN_Number__c) + '</td></tr>'
                + '<tr><td><b>Aadhaar No</b></td><td>' + safe(acc.Aadhaar_No__c) + '</td></tr>'
                + '<tr><td><b>State</b></td><td>' + safe(acc.State__c) + '</td></tr>'
                + '<tr><td><b>District</b></td><td>' + safe(acc.District__c) + '</td></tr>'
                + '<tr><td><b>Door No</b></td><td>' + safe(acc.Door_No__c) + '</td></tr>'
                + '<tr><td><b>Building Name</b></td><td>' + safe(acc.Building_Name__c) + '</td></tr>'
                + '<tr><td><b>Street</b></td><td>' + safe(acc.Street__c) + '</td></tr>'
                + '<tr><td><b>Land Mark</b></td><td>' + safe(acc.Land_Mark__c) + '</td></tr>'
                + '<tr><td><b>City/Town</b></td><td>' + safe(acc.City_Town__c) + '</td></tr>'
                + '<tr><td><b>Pincode</b></td><td>' + safe(acc.Pincode__c) + '</td></tr>'
                + '<tr><td><b>Sales Channel</b></td><td>' + safe(acc.Sales_Channel__c) + '</td></tr>'
                + '<tr><td><b>Approval Status</b></td><td>' + safe(acc.Approval_Status__c) + '</td></tr>'
                + '<tr><td><b>Payment Type</b></td><td>' + safe(acc.Payment_Type__c) + '</td></tr>'
                + '<tr><td><b>Credit Limit</b></td><td>' + safe(acc.Credit_Limit__c) + '</td></tr>'
                + '<tr><td><b>Credit Description</b></td><td>' + safe(creditDescription) + '</td></tr>'
                + '</table><br/>';

            if (!fileLinks.isEmpty()) {
                body += '<p><b>Document Links:</b><br/>';
                for (String link : fileLinks) {
                    body += link + '<br/>';
                }
                body += '</p>';
            } else {
                body += '<p><i>No documents are available for this customer.</i></p>';
            }

            body += '<p>Regards,<br/>ELITE FOODS PRIVATE LIMITED</p></body></html>';

            // Prepare and add email
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { toEmail });
            mail.setOrgWideEmailAddressId(owea.Id);
            mail.setSubject('Customer has been approved by the Credit Department: ' + acc.Name);
            mail.setHtmlBody(body);

            emails.add(mail);
        }

        // Send all emails
        if (!emails.isEmpty()) {
            System.debug(' Sending Emails...');
            Messaging.sendEmail(emails);
        }
    }

    // Utility function to handle nulls safely
    private static String safe(Object val) {
        return val == null ? '—' : String.valueOf(val);
    }
}