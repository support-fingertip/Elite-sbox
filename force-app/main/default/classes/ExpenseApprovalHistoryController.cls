global class ExpenseApprovalHistoryController {
    @AuraEnabled
    public static List<WrapSObject> GetData(Id expenseId, String filter) {
        List<WrapSObject> glist = new List<WrapSObject>();
        
        if (expenseId == null) {
            return glist;
        }
        
        // Get all Expense Line Item IDs for the given Expense
        List<Expenses_Line_Item__c> lineItems = [
            SELECT Id 
            FROM Expenses_Line_Item__c 
            WHERE Expense__c = :expenseId
        ];
        
        List<Id> expenseLineIds = new List<Id>();
        for (Expenses_Line_Item__c li : lineItems) {
            expenseLineIds.add(li.Id);
        }
        
        if (expenseLineIds.isEmpty()) {
            return glist;
        }
        
        List<Expenses_Line_Item__History> historyList = [
            SELECT CreatedById,
            CreatedBy.Name,
            CreatedDate,
            Field,
            NewValue,
            OldValue,
            ParentId,
            Parent.Name,
            Parent.Expense_Date__c,
            Parent.Expense_Type__c
            FROM Expenses_Line_Item__History
            WHERE ParentId IN :expenseLineIds and Field = 'Approval_Status__c'
            ORDER BY CreatedDate DESC
        ];
        Map<String, Schema.SObjectField> fieldMap = 
            Schema.getGlobalDescribe().get('Expenses_Line_Item__c')
            .getDescribe().fields.getMap();
        
        for (Expenses_Line_Item__History h : historyList) {
            if (h.Field == null) continue;
            
            WrapSObject wso = new WrapSObject();
            wso.CreatedByID = h.CreatedById;
            wso.CreatedByName = h.CreatedBy.Name;
            wso.CreatedDate = h.CreatedDate;
            wso.RecordID = h.ParentId;
            wso.type = 'History';
            // Get Parent details
            if (h.Parent != null) {
                wso.ExpenseDate = String.valueOf(h.Parent.Expense_Date__c);
                wso.ExpenseType = String.valueOf(h.Parent.Expense_Type__c);
            } 
            
            // Try to get Field Label
            try {
                Schema.DescribeFieldResult fDesc = fieldMap.get(h.Field).getDescribe();
                wso.Field = fDesc.getLabel();
            } catch (Exception e) {
                wso.Field = h.Field;
            }
            
            wso.NewValue = h.NewValue != null ? String.valueOf(h.NewValue) : 'Empty';
            wso.OldValue = h.OldValue != null ? String.valueOf(h.OldValue) : 'Empty';
            
            glist.add(wso);
        }
        
        
        // Sort latest first (just to be safe)
        glist.sort();
        return glist;
    }
    global class WrapSObject implements Comparable{
        @AuraEnabled public string CreatedByID{set;get;}
        @AuraEnabled public string CreatedByName{set;get;}
        @AuraEnabled public DateTime CreatedDate{set;get;}
        @AuraEnabled public string Field{set;get;}
        @AuraEnabled public string RecordID{set;get;}
        @AuraEnabled public string AccountID{set;get;}
        @AuraEnabled public string NewValue{set;get;}
        @AuraEnabled public string OldValue{set;get;}
        @AuraEnabled public string Subject{set;get;}
        @AuraEnabled public string Description{set;get;}
        @AuraEnabled public string type{set;get;}
        @AuraEnabled public string LeadName{set;get;}
        @AuraEnabled public decimal TotAmount{set;get;}
        @AuraEnabled public decimal TargetValue{set;get;}
        @AuraEnabled public decimal ActualValue{set;get;}
        @AuraEnabled public decimal achievedPercentage{set;get;}
        @AuraEnabled public string PeriodName{set;get;}
        @AuraEnabled public string comments{set;get;}
        @AuraEnabled public String ExpenseItemName { get; set; }
        @AuraEnabled public String ExpenseDate { get; set; }
        @AuraEnabled public String ExpenseType { get; set; }
        
        
        public  Integer compareTo(Object anotherObject){
            WrapSObject wso2=(WrapSObject) anotherObject;
            if(CreatedDate>wso2.CreatedDate){
                return -1;
            }else if(CreatedDate<wso2.CreatedDate){
                return 1;
            }
            return 0;
        }
        
        
    }
    
}