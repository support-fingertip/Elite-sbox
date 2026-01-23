@isTest
public class ExpenseController_Test {
 private static User createUser(String alias) {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];


           User testUser1 = new User(
            Alias = 'tuser',
            Employee_Code__c  = '1as212231'+alias,
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'TSE' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testuser@ekskslsslxample.com' + System.currentTimeMillis(),
               isactive =true,
           Sales_Channel__c = 'Cake'
        );
        
    
        insert testUser1;
        return testUser1;
    }
   @TestSetup
    static void setupData() {
        // *** Users ***
        User execUser = createUser('Exec1');
        User approver = createUser('Approver1');

        // *** City ***
        insert new City__c(Name='Pune', Type__c='Metro');


             Daily_Log__c dailyLog = new Daily_Log__c(
                User__c = execUser.Id,
                Sales_App_id__c = 'TestApp123',
                Day_started_time__c = system.Now(),
                OwnerId = UserInfo.getUserId()     
              );
            insert dailyLog;
            

        // *** Travel Eligibility ***
        insert new Travel_Eligibility__c(
            Band__c='F1',
            Eligibility_For__c='Band',
            Conveyance_Allowance_per_KM_Bike__c=5,
            Daily_Allowance__c=50
        );
    }

   @isTest
    static void testGetExpenses() {
        User u = [SELECT Id FROM User where isactive=true LIMIT 1];
        System.runAs(u) {

            // Create Expense
            Expense__c exp = new Expense__c(
                Start_Date__c = Date.today(),
                End_Date__c = Date.today(),
                OwnerId = u.Id
            );
            insert exp;
        day__c da= new day__c();
        da.Date__c=system.today();
        da.Expense__c=exp.id;
        insert da;
            // Create Line Items
            insert new Expenses_Line_Item__c(
                Expense__c = exp.Id,
                Expense_Type__c='Local Conveyance',
                Expense_Date__c = Date.today(),
                City_Name__c='Pune',
                Approval_Status__c='Draft',
                day__c=da.id
            );

               // Get existing Profile
        Profile p = [SELECT Id, Name FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        // Just query an existing UserRole to avoid Mixed DML issues
        UserRole ur = [SELECT Id FROM UserRole LIMIT 1];

        // Create mock Employee__c record
        Employee__c emp = new Employee__c(
            Name = 'John Doe',
            Mail_Id__c = 'john.doe@example.com',
            User_Name__c = 'john.doe@example.com.testuser',
            Primary_Phone_Number__c = '1234567890',
            Employee_Code__c = 'EMP123',
            Designation__c = 'Sales Exec',
            Profile__c = 'Admin',
            Role_Id__c = ur.Id,
            Is_Active__c = true,
            // Required fields
            Basic_Pay__c = 25000,
            Aadhar_Number__c = '123456789012',
            Gross_Salary__c = 35000,
            DA__c = 5000,
            TA_limit__c = 2000,
            Area__c = 'Central',
            Region__c = 'West',
            ASM_TSM__c = u.Id,
            RSM__c = u.Id,
            Employee_Approver_3_HR__c = u.Id,
            
            Secondary_Customer_Approver_1__c = u.Id,
            Secondary_Customer_Approver_2__c = u.Id,
            
            Primary_Customer_Approver_1__c = u.Id,
            Primary_Customer_Approver_2__c = u.Id,
            Primary_Customer_Approver_3_CD__c = u.Id,
            
            PJP_Approver_1__c = u.Id,
            PJP_Approver_2__c = u.Id,
            
            Expense_Approver_1__c = u.Id,
            Expense_Approver_2_Finance_Department__c = u.Id,
            Sales_Channel__c = 'Cake',
            State__c = 'Uttar Pradesh',
            District__c = 'Lucknow',
            Pincode__c = '226001',
            User__c = u.Id,
            Cloning_is_Completed__c = false
        );
        insert emp;
   
            
            ExpenseController.ExpenseData data =
                ExpenseController.getExpenses(exp.Id);

            System.assertNotEquals(null, data);
            System.assertNotEquals(null, data.lineItems);
            System.assertEquals(exp.Id, data.expense.Id);
        }
    }

  @isTest
    static void testValidateFiles() {
        User u = [SELECT Id FROM User where isactive=true LIMIT 1];
        ContentVersion cv = new ContentVersion(
            Title = 'Test Upload',
            PathOnClient = 'file.txt',
            VersionData = Blob.valueOf('Hello'),
            Description = 'ROW1'   // used as localId__c
        );
        insert cv;

        // Fetch ContentDocumentId
        cv = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
        ];

        // Link document to user (or your target record)
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = u.Id,
            ShareType = 'V'
        );
        insert cdl;

            
            List<Map<String, String>> req = new List<Map<String, String>>();
            
            Map<String, String> row1 = new Map<String, String>();
            row1.put('uniqueKey', 'ROW1');
            row1.put('Id', u.Id);
            
            req.add(row1);

            Map<String,Boolean> result = ExpenseController.validateFiles(req);

            System.assertEquals(true, result.get('ROW1'));
        }
    
 
    @isTest
    static void testSaveExpense_CreateSubmitApproveReject() {
        User u = [SELECT Id FROM User where isactive=true LIMIT 1];

            // Create *New* Expense
            Expense__c exp = new Expense__c(
                Start_Date__c = Date.today(),
                End_Date__c = Date.today()
            );
insert exp;
 /*       exp.OwnerId=u.id;
        update exp;*/
        
        day__c da= new day__c();
        da.Date__c=system.today();
        da.Expense__c=exp.id;
        insert da;
        
            List<Expenses_Line_Item__c> items = new List<Expenses_Line_Item__c>();
            items.add(new Expenses_Line_Item__c(
                localId__c='LOCAL-A',
                Expense_Type__c='Local Conveyance',
                Expense_Date__c=Date.today(),
                Approval_Status__c='Pending',
                Is_Updated__c=true,
                day__c=da.id
            ));

        Expense__c exp1 = new Expense__c(
                Start_Date__c = Date.today(),
                End_Date__c = Date.today()
            );
         List<Expenses_Line_Item__c> items1 = new List<Expenses_Line_Item__c>();
            items1.add(
        new Expenses_Line_Item__c(
                localId__c='LOCAL-A',
                Expense_Type__c='Local Conveyance',
                Expense_Date__c=Date.today(),
                Approval_Status__c='Pending',
                Is_Updated__c=true
            ));
            
            // ----------- CREATE + SUBMIT -------------------------------
            ExpenseController.ExpenseData created =
                ExpenseController.saveExpense(exp, items, new List<String>(), true, false, false, 'Submitting');

            System.assertNotEquals(null, created.expenseId);

            // ----------- APPROVE ---------------------------------------
            ExpenseController.ExpenseData approveData =
                ExpenseController.saveExpense(exp,
                    items, new List<String>(),
                    false, true, false,
                    'Approved OK'
                );

            System.assertNotEquals(null, approveData);

            // ----------- REJECT ----------------------------------------
            ExpenseController.ExpenseData rejectData =
                ExpenseController.saveExpense(exp,
                    items, new List<String>(),
                    false, false, true,
                    'Rejected test'
                );
        id d=[select id from Expenses_Line_Item__c limit 1].id;
       List<String> myList = new List<String>{ d};

         ExpenseController.saveExpense(exp1,
                    items1, myList,
                    false, false, true,
                    'Rejected test'
                );
ExpenseController.getMonthName(7);
        ExpenseController.getMonthName(1);
        ExpenseController.getMonthName(2);
        ExpenseController.getMonthName(3);
        ExpenseController.getMonthName(4);
        ExpenseController.getMonthName(5);
        ExpenseController.getMonthName(6);
           ExpenseController.getMonthName(8);
        ExpenseController.getMonthName(9);
        ExpenseController.getMonthName(10);
        ExpenseController.getMonthName(11);
        ExpenseController.getMonthName(12);
            System.assertNotEquals(null, rejectData);
          }

}