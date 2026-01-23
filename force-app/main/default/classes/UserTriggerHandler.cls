public class UserTriggerHandler {
    public static Boolean userdeactivationProcess = false;
    public static void handleBeforeUpdate(List<User> newUsers, Map<Id, User> oldUserMap) {
        Set<Id> employeeApproverChangedUsers = new Set<Id>();
        Set<Id> primaryApproverChangedUsers = new Set<Id>();
        Set<Id> secondaryApproverChangedUsers = new Set<Id>();
        Set<Id> expenseApproverChangedUsers = new Set<Id>();
        Set<Id> pjpApproverChangedUsers = new Set<Id>();
        Map<Id, User> updatedMap = new Map<Id, User>();

        for (User newUser : newUsers) {
            User oldUser = oldUserMap.get(newUser.Id);

            Boolean employeeChanged = 
                newUser.RSM__c != oldUser.RSM__c || 
                newUser.ASM_TSM__c != oldUser.ASM_TSM__c || 
                newUser.Employee_Approver_3_HR__c != oldUser.Employee_Approver_3_HR__c;

            Boolean primaryChanged =
                newUser.Primary_Customer_Approver_1__c != oldUser.Primary_Customer_Approver_1__c ||
                newUser.Primary_Customer_Approver_2__c != oldUser.Primary_Customer_Approver_2__c ||
                newUser.Primary_Customer_Approver_3_Credit_Dept__c != oldUser.Primary_Customer_Approver_3_Credit_Dept__c;

            Boolean secondaryChanged =
                newUser.Secondary_Customer_Approver_1__c != oldUser.Secondary_Customer_Approver_1__c ||
                newUser.Secondary_Customer_Approver_2__c != oldUser.Secondary_Customer_Approver_2__c;

            Boolean expenseChanged =
                newUser.Expense_Approver_1__c != oldUser.Expense_Approver_1__c ||
                newUser.Expense_Approver_2_Finance_Dept__c != oldUser.Expense_Approver_2_Finance_Dept__c;
            
            Boolean pjpChanged = newUser.PJP_Approver_1__c != oldUser.PJP_Approver_1__c;

            if (employeeChanged) employeeApproverChangedUsers.add(newUser.Id);
            if (primaryChanged) primaryApproverChangedUsers.add(newUser.Id);
            if (secondaryChanged) secondaryApproverChangedUsers.add(newUser.Id);
            if (expenseChanged) expenseApproverChangedUsers.add(newUser.Id);  
            if (pjpChanged) pjpApproverChangedUsers.add(newUser.Id);
            
            if (employeeChanged || primaryChanged || secondaryChanged || expenseChanged || pjpChanged) {
                updatedMap.put(newUser.Id, newUser);
            }
        }

        // Update Employee__c records
        if (!employeeApproverChangedUsers.isEmpty()) {
            List<Employee__c> employeesToUpdate = [
                SELECT Id, OwnerId ,Approver_ASM__c,Approver_RSM__c,Employee_Owner_Approver_3_HR__c
                FROM Employee__c 
                WHERE OwnerId IN :employeeApproverChangedUsers 
                AND Payroll__c = 'No' 
                AND Is_Active__c = false 
                AND Approval_Status__c != 'HR Approved'
            ];
            for (Employee__c emp : employeesToUpdate) {
                User updatedUser = updatedMap.get(emp.OwnerId);
                emp.Approver_ASM__c = updatedUser.ASM_TSM__c;
                emp.Approver_RSM__c = updatedUser.RSM__c;
                emp.Employee_Owner_Approver_3_HR__c = updatedUser.Employee_Approver_3_HR__c;
            }
            update employeesToUpdate;
        }

        // Update Primary Customer Accounts
        if (!primaryApproverChangedUsers.isEmpty()) {
            List<Account> primaryAccountsToUpdate = [
                SELECT Id, CreatedBy_Id__c, ASM_TSM__c, RSM__c, Primary_Customer_Approver_L3_Credit__c 
                FROM Account 
                WHERE CreatedBy_Id__c IN :primaryApproverChangedUsers 
                AND Customer_Type__c = 'Primary Customer' 
                AND Approval_Status__c != 'Credit Dept. Approved' 
                AND Customer_Status__c != 'Active'
            ];
            for (Account acc : primaryAccountsToUpdate) {
                User updatedUser = updatedMap.get(acc.CreatedBy_Id__c);
                acc.ASM_TSM__c = updatedUser.Primary_Customer_Approver_1__c;
                acc.RSM__c = updatedUser.Primary_Customer_Approver_2__c;
                acc.Primary_Customer_Approver_L3_Credit__c = updatedUser.Primary_Customer_Approver_3_Credit_Dept__c;
            }
            update primaryAccountsToUpdate;
        }

        // Update Secondary Customer Accounts
        if (!secondaryApproverChangedUsers.isEmpty()) {
            List<Account> secondaryAccountsToUpdate = [
                SELECT Id, CreatedBy_Id__c, ASM_TSM__c, RSM__c 
                FROM Account 
                WHERE CreatedBy_Id__c IN :secondaryApproverChangedUsers 
                AND Customer_Type__c = 'Secondary Customer' 
                AND Approval_Status__c != 'Level 2 Approved' 
                AND Customer_Status__c != 'Active'
            ];
            for (Account acc : secondaryAccountsToUpdate) {
                User updatedUser = updatedMap.get(acc.CreatedBy_Id__c);
                acc.ASM_TSM__c = updatedUser.Secondary_Customer_Approver_1__c;
                acc.RSM__c = updatedUser.Secondary_Customer_Approver_2__c;
            }
            update secondaryAccountsToUpdate;
        }

        // Update Expense__c records
        if (!expenseApproverChangedUsers.isEmpty()) {
            List<Expense__c> expensesToUpdate = [
                SELECT Id, OwnerId,Expense_Finance_Department_Approver__c
                FROM Expense__c 
                WHERE OwnerId IN :expenseApproverChangedUsers
            ];
            for (Expense__c ex : expensesToUpdate) {
                User updatedUser = updatedMap.get(ex.OwnerId);
                ex.Expense_Approver_L1__c = updatedUser.Expense_Approver_1__c;
                ex.Expense_Finance_Department_Approver__c = updatedUser.Expense_Approver_2_Finance_Dept__c;
            }
            update expensesToUpdate;
        }
        
        //Update PJP records
        if(!pjpApproverChangedUsers.isEmpty())
        {
            List<Calendar_beat__c> pjpToUpdate = [
                SELECT Id, OwnerId,Approver__c,User__c
                FROM Calendar_beat__c 
                WHERE User__c IN :pjpApproverChangedUsers
            ];
            for (Calendar_beat__c pjp : pjpToUpdate) {
                User updatedUser = updatedMap.get(pjp.User__c);
                pjp.Approver__c = updatedUser.PJP_Approver_1__c;
                
            }
            update pjpToUpdate;
        }
        
        
        
        
    }
}