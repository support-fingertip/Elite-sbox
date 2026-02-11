public with sharing class InvoiceController {
    @AuraEnabled(cacheable=true)
    public static List<Secondary_Invoice__c> getInvoices(String fromDate, String toDate) {
        Date startDate, endDate;
        
        // Parse dates with validation
        try {
            startDate = Date.valueOf(fromDate);
            endDate = Date.valueOf(toDate);
        } catch (Exception e) {
            throw new AuraHandledException('Invalid date format. Use YYYY-MM-DD');
        }
        
        // Validate date range
        if (startDate > endDate) {
            throw new AuraHandledException('From Date cannot be after To Date');
        }
        
        // Build SOQL query based on filters
        String query = 'SELECT Name, Store__r.Name, Invoice_Date__c, Status__c, Total_Quantity__c, Grand_Total__c, Total_Tax__c ' +
            'FROM Secondary_Invoice__c ' +
            'WHERE Invoice_Date__c >= :startDate ' +
            'AND Invoice_Date__c <= :endDate';
        
        query += ' ORDER BY Name DESC LIMIT 10000';
        
        // Execute the query and return the filtered invoices
        List<Secondary_Invoice__c> invoices = Database.query(query);
        System.debug('Fetched invoices: ' + invoices);
        return invoices;
    }
    
    
    // Method to fetch Primary Invoices
    @AuraEnabled(cacheable=true)
    public static List<Invoice__c> getPrimaryInvoices(String status, Date frmDate, Date toDate) {
        // Ensure that the date range is valid
        Date startDate = frmDate;
        Date endDate = toDate;
        
        // List to hold the invoices
        List<Invoice__c> inv;
        Id accountId;
        List<User> partnerUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()];
        if(partnerUser.size() >0){
            List<Contact> contact = [SELECT AccountId FROM Contact WHERE Id = :partnerUser[0].ContactId LIMIT 1];
            accountId = contact[0].AccountId;
        }
        // Check if status is 'All', then fetch all invoices
        if (status == 'All') {
            inv = [
                SELECT Id, Name, Store__c, Invoice_Date__c, isDisabled__c, Status__c, Total_Amount__c, Store__r.Name,
                Total_Quantity__c, Grand_Total__c/*, Total_Tax__c*/, Pending_Amount__c
                FROM Invoice__c
                WHERE  Store__c =: accountId
                ORDER BY Invoice_Date__c DESC
            ];
        } else {
            // If status is not 'All', filter invoices based on 'Raised' or 'Overdue'
            inv = [
                SELECT Id, Name, Store__c, Invoice_Date__c, isDisabled__c, Status__c, Total_Amount__c, Store__r.Name,
                Total_Quantity__c, Grand_Total__c/*, Total_Tax__c*/, Pending_Amount__c
                FROM Invoice__c
                WHERE (Status__c = 'Raised' OR Status__c = 'Overdue')
                AND Invoice_Date__c >= :startDate
                AND Invoice_Date__c <= :endDate
                AND Store__c =: accountId
                ORDER BY Name DESC
            ];
        }
        
        // Return the list of primary invoices
        return inv;
    }
}