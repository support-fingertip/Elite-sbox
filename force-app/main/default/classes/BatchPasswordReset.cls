global class BatchPasswordReset implements Database.Batchable<SObject> {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        // Read sales channel from custom label
        String saleschannel = Label.Password_Reset_Sales_Channel;

        // Ensure the saleschannel value is safely quoted in the query
        String query = 'SELECT Id, User__c FROM Employee__c ' +
                       'WHERE IsDataUpload__c = true ' +
                       'AND User__c != null ' +
                       'AND is_Active__c = true ' +
                       'AND Sales_Channel__c = \'' + String.escapeSingleQuotes(saleschannel) + '\'';

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Employee__c> scope) {
        for (Employee__c emp : scope) {
            try {
                String newpassword = Label.Bulk_Reset_Password;

                // Reset the user's password
                System.setPassword(emp.User__c, newpassword);
                System.debug('Password set for User ID: ' + emp.User__c);
            } catch (Exception e) {
                System.debug('Error setting password for User ID ' + emp.User__c + ': ' + e.getMessage());
            }
        }
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('Batch password reset completed.');
    }
}