public class EODReportQueueableMail implements Queueable, Database.AllowsCallouts {
    private Id dailyLogId;
    
    public EODReportQueueableMail(Id dlId) {
        this.dailyLogId = dlId;
    }
    
    public void execute(QueueableContext context) {
        Daily_Log__c dlNew = [
            SELECT Id, Owner_Email_Id__c, Owner_Manager_Email__c, Owner_Name__c,OwnerId,Day_Started_Date__c
            FROM Daily_Log__c
            WHERE Id = :dailyLogId
            LIMIT 1
        ];
        
        // Step 1: Generate VF PDF
        PageReference pdfPage = Page.EODReportPdf;
        pdfPage.getParameters().put('id', dlNew.OwnerId);
        Blob pdfBlob;
        if (Test.isRunningTest()) {
            pdfBlob = Blob.valueOf('Test PDF content');
        } else {
            pdfBlob = pdfPage.getContentAsPDF();
        }      
        // Step 2: Build email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<String> mailIds = new List<String>();
        
        if (dlNew.Owner_Email_Id__c != null) {
            mailIds.add(dlNew.Owner_Email_Id__c);  
        }
        if (dlNew.Owner_Manager_Email__c != null) {
            mailIds.add(dlNew.Owner_Manager_Email__c);
        }
        
        if (!mailIds.isEmpty()) {
            mail.setToAddresses(mailIds);
            String datevalue = dlNew.Day_Started_Date__c != null ?
                DateTime.newInstance(dlNew.Day_Started_Date__c.year(), dlNew.Day_Started_Date__c.month(), dlNew.Day_Started_Date__c.day()).format('dd/MM/yyyy') : 
            '' ;
            
            mail.setPlainTextBody(
                'Please find attached End of Day report of ' + dlNew.Owner_Name__c + 
                ' for ' + datevalue + '.\n\n' +
                'Regards,\nELITE FOODS PRIVATE LIMITED'
            );
            
            
            
            mail.setSubject('EOD Report of ' + dlNew.Owner_Name__c + ' - ' + datevalue);
            
            // Step 3: Attach PDF
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFileName('EODReport_'+dlNew.Owner_Name__c+'_'+datevalue + '.pdf');
            attachment.setBody(pdfBlob);
            attachment.setContentType('application/pdf');
            mail.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
            
            
            // Set sender using Org-Wide Email Address (Name = "System Admin Email")
            OrgWideEmailAddress owea = [
                SELECT Id 
                FROM OrgWideEmailAddress 
                WHERE DisplayName = 'Elite Admin' // or use Address = 'admin@yourdomain.com'
                LIMIT 1
            ];
            mail.setOrgWideEmailAddressId(owea.Id);
            
            
            // Step 4: Send mail
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }
}