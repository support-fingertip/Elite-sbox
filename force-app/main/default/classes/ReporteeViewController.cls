public with sharing class ReporteeViewController {

    public class SubordinateWrapper {
        @AuraEnabled public Id userId;
        @AuraEnabled public String userName;
        @AuraEnabled public String roleName;
        @AuraEnabled public Boolean isActive;
        @AuraEnabled public String profileName;
    }

    public class BeatWrapper {
        @AuraEnabled public Id beatId;
        @AuraEnabled public String beatName;
        @AuraEnabled public String primaryCustomerName;
        @AuraEnabled public String beatType;
        @AuraEnabled public Boolean isActive;
        @AuraEnabled public Integer outletCount;
    }

    // Get all subordinates (active + inactive with active beats) using RoleHeirarchyUtility
    @AuraEnabled
    public static List<SubordinateWrapper> getSubordinates() {
        Id currentUserId = UserInfo.getUserId();
        Set<Id> subordinateIds = RoleHeirarchyUtility.getRoleSubordinateUsers(currentUserId);
        // Exclude the current user from subordinates
        subordinateIds.remove(currentUserId);

        if (subordinateIds == null || subordinateIds.isEmpty()) {
            return new List<SubordinateWrapper>();
        }

        List<User> subordinateUsers = [
            SELECT Id, Name, Profile.Name, UserRole.Name, IsActive
            FROM User
            WHERE Id IN :subordinateIds
        ];

        // Also find inactive users who still have active beats
        Set<Id> inactiveUserIds = new Set<Id>();
        for (User u : subordinateUsers) {
            if (!u.IsActive) inactiveUserIds.add(u.Id);
        }

        // Check for active beats owned by inactive users
        Set<Id> inactiveUsersWithActiveBeats = new Set<Id>();
        if (!inactiveUserIds.isEmpty()) {
            for (Child_beat__c beat : [SELECT OwnerId FROM Child_beat__c WHERE OwnerId IN :inactiveUserIds AND Active__c = true]) {
                inactiveUsersWithActiveBeats.add(beat.OwnerId);
            }
        }

        List<SubordinateWrapper> result = new List<SubordinateWrapper>();
        for (User u : subordinateUsers) {
            // Include active users, and inactive users who still have active beats
            if (u.IsActive || inactiveUsersWithActiveBeats.contains(u.Id)) {
                SubordinateWrapper sw = new SubordinateWrapper();
                sw.userId = u.Id;
                sw.userName = u.Name;
                sw.roleName = u.UserRole != null ? u.UserRole.Name : '';
                sw.isActive = u.IsActive;
                sw.profileName = u.Profile != null ? u.Profile.Name : '';
                result.add(sw);
            }
        }
        return result;
    }

    // Get all ACTIVE beats for a selected subordinate (no day/date restriction per BRD 3a)
    @AuraEnabled
    public static List<BeatWrapper> getSubordinateBeats(Id subordinateUserId) {
        // Verify the current user is in the hierarchy above the subordinate
        Id currentUserId = UserInfo.getUserId();
        Set<Id> subordinateIds = RoleHeirarchyUtility.getRoleSubordinateUsers(currentUserId);
        subordinateIds.remove(currentUserId);

        if (subordinateIds == null || !subordinateIds.contains(subordinateUserId)) {
            throw new AuraHandledException('You do not have access to this user\'s beats.');
        }

        List<Child_beat__c> beats = [
            SELECT Id, Name, Primary_Customer__r.Name, Beat_Type__c, Active__c,
                   (SELECT Id FROM Junction_Beats__r WHERE Active__c = true)
            FROM Child_beat__c
            WHERE OwnerId = :subordinateUserId AND Active__c = true
        ];

        List<BeatWrapper> result = new List<BeatWrapper>();
        for (Child_beat__c beat : beats) {
            BeatWrapper bw = new BeatWrapper();
            bw.beatId = beat.Id;
            bw.beatName = beat.Name;
            bw.primaryCustomerName = beat.Primary_Customer__r != null ? beat.Primary_Customer__r.Name : '';
            bw.beatType = beat.Beat_Type__c;
            bw.isActive = beat.Active__c;
            bw.outletCount = beat.Junction_Beats__r != null ? beat.Junction_Beats__r.size() : 0;
            result.add(bw);
        }
        return result;
    }
}
