/*
*********************************************************
Apex Class Name    : ReporteeViewController
Created Date       : MAR 03, 2026
@description       : Controller for Reportee View - Today's Visit Tab
                     Allows managers to view and work on subordinates' beats
@author            : Elite Foods Dev Team
*********************************************************
*/
public without sharing class ReporteeViewController {

    public class SubordinateWrapper {
        @AuraEnabled public Id userId;
        @AuraEnabled public Id employeeId;
        @AuraEnabled public String name;
        @AuraEnabled public String employeeCode;
        @AuraEnabled public String roleName;
        @AuraEnabled public Boolean isActive;
        @AuraEnabled public Integer beatCount;
    }

    public class BeatWrapper {
        @AuraEnabled public Id beatId;
        @AuraEnabled public String beatName;
        @AuraEnabled public String primaryCustomerName;
        @AuraEnabled public String beatType;
        @AuraEnabled public Integer outletCount;
        @AuraEnabled public Boolean isActive;
    }

    @AuraEnabled(cacheable=false)
    public static List<SubordinateWrapper> getSubordinates() {
        Id currentUserId = UserInfo.getUserId();
        Set<Id> subordinateUserIds = RoleHeirarchyUtility.getRoleSubordinateUsers(currentUserId);
        // Remove current user from the set
        subordinateUserIds.remove(currentUserId);

        if (subordinateUserIds.isEmpty()) return new List<SubordinateWrapper>();

        // Get employee records for subordinates (include inactive if beats exist)
        Map<Id, Employee__c> userToEmployee = new Map<Id, Employee__c>();
        for (Employee__c emp : [
            SELECT Id, Name, User__c, Role__c, Is_Active__c, Employee_Code__c
            FROM Employee__c
            WHERE User__c IN :subordinateUserIds
        ]) {
            userToEmployee.put(emp.User__c, emp);
        }

        // Count active beats per user via AggregateResult
        Map<Id, Integer> userBeatCount = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT OwnerId, COUNT(Id) cnt
            FROM Child_beat__c
            WHERE OwnerId IN :subordinateUserIds AND Active__c = true
            GROUP BY OwnerId
        ]) {
            userBeatCount.put((Id)ar.get('OwnerId'), (Integer)ar.get('cnt'));
        }

        // Build result — include inactive employees if their beats are still active
        List<SubordinateWrapper> result = new List<SubordinateWrapper>();
        for (Id subUserId : subordinateUserIds) {
            Employee__c emp = userToEmployee.get(subUserId);
            if (emp == null) continue;

            Boolean isActive = emp.Is_Active__c;
            Integer beatCnt = userBeatCount.containsKey(subUserId) ? userBeatCount.get(subUserId) : 0;

            // Include inactive employees only if they have active beats
            if (!isActive && beatCnt == 0) continue;

            SubordinateWrapper sw = new SubordinateWrapper();
            sw.userId = subUserId;
            sw.employeeId = emp.Id;
            sw.name = emp.Name;
            sw.employeeCode = emp.Employee_Code__c;
            sw.roleName = emp.Role__c;
            sw.isActive = isActive;
            sw.beatCount = beatCnt;
            result.add(sw);
        }

        return result;
    }

    @AuraEnabled(cacheable=false)
    public static List<BeatWrapper> getSubordinateBeats(Id subordinateUserId) {
        if (subordinateUserId == null) return new List<BeatWrapper>();

        // Count outlets per beat via AggregateResult
        Map<Id, Integer> beatOutletCount = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT Child_beat__c beatId, COUNT(Id) cnt
            FROM Junction_Beat__c
            WHERE Child_beat__r.OwnerId = :subordinateUserId AND Active__c = true
            GROUP BY Child_beat__c
        ]) {
            beatOutletCount.put((Id)ar.get('beatId'), (Integer)ar.get('cnt'));
        }

        List<BeatWrapper> result = new List<BeatWrapper>();
        for (Child_beat__c beat : [
            SELECT Id, Name, Primary_Customer__r.Name, Beat_Type__c, Active__c
            FROM Child_beat__c
            WHERE OwnerId = :subordinateUserId AND Active__c = true
            ORDER BY Name ASC
        ]) {
            BeatWrapper bw = new BeatWrapper();
            bw.beatId = beat.Id;
            bw.beatName = beat.Name;
            bw.primaryCustomerName = beat.Primary_Customer__r != null ? beat.Primary_Customer__r.Name : '';
            bw.beatType = beat.Beat_Type__c;
            bw.isActive = beat.Active__c;
            bw.outletCount = beatOutletCount.containsKey(beat.Id) ? beatOutletCount.get(beat.Id) : 0;
            result.add(bw);
        }

        return result;
    }

    @AuraEnabled(cacheable=false)
    public static List<Junction_Beat__c> getSubordinateBeatOutlets(Id beatId) {
        if (beatId == null) return new List<Junction_Beat__c>();

        return [
            SELECT Id, Name, Account__c, Account__r.Name, Active__c, Order_Number__c, Beat_Type__c
            FROM Junction_Beat__c
            WHERE Child_beat__c = :beatId AND Active__c = true
            ORDER BY Order_Number__c ASC NULLS LAST
        ];
    }
}