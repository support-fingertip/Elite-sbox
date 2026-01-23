public class EmployeeUserPasswordResetController {
    public List<Employee__c> selectedEmployees { get; set; }
    public List<String> results { get; set; }
    public List<Id> selectedRecordIds { get; set; }
    public Boolean hasResults { get; set; }

    public EmployeeUserPasswordResetController(ApexPages.StandardSetController controller) {
        selectedRecordIds = new List<Id>();
        selectedEmployees = new List<Employee__c>();
        results = new List<String>();
        hasResults = false; // Ensure results section is hidden initially

        for (Employee__c emp : (List<Employee__c>)controller.getSelected()) {
            selectedRecordIds.add(emp.Id);
        }
        if (!selectedRecordIds.isEmpty()) {
            selectedEmployees = [
                SELECT Id, Name, Primary_Phone_Number__c, Mail_Id__c, User_Name__c, User__c
                FROM Employee__c
                WHERE Id IN :selectedRecordIds
            ];
        }
    }

    public PageReference resetPasswords() {
        results = new List<String>(); // Clear previous results
        hasResults = false; // Reset hasResults at the start

        if (selectedRecordIds.isEmpty()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No records selected. Please select at least one record.'));
            results.add('Error: No records selected.');
            hasResults = true; // Show results section for error
            System.debug('Results size: ' + results.size());
            return null;
        }

        try {
            // Query Employee records with their associated User lookup
            List<Employee__c> employees = [
                SELECT Id, Name, Mail_Id__c, User_Name__c, User__c
                FROM Employee__c 
                WHERE Id IN :selectedRecordIds AND User__c != null
            ];

            if (employees.isEmpty()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No valid users found for the selected employees.'));
                results.add('Error: No valid users found for the selected employees.');
                hasResults = true;
                System.debug('Results size: ' + results.size());
                return null;
            }

            // Collect User IDs for password reset
            Set<Id> userIds = new Set<Id>();
            for (Employee__c emp : employees) {
                userIds.add(emp.User__c);
            }

            // Query Users to ensure they are active
            Map<Id, User> userMap = new Map<Id, User>([
                SELECT Id, Username, IsActive, Name
                FROM User
                WHERE Id IN :userIds AND IsActive = true
            ]);

            // Process each employee
            for (Employee__c emp : employees) {
                try {
                    User user = userMap.get(emp.User__c);
                    if (user == null) {
                        results.add('Error for ' + (emp.Name ?? 'Unknown') + ' (Username: ' + (emp.User_Name__c ?? 'N/A') + '): No active user found.');
                        continue;
                    }

                    // Reset password
                    System.resetPassword(user.Id, true);
                    results.add('Success for ' + (emp.Name ?? 'Unknown') + ' (Username: ' + (emp.User_Name__c ?? 'N/A') + '): Password reset email sent.');
                } catch (Exception ex) {
                    results.add('Error for ' + (emp.Name ?? 'Unknown') + ' (Username: ' + (emp.User_Name__c ?? 'N/A') + '): Password reset failed: ' + ex.getMessage());
                }
            }

            hasResults = !results.isEmpty(); // Show results section if there are results
            System.debug('Results size after processing: ' + results.size());
            System.debug('Results content: ' + results);
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Bulk password reset failed: ' + ex.getMessage()));
            results.add('Error: Bulk password reset failed: ' + ex.getMessage());
            hasResults = true; // Show results section for error
            System.debug('Results size after error: ' + results.size());
        }

        return null;
    }

    public PageReference cancel() {
        results = new List<String>(); // Clear results
        hasResults = false; // Hide results section
        return new PageReference('/' + Employee__c.SObjectType.getDescribe().getKeyPrefix());
    }
}