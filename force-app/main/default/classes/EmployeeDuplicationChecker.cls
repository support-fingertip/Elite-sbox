public without sharing class EmployeeDuplicationChecker {
    /**----------LWC Controller ---------**/
    public class DataBox{
        @AuraEnabled public string employeeName;
        @AuraEnabled public boolean duplicateFound;
        @AuraEnabled public String duplicateField;
        @AuraEnabled public String errorMessage;
    }
    @AuraEnabled
    public static DataBox duplicationCheck(Employee__c employeeData) {
        DataBox db = new DataBox();
        db.employeeName = '';
        db.duplicateFound = false;
        db.duplicateField = '';
        
        if (employeeData == null) {
            return db;
        }
        
        // Check User_Name__c duplication
        if (!String.isBlank(employeeData.User_Name__c)) {
            List<Employee__c> userDup = [
                SELECT Id, Name 
                FROM Employee__c 
                WHERE User_Name__c = :employeeData.User_Name__c 
                AND Id != :employeeData.Id 
                LIMIT 1
            ];
            
            if (!userDup.isEmpty()) {
                db.employeeName = userDup[0].Name;
                db.duplicateFound = true;
                db.duplicateField = 'User_Name__c';
                return db;
            }
        }
        
        // Check Aadhar Number duplication
        if (!String.isBlank(employeeData.Aadhar_Number__c)) {
            List<Employee__c> aadharDup = [
                SELECT Id, Name 
                FROM Employee__c 
                WHERE Aadhar_Number__c = :employeeData.Aadhar_Number__c and  Aadhar_Number__c != null
                AND Id != :employeeData.Id 
                LIMIT 1
            ];
            
            if (!aadharDup.isEmpty()) {
                db.employeeName = aadharDup[0].Name;
                db.duplicateFound = true;
                db.duplicateField = 'Aadhar_Number__c';
                return db;
            }
        }
        
        // Check Employee Code duplication
        if (!String.isBlank(employeeData.Employee_Code__c)) {
            List<Employee__c> codeDup = [
                SELECT Id, Name 
                FROM Employee__c 
                WHERE Employee_Code__c = :employeeData.Employee_Code__c 
                AND Id != :employeeData.Id 
                LIMIT 1
            ];
            
            if (!codeDup.isEmpty()) {
                db.employeeName = codeDup[0].Name;
                db.duplicateFound = true;
                db.duplicateField = 'Employee_Code__c';
                return db;
            }
        }
        
        
        
        // NEW: Check Expense Cycle changes
        if (employeeData.Id != null) {
            Employee__c oldEmp = [
                SELECT Expense_Start_Date__c, Expense_End_Date__c, User__c 
                FROM Employee__c 
                WHERE Id = :employeeData.Id
                LIMIT 1
            ];
            
            Boolean cycleChanged = (employeeData.Expense_Start_Date__c != oldEmp.Expense_Start_Date__c 
                                    || employeeData.Expense_End_Date__c   != oldEmp.Expense_End_Date__c);
            
            if (cycleChanged && oldEmp.User__c != null &&  oldEmp.Expense_Start_Date__c != null && oldEmp.Expense_End_Date__c   != null ) {
                
                Date today = Date.today();
                // Compare with new values
                Integer startDay = oldEmp.Expense_Start_Date__c != null ? oldEmp.Expense_Start_Date__c.intValue() : null;
                Integer endDay   = oldEmp.Expense_End_Date__c   != null ? oldEmp.Expense_End_Date__c.intValue()   : null;
                
                Date startDate; 
                Date endDate;
                
                // Special case: 1 → 15 cycle
                if (startDay == 1 && endDay == 15) {
                    if (today.day() <= 15) {
                        // First half of month
                        startDate = Date.newInstance(today.year(), today.month(), 1);
                        endDate   = Date.newInstance(today.year(), today.month(), 15);
                    } else {
                        // Second half of month → 16 → last day of month
                        Integer lastDay = Date.daysInMonth(today.year(), today.month());
                        startDate = Date.newInstance(today.year(), today.month(), 16);
                        endDate   = Date.newInstance(today.year(), today.month(), lastDay);
                    }
                }
                // Normal wrap-around cycles (30/31 day cycles)
                else {
                    // Case 1: today is on/before EndDay → cycle started last month and ends this month
                    if (today.day() <= endDay) {
                        startDate = Date.newInstance(today.year(), today.month() - 1, startDay);
                        endDate   = Date.newInstance(today.year(), today.month(), endDay);
                    }
                    // Case 2: today is after EndDay → cycle started this month and ends next month
                    else {
                        startDate = Date.newInstance(today.year(), today.month(), startDay); 
                        endDate   = Date.newInstance(today.year(), today.month() + 1, endDay);
                    }
                }
               
                
                List<Expense__c> existingExpenses = [
                    SELECT Id, Name, Start_Date__c, End_Date__c 
                    FROM Expense__c
                    WHERE OwnerId = :oldEmp.User__c
                    AND Start_Date__c = :startDate
                    AND End_Date__c   = :endDate
                    LIMIT 1
                ];
                
                if (!existingExpenses.isEmpty()) {
                    db.duplicateFound = true;
                    db.duplicateField = 'Expense_Cycle';
                    
                    String startStr = existingExpenses[0].Start_Date__c.format(); // YYYY-MM-DD
                    String endStr   = existingExpenses[0].End_Date__c.format();
                    
                    db.errorMessage = 'Expense record already exists for cycle ' 
                        + startStr + ' → ' + endStr 
                        + '. You cannot change the expense start date and end date.';
                    return db;
                }
            }
        }

        
        return db;
    }
}