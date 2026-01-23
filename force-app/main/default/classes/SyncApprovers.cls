public class SyncApprovers {
    @AuraEnabled
    public static String syncApprovers(String empId) {
        // Fetch Employee
        List<Employee__c> employeeList = [
            SELECT Id, Name, User__c,RSM__c,ASM_TSM__c,Employee_Approver_3_HR__c,
            Secondary_Customer_Approver_1__c,Secondary_Customer_Approver_2__c,
            Primary_Customer_Approver_1__c,Primary_Customer_Approver_2__c,Primary_Customer_Approver_3_CD__c,
            PJP_Approver_1__c,Expense_Approver_1__c,Expense_Approver_2_Finance_Department__c
            FROM Employee__c 
            WHERE Id = :empId
        ];
        if (employeeList.isEmpty()) { return 'Error: EMPLOYEE_NOT_FOUND';}

        Employee__c emp = employeeList[0];
        if (emp.User__c == null) {return 'Error: USER_NOT_FOUND';}

        // Fetch User
        List<User> userList = [
            SELECT Id,RSM__c,ASM_TSM__c,Employee_Approver_3_HR__c,
            Primary_Customer_Approver_1__c, Primary_Customer_Approver_2__c, Primary_Customer_Approver_3_Credit_Dept__c,
            Secondary_Customer_Approver_1__c, Secondary_Customer_Approver_2__c,
            Expense_Approver_1__c,Expense_Approver_2_Finance_Dept__c, PJP_Approver_1__c
            FROM User WHERE Id = :emp.User__c
        ];
        if (userList.isEmpty()) {
            return 'Error: USER_RECORD_NOT_FOUND';
        }

        User usr = userList[0];

        // === Update Employee__c records ===
        List<Employee__c> employeesToUpdate = [
            SELECT Id, OwnerId, Approver_ASM__c, Approver_RSM__c, Employee_Owner_Approver_3_HR__c
            FROM Employee__c WHERE OwnerId = :usr.Id AND Payroll__c = 'No' AND Is_Active__c = false AND Approval_Status__c != 'HR Approved'
        ];

        for (Employee__c e : employeesToUpdate) {
            if(emp.ASM_TSM__c !=null) e.Approver_ASM__c = emp.ASM_TSM__c;
            if(emp.RSM__c !=null) e.Approver_RSM__c = emp.RSM__c;
            if(emp.Employee_Approver_3_HR__c !=null) e.Employee_Owner_Approver_3_HR__c = emp.Employee_Approver_3_HR__c;
        }
        if (!employeesToUpdate.isEmpty()) {
            database.update(employeesToUpdate,false);
        }

        // === Update Primary Customer Accounts ===
        List<Account> primaryAccountsToUpdate = [
            SELECT Id, CreatedById, ASM_TSM__c, RSM__c, Primary_Customer_Approver_L3_Credit__c FROM Account
            WHERE CreatedById = :usr.Id AND Customer_Type__c = 'Primary Customer' AND Approval_Status__c != 'Credit Dept. Approved' AND Customer_Status__c != 'Active'
        ];

        for (Account acc : primaryAccountsToUpdate) {
            if(emp.Primary_Customer_Approver_1__c !=null) acc.ASM_TSM__c = emp.Primary_Customer_Approver_1__c;
            if(emp.Primary_Customer_Approver_2__c !=null) acc.RSM__c = emp.Primary_Customer_Approver_2__c;
            if(emp.Primary_Customer_Approver_3_CD__c !=null) acc.Primary_Customer_Approver_L3_Credit__c = emp.Primary_Customer_Approver_3_CD__c;
        }
        if (!primaryAccountsToUpdate.isEmpty()) {
            database.update(primaryAccountsToUpdate,false);
        }

        // === Update Secondary Customer Accounts ===
        List<Account> secondaryAccountsToUpdate = [ SELECT Id, CreatedById, ASM_TSM__c, RSM__c FROM Account WHERE CreatedById = :usr.Id
            AND Customer_Type__c = 'Secondary Customer' AND Approval_Status__c != 'Level 2 Approved' AND Customer_Status__c != 'Active'
        ];

        for (Account acc : secondaryAccountsToUpdate) {
            if(emp.Secondary_Customer_Approver_1__c !=null) acc.ASM_TSM__c = emp.Secondary_Customer_Approver_1__c;
            if(emp.Secondary_Customer_Approver_2__c !=null) acc.RSM__c = emp.Secondary_Customer_Approver_2__c;
        }
        if (!secondaryAccountsToUpdate.isEmpty()) {
            database.update(secondaryAccountsToUpdate,false);
        }

        // === Update Expense__c records ===
        List<Expense__c> expensesToUpdate = [
            SELECT Id, OwnerId, Expense_Approver_L1__c, Expense_Finance_Department_Approver__c FROM Expense__c WHERE OwnerId = :usr.Id
        ];

        for (Expense__c exp : expensesToUpdate) {
            if(emp.Expense_Approver_1__c !=null) exp.Expense_Approver_L1__c = emp.Expense_Approver_1__c;
            if(emp.Expense_Approver_2_Finance_Department__c !=null) exp.Expense_Finance_Department_Approver__c = emp.Expense_Approver_2_Finance_Department__c;
        }
        if (!expensesToUpdate.isEmpty()) {
            database.update(expensesToUpdate,false);
        }

        // === Update PJP (Calendar_beat__c) records ===
        List<Calendar_beat__c> pjpToUpdate = [
            SELECT Id, OwnerId, Approver__c, User__c FROM Calendar_beat__c WHERE User__c = :usr.Id
        ];

        for (Calendar_beat__c pjp : pjpToUpdate) {
            if(emp.PJP_Approver_1__c !=null) pjp.Approver__c = emp.PJP_Approver_1__c;
        }
        if (!pjpToUpdate.isEmpty()) {
            database.update(pjpToUpdate,false);
        }
        updateUser(emp.Id, emp.User__c);


        return 'Success: Approvers synced successfully.';
    }
    
    @future
    public static void updateUser(Id empId, Id userId)
    {
        // Query the Employee record
        Employee__c emp = [
            SELECT RSM__c, ASM_TSM__c, Employee_Approver_3_HR__c,
            Secondary_Customer_Approver_1__c, Secondary_Customer_Approver_2__c,
            Primary_Customer_Approver_1__c, Primary_Customer_Approver_2__c, Primary_Customer_Approver_3_CD__c,
            PJP_Approver_1__c, PJP_Approver_2__c,
            Expense_Approver_1__c, Expense_Approver_2_Finance_Department__c,
            District_In_charge__c
            FROM Employee__c
            WHERE Id = :empId
            LIMIT 1
        ];
        
        User usr = new User(
            Id = userId,
            RSM__c = emp.RSM__c,
            ASM_TSM__c = emp.ASM_TSM__c,
            Employee_Approver_3_HR__c = emp.Employee_Approver_3_HR__c,
            Secondary_Customer_Approver_1__c = emp.Secondary_Customer_Approver_1__c,
            Secondary_Customer_Approver_2__c = emp.Secondary_Customer_Approver_2__c,
            Primary_Customer_Approver_1__c = emp.Primary_Customer_Approver_1__c,
            Primary_Customer_Approver_2__c = emp.Primary_Customer_Approver_2__c,
            Primary_Customer_Approver_3_Credit_Dept__c = emp.Primary_Customer_Approver_3_CD__c,
            PJP_Approver_1__c = emp.PJP_Approver_1__c,
            PJP_Approver_2__c = emp.PJP_Approver_2__c,
            Expense_Approver_1__c = emp.Expense_Approver_1__c,
            Expense_Approver_2_Finance_Dept__c = emp.Expense_Approver_2_Finance_Department__c,
            District_In_charge__c = emp.District_In_charge__c
        );
        
        update usr;
    }
    
}