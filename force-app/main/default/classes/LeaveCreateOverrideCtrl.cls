public without sharing class LeaveCreateOverrideCtrl {

    @AuraEnabled
    public static Boolean checkUserRole() {
        Id userId = UserInfo.getUserId();
        // Query profile name safely
        List<User> users = [SELECT Profile.Name FROM User WHERE Id = :userId LIMIT 1];
        if(users.isEmpty()) return false;
        
        String profileName = users[0].Profile.Name;
        return (profileName == 'System Administrator' || profileName == 'HR');
    }

    @AuraEnabled
    public static String validateLeaveDates(Map<String, Object> leaveData) {
        try {
            // Get data from the JS Map
            String userStr = (String)leaveData.get('User__c');
            Id targetUserId = String.isNotBlank(userStr) ? (Id)userStr : UserInfo.getUserId();

            Date fromDt = Date.valueOf((String)leaveData.get('From_Date__c'));
            Date toDt = Date.valueOf((String)leaveData.get('To_Date__c'));

            // Check for overlaps (Ignoring Cancelled/Rejected)
            List<Leaves__c> overlaps = [
                SELECT Name, From_Date__c, To_Date__c 
                FROM Leaves__c 
                WHERE User__c = :targetUserId 
                AND ApprovalStatus__c NOT IN ('Leave Cancelled', 'Leave Rejected')
                AND (
                    (From_Date__c <= :toDt AND To_Date__c >= :fromDt)
                )
                LIMIT 1
            ];
            
            if (!overlaps.isEmpty()) {
                return 'An existing leave request (' + overlaps[0].Name + 
                    ') already exists for ' + overlaps[0].From_Date__c.format() + ' to ' + overlaps[0].To_Date__c.format();
            }
            return null;
        } catch (Exception e) {
            throw new AuraHandledException('Validation Error: ' + e.getMessage());
        }
    }
}