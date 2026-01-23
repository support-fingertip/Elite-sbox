public class EmployeePasswordResetController {
    
    @AuraEnabled
    public static String resetUserPassword(Id recordId) {
        try {
            // Query the Employee record to get the associated User
            Employee__c employee = [
                SELECT Id, Name, User_Name__c, User__c, Mail_Id__c
                FROM Employee__c
                WHERE Id = :recordId
                LIMIT 1
            ];

            if (employee.User__c == null) {
                return 'Error: No user associated with this employee record.';
            }

            // Query the User to ensure it exists and is active
            User user = [
                SELECT Id, Username, IsActive, Name
                FROM User
                WHERE Id = :employee.User__c AND IsActive = true
                LIMIT 1
            ];

            // Reset the user's password
            System.resetPassword(user.Id, true);
            return 'Success: Password reset email sent successfully';
        } catch (Exception ex) {
            String errorMsg = 'Error: Failed to reset password';
            return errorMsg;
        }
    }
}