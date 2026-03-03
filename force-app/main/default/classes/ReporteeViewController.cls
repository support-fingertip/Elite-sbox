/*
*********************************************************
Apex Class Name    : ReporteeViewController
Created Date       : 2026
@description       : Controller for Reportee View - allows managers to view subordinate beats
@author            : Copilot
*********************************************************
*/
public with sharing class ReporteeViewController {

    public class SubordinateWrapper {
        @AuraEnabled public Id userId;
        @AuraEnabled public String userName;
        @AuraEnabled public String roleName;
        @AuraEnabled public String profileName;
        @AuraEnabled public Boolean isActive;
        @AuraEnabled public Id employeeId;
    }

    public class BeatWrapper {
        @AuraEnabled public Id beatId;
        @AuraEnabled public String beatName;
        @AuraEnabled public String primaryCustomerName;
        @AuraEnabled public String beatType;
        @AuraEnabled public Integer outletCount;
        @AuraEnabled public Boolean isActive;
        @AuraEnabled public String ownerName;
    }

    // Get all subordinates using role hierarchy (include inactive users whose beats are still active)
    @AuraEnabled
    public static List<SubordinateWrapper> getSubordinates() {
        try {
            Id currentUserId = UserInfo.getUserId();
            Set<Id> subordinateIds = RoleHeirarchyUtility.getRoleSubordinateUsers(currentUserId);
            // Remove current user from the set
            subordinateIds.remove(currentUserId);

            if (subordinateIds == null || subordinateIds.isEmpty()) {
                return new List<SubordinateWrapper>();
            }

            List<SubordinateWrapper> result = new List<SubordinateWrapper>();

            List<User> users = [SELECT Id, Name, IsActive, Profile.Name, UserRole.Name
                                FROM User WHERE Id IN :subordinateIds];

            Map<Id, Employee__c> userToEmployee = new Map<Id, Employee__c>();
            for (Employee__c emp : [SELECT Id, User__c, Is_Active__c FROM Employee__c WHERE User__c IN :subordinateIds]) {
                userToEmployee.put(emp.User__c, emp);
            }

            for (User u : users) {
                SubordinateWrapper sw = new SubordinateWrapper();
                sw.userId = u.Id;
                sw.userName = u.Name;
                sw.roleName = u.UserRole != null ? u.UserRole.Name : '';
                sw.profileName = u.Profile != null ? u.Profile.Name : '';
                sw.isActive = u.IsActive;
                Employee__c emp = userToEmployee.get(u.Id);
                sw.employeeId = emp != null ? emp.Id : null;
                result.add(sw);
            }

            return result;
        } catch (Exception e) {
            ExceptionHandler.addLog(e, '', 'ReporteeViewController.getSubordinates');
            throw new AuraHandledException(e.getMessage());
        }
    }

    // Get all ACTIVE beats for a selected subordinate (no day/date restriction)
    @AuraEnabled
    public static List<BeatWrapper> getSubordinateBeats(Id subordinateUserId) {
        try {
            List<BeatWrapper> result = new List<BeatWrapper>();

            List<Child_beat__c> beats = [SELECT Id, Name, Primary_Customer__c, Primary_Customer__r.Name,
                                         Beat_Type__c, Active__c, OwnerId, Owner.Name,
                                         (SELECT Id FROM Junction_Beats__r WHERE Active__c = true)
                                         FROM Child_beat__c
                                         WHERE OwnerId = :subordinateUserId AND Active__c = true
                                         ORDER BY Name];

            for (Child_beat__c beat : beats) {
                BeatWrapper bw = new BeatWrapper();
                bw.beatId = beat.Id;
                bw.beatName = beat.Name;
                bw.primaryCustomerName = beat.Primary_Customer__r != null ? beat.Primary_Customer__r.Name : '';
                bw.beatType = beat.Beat_Type__c;
                bw.outletCount = beat.Junction_Beats__r != null ? beat.Junction_Beats__r.size() : 0;
                bw.isActive = beat.Active__c;
                bw.ownerName = beat.Owner.Name;
                result.add(bw);
            }

            return result;
        } catch (Exception e) {
            ExceptionHandler.addLog(e, String.valueOf(subordinateUserId), 'ReporteeViewController.getSubordinateBeats');
            throw new AuraHandledException(e.getMessage());
        }
    }
}
