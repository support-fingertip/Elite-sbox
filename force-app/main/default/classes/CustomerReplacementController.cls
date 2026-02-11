public class CustomerReplacementController {
    
    @AuraEnabled
    public static String customerReplacement(Id recordId) {
        try {
            List<Account> customerList = [SELECT Id,Transferred_To__c,Transferred_To__r.Name,Deactivate_Reason2__c,Is_Transfer_Completed__c,
                                          Customer_Status__c,Customer_Type__c,Secondary_Customer_Type__c
                                          FROM Account WHERE Id = :recordId];
            
            if (customerList.isEmpty()) {
                return 'Error: CUSTOMER_NOT_FOUND';
            }
            
            Account acc = customerList[0];
  
            // Validate required fields
            if (acc.Transferred_To__c == null) {
                return 'Error: TRANSFERRED_TO_MISSING';
            }

            // Proceed with replacement if not already cloned
            if (!acc.Is_Transfer_Completed__c) {
                Map<String, String> oldPrimaryCustomerToNewMap = new Map<String, String>();
                Map<String, String> oldSubStockiestToNewSubStockiestMap = new Map<String, String>();
                
                
                // Collect inactive customers for replacement
                if (acc.Customer_Status__c == 'Inactive' && acc.Deactivate_Reason2__c == 'Replacement') {
                    if (acc.Customer_Type__c == 'Primary Customer') {
                        oldPrimaryCustomerToNewMap.put(acc.Id, acc.Transferred_To__c);
                    }
                    if (acc.Customer_Type__c == 'Secondary Customer' && acc.Secondary_Customer_Type__c == 'Sub Stockiest') {
                        oldSubStockiestToNewSubStockiestMap.put(acc.Id, acc.Transferred_To__c);
                    }
                }
                
                
                
                if (!oldPrimaryCustomerToNewMap.isEmpty() || !oldSubStockiestToNewSubStockiestMap.isEmpty()) {
                    CustomSharingService.customerReplacement(oldPrimaryCustomerToNewMap, oldSubStockiestToNewSubStockiestMap);
                    // Mark cloning complete for new Customer
                    acc.Is_Transfer_Completed__c = true;
                    update acc;
                }
                return 'Success: Customer Beats, Secoundary Customers and Executive Mappings successfully transferred.';
            } else {
                return 'Error: TRANSFER_COMPLETED';
            }
        } catch (Exception ex) {
            System.debug('Exception in employeeReplacement: ' + ex.getMessage());
            return 'Error: ' + ex.getMessage();
        }
    }
    
    
}