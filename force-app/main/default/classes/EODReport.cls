global class EODReport implements Database.Batchable<SObject>, Database.Stateful {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        // Query only users who are managers (Role != null is a good filter)
        return Database.getQueryLocator([
            SELECT Id, Email, Name 
            FROM User 
            WHERE IsActive = true
            AND UserRoleId != null
        ]);
    }
    
    global void execute(Database.BatchableContext bc, List<User> scope) {
        User manager = scope[0];
        
        // Get subordinates under this manager
        Set<Id> subordinateIds = RoleHeirarchyUtility.getUsersUnderRoleHierarchy(manager.Id);
        
        if (subordinateIds.isEmpty()) {
            return; // no team → no report
        }
        
        List<User> subordinates = [
            SELECT Id, Name,Employee_Code__c, Email ,Username,Mail_Id__c,Phone,Sales_Channel__c,Title,Manager_Name__c,Manager_Employee_Code__c
            
            FROM User 
            WHERE Id IN :subordinateIds
        ];
        
        Map<Id, Daily_Log__c> logsByUser = new Map<Id, Daily_Log__c>(
            [SELECT Id, OwnerId,
             Start_time__c, First_Visit_Time__c, Last_Visit_Time__c, End_Time__c, Effective_Man_Hours__c, Market_Hours__c,
             Assigned_Beat__r.Name, Current_Beat__r.Name, Beat_Switch_History__c,
             Distributor_Name__c, Distributor_Id__c, Calls_Made__c, Total_Visits__c, Prouctive_Calls_Made__c, Total_Productive_Calls__c,
             Total_Non_Productive_Calls__c, New_Calls__c, Distance_Travelled_by_Odometer__c, Distance_Travelled__c, TLSD__c,
             Total_Outlets__c, Total_Order_Amount__c, Primary_Order_Amount__c, Secondary_Order_Amont__c, TLSD_Retailers_Outlets__c,
             TLSD_Sub_Stockist__c, TLSD_Primary__c, Lines_Per_OL__c, TPut_Per_OL__c, Normal_Call__c, Telephonic_Call__c
             FROM Daily_Log__c  
             WHERE OwnerId IN :subordinateIds 
             AND CreatedDate = TODAY]
        );
        
        
        // Build CSV header
        String csv = 'Date,User Name,Employee Code,Username,Mail Id,Phone,Sales Channel,Designation,Reporting Manager,Reporting Manager Code,' +
            'Day Start Time,First Visit Time,Last Visit Time,End Time,Effective Man Hours,Market Hours,Assigned Beat,Current Beat,Beat Switch History,' +
            'Distributor Name,Distributor Id,Calls Made %,Calls Made,Productive Calls Made %,Productive Calls Made,Non Productive Calls,New Calls,' +
            'Distance Travelled by Odometer,Distance Travelled,TLSD,Total Outlets,Total Order Amount,Primary Order Amount,Secondary Order Amount,' +
            'TLSD Retailers Outlets,TLSD Sub Stockist,TLSD Primary,Lines Per OL,TPut Per OL,Normal Call,Telephonic Call,Status\n';
        
        Date todayDate = Date.today();
        
        for (User sub : subordinates) {
            Daily_Log__c log = logsByUser.get(sub.Id);
            
            String status = (log != null) ? 'Present' : 'Absent';
            
            // Build row (user fields first)
            csv +=
                todayDate.format() + ',' +
                sub.Name + ',' +
                sub.Employee_Code__c + ',' +
                sub.Username + ',' +
                sub.Mail_Id__c + ',' +
                sub.Phone + ',' +
                sub.Sales_Channel__c + ',' +
                ( sub.Title  != null ?  sub.Title : '') + ',' +
                sub.Manager_Name__c + ',' +
                sub.Manager_Employee_Code__c + ',';
            
            if (log != null) {
                // You’ll need to calculate percentages if they’re not fields in Daily_Log__c
                Decimal callsMadePct = (log.Total_Visits__c != null && log.Total_Visits__c > 0) 
                    ? ((log.Calls_Made__c / log.Total_Visits__c) * 100) 
                    : null;
                Decimal productiveCallsPct = (log.Total_Productive_Calls__c != null && log.Calls_Made__c != null && log.Calls_Made__c > 0) 
                    ? ((log.Total_Productive_Calls__c / log.Calls_Made__c) * 100) 
                    : null;
                
                csv +=
                    log.Start_time__c + ',' +
                    log.First_Visit_Time__c + ',' +
                    log.Last_Visit_Time__c + ','+
                    (log.End_Time__c != null ? log.End_Time__c : '') + ','+
                    (log.Effective_Man_Hours__c != null ? log.Effective_Man_Hours__c : '') + ','+
                    (log.Market_Hours__c != null ? log.Market_Hours__c : '') + ','+
                    (log.Assigned_Beat__r != null ? log.Assigned_Beat__r.Name : '') + ',' +
                    (log.Current_Beat__r != null ? log.Current_Beat__r.Name : '') + ',' +
                    (log.Beat_Switch_History__c != null ? log.Beat_Switch_History__c : '') + ','+
                    (log.Distributor_Name__c != null ? log.Distributor_Name__c : '') + ','+
                    (log.Distributor_Id__c != null ? log.Distributor_Id__c : '') + ','+
                    (log.Calls_Made__c != null ?    log.Calls_Made__c + '%' : '') + ',' +   // Calls Made %
                    (log.Total_Visits__c != null ? log.Total_Visits__c : 0) + ','+
                    (log.Prouctive_Calls_Made__c != null ? log.Prouctive_Calls_Made__c + '%' : '') + ',' +  // Productive Calls Made %
                    (log.Total_Productive_Calls__c != null ? log.Total_Productive_Calls__c : 0) + ','+
                    (log.Total_Non_Productive_Calls__c != null ? log.Total_Non_Productive_Calls__c : 0) + ','+
                    (log.New_Calls__c != null ? log.New_Calls__c : 0) + ','+
                    (log.Distance_Travelled_by_Odometer__c != null ? log.Distance_Travelled_by_Odometer__c : 0) + ','+
                    (log.Distance_Travelled__c != null ? log.Distance_Travelled__c : 0) + ','+
                    (log.TLSD__c != null ? log.TLSD__c : 0) + ','+
                    (log.Total_Outlets__c != null ? log.Total_Outlets__c : 0) + ','+
                    (log.Total_Order_Amount__c != null ? log.Total_Order_Amount__c : 0) + ','+
                    (log.Primary_Order_Amount__c != null ? log.Primary_Order_Amount__c : 0) + ','+
                    (log.Secondary_Order_Amont__c != null ? log.Secondary_Order_Amont__c : 0) + ','+
                    (log.TLSD_Retailers_Outlets__c != null ? log.TLSD_Retailers_Outlets__c : 0) + ','+
                    (log.TLSD_Sub_Stockist__c != null ? log.TLSD_Sub_Stockist__c : 0) + ','+
                    (log.TLSD_Primary__c != null ? log.TLSD_Primary__c : 0) + ','+
                    (log.Lines_Per_OL__c != null ? log.Lines_Per_OL__c : 0) + ','+
                    (log.TPut_Per_OL__c != null ? log.TPut_Per_OL__c : 0) + ','+
                    (log.Normal_Call__c != null ? log.Normal_Call__c : 0) + ','+
                    (log.Telephonic_Call__c != null ? log.Telephonic_Call__c : 0) + ',';
            } else {
                // If no log → fill blanks for all log fields (34 fields here, keep commas consistent!)
                csv += ',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,';
            }
            
            csv += status + '\n'; // Final column
        }
        
        
        // Send only once per manager
        if (!String.isBlank(manager.Email)) {
            Messaging.EmailFileAttachment att = new Messaging.EmailFileAttachment();
            att.setFileName('Elite EOD Report ' + Date.today().format() + '.csv');
            att.setBody(Blob.valueOf(csv));
            
            Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
            msg.setToAddresses(new String[] { manager.Email });
            msg.setSubject('Elite EOD Report - ' + Date.today().format());
            
            // Personalized body
            msg.setPlainTextBody('Dear ' + manager.Name + ',\n\n' + 
                                 'Please find your team\'s EOD report attached.\n\n' +
                                 'Regards,\nElite Team');
            
            msg.setFileAttachments(new Messaging.EmailFileAttachment[] { att });
            msg.setSaveAsActivity(false);
            
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ msg }, false);
        }

    }
    
    global void finish(Database.BatchableContext bc) {
        // nothing needed here
    }

}