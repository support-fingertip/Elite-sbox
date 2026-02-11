public class EmployeeSubmitForApprovalController {
    @AuraEnabled
    public static String getAssignments(Id recordId) {
        Employee__c emp = [
            SELECT Id, Name, User__c, Is_Active__c, Payroll__c, Is_SSA_DSM__c 
            FROM Employee__c 
            WHERE Id = :recordId 
            LIMIT 1
        ];
        
        Boolean isPrimaryCustomerAssigned = false;
        Boolean isSecondaryCustomerAssigned = false;
        
        // -------------------------
        // Primary Assignment Check
        // -------------------------
        if (emp.Is_SSA_DSM__c) {
            List<Employee_Customer_Assignment__c> primaryAssignments = [
                SELECT Id 
                FROM Employee_Customer_Assignment__c 
                WHERE Employee__c = :recordId 
            ];
            isPrimaryCustomerAssigned = !primaryAssignments.isEmpty();
        } else {
            List<Product_Mapping__c> primaryAssignments = [
                SELECT Id 
                FROM Product_Mapping__c 
                WHERE Employee__c =: recordId 
                AND Customer__r.Customer_Type__c = 'Primary Customer'
            ];
            isPrimaryCustomerAssigned = !primaryAssignments.isEmpty();
        }
        
        // ----------------------------
        // Secondary Assignment Check
        // ----------------------------
        List<Product_Mapping__c> secondaryAssignments = [
            SELECT Id FROM Product_Mapping__c 
            WHERE Employee__c = :recordId  AND Customer__r.Customer_Type__c = 'Secondary Customer'
        ];
        isSecondaryCustomerAssigned = !secondaryAssignments.isEmpty();
        
        // ----------------------------
        // Final Response
        // ----------------------------
        if (isPrimaryCustomerAssigned && isSecondaryCustomerAssigned) {
            return 'Success';
        } else if (!isPrimaryCustomerAssigned && !isSecondaryCustomerAssigned) {
            return 'primary and secondary customers';
        } else if (!isPrimaryCustomerAssigned) {
            return 'primary customers';
        } else {
            return 'secondary customers';
        }
    }
    
    
    @AuraEnabled
    public static void submitForApproval(Id recordId, string comments) 
    {
        try {
            if (String.isBlank(comments)) comments = 'Submitting for Approval';
        
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setComments(comments);
            req.setObjectId(recordId);
            Approval.ProcessResult result = Approval.process(req);
            
            if (result.isSuccess()) {
                System.debug('Record submitted successfully for approval.');
            } else {
                System.debug('Failed to submit record for approval. Error: ' + result.getErrors()[0].getMessage());
            }
        }
        catch (Exception e) {
            System.debug('Something Went wrong: ' + e.getMessage());
            // throw new AuraHandledException('Error: ' + e.getMessage());
        }
        
    }
    
}