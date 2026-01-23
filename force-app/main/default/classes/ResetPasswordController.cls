public without  sharing class ResetPasswordController {

    @AuraEnabled
    public static User getUserDetails(Id employeeId) {
        Employee__c emp = [SELECT Id, User__c, User__r.Username FROM Employee__c WHERE Id = :employeeId LIMIT 1];
        return emp.User__r;
    }

    @AuraEnabled
    public static void setPassword(Id userId, String newPassword) {
        if (String.isBlank(newPassword) || newPassword.length() < 8) {
            throw new AuraHandledException('Password must be at least 8 characters.');
        }
        System.setPassword(userId, newPassword);
    }
}