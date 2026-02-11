// Batch class to create missing Price Book entries
global class CreateMissingPriceBooksBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    global Integer totalRecordsProcessed = 0;
    global Integer totalRecordsCreated = 0;
    global Integer totalErrors = 0;
    global List<String> errorMessages = new List<String>();
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // Query only accounts with TN sales channel
        return Database.getQueryLocator([
            SELECT Id, Name, Sales_Channel__c 
            FROM Account 
            WHERE Sales_Channel__c LIKE '%TS%'
        ]);
    }
    
    global void execute(Database.BatchableContext BC, List<Account> scope) {
        List<Price_Book__c> newPriceBooks = new List<Price_Book__c>();
        Set<Id> accountIds = new Set<Id>();
        
        // Collect account IDs from the batch scope
        for(Account acc : scope) {
            accountIds.add(acc.Id);
            totalRecordsProcessed++;
        }
        
        // Get all existing Price Books for these accounts in one query
        Map<Id, Set<Id>> accountToExistingSKUs = new Map<Id, Set<Id>>();
        for(Price_Book__c pb : [SELECT Id, Customer__c, Product__c 
                               FROM Price_Book__c 
                               WHERE Customer__c IN :accountIds 
                               AND Customer_Type__c = 'Primary Customer']) {
            if(!accountToExistingSKUs.containsKey(pb.Customer__c)) {
                accountToExistingSKUs.put(pb.Customer__c, new Set<Id>());
            }
            accountToExistingSKUs.get(pb.Customer__c).add(pb.Product__c);
        }
        
        // Get all SKUs for TN sales channel (cached for the entire execute method)
        List<Sales_Channel_To_SKU__c> channelSKUs = [SELECT Id, SKU__c, SKU__r.List_Price__c, 
                                                    SKU__r.MRP__c, SKU__r.Name 
                                                    FROM Sales_Channel_To_SKU__c 
                                                    WHERE Sales_Channel__c = 'TS'];
        
        // Create missing Price Books
        for(Account acc : scope) {
            Set<Id> existingSKUs = accountToExistingSKUs.get(acc.Id);
            if(existingSKUs == null) {
                existingSKUs = new Set<Id>();
            }
            
            for(Sales_Channel_To_SKU__c scs : channelSKUs) {
                if(!existingSKUs.contains(scs.SKU__c)) {
                    Price_Book__c newPB = new Price_Book__c(
                        Customer__c = acc.Id,
                        Product__c = scs.SKU__c,
                        Customer_Type__c = 'Primary Customer',
                        Unit_Price__c = scs.SKU__r.List_Price__c,
                        MRP__c = scs.SKU__r.MRP__c
                    );
                    newPriceBooks.add(newPB);
                }
            }
        }
        
        // Insert new Price Books with error handling
        if(!newPriceBooks.isEmpty()) {
            List<Database.SaveResult> results = Database.insert(newPriceBooks, false);
            
            for(Integer i = 0; i < results.size(); i++) {
                if(results[i].isSuccess()) {
                    totalRecordsCreated++;
                } else {
                    totalErrors++;
                    String errorMsg = 'Error for Account: ' + newPriceBooks[i].Customer__c + 
                                    ', Product: ' + newPriceBooks[i].Product__c + 
                                    ' - ' + results[i].getErrors()[0].getMessage();
                    errorMessages.add(errorMsg);
                }
            }
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        // Send summary email
        String emailBody = 'Price Book Creation Batch Process Completed\n\n';
        emailBody += 'Total Accounts Processed: ' + totalRecordsProcessed + '\n';
        emailBody += 'Total Price Book Records Created: ' + totalRecordsCreated + '\n';
        emailBody += 'Total Errors: ' + totalErrors + '\n\n';
        
        if(!errorMessages.isEmpty()) {
            emailBody += 'ERROR DETAILS:\n';
            for(String error : errorMessages) {
                emailBody += error + '\n';
            }
        }
        
        // Send email to current user
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[]{UserInfo.getUserEmail()});
        mail.setSubject('Price Book Creation Batch Completed');
        mail.setPlainTextBody(emailBody);
        
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
        
        System.debug('Batch completed: ' + emailBody);
    }
}