public class ExpenseTriggerHandler {
    public static void afterInsert(List<Expense__c> newExpenses) {
        Map<Id, User> userMap = new Map<Id, User>([SELECT Id,Expense_Approver_1__c,Expense_Approver_2_Finance_Dept__c FROM User]);
        
        for(Expense__c exp: newExpenses)
        {           
            User us = userMap.get(exp.OwnerId);
            if(us.Expense_Approver_1__c != null)
            {
                exp.Expense_Approver_L1__c =us.Expense_Approver_1__c;
            }
            if(us.Expense_Approver_2_Finance_Dept__c != null)
            {
                exp.Expense_Finance_Department_Approver__c =us.Expense_Approver_2_Finance_Dept__c;
            }
        }
        
    }
    
  /*  public static void afterUpdate(List<Expense__c> newExpenses,map<Id,Expense__c> oldMap) {
        
        set<Id> expenseIds = new set<Id>(); 
        map<Id,String> expenseWithApprovalStatus = new map<Id,String>();
        List<Expense__c> toUnlock = new List<Expense__c>();
        for(Expense__c exp: newExpenses)
        {   
            if(exp.Approval_Status__c != oldMap.get(exp.Id).Approval_Status__c)
            {
                toUnlock.add(exp);
                expenseIds.add(exp.Id);
                expenseWithApprovalStatus.put(exp.Id,exp.Approval_Status__c );
            }
        }
        
        if (!toUnlock.isEmpty()) {
            UnlockExpenseRecord.unlockExpenses(new Map<Id,Expense__c>(toUnlock).keySet());
        }
        
        
        list<Expenses_Line_Item__c> expenseItemsToUpdate =[select Id,Name,Expense__c,Expense__r.Approval_Status__c,Approval_Status__c from Expenses_Line_Item__c where
                                                           Approval_Status__c !='Finance Dept. Approved'
                                                          ];
        for(Expenses_Line_Item__c expItem : expenseItemsToUpdate)
        {
            if(expenseWithApprovalStatus.containsKey(expItem.Expense__c))
            {
                String ApprovalStatus = expenseWithApprovalStatus.get(expItem.Expense__c);
                if(ApprovalStatus =='Pending' && (expItem.Approval_Status__c =='Not Submitted' || 
                                                  expItem.Approval_Status__c =='Level 1 Rejected' || 	expItem.Approval_Status__c =='Finance Dept. Rejected'))
                {
                    expItem.Approval_Status__c = ApprovalStatus;
                }
                if(ApprovalStatus =='Level 1 Approved' && (expItem.Approval_Status__c =='Pending'))
                {
                     expItem.Approval_Status__c = ApprovalStatus;
                }
                if(ApprovalStatus =='Level 1 Rejected' && (expItem.Approval_Status__c =='Pending'))
                {
                    expItem.Approval_Status__c = ApprovalStatus;
                }
                if(ApprovalStatus =='Finance Dept. Approved' && (expItem.Approval_Status__c =='Pending' || expItem.Approval_Status__c =='Level 1 Approved'))
                {
                    expItem.Approval_Status__c = ApprovalStatus;
                }
                if(ApprovalStatus =='Finance Dept. Rejected' && (expItem.Approval_Status__c =='Pending' || expItem.Approval_Status__c =='Level 1 Approved'))
                {
                    expItem.Approval_Status__c = ApprovalStatus;
                }
             
            }
            
        }
        if(!expenseItemsToUpdate.isEmpty())
        {
            update expenseItemsToUpdate;
        }
      
        
        
    }*/
}