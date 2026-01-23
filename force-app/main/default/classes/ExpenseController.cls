public with sharing class ExpenseController {
    
    public class ExpenseData{
        @AuraEnabled public User LoggedInUser;
        @AuraEnabled public User selectedUser;
        @AuraEnabled public Expense__c expense;
        @AuraEnabled public List<Expenses_Line_Item__c> lineItems;
        @AuraEnabled public List<Daily_Log__c> days;
        @AuraEnabled public List<City__c> cities;
        @AuraEnabled public Travel_Eligibility__c eligibilities;
        @AuraEnabled public List<String> travelTypes;
        @AuraEnabled public List<String> travelModes;
        @AuraEnabled public List<String> expenseTypes;
        @AuraEnabled public List<String> foodTypes;
        @AuraEnabled public List<String> approvalStatus;
        @AuraEnabled public Date startDate;
        @AuraEnabled public Date endDate;
        @AuraEnabled public boolean isCurrentUserApprover;
        @AuraEnabled public Id approverId;
        @AuraEnabled public boolean isDistrictInCharge;
        @AuraEnabled public String expenseId;
        @AuraEnabled public String expenseCommnents;
        @AuraEnabled public boolean isExpenseAllowed;
    }
    
    @AuraEnabled(cacheable=false) 
    public static ExpenseData getExpenses(String recordId){
        
        string userId = UserInfo.getUserId();
        User userRec = [ SELECT Id, Name, Band__c, Profile.Name, District_In_Charge__c,Expense_Back_Day_Entry_Limit__c,
                        Title,isAdmin__c, Expense_Start_Date__c, Expense_End_Date__c FROM User WHERE Id = :userId
                       ];
        
        String Executive_Band = userRec.Band__c;
        String Executive_Profile = userRec.Profile.Name;
        String Executive_Desigination = userRec.Title;
        String ExectiveId = userRec.Id;
        Boolean isDistrictInCharge = userRec.District_In_charge__c;
        
        //======================================
        //Expense Start Date and End Date setting
        //========================================
        Date today = Date.today();
        // If null → default values (25 & 24)
        Integer startDay = (userRec.Expense_Start_Date__c == null) ? 25 : Integer.valueOf(userRec.Expense_Start_Date__c);
        Integer endDay = (userRec.Expense_End_Date__c == null) ? 24 : Integer.valueOf(userRec.Expense_End_Date__c);
        Date startDate; 
        Date endDate;
        Expense__c exp;
        // If Record Id  Present
        if(recordId != null)
        {
            List<Expense__c> expList = [
                SELECT Id, Name, Start_Date__c, End_Date__c, Employee__c, OwnerId, Comments__c,
                Approval_Status__c, Expense_Approver_L1__c,Executive_Name__c,Expense_Approver_L2__c,Executive_Designation__c,
                Expense_Finance_Department_Approver__c, Executive_Profile__c, Executive_Band__c,District_In_charge__c
                FROM Expense__c WHERE Id = :recordId LIMIT 1 ];
            if (!expList.isEmpty()) {
                exp = expList[0];
                ExectiveId = exp.OwnerId;
                startDate = exp.Start_Date__c;
                endDate = exp.End_Date__c;
            }
        }
        else if (startDay == 1 && endDay == 15) {
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
        

        ExpenseData data = new ExpenseData();
        data.startDate = startDate;
        data.endDate = endDate;
        data.travelModes = getPicklistValues('Expenses_Line_Item__c','Travel_Mode__c');
        data.expenseTypes = getPicklistValues('Expenses_Line_Item__c','Expense_Type__c');
        data.travelTypes = getPicklistValues('Expenses_Line_Item__c','Travel_Type__c');
        data.foodTypes = getPicklistValues('Expenses_Line_Item__c','Food_Type__c');
        data.approvalStatus = getPicklistValues('Expenses_Line_Item__c','Approval_Status__c');
        data.cities = [SELECT Id,Name,Type__c FROM City__c];
        data.LoggedInUser = userRec;
        

        
      
       
        
        // 2. If not found, check by OwnerId + Start/End date
        if (exp == null) {
            List<Expense__c> expList = [ 
                SELECT Id, Name, Start_Date__c, End_Date__c, Employee__c, OwnerId, Comments__c,
                Approval_Status__c, Expense_Approver_L1__c,Executive_Name__c,Expense_Approver_L2__c,Executive_Designation__c,
                Expense_Finance_Department_Approver__c, Executive_Profile__c, Executive_Band__c,District_In_charge__c
                FROM Expense__c
                WHERE OwnerId = :userId
                AND Start_Date__c = :startDate
                AND End_Date__c   = :endDate
                LIMIT 1
            ];
            if (!expList.isEmpty()) {
                exp = expList[0];
            }
        }
        
        // 3. If expense found → fetch line items
        if (exp != null) {
            Executive_Profile = exp.Executive_Profile__c;
            Executive_Desigination = exp.Executive_Designation__c;
            Executive_Band    = exp.Executive_Band__c;
            isDistrictInCharge = exp.District_In_charge__c;
            
            data.lineItems = [
                SELECT Id, Name, Travel_Mode__c, Travel_Type__c, Expense_Type__c, Day__c,
                Daily_Log__c, Amount__c, Expense__c, Expense_Date__c,City__c,City_Name__c,
                Remarks__c, Total_KM__c,Working_Hours__c,Calculated_KM__c,Food_Type__c,lodging_Limit__c,
                Local_Conveyance_Limit__c,localId__c,Approval_Status__c,System_Calculated_Amount__c,
                Lodging_Food_Expense_Limit__c,Is_Updated__c,To__c,From__c
                FROM Expenses_Line_Item__c 
                WHERE Expense__c = :exp.Id
                ORDER BY Expense_Date__c ASC
            ];
            
            data.expense = exp;
        }
        
        
        data.days = [SELECT Id,Name,Date__c,Travel_Type__c,Distance_Travelled__c,Working_Hours_For_Expense__c,Purpose_of_Visit__c
                     FROM Daily_Log__c WHERE OwnerId=:ExectiveId AND Day_ended_time__c != null AND
                     (Date__c >=:startDate AND Date__c <=:endDate)
                     order by Date__c asc]; 
        
        system.debug(data.days);
        
        //Travel Eligibliy
        Travel_Eligibility__c travelEligibility;

        List<Travel_Eligibility__c> desiginationElig = [SELECT Id,Name,Eligibility_For__c, Band__c, Profile__c,
                                                        Conveyance_Allowance_per_KM_Bike__c, Conveyance_Allowance_per_KM_Own_Car__c, 
                                                        Daily_Allowance_HQ__c, Dearness_Allowance__c,Daily_KM_Limit__c, Daily_KM_Limit_for_DIC__c,
                                                        Local_Conveyance__c,Mandatory_Remarks_File_Types__c,Mandatory_File_Expense_Types__c ,
                                                        Lodging_Expense_per_Day_Metro__c, Lodging_Expense_per_Day_Non_Metro__c,Daily_KM_Limit_UP__c, 
                                                        Lodging_Food_Expenses__c, Travel_Mode_HQ__c,
                                                        Travel_Mode_UC__c,Expense_Type_UC__c,Expense_Type_HQ__c, Daily_Allowance__c,
                                                        Locking_KM__c, Mobile_Expense__c, Rate_Per_KM__c
                                                        FROM Travel_Eligibility__c WHERE Designation__c = :Executive_Desigination];
        data.isExpenseAllowed = false;
        if (!desiginationElig.isEmpty()) {
            travelEligibility = desiginationElig[0];
            data.isExpenseAllowed = true;
        }
        else {
            List<Travel_Eligibility__c> bandEligibility = [SELECT Id,Name,Eligibility_For__c, Band__c, Profile__c,
                                                           Conveyance_Allowance_per_KM_Bike__c, Conveyance_Allowance_per_KM_Own_Car__c, 
                                                           Daily_Allowance_HQ__c, Dearness_Allowance__c,Daily_KM_Limit__c, Daily_KM_Limit_for_DIC__c,
                                                           Local_Conveyance__c,Mandatory_Remarks_File_Types__c,Mandatory_File_Expense_Types__c ,
                                                           Lodging_Expense_per_Day_Metro__c, Lodging_Expense_per_Day_Non_Metro__c,Daily_KM_Limit_UP__c, 
                                                           Lodging_Food_Expenses__c, Travel_Mode_HQ__c,
                                                           Travel_Mode_UC__c,Expense_Type_UC__c,Expense_Type_HQ__c, Daily_Allowance__c,
                                                           Locking_KM__c, Mobile_Expense__c, Rate_Per_KM__c
                                                           FROM Travel_Eligibility__c WHERE Band__c = :Executive_Band];

            if (!bandEligibility.isEmpty()) {
                data.isExpenseAllowed = true;
                travelEligibility = bandEligibility[0];
            }
        }
        
        
        
        data.eligibilities = travelEligibility;
        data.isDistrictInCharge = isDistrictInCharge;
        return data;
    }
    
    public static List<String> getPicklistValues(String objectName, String fieldName) {
        List<String> picklistValues = new List<String>();
        
        // Describe the object
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        
        // Describe the field
        Schema.DescribeFieldResult fieldDescribe = objDescribe.fields.getMap().get(fieldName).getDescribe();
        
        // Get picklist values
        for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
            picklistValues.add(entry.getLabel());
        }
        return picklistValues;
    }
    
    @AuraEnabled(cacheable=false)
    public static Map<String, Boolean> validateFiles(List<Map<String, String>> itemsToCheck) {
        Map<String, Boolean> results = new Map<String, Boolean>(); // key = uniqueKey, value = hasFile?
        
        if (itemsToCheck == null || itemsToCheck.isEmpty()) {
            return results;
        }
        
        // Collect Ids and localIds separately
        Set<Id> docIds = new Set<Id>();
        Set<String> localIds = new Set<String>();
        
        for (Map<String, String> item : itemsToCheck) {
            if (item.containsKey('Id') && String.isNotBlank(item.get('Id'))) {
                docIds.add(item.get('Id'));
            } else if (item.containsKey('localId__c') && String.isNotBlank(item.get('localId__c'))) {
                localIds.add(item.get('localId__c'));
            }
        }
        
        // Query by Id
        Set<Id> foundDocIds = new Set<Id>();
        if (!docIds.isEmpty()) {      
            for(ContentDocumentLink doc:  [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN:docIds]) {  
                foundDocIds.add(doc.LinkedEntityId);
            } 
        }
        
        // Query by localId__c (stored in Description)
        Set<String> foundLocalIds = new Set<String>();
        if (!localIds.isEmpty()) {
         
            for (ContentVersion ver : [
                SELECT Description FROM ContentVersion WHERE Description IN :localIds
            ]) {
                foundLocalIds.add(ver.Description);
            }
        }
        
        // Prepare results
        for (Map<String, String> item : itemsToCheck) {
            String uniqueKey = item.get('uniqueKey'); // you send this from LWC
            Boolean hasFile = false;
            
            if (item.containsKey('Id') && foundDocIds.contains(item.get('Id'))) {
                hasFile = true;
            }
            if (item.containsKey('localId__c') && foundLocalIds.contains(item.get('localId__c'))) {
                hasFile = true;
            }
            
            results.put(uniqueKey, hasFile);
        }
        
        return results;
    }
    
    @AuraEnabled
    public static ExpenseData saveExpense(Expense__c expense , list<Expenses_Line_Item__c> expenseItems,List<string> delitems, boolean submitforApproval,boolean approveRecord,boolean rejectRecord,String approvalComments)
    {
        list<Expenses_line_item__c> expenseItemsToUpsert = new list<Expenses_line_item__c>();
        Set<Id> expenseIdsToDelete = new Set<Id>();
        if(delitems.size()>0){
            
            if (delitems != null && !delitems.isEmpty()) {
                for (String idStr : delitems) {
                    if (String.isNotBlank(idStr)) {
                        expenseIdsToDelete.add((Id) idStr);
                    }
                }
            }
            list<Expenses_line_item__c> DelExpLineItem = [select Id,Name from Expenses_line_item__c where id =: delitems];
            delete DelExpLineItem;
        }
        if(expense !=null ){
            if(expense.Id == null){
                User usr = [
                    SELECT Name 
                    FROM User 
                    WHERE Id = :UserInfo.getUserId() 
                    LIMIT 1
                ];
                
                Date startDate = expense.Start_Date__c;
                Date endDate   = expense.End_Date__c;
                
                // Extract day, month, year parts
                String startDay   = String.valueOf(startDate.day());
                String startMonth = getMonthName(startDate.month());
                String startYear  = String.valueOf(startDate.year());
                
                String endDay     = String.valueOf(endDate.day());
                String endMonth   = getMonthName(endDate.month());
                String endYear    = String.valueOf(endDate.year());
                
                // Build label depending on year change
                String datePart = startDay + ' ' + startMonth + ' ' + startYear + ' To ' + endDay + ' ' + endMonth + ' ' + endYear;

                // Final Name
                expense.Name = datePart + ' / ' + usr.Name;
            }
      
            upsert expense;
            Set<Date> updatedDates = new Set<Date>();
            for(Expenses_line_item__c itm: expenseItems){ 
                if (itm.Is_Updated__c == true && itm.Expense_Date__c != null) {
                    updatedDates.add(itm.Expense_Date__c);
                }
                if(String.isEmpty(itm.Id)){
                    Expenses_line_item__c exp = new Expenses_line_item__c();
                    exp.localId__c = itm.localId__c;
                    exp.Expense_Date__c = itm.Expense_Date__c;
                    exp.Expense_Type__c = itm.Expense_Type__c;
                    exp.To__c = itm.To__c;
                    exp.From__c = itm.From__c;
                    exp.Travel_Type__c = itm.Travel_Type__c;
                    exp.Travel_Mode__c = itm.Travel_Mode__c;
                    exp.City__c = itm.City__c;
                    exp.Daily_Log__c = itm.Daily_Log__c;
                    exp.City_Name__c = itm.City_Name__c;
                    exp.Working_Hours__c = itm.Working_Hours__c;
                    exp.Total_KM__c = itm.Total_KM__c;
                    exp.Amount__c = itm.Amount__c;
                    exp.Remarks__c=itm.Remarks__c;
                    exp.Calculated_KM__c = itm.Calculated_KM__c;
                    exp.Food_Type__c = itm.Food_Type__c;
                    exp.lodging_Limit__c = itm.lodging_Limit__c;
                    exp.Local_Conveyance_Limit__c = itm.Local_Conveyance_Limit__c;
                    exp.System_Calculated_Amount__c = itm.System_Calculated_Amount__c;
                    // Temporary status to trigger history tracking
                    if (submitforApproval && itm.Approval_Status__c == 'Pending') {
                        exp.Approval_Status__c = 'Draft'; // or some dummy initial value
                    } else {
                        exp.Approval_Status__c = itm.Approval_Status__c;
                    }
                    exp.Expense__c = expense.Id;
                    expenseItemsToUpsert.add(exp);
                   
                }
                else{
                    if(!expenseIdsToDelete.contains(itm.Id))
                    {
                        Expenses_line_item__c exp = new Expenses_line_item__c();
                        exp.Id = itm.Id;
                        exp.localId__c = itm.localId__c;
                        exp.To__c = itm.To__c;
                        exp.From__c = itm.From__c;
                        exp.Expense_Date__c = itm.Expense_Date__c;
                        exp.Expense_Type__c = itm.Expense_Type__c;
                        exp.Travel_Type__c = itm.Travel_Type__c;
                        exp.Travel_Mode__c = itm.Travel_Mode__c;
                        exp.City__c = itm.City__c;
                        exp.Daily_Log__c = itm.Daily_Log__c;
                        exp.City_Name__c = itm.City_Name__c;
                        exp.Working_Hours__c = itm.Working_Hours__c;
                        exp.Total_KM__c = itm.Total_KM__c;
                        exp.Amount__c = itm.Amount__c;
                        exp.Remarks__c=itm.Remarks__c;
                        exp.Calculated_KM__c = itm.Calculated_KM__c;
                        exp.Food_Type__c = itm.Food_Type__c;
                        exp.lodging_Limit__c = itm.lodging_Limit__c;
                        exp.Local_Conveyance_Limit__c = itm.Local_Conveyance_Limit__c;
                        exp.System_Calculated_Amount__c = itm.System_Calculated_Amount__c;
                        if (itm.Is_Updated__c == true) exp.Approval_Status__c = itm.Approval_Status__c;
                        expenseItemsToUpsert.add(exp);
                     }
                }
            }
            upsert expenseItemsToUpsert;
           
            ExpenseData data = new ExpenseData();
            //When Submitted
            if(expense.Id != null)
            {
                string currentUserId = UserInfo.getUserId();
                user currentUser = [select Id,Name from User where Id =:currentUserId ];
                list<Expense__c> expenseRecord = [select Id,Name,Expense_Approver_L1__c,Expense_Approver_L2__c,Expense_Executive_Name__c,
                                                  OwnerId,Comments__c,
                                                  Expense_Finance_Department_Approver__c from Expense__c where Id =:expense.Id ];
                
                
                // After upsert of expense and items
                if (!String.isBlank(approvalComments)) {
                    // Fetch existing comment history
                    String existingComments = expenseRecord[0].Comments__c != null
                        ? expenseRecord[0].Comments__c + '\n\n'
                        : '';
                    system.debug('existingComments'+existingComments);
                    
                    String currentUserName = currentUser.Name;
                    String currentDate = Datetime.now().format('dd-MMM-yyyy hh:mm a');
                    
                    // Clean up comment text (remove brackets and trim spaces)
                    String cleanComment = approvalComments.replaceAll('\\[|\\]', '').trim();
                    system.debug('cleanComment'+cleanComment);
                    
                    // Create new formatted comment block
                    String newFormattedComment = '[' + currentDate + ' | ' + currentUserName + ']\n' + cleanComment;
                    
                    system.debug('newFormattedComment'+newFormattedComment);
                    
                    // Append to history
                    expenseRecord[0].Comments__c = existingComments + newFormattedComment;
                    
                    update expenseRecord[0];
                    
                }

                data.expenseCommnents = expenseRecord[0].Comments__c;

                if (!updatedDates.isEmpty() && !expenseRecord.isEmpty() ) {
                    expense__c expRec =  expenseRecord[0];
                    // Find min and max date
                    Date minDate = null;
                    Date maxDate = null;
                    for (Date d : updatedDates) {
                        if (minDate == null || d < minDate) minDate = d;
                        if (maxDate == null || d > maxDate) maxDate = d;
                    }
                    String dateRange = 'Date Range : ' +
                        minDate.format() + ' to ' + maxDate.format();
                    CustomNotificationType notificationType = [
                        SELECT Id 
                        FROM CustomNotificationType 
                        WHERE DeveloperName = 'Expense_Approval_Notification' 
                        LIMIT 1
                    ];
                    if(submitforApproval == true)
                    {
                        List<Expenses_line_item__c> toUpdate = new List<Expenses_line_item__c>();
                        for (Expenses_line_item__c e : expenseItemsToUpsert) {
                            if (e.Approval_Status__c == 'Draft') {
                                e.Approval_Status__c = 'Pending';
                                toUpdate.add(e);
                            }
                        }
                        if (!toUpdate.isEmpty()) {
                            update toUpdate; // This will trigger Field History Tracking
                        }
                        // ---- Notification for Current User ----
                        CustomNotificationService.notificationSend(
                            'Expenses has been Submitted for Approval', 
                            expRec.Id, 
                            'Executive Name : ' + expRec.Expense_Executive_Name__c+'\n'+dateRange, 
                            new Set<String>{expRec.OwnerId }, 
                            notificationType.Id
                        );

                        
                        // ---- Notification for Approver ----
                        Id approverId;
                        if (expRec.Expense_Approver_L1__c != null)
                        {
                            approverId = expRec.Expense_Approver_L1__c;
                        } 
                        else if (expRec.Expense_Approver_L2__c != null)
                        {
                            approverId = expRec.Expense_Approver_L2__c;
                        } else if (expRec.Expense_Finance_Department_Approver__c != null) {
                            approverId = expRec.Expense_Finance_Department_Approver__c;
                        }
                        
                        if (approverId != null) {
                            CustomNotificationService.notificationSend(
                                currentUser.Name+' is requesting approval for expense', 
                                expRec.Id, 
                                'Executive Name : ' + expRec.Expense_Executive_Name__c+'\n'+dateRange, 
                                new Set<String>{approverId }, 
                                notificationType.Id
                            );
                        }
                    }
                    //when approved or rejected
                    if ((approveRecord == true || rejectRecord == true)) {
                        
                        data.lineItems = [
                            SELECT Id, Name, Travel_Mode__c, Travel_Type__c, Expense_Type__c, Day__c,
                            Daily_Log__c, Amount__c, Expense__c, Expense_Date__c,City__c,City_Name__c,
                            Remarks__c, Total_KM__c,Working_Hours__c,Calculated_KM__c,Food_Type__c,lodging_Limit__c,
                            Local_Conveyance_Limit__c,localId__c,Approval_Status__c,System_Calculated_Amount__c,
                            Lodging_Food_Expense_Limit__c
                            FROM Expenses_Line_Item__c 
                            WHERE Expense__c = :expense.Id
                            ORDER BY Expense_Date__c ASC
                        ];
                        if(approveRecord == true)
                        {
                            // ---- Notification for Owner----
                            CustomNotificationService.notificationSend(
                                'Expenses has been Approved by '+ currentUser.Name, 
                                expRec.Id, 
                                'Executive Name : ' + expRec.Expense_Executive_Name__c+'\n'+dateRange,
                                new Set<String>{ expRec.OwnerId }, 
                                notificationType.Id
                            );
                            
                            // ---- Notification for Approver ----
                            if (currentUserId != null) {
                                CustomNotificationService.notificationSend(
                                    'Approval request for expense is approved', 
                                    expRec.Id, 
                                     'Executive Name : ' + expRec.Expense_Executive_Name__c+'\n'+dateRange,
                                    new Set<String>{currentUserId }, 
                                    notificationType.Id
                                );
                            }
                            
                            // ----Notification for Next Approver----
                            Id nextApprovedId;
                            if (expRec.Expense_Approver_L1__c == currentUserId)
                            {
                                if(expRec.Expense_Approver_L2__c != null )
                                {
                                    nextApprovedId = expRec.Expense_Approver_L2__c;
                                }
                                else 
                                {
                                     nextApprovedId = expRec.Expense_Finance_Department_Approver__c;
                                }
                            } 
                            else if (expRec.Expense_Approver_L2__c == currentUserId)
                            {
                                if(expRec.Expense_Finance_Department_Approver__c != null )
                                {
                                    nextApprovedId = expRec.Expense_Approver_L2__c;
                                }
                            } 
                            
                            if (nextApprovedId != null) {
                                CustomNotificationService.notificationSend(
                                    currentUser.Name+' is requesting approval for expense', 
                                    expRec.Id, 
                                    'Executive Name : ' + expRec.Expense_Executive_Name__c+'\n'+dateRange, 
                                    new Set<String>{nextApprovedId }, 
                                    notificationType.Id
                                );
                            }
                        }
                        
                        if(rejectRecord == true)
                        {
                            // ---- Notification for Owner----
                            CustomNotificationService.notificationSend(
                                'Expenses has been Rejected by '+ currentUser.Name, 
                                expRec.Id, 
                                'Executive Name : ' + expRec.Expense_Executive_Name__c+'\n'+dateRange,
                                new Set<String>{ expRec.OwnerId }, 
                                notificationType.Id
                            );
                            
                            // ---- Notification for Approver ----
                            CustomNotificationService.notificationSend(
                                'Approval request for expense is rejected', 
                                expRec.Id, 
                                'Executive Name : ' + expRec.Expense_Executive_Name__c+'\n'+dateRange,
                                new Set<String>{currentUserId }, 
                                notificationType.Id
                            );
                            
                        }  
                    } 
                }    
            }
       
            data.expenseId = expense.Id;
            
            return data;
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
    }  
    
}