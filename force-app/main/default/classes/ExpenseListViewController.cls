global with sharing class ExpenseListViewController 
{
   /* //Expense Data
    @AuraEnabled
    public static DataBox getExpenses() 
    {
        DataBox dt = new DataBox();
        string userId = UserInfo.getUserId();
        dt.expenses = [Select Id, Name, Expense_From_Date__c,Expense_To_Date__c,DA_Amount__c,others_Amount__c,
                                        OwnerId,TA_Amount__c,Total_Expense_Amount__c,Approval_Status__c,Comments__c,
                                        Total_Amount__c,Total_Amount_DA__c,	Total_Amount_TA__c, Total_other_amount__c,
                                        (select Id,Name,Amount__c,Expense__c,Calculated_KM__c,Expense__r.Expense_From_Date__c,
                                         Description__c, Expense_Type__c,Mode_of_transport__c,Total_KM__c,Allowance_Type__c,
                                         Expense_Date__c,Area_Name__c,City__c from 	Expenses_line_items__r order by Expense_Date__c ASC)
                                        from Expense__c order by Expense_From_Date__c ASC];
        dt.months = GetPicklistValues.extractPicklistValues('Expense__c','Month__c'); 
        dt.years = GetPicklistValues.extractPicklistValues('Expense__c','Year__c'); 
        dt.approvalStatus = GetPicklistValues.extractPicklistValues('Expense__c','Approval_Status__c'); 
        Set<ID> UserIds = RoleHeirarchyUtility.getRoleSubordinateUsers(userId); 
        dt.userList = [select Id,Name,ManagerId,Manager.ManagerId,Profile.Name,Sales_Channel__c from User where id in:UserIds and isactive = true];
        return dt;
    }
    @AuraEnabled
    public static List<Expense__c> getExpensesbyFilter(String userId, String year, String month, String approvalStatus) {
        String baseQuery = 'SELECT Id, Name, Expense_From_Date__c, Expense_To_Date__c, DA_Amount__c, others_Amount__c, ' +
            'OwnerId, TA_Amount__c, Total_Expense_Amount__c, Approval_Status__c, Comments__c, ' +
            'Total_Amount__c, Total_Amount_DA__c, Total_Amount_TA__c, Total_other_amount__c, ' +
            '(SELECT Id, Name, Amount__c, Expense__c, Calculated_KM__c, Expense__r.Expense_From_Date__c, ' +
            'Description__c, Expense_Type__c, Mode_of_transport__c, Total_KM__c, Allowance_Type__c, ' +
            'Expense_Date__c, Area_Name__c, City__c FROM Expenses_line_items__r ORDER BY Expense_Date__c ASC) ' +
            'FROM Expense__c WHERE Id != null';
        
        if (String.isNotBlank(userId) && userId != 'All') {
            baseQuery += ' AND OwnerId = :userId';
        }
        if (String.isNotBlank(year) && year != 'All') {
            baseQuery += ' AND Year__c = :year';
        }
        if (String.isNotBlank(month) && month != 'All') {
            baseQuery += ' AND Month__c = :month';
        }
        if (String.isNotBlank(approvalStatus) && approvalStatus != 'All') {
            baseQuery += ' AND Approval_Status__c = :approvalStatus';
        }
        
        baseQuery += ' ORDER BY Expense_From_Date__c ASC';
        
        return Database.query(baseQuery);
    }
    
    
    //Get Expense Line Items
    @AuraEnabled
    public static DataBox getAllData(String recordId)
    {
        dataBox db = new dataBox();
        List<ListView> listviews = [SELECT Id, Name FROM ListView WHERE SobjectType = 'Expense__c' and Name='All'];
        db.listId = listviews[0].Id;
        Id profileId = [SELECT ProfileId FROM User WHERE Id = :UserInfo.getUserId()].ProfileId;
        string  profileName = [SELECT Name FROM Profile WHERE Id = :profileId].Name;
        db.ProfileName = profileName;
        db.BackDatedEntry= label.ExpenseDateLimit;
        db.ExpTypes = GetPicklistValues.extractPicklistValues('Expenses_line_item__c','Expense_Type__c');
        db.ModOfTrans = GetPicklistValues.extractPicklistValues('Expenses_line_item__c','Mode_of_transport__c');
        db.AllwTypes = GetPicklistValues.extractPicklistValues('Expenses_line_item__c','Allowance_Type__c');
                
        if(recordId != null && recordId != '')
        {
            db.ExlineItems = [select Id,Name,Amount__c,Expense__c,Calculated_KM__c,Expense__r.Expense_From_Date__c,Description__c,With_Companion__c,
                              Colleague_Name__c,Colleague_Name_2__c,AddtionalKMWith20__c, Expense_Type__c,Mode_of_transport__c,Total_KM__c,
                              Allowance_Type__c,Expense_Date__c,Area_Name__c,City__c from Expenses_line_item__c where Expense__c =: recordId];
            Expense__c ex=[Select Id, Name, Expense_From_Date__c,Expense_To_Date__c,DA_Amount__c,others_Amount__c,OwnerId,TA_Amount__c,
                           Total_Expense_Amount__c,Approval_Status__c,Comments__c,	Total_Amount__c,Total_Amount_DA__c,	Total_Amount_TA__c,
                           Total_other_amount__c from Expense__c where Id=:recordId];   
            db.expense = ex;
            Id currentUserId = UserInfo.getUserId();
            integer monthValue = ex.Expense_From_Date__c.month();
            integer Yearvalue = ex.Expense_From_Date__c.Year();
            
            db.dailyLogList=[select id,name,Today_Day_Travelled_Distance_KM__c,KMs_Travelled__c,LogDate__c,Travel_Type__c,User__c,
                             User__r.Name from Daily_Log__c where ownerid =:ex.OwnerId and
                             Log_Month__c =: monthValue and Log_Year__c =:Yearvalue ];           
        }
        return db;
    }
    //Checkig expense with same date
    @AuraEnabled
    public static ValdataBox checkExist(date start){
        Id currentUserId = UserInfo.getUserId();
        boolean AlreadyExist = false;
        integer monthValue = start.month();
        integer Yearvalue = start.Year();
        
        list<Expense__c> ex=[select id from Expense__c where Expense_Month__c=:monthValue 
                             and Expense_Year__c =:Yearvalue and ownerid=:currentUserId];
        if(ex.size()>0){
            AlreadyExist = true;
        }
        ValdataBox vDb=new ValdataBox();
        vDb.RecordExistedOrnot=AlreadyExist;
        if(!AlreadyExist)
        {
            vDb.dailyLogList=[select Id,name,KMs_Travelled__c,	Today_Day_Travelled_Distance_KM__c,LogDate__c,Visit_Type__c,Travel_Type__c
                              from Daily_Log__c where ownerid =:currentUserId and
                              Log_Month__c =: monthValue and Log_Year__c =:Yearvalue ];
        }
        
        return vDb;
    } 

    //Insert Expense Item
    @AuraEnabled
    public static Expenses_line_item__c insertExpenseItem(Expenses_line_item__c expenseItem){ 
        try {
            upsert expenseItem; 
            return [select Id,Name,Amount__c,Expense__c,Calculated_KM__c,Expense__r.Expense_From_Date__c,Description__c,With_Companion__c,
                    Colleague_Name__c,Colleague_Name_2__c,AddtionalKMWith20__c, Expense_Type__c,Mode_of_transport__c,Total_KM__c,
                Allowance_Type__c,Expense_Date__c,Area_Name__c,City__c from Expenses_line_item__c where Id =: expenseItem.Id];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static void submitForApproval(Id recordId, String comments) {
        // Create an approval request
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setComments(comments);
        req.setObjectId(recordId);

        // Submit the approval request
        Approval.ProcessResult result = Approval.process(req);

        // Check the result
        if (result.isSuccess()) {
            System.debug('Successfully submitted for approval.');
        } else {
            // Handle errors
            for (Database.Error err : result.getErrors()) {
                System.debug('Error: ' + err.getMessage());
                throw new AuraHandledException(err.getMessage());
            }
        }
    }
    
    global class DataBox{ 
        @AuraEnabled public list<Expense__c> expenses = new list<Expense__c>();
        @AuraEnabled public List<Map<String, String>> months = new List<Map<String, String>> ();
        @AuraEnabled public List<Map<String, String>> years = new List<Map<String, String>> ();
        @AuraEnabled public List<Map<String, String>> approvalStatus = new List<Map<String, String>> ();
        @AuraEnabled public List<User> userList = new List<User> ();
        
        
        @AuraEnabled public string listId;
        @AuraEnabled public String ProfileName;
        @AuraEnabled public string ApprovedId;
        @AuraEnabled public string BackDatedEntry;
       // @AuraEnabled public Price_Master__mdt PriceMaster;
       // @AuraEnabled public DA_Amount_Master__mdt DAMaster;
        @AuraEnabled public List<Map<String, String>> ExpTypes = new List<Map<String, String>> ();
        @AuraEnabled public List<Map<String, String>> ModOfTrans = new List<Map<String, String>> ();
        @AuraEnabled public List<Map<String, String>> AllwTypes = new List<Map<String, String>> ();
        
        
        @AuraEnabled public list<Expenses_line_item__c> ExlineItems;
        @AuraEnabled public Expense__c expense;
        @AuraEnabled public list<Daily_Log__c> dailyLogList;
    }
    global class ValdataBox{
        @AuraEnabled
        public Boolean LogExists {get; set;}
        @AuraEnabled
        public decimal TotalKM {get; set;}  
        @AuraEnabled
        public string CanCreate {get; set;}
        @AuraEnabled
        public Daily_Log__c dailyLogRec {get; set;}
        @AuraEnabled
        public list<Daily_Log__c> dailyLogList {get; set;}
        @AuraEnabled
        public Boolean RecordExistedOrnot {get; set;}
        @AuraEnabled
        public list<Expenses_line_item__c> ExlineItems {get; set;}
    }*/

}