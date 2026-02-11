public class ApproverReplacementQueue implements Queueable {

    private Map<String, String> oldEmployeeWithNewEmployeeMap;
    private Set<String> oldUserIds;

    // ✅ Constructor
    public ApproverReplacementQueue(Map<String, String> oldEmployeeWithNewEmployeeMap, Set<String> oldUserIds) {
        this.oldEmployeeWithNewEmployeeMap = oldEmployeeWithNewEmployeeMap;
        this.oldUserIds = oldUserIds;
    }

    public void execute(QueueableContext context) {
        List<Employee__c> employeesToUpdate = [
            SELECT Id,
                RSM__c, ASM_TSM__c, Employee_Approver_3_HR__c,
                Secondary_Customer_Approver_1__c, Secondary_Customer_Approver_2__c,
                Primary_Customer_Approver_1__c, Primary_Customer_Approver_2__c, Primary_Customer_Approver_3_CD__c,
                PJP_Approver_1__c, PJP_Approver_2__c,
                Expense_Approver_1__c, Expense_Approver_2_Finance_Department__c, Reporting_Manager__c
            FROM Employee__c
            WHERE RSM__c IN :oldUserIds
                OR ASM_TSM__c IN :oldUserIds
                OR Employee_Approver_3_HR__c IN :oldUserIds
                OR Secondary_Customer_Approver_1__c IN :oldUserIds
                OR Secondary_Customer_Approver_2__c IN :oldUserIds
                OR Primary_Customer_Approver_1__c IN :oldUserIds
                OR Primary_Customer_Approver_2__c IN :oldUserIds
                OR Primary_Customer_Approver_3_CD__c IN :oldUserIds
                OR PJP_Approver_1__c IN :oldUserIds
                OR PJP_Approver_2__c IN :oldUserIds
                OR Expense_Approver_1__c IN :oldUserIds
                OR Expense_Approver_2_Finance_Department__c IN :oldUserIds
                OR Reporting_Manager__c IN :oldUserIds
        ];

        List<Employee__c> updatedEmployees = new List<Employee__c>();

        for (Employee__c emp : employeesToUpdate) {
            Boolean isChanged = false;

            if (oldEmployeeWithNewEmployeeMap.containsKey(emp.RSM__c)) {
                emp.RSM__c = oldEmployeeWithNewEmployeeMap.get(emp.RSM__c);
                isChanged = true;
            }
            if (oldEmployeeWithNewEmployeeMap.containsKey(emp.ASM_TSM__c)) {
                emp.ASM_TSM__c = oldEmployeeWithNewEmployeeMap.get(emp.ASM_TSM__c);
                isChanged = true;
            }
            if (oldEmployeeWithNewEmployeeMap.containsKey(emp.Employee_Approver_3_HR__c)) {
                emp.Employee_Approver_3_HR__c = oldEmployeeWithNewEmployeeMap.get(emp.Employee_Approver_3_HR__c);
                isChanged = true;
            }
            if (oldEmployeeWithNewEmployeeMap.containsKey(emp.Secondary_Customer_Approver_1__c)) {
                emp.Secondary_Customer_Approver_1__c = oldEmployeeWithNewEmployeeMap.get(emp.Secondary_Customer_Approver_1__c);
                isChanged = true;
            }
            if (oldEmployeeWithNewEmployeeMap.containsKey(emp.Secondary_Customer_Approver_2__c)) {
                emp.Secondary_Customer_Approver_2__c = oldEmployeeWithNewEmployeeMap.get(emp.Secondary_Customer_Approver_2__c);
                isChanged = true;
            }
            if (oldEmployeeWithNewEmployeeMap.containsKey(emp.Primary_Customer_Approver_1__c)) {
                emp.Primary_Customer_Approver_1__c = oldEmployeeWithNewEmployeeMap.get(emp.Primary_Customer_Approver_1__c);
                isChanged = true;
            }
            if (oldEmployeeWithNewEmployeeMap.containsKey(emp.Primary_Customer_Approver_2__c)) {
                emp.Primary_Customer_Approver_2__c = oldEmployeeWithNewEmployeeMap.get(emp.Primary_Customer_Approver_2__c);
                isChanged = true;
            }
            if (oldEmployeeWithNewEmployeeMap.containsKey(emp.Primary_Customer_Approver_3_CD__c)) {
                emp.Primary_Customer_Approver_3_CD__c = oldEmployeeWithNewEmployeeMap.get(emp.Primary_Customer_Approver_3_CD__c);
                isChanged = true;
            }
            if (oldEmployeeWithNewEmployeeMap.containsKey(emp.PJP_Approver_1__c)) {
                emp.PJP_Approver_1__c = oldEmployeeWithNewEmployeeMap.get(emp.PJP_Approver_1__c);
                isChanged = true;
            }
            if (oldEmployeeWithNewEmployeeMap.containsKey(emp.PJP_Approver_2__c)) {
                emp.PJP_Approver_2__c = oldEmployeeWithNewEmployeeMap.get(emp.PJP_Approver_2__c);
                isChanged = true;
            }
            if (oldEmployeeWithNewEmployeeMap.containsKey(emp.Expense_Approver_1__c)) {
                emp.Expense_Approver_1__c = oldEmployeeWithNewEmployeeMap.get(emp.Expense_Approver_1__c);
                isChanged = true;
            }
            if (oldEmployeeWithNewEmployeeMap.containsKey(emp.Expense_Approver_2_Finance_Department__c)) {
                emp.Expense_Approver_2_Finance_Department__c = oldEmployeeWithNewEmployeeMap.get(emp.Expense_Approver_2_Finance_Department__c);
                isChanged = true;
            }
            if (oldEmployeeWithNewEmployeeMap.containsKey(emp.Reporting_Manager__c)) {
                emp.Reporting_Manager__c = oldEmployeeWithNewEmployeeMap.get(emp.Reporting_Manager__c);
                isChanged = true;
            }

            if (isChanged) {
                updatedEmployees.add(emp);
            }
        }

        if (!updatedEmployees.isEmpty()) {
            Database.update(updatedEmployees, false);
        }
    }
}