public class RejectOrder {
    @AuraEnabled
    public static string rejectOrder(string recordId)
    {
        try {
            List<Order__c> ordList = [select Id,Name,Status__c from Order__c where Id =:recordId ];
            if (ordList.isEmpty()) {  return 'Error: ORDER_NOT_FOUND'; }
            Order__c ord = ordList[0];
            // Check if the replacement has already been done
            if (ord.Status__c == 'Rejected' ) {
                return 'Error: REJECTION_COMPLETED';
            }
            
            ord.Status__c = 'Rejected';
            update Ord;
            return 'Success:Order has been rejected successfully.';
        }
        catch (Exception ex) {
            System.debug('Exception in rejcting order: ' + ex.getMessage());
            return 'Error: ' + ex.getMessage();
        }
        
    }
}