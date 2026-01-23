public class CreditApprovalComponentController {
    @AuraEnabled
    public static void submitForApproval(Id recordId, string comments) 
    {
        Account Account = [select id,Requesting_For_Credit_Approval__c from Account where id =:recordId];
        Account.Requesting_For_Credit_Approval__c = true;
        update Account;
        try {
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
    @AuraEnabled
    public static string validateCreditField(Id recordId) 
    {
        string returnValue = 'Success';
        Account Account = [select id,Requesting_For_Credit_Approval__c,	Credit_Limit__c,Credit_Days__c from Account where id =:recordId];
        if(Account.Credit_Limit__c == null){
            returnValue = 'Credit_Limit';
        }
        else if(Account.Credit_Days__c == null){
              returnValue = 'Credit_Days';
        }
        else {
            returnValue = 'Success';
        }
        return returnValue;
      
    }

}