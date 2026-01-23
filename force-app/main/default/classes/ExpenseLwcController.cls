public class ExpenseLwcController 
{
    public class dataBox
    { 
        @AuraEnabled public string listId {get; set;} 
        @AuraEnabled public String profileName {get;set;}
        @AuraEnabled public string approvedId{get;set;}
        @AuraEnabled public decimal backDatedEntry{get;set;}
        @AuraEnabled public List<Map<String, String>> travelTypes = new List<Map<String, String>> ();
        @AuraEnabled public List<Map<String, String>> expenseTypes = new List<Map<String, String>> ();
        @AuraEnabled public List<Map<String, String>> travelModes = new List<Map<String, String>> ();
        @AuraEnabled public List<City__c> cities;
        @AuraEnabled public Travel_Eligibility__c travelEligibility {get; set;}
        @AuraEnabled public list<Expenses_line_item__c> ExlineItems {get; set;}
        @AuraEnabled public Expense__c expense {get; set;}
        @AuraEnabled public list<Daily_Log__c> dailyLogList {get; set;}
        @AuraEnabled public boolean disabledFields {get; set;}
    }
    public class ValdataBox
    {
        @AuraEnabled
        public list<Daily_Log__c> dailyLogList {get; set;}
        @AuraEnabled
        public list<Expense__c> expenseItems {get; set;}
    }
    public class ReturndataBox{
        @AuraEnabled
        public Expense__c Exps {get; set;}
        @AuraEnabled
        public List<Expenses_line_item__c> ExpLis {get; set;}       
    }
    
   /* @AuraEnabled
    public static dataBox getAllData(String recordId)
    {
        dataBox db = new dataBox();
        List<ListView> listviews = [SELECT Id, Name FROM ListView WHERE SobjectType = 'Expense__c' and Name='All'];
        db.listId = listviews[0].Id;
        String userId = UserInfo.getUserId();
        user userRecord =  [SELECT Id,Name,isAdmin__c,Profile.Name,Sales_Channel__c,Band__c FROM User WHERE Id = :userId limit 1];
        String profileName = userRecord.Profile.Name;
        String Executive_Band = userRecord.Band__c;
        String Executive_Profile = profileName;
        
        db.ProfileName = profileName;
        Decimal expenseLimit = !String.isBlank(Label.ExpenseDateLimit)  ? Decimal.valueOf(Label.ExpenseDateLimit) : 1;
        
        db.BackDatedEntry = expenseLimit;
        db.cities = [SELECT Id,Name,Type__c FROM City__c];
        db.travelTypes = GetPicklistValues.extractPicklistValues('Expense__c','Travel_Type__c');
        db.expenseTypes = GetPicklistValues.extractPicklistValues('Expenses_line_item__c','Expense_Type__c');
        db.travelModes = GetPicklistValues.extractPicklistValues('Expenses_Line_Item__c','Travel_Mode__c');
        

        if(recordId != null)
        {
            Expense__c  expense = [select Id,Executive_Band__c,Executive_Profile__c From Expense__c where Id =:recordId];
            Executive_Profile = expense.Executive_Profile__c;
            Executive_Band = expense.Executive_Band__c;
        }
        Travel_Eligibility__c travelEligibility;
        
        List<Travel_Eligibility__c> bandElig = [
            SELECT Id, Band__c, Travel_Mode_UC__c, Travel_Mode_HQ__c, Daily_KM_Limit__c,
            Daily_Allowance_HQ__c, Dearness_Allowance__c, Local_Conveyance__c,
            Lodging_Expense_per_Day_Non_Metro__c, Lodging_Expense_per_Day_Metro__c,
            Conveyance_Allowance_per_KM_Own_Car__c, Conveyance_Allowance_per_KM_Bike__c
            FROM Travel_Eligibility__c
            WHERE Band__c = :userRecord.Band__c
            LIMIT 1
        ];
        
        if (!bandElig.isEmpty()) {
            travelEligibility = bandElig[0];
        } else {
            List<Travel_Eligibility__c> profileElig = [
                SELECT Id, Band__c, Travel_Mode_UC__c, Travel_Mode_HQ__c, Daily_KM_Limit__c,
                Daily_Allowance_HQ__c, Dearness_Allowance__c, Local_Conveyance__c,
                Lodging_Expense_per_Day_Non_Metro__c, Lodging_Expense_per_Day_Metro__c,
                Conveyance_Allowance_per_KM_Own_Car__c, Conveyance_Allowance_per_KM_Bike__c
                FROM Travel_Eligibility__c
                WHERE Profile__c = :profileName
                LIMIT 1
            ];
            if (!profileElig.isEmpty()) {
                travelEligibility = profileElig[0];
            }
        }
        db.travelEligibility = travelEligibility;
        
        return db;
    }

    @AuraEnabled
    public static ValdataBox validateExpenseDate(Date expenseDate){
        system.debug('expenseDate============>'+expenseDate);
        Id currentUserId = UserInfo.getUserId();        
        ValdataBox vDb=new ValdataBox();
        vDb.expenseItems = [
            SELECT Id,Travel_Type__c,
            (SELECT Id,Expense_Date__c,Expense_Type__c,Travel_Mode__c,City__c,City_Name__c,Total_KM__c,Calculated_KM__c,
             Amount__c,Remarks__c
             FROM Expenses_line_items__r) 
            FROM Expense__c 
            WHERE OwnerId = :currentUserId 
            AND Expense_Date__c = :expenseDate
        ];
        vDb.dailyLogList=[select Id,Travel_Type__c,Distance_Travelled__c from Daily_Log__c where ownerid =:currentUserId AND LogDate__c = :expenseDate];
        return vDb;
    } */
   /* @AuraEnabled
    public static ReturndataBox insertExpense(Expense__c expense,List<	Expenses_line_item__c> items, List<string> delitems){ 
        list<Expenses_line_item__c> NewExpLI =new list<	Expenses_line_item__c>();
        list<Expenses_line_item__c> OldExpLI =new list<	Expenses_line_item__c>();
        
        system.debug(expense); 
        system.debug(items);
        
        if(delitems.size()>0){
            list<Expenses_line_item__c> DelExpLineItem = [select Id,Name from 	Expenses_line_item__c where id =: delitems];
            delete DelExpLineItem;
        }
        if(expense !=null ){
            if(expense.Id == null){
                user usr = [SELECT Name from user where Id =:userinfo.getUserId() ];
                String year = String.valueOf(expense.Expense_From_Date__c.year());
                Integer month = expense.Expense_From_Date__c.month();
                String monthName = getMonthName(month);
                expense.Name = usr.Name + '/' + monthName + '/' + year;
                system.debug(expense.Name+ ' expense.Name');
            }
            upsert expense;
            
            for(Expenses_line_item__c itm: items){ 
                system.debug('itm.Id '+itm.Id);
                if(String.isEmpty(itm.Id)){
                    Expenses_line_item__c exp = new 	Expenses_line_item__c();
                    exp.Expense_Date__c = itm.Expense_Date__c;
                    exp.Expense_Type__c = itm.Expense_Type__c;
                    exp.Allowance_Type__c = itm.Allowance_Type__c;
                    exp.Area_Name__c = itm.Area_Name__c;
                    exp.City__c = itm.City__c;
                    exp.Description__c = itm.Description__c;
                    exp.Mode_of_transport__c = itm.Mode_of_transport__c;
                    exp.Total_KM__c = itm.Total_KM__c;
                    exp.Amount__c = itm.Amount__c;
                    exp.AddtionalKMWith20__c=itm.AddtionalKMWith20__c;
                    exp.Calculated_KM__c = itm.Calculated_KM__c;
                    exp.Expense__c = expense.Id;
                    NewExpLI.add(exp);
                }
                else{
                    OldExpLI.add(itm);
                }
            }
            upsert NewExpLI;
            upsert OldExpLI;
            
            list<Expenses_line_item__c> RetExpLineItem = [select Id,Name,Amount__c,Calculated_KM__c,AddtionalKMWith20__c,Expense__c,Expense__r.Expense_From_Date__c,Description__c,Expense_Type__c,Mode_of_transport__c,Total_KM__c,Allowance_Type__c,Expense_Date__c,Area_Name__c,City__c from 	Expenses_line_item__c where Expense__c =: expense.id Order by Expense_Date__c];
            
            ReturndataBox rdb= new ReturndataBox();
            rdb.Exps =[Select Id, Name, Expense_From_Date__c,Expense_To_Date__c,DA_Amount__c,others_Amount__c,	TA_Amount__c,
                       Total_Expense_Amount__c,Approval_Status__c,Comments__c from Expense__c where Id=:expense.Id ];
            rdb.ExpLis= RetExpLineItem;
            return rdb;
        }
        else{
            return null;
        }
    }
    public static String getMonthName(Integer monthNumber) {
        String monthName = '';
        switch on monthNumber {
            when 1{
                monthName = 'JAN';
            }
            when 2{
                monthName = 'FEB';
            }
            when 3{
                monthName = 'MARCH';
            }
            when 4{
                monthName = 'APRIL';
            }
            when 5{
                monthName = 'MAY';
            }
            when 6{
                monthName = 'JUNE';
            }
            when 7{
                monthName = 'JULY';
            }
            when 8{
                monthName = 'AUG';
            }
            when 9{
                monthName = 'SEPT';
            }
            when 10{
                monthName = 'OCT';
            }
            when 11{
                monthName = 'NOV';
            }
            when 12{
                monthName = 'DEC';
            }
        }
        return monthName;
    }*/
    
    
}