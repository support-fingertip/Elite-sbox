public class StockUpdateNotification {

    public static void getCustomersWithoutStock() {
        Date firstDayOfMonth;
        Date todayDate;
        
        Integer currentDay = Date.today().day();
        string monthref = '';
        if (currentDay == 1) {
            // Check for *last month's* stock
            monthref = 'last month';
            Date lastMonth = Date.today().addMonths(-1);
            firstDayOfMonth = lastMonth.toStartOfMonth();
            todayDate = lastMonth.toStartOfMonth().addMonths(1).addDays(-1); // End of last month
        } else if (currentDay >= 25) {
            // Check for *current month's* stock
              monthref = 'this month';
            firstDayOfMonth = Date.today().toStartOfMonth();
            todayDate = Date.today(); // Today as end date
        } else {
            // Not 25–31 or 1st → skip execution
            return;
        }

        // Step 1: Get customers with no stock entry this month
        List<Account> accountsList = [
            SELECT Id, Name
            FROM Account
            WHERE Customer_Type__c = 'Primary Customer'
            AND Id NOT IN (
                SELECT Store__c
                FROM Dealer_Stock__c
                WHERE CreatedDate >= :firstDayOfMonth AND CreatedDate <= :todayDate
            )
        ];

        if (accountsList.isEmpty()) return;

        Set<Id> customerIds = new Set<Id>();
        for (Account acc : accountsList) {
            customerIds.add(acc.Id);
        }

        // Step 2: Get Executive mappings for those customers
        Map<Id, List<String>> execToCustomerNames = new Map<Id, List<String>>();
        Set<Id> execIds = new Set<Id>();

        List<Product_Mapping__c> mappings = [
            SELECT Customer__c, Exectuive__c, Customer__r.Name,Customer__r.SAP_Customer_Code__c
            FROM Product_Mapping__c
            WHERE Customer__c IN :customerIds and Customer__c!= null
        ];

        // Track customer IDs added per executive to avoid duplicates
        Map<Id, Set<Id>> execToCustomerSet = new Map<Id, Set<Id>>();
        
        for (Product_Mapping__c mapping : mappings) {
            Id execId = mapping.Exectuive__c;
            Id custId = mapping.Customer__c;
            
            if (execId != null && custId != null) {
                execIds.add(execId);
                
                // Initialize map and set if not already done
                if (!execToCustomerNames.containsKey(execId)) {
                    execToCustomerNames.put(execId, new List<String>());
                    execToCustomerSet.put(execId, new Set<Id>());
                }
                
                // Add only if customer not already added
                if (!execToCustomerSet.get(execId).contains(custId)) {
                    String customerDisplayName = mapping.Customer__r.Name;
                    if (String.isNotBlank(mapping.Customer__r.SAP_Customer_Code__c)) {
                        customerDisplayName += ' (' + mapping.Customer__r.SAP_Customer_Code__c + ')';
                    }
                    
                    execToCustomerNames.get(execId).add(customerDisplayName);
                    execToCustomerSet.get(execId).add(custId);
                }
            }
        }

        if (execToCustomerNames.isEmpty()) return;

        // Step 3: Filter only active executive users
        Map<Id, User> execUserMap = new Map<Id, User>(
            [SELECT Id, Name, Email FROM User WHERE Id IN :execIds AND IsActive = true]
        );

        if (execUserMap.isEmpty()) return;

        // Step 4: Get Notification Type
        CustomNotificationType notificationType = [
            SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Stock_Update_Notification' LIMIT 1
        ];
        // Collect emails to send in bulk
        List<Messaging.SingleEmailMessage> allEmails = new List<Messaging.SingleEmailMessage>();
        
        for (Id execId : execUserMap.keySet()) {
            List<String> customerNames = execToCustomerNames.get(execId);
            if (customerNames == null || customerNames.isEmpty()) continue;
            
            // Notification
            String title = 'Stock Update Reminder';
            String body = 'You have ' + customerNames.size() + ' customer(s) pending stock update. Please complete the stock update at the earliest. The list of customers has been sent to your email.';
            
            CustomNotificationService.notificationSend(title, execId, body, new Set<String>{execId}, notificationType.Id);
            
            // Email body with table
            String emailBody = '<p>Dear ' + execUserMap.get(execId).Name + ',</p>';
            emailBody += '<p>The following customers assigned to you have not updated stock for '+ monthref+'</p>';
            emailBody += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse:collapse;">';
            emailBody += '<tr><th>#</th><th>Customer Name</th></tr>';
            
            Integer i = 1;
            for (String custName : customerNames) {
                emailBody += '<tr><td>' + i + '</td><td>' + custName + '</td></tr>';
                i++;
            }
            
            emailBody += '</table>';
            emailBody += '<p>Please update the stock as soon as possible.</p>';
            emailBody += '<p>Thank you.</p>';
            
            // Build email (DO NOT send yet)
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] { execUserMap.get(execId).Email });
            email.setSubject('Pending Stock Update - Customer List');
            email.setHtmlBody(emailBody);
            
            allEmails.add(email);
        }
        
        // Send all emails in one call (LIMIT = 10 per transaction)
        if (!allEmails.isEmpty()) {
            Messaging.sendEmail(allEmails);
        }

    }
}