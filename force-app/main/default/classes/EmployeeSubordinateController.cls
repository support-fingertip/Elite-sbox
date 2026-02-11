public with sharing class EmployeeSubordinateController {
    @AuraEnabled(cacheable=true)
    public static List<Employee__c> getSubordinates(Id employeeId) {
        Employee__c emp = [SELECT Id, User__c,User__r.UserRoleId  FROM Employee__c WHERE Id = :employeeId  LIMIT 1];
        Id empUserId = emp.User__c;
        Id empRoleId = emp.User__r.UserRoleId;
        Set<Id> userIds = RoleHeirarchyUtility.getUsersUnderRoleHierarchy(empUserId);
        // Remove users having the same role as the current employee
        if (empRoleId != null && !userIds.isEmpty()) {
            List<User> sameRoleUsers = [SELECT Id  FROM User WHERE UserRoleId = :empRoleId  AND Id IN :userIds  ];
            for (User sameRoleUser : sameRoleUsers) {userIds.remove(sameRoleUser.Id); }
        }

        return [
            SELECT Id, Name, Employee_Code__c, Profile__c,	Designation__c,Sales_Channel__c,	Vendor_Code__c,Is_Active__c FROM Employee__c WHERE User__c IN :userIds AND Is_Active__c = true ORDER BY Profile__c
        ];
    }
}