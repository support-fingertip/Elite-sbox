/**
 * Runs the employee transfer in "without sharing" context so that admins and
 * managers without direct Modify All on Child_beat__c can still reassign
 * beats (Child_beat__c.User__c and OwnerId), product mappings, employee
 * customer assignments, and PJPs from the old user to the new user.
 *
 * This mirrors the pattern used by CustomerReplacementController.
 */
public without sharing class EmployeeTransferService {

    public static void transferEmployee(Map<String, String> oldToNewUserMap) {
        CustomSharingService.employeeTransfer(oldToNewUserMap);
    }
}