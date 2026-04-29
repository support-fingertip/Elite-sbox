public with sharing class UserFreezeStatusController {

    public class FreezeStatusResult {
        @AuraEnabled public Boolean isFrozen;
        @AuraEnabled public String freezeReason;
        @AuraEnabled public String userName;
        @AuraEnabled public String userId;
    }

    /**
     * Returns freeze status of the User linked to the given Employee__c record.
     * freezeReason values: 'VPN' | 'MultipleLogins' | 'Unknown'
     */
    @AuraEnabled(cacheable=true)
    public static FreezeStatusResult getUserFreezeStatus(Id employeeId) {
        FreezeStatusResult result = new FreezeStatusResult();
        result.isFrozen = false;

        // 1. Get the User lookup from Employee__c
        Employee__c emp = [
            SELECT Id, User__c, User__r.Name
            FROM Employee__c
            WHERE Id = :employeeId
            LIMIT 1
        ];

        if (emp.User__c == null) {
            result.isFrozen = false;
            return result;
        }

        result.userId   = emp.User__c;
        result.userName = emp.User__r.Name;

        // 2. Check UserLogin for freeze status
        List<UserLogin> logins = [
            SELECT Id, IsFrozen
            FROM UserLogin
            WHERE UserId = :emp.User__c
            LIMIT 1
        ];

        if (logins.isEmpty() || !logins[0].IsFrozen) { result.isFrozen = false;
            return result;
        }
        result.isFrozen = true;
        // 3. Determine reason from recent LoginHistory
        //    VPN detection: TOR / anonymizing proxy shows as Network/API login type or specific status
        List<LoginHistory> history = [ SELECT Id, LoginType, Status, SourceIp, LoginTime FROM LoginHistory WHERE UserId = :emp.User__c  ORDER BY LoginTime DESC LIMIT 20];
        result.freezeReason = 'Unknown';
        for (LoginHistory lh : history) {
            String status = lh.Status != null ? lh.Status.toLowerCase() : '';
            String loginType = lh.LoginType != null ? lh.LoginType.toLowerCase() : '';
            if (status.contains('failed') || status.contains('invalid password') || status.contains('blocked')) { result.freezeReason = 'MultipleLogins';                                                                                                 break; }
            // Salesforce flags TOR/VPN logins with specific status messages
            if (status.contains('anonymiz') || status.contains('vpn') || status.contains('tor') || status.contains('oauth') || loginType.contains('oauth')) {result.freezeReason = 'VPN';                                                                                                                                                break; }
        }
        return result;
    }

    /**
     * Unfreezes the User linked to the Employee__c record.
     */
    @AuraEnabled
    public static void unfreezeUser(Id employeeId) {
        Employee__c emp = [
            SELECT Id, User__c
            FROM Employee__c
            WHERE Id = :employeeId
            LIMIT 1
        ];

        if (emp.User__c == null) {
            throw new AuraHandledException('No user linked to this employee record.');
        }

        List<UserLogin> logins = [
            SELECT Id, IsFrozen
            FROM UserLogin
            WHERE UserId = :emp.User__c
            LIMIT 1
        ];

        if (logins.isEmpty()) {
            throw new AuraHandledException('UserLogin record not found.');
        }

        logins[0].IsFrozen = false;

        try {
            update logins;
        } catch (DmlException e) {
            throw new AuraHandledException('Failed to unfreeze user: ' + e.getMessage());
        }
    }
}