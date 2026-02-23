public without sharing class EmployeeDuplicationChecker {
    /**----------LWC Controller ---------**/
    public class DataBox{
        @AuraEnabled public string employeeName;
        @AuraEnabled public boolean duplicateFound;
        @AuraEnabled public String duplicateField;
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
                WHERE Aadhar_Number__c = :employeeData.Aadhar_Number__c 
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
        
        return db;
    }
}