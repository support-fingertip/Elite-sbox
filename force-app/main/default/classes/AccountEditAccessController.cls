public with sharing class AccountEditAccessController {
    @AuraEnabled(cacheable=true)
    public static Boolean getEditPermission(Id userId) {
        User u = [SELECT Id, Profile.Name FROM User WHERE Id = :userId LIMIT 1];

        // Example logic: Allow edit only for specific profiles
        Set<String> allowedProfiles = new Set<String>{'System Administrator', 'Sales Manager'};

        return allowedProfiles.contains(u.Profile.Name);
    }
}