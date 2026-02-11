public with sharing class RoleHeirarchyUtility {
    
    public static Set<ID> getRoleSubordinateUsers(Id userId) {
        
        Set<Id> allSubRoleIds = getAllSubRoleIds(New Set<ID>{userId});
        allSubRoleIds.add(userId);
        Map<Id, User> users = new Map<Id, User>([SELECT Id, Name From  User Where Id IN  :allSubRoleIds and isActive = true]);
        
        return users.keySet();
    }
    
    //Recursive function
    private static Set<ID> getAllSubRoleIds(Set<ID> userId) {
        
        Set<ID> currentRoleIds = new Set<ID>();
        
        for(User userRole :[SELECT Id, Name,ManagerId From  User Where ManagerId IN :userId AND ManagerId != null and isActive = true]){
            currentRoleIds.add(userRole.Id);
        }
        if(currentRoleIds.size() > 0){
            currentRoleIds.addAll(getAllSubRoleIds(currentRoleIds));
        }        
        return currentRoleIds;   
    }
    
    public static Set<Id> getUsersUnderRoleHierarchy(Id userId) {
        // Step 1: Get user's role
        Id userRoleId = [SELECT UserRoleId FROM User WHERE Id = :userId].UserRoleId;
        if (userRoleId == null) return new Set<Id>();
        
        // Step 2: Get all subordinate role IDs
        Set<Id> roleIds = getAllChildRoleIds(new Set<Id>{ userRoleId });
        roleIds.add(userRoleId); // include the current user's role if needed
        
        // Step 3: Query all users with those roles
        List<User> subordinateUsers = [
            SELECT Id
            FROM User
            WHERE UserRoleId IN :roleIds
            AND IsActive = true
        ];
        
        // Step 4: Collect user IDs
        Set<Id> userIds = new Set<Id>();
        for (User u : subordinateUsers) {
            userIds.add(u.Id);
        }
        
        return userIds;
    }
    
    
    // Public method to get all subordinate UserRole IDs for a given User
    public static Set<Id> getSubordinateUserRoleIds(Id userId) {
        // Get the User's Role ID
        Id userRoleId = [SELECT UserRoleId FROM User WHERE Id = :userId].UserRoleId;
        if (userRoleId == null) return new Set<Id>();
        
        // Collect all subordinate role Ids recursively
        Set<Id> subordinateRoleIds = getAllChildRoleIds(new Set<Id>{ userRoleId });
        return subordinateRoleIds;
    }
    
    // Recursive function to get all child role IDs from a given set of parent role IDs
    private static Set<Id> getAllChildRoleIds(Set<Id> parentRoleIds) {
        Set<Id> childRoleIds = new Set<Id>();
        
        // Fetch roles where ParentRoleId is in the given set
        List<UserRole> childRoles = [
            SELECT Id, ParentRoleId 
            FROM UserRole 
            WHERE ParentRoleId IN :parentRoleIds
        ];
        
        for (UserRole role : childRoles) {
            childRoleIds.add(role.Id);
        }
        
        // Recurse if new child roles are found
        if (!childRoleIds.isEmpty()) {
            childRoleIds.addAll(getAllChildRoleIds(childRoleIds));
        }
        
        return childRoleIds;
    }
    
    
    
    
    
    
    //It will get the Manager to Subordinate Users without Inner Queries
    public static Map<Id, Set<Id>> getManagerWithSubordinates(Set<Id> userIds) {
        Map<Id, Set<Id>> managerToSubordinates = new Map<Id, Set<Id>>();
        
        if (userIds == null || userIds.isEmpty()) return managerToSubordinates;
        
        // STEP 1: Query only the managers' roles
        Map<Id, User> inputUsers = new Map<Id, User>(
            [SELECT Id, UserRoleId FROM User WHERE Id IN :userIds AND UserRoleId != null]
        );
        
        Set<Id> managerRoleIds = new Set<Id>();
        for (User u : inputUsers.values()) {
            managerRoleIds.add(u.UserRoleId);
        }
        
        // STEP 2: Query only UserRole records (SAFE: user roles never exceed 10k)
        Map<Id, UserRole> allRoles = new Map<Id, UserRole>(
            [SELECT Id, ParentRoleId FROM UserRole]
        );
        
        // STEP 3: Build ParentRole → ChildRole map
        Map<Id, Set<Id>> parentToChildren = new Map<Id, Set<Id>>();
        for (UserRole role : allRoles.values()) {
            if (role.ParentRoleId != null) {
                if (!parentToChildren.containsKey(role.ParentRoleId)) {
                    parentToChildren.put(role.ParentRoleId, new Set<Id>());
                }
                parentToChildren.get(role.ParentRoleId).add(role.Id);

            }
        }
        
        // STEP 4: Get ALL subordinate role Ids for all managers
        Set<Id> allSubordinateRoles = new Set<Id>();
        Map<Id, Set<Id>> managerToRoleSet = new Map<Id, Set<Id>>();
        
        for (Id managerId : inputUsers.keySet()) {
            Set<Id> roleSet = new Set<Id>();
            collectChildRoles(inputUsers.get(managerId).UserRoleId, parentToChildren, roleSet);
            managerToRoleSet.put(managerId, roleSet);
            allSubordinateRoles.addAll(roleSet);
        }
        
        // STEP 5: Query only users assigned to subordinate roles
        Map<Id, List<User>> roleToUsers = new Map<Id, List<User>>();
        if (!allSubordinateRoles.isEmpty()) {
            for (User u : [
                SELECT Id, UserRoleId
                FROM User
                WHERE UserRoleId IN :allSubordinateRoles and isActive = true
            ]) {
                if (!roleToUsers.containsKey(u.UserRoleId)) {
                    roleToUsers.put(u.UserRoleId, new List<User>());
                }
                roleToUsers.get(u.UserRoleId).add(u);
            }
        }
        
        // STEP 6: Map managers → subordinate users
        for (Id managerId : managerToRoleSet.keySet()) {
            Set<Id> subordinateUserIds = new Set<Id>();
            
            for (Id rId : managerToRoleSet.get(managerId)) {
                if (roleToUsers.containsKey(rId)) {
                    for (User u : roleToUsers.get(rId)) {
                        subordinateUserIds.add(u.Id);
                    }
                }
            }
            
            managerToSubordinates.put(managerId, subordinateUserIds);
        }
        
        return managerToSubordinates;
    }
    
    // Recursively collect child roles
    private static void collectChildRoles(Id parentRoleId, Map<Id, Set<Id>> parentToChildren, Set<Id> result) {
        if (!parentToChildren.containsKey(parentRoleId)) return;
        
        for (Id childRoleId : parentToChildren.get(parentRoleId)) {
            if (result.add(childRoleId)) {
                collectChildRoles(childRoleId, parentToChildren, result);
            }
        }
    }
    
    
    
}