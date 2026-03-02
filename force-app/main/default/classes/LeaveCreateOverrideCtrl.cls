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
            String sessionType = (String)leaveData.get('Session_Type__c');

            // Check for overlaps (Ignoring Cancelled/Rejected)
            List<Leaves__c> overlaps = [
                SELECT Name, From_Date__c, To_Date__c, Session_Type__c
                FROM Leaves__c 
                WHERE User__c = :targetUserId 
                AND ApprovalStatus__c NOT IN ('Leave Cancelled', 'Leave Rejected')
                AND (
                    (From_Date__c <= :toDt AND To_Date__c >= :fromDt)
                )
            ];
            
            for (Leaves__c overlap : overlaps) {
                // Allow if both are single-day leaves on the same date with different session types
                // e.g. existing = First Half, new = Second Half (or vice versa)
                if (fromDt == toDt 
                    && overlap.From_Date__c == overlap.To_Date__c 
                    && fromDt == overlap.From_Date__c
                    && String.isNotBlank(sessionType) 
                    && String.isNotBlank(overlap.Session_Type__c)
                    && sessionType != overlap.Session_Type__c) {
                    continue;
                }
                
                return 'An existing leave request (' + overlap.Name + 
                    ') already exists for ' + overlap.From_Date__c.format() + ' to ' + overlap.To_Date__c.format();
            }
            return null;
        } catch (Exception e) {
            throw new AuraHandledException('Validation Error: ' + e.getMessage());
        }
    }

		//Added by pattu -- 25/02/26
        @AuraEnabled
        public static List<User> searchUsers(String searchTerm) {
            if (String.isBlank(searchTerm) || searchTerm.length() < 2) {
                return new List<User>();
            }
            
            String wildcard = '%' + String.escapeSingleQuotes(searchTerm.trim()) + '%';
            
            List<User> results = new List<User>();
            Set<Id> addedIds = new Set<Id>();
            
            // Search by Name
            for (User u : [
                SELECT Id, Name, Employee_Code__c, Vendor_Code__c, User_Id__c
                FROM User
                WHERE IsActive = true
                AND Name LIKE :wildcard
                LIMIT 10
            ]) {
                if (!addedIds.contains(u.Id)) {
                    results.add(u);
                    addedIds.add(u.Id);
                }
            }
            
            // Search by Employee Code
            for (User u : [
                SELECT Id, Name, Employee_Code__c, Vendor_Code__c, User_Id__c
                FROM User
                WHERE IsActive = true
                AND Employee_Code__c LIKE :wildcard
                LIMIT 10
            ]) {
                if (!addedIds.contains(u.Id)) {
                    results.add(u);
                    addedIds.add(u.Id);
                }
            }
            
            // Search by Vendor Code
            for (User u : [
                SELECT Id, Name, Employee_Code__c, Vendor_Code__c, User_Id__c
                FROM User
                WHERE IsActive = true
                AND Vendor_Code__c LIKE :wildcard
                LIMIT 10
            ]) {
                if (!addedIds.contains(u.Id)) {
                    results.add(u);
                    addedIds.add(u.Id);
                }
            }
            
            // Search by User_Id__c (Auto Number - use exact match or LIKE on text)
            for (User u : [
                SELECT Id, Name, Employee_Code__c, Vendor_Code__c, User_Id__c
                FROM User
                WHERE IsActive = true
                AND User_Id__c LIKE :wildcard
                LIMIT 10
            ]) {
                if (!addedIds.contains(u.Id)) {
                    results.add(u);
                    addedIds.add(u.Id);
                }
            }
            
            return results;
        }
}