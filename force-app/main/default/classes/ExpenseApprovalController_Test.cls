@isTest
public class ExpenseApprovalController_Test {

    // Utility method: Create User with selected profile
 
    @testSetup
    static void setup() {
         User testUser1 = new User(
            Alias = 'tuser',
            Employee_Code__c  = '123212231',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'TSE' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testuser@ekskslsslxample.com' + System.currentTimeMillis(),
           Sales_Channel__c = 'Cake'
        );
        
    
     User testUser2 = new User(
             Alias = 'tuser12',
            Employee_Code__c  = '1232122343',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            Primary_Customer_Approver_2__c = testUser1.Id,
            Employee_Approver_3_HR__c = testUser1.Id,
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'TSE' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testuser@example.com' + System.currentTimeMillis(),
           Sales_Channel__c = 'Cake'
        );
        insert new List<User>{ testUser1, testUser2 };

            
            
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
            Is_Active__c = false,
            // Required fields
            Basic_Pay__c = 25000,
            Aadhar_Number__c = '123456789012',
            Gross_Salary__c = 35000,
            DA__c = 5000,
            TA_limit__c = 2000,
            Area__c = 'Central',
            Region__c = 'West',
            ASM_TSM__c = testUser1.Id,
            RSM__c = testUser1.Id,
            Employee_Approver_3_HR__c = testUser1.Id,
            
            Secondary_Customer_Approver_1__c = testUser1.Id,
            Secondary_Customer_Approver_2__c = testUser1.Id,
            
            Primary_Customer_Approver_1__c = testUser1.Id,
            Primary_Customer_Approver_2__c = testUser1.Id,
            Primary_Customer_Approver_3_CD__c = testUser1.Id,
            
            PJP_Approver_1__c = testUser1.Id,
            PJP_Approver_2__c = testUser1.Id,
            
            Expense_Approver_1__c = testUser1.Id,
            Expense_Approver_2_Finance_Department__c = testUser1.Id,
            Sales_Channel__c = 'Cake',
            State__c = 'Uttar Pradesh',
            District__c = 'Lucknow',
            Pincode__c = '226001',
            User__c = testUser2.Id,
            Cloning_is_Completed__c = false
        );
        insert emp;
   
            
        
        // Create Expense record
        Expense__c exp = new Expense__c(
            Name = 'Test Expense',
            OwnerId = testUser1.Id,
            Expense_Approver_L1__c = testUser1.Id,
            Expense_Finance_Department_Approver__c = testUser2.id
        );
        insert exp;
      
        day__c da= new day__c();
        da.Date__c=system.today();
        da.Expense__c=exp.id;
        insert da;

        // Create expense line items
        List<Expenses_Line_Item__c> items = new List<Expenses_Line_Item__c>();
        for (Integer i = 0; i < 3; i++) {
            items.add(new Expenses_Line_Item__c(
                Expense__c = exp.Id,
                Expense_Type__c = 'Local Conveyance',
                Approval_Status__c = 'Pending',
                Expense_Date__c = Date.today().addDays(-i),
                Day__c=da.id
            ));
        }
        insert items;

        // Create ContentDocument + ContentDocumentLink
        ContentVersion cv = new ContentVersion(
            Title = 'Receipt1',
            PathOnClient = 'receipt.jpg',
            VersionData = Blob.valueOf('TestReceipt')
        );
        insert cv;

        Id contentDocumentId = [
            SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id
        ].ContentDocumentId;

        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = contentDocumentId,
            LinkedEntityId = items[0].Id,
            ShareType = 'V'
        );
        insert cdl;

    }


    // -------------------- TEST getExpenseLineItems --------------------
    @isTest
    static void testGetExpenseLineItems_Owner() {
        User owner = [SELECT Id FROM User WHERE Email = 'testuser@example.com' LIMIT 1];
        System.runAs(owner) {
            Expense__c exp = [SELECT Id FROM Expense__c LIMIT 1];

            Test.startTest();
            List<ExpenseApprovalController.ExpenseWrapper> result =
                ExpenseApprovalController.getExpenseLineItems(exp.Id);
            Test.stopTest();

            System.assert(!result.isEmpty(), 'Line items should return for owner');
            System.assert(result[0].files.size() == 1, 'File should be attached');
        }
    }


    // -------------------- TEST getExpenseDetails --------------------
    @isTest
    static void testGetExpenseDetails() {
        User owner = [SELECT Id FROM User WHERE Email = 'testuser@example.com' LIMIT 1];
        Expense__c exp = [SELECT Id FROM Expense__c LIMIT 1];

        System.runAs(owner) {
            Test.startTest();
            ExpenseApprovalController.DataBox box =
                ExpenseApprovalController.getExpenseDetails(exp.Id);
            Test.stopTest();

            System.assertEquals(exp.Id, box.expense.Id);
            System.assertEquals(true, box.isOpenedByOwner);
        }
    }


    // -------------------- TEST updateExpenseLineItems --------------------
    @isTest
    static void testUpdateExpenseLineItems() {
        List<Expenses_Line_Item__c> items = [
            SELECT Id FROM Expenses_Line_Item__c LIMIT 1
        ];
        items[0].Remarks__c = 'Updated remarks';

        Test.startTest();
        ExpenseApprovalController.updateExpenseLineItems(items);
        Test.stopTest();

        Expenses_Line_Item__c updated = [
            SELECT Remarks__c FROM Expenses_Line_Item__c WHERE Id = :items[0].Id
        ];

        System.assertEquals('Updated remarks', updated.Remarks__c);
    }


    // -------------------- TEST approveExpenseItems --------------------
    @isTest
    static void testApproveExpenseItems_L1() {
        User approverL1 = [SELECT Id FROM User WHERE Email = 'testuser@example.com' LIMIT 1];
        Expense__c exp = [SELECT Id FROM Expense__c LIMIT 1];
        List<Expenses_Line_Item__c> items = [
            SELECT Id FROM Expenses_Line_Item__c
        ];

        System.runAs(approverL1) {
            Test.startTest();
            ExpenseApprovalController.approveExpenseItems(
                new List<Id>{ items[0].Id },
                exp.Id,
                'Approved by L1'
            );
            Test.stopTest();
        }

        Expenses_Line_Item__c updated = [
            SELECT Approval_Status__c FROM Expenses_Line_Item__c WHERE Id = :items[0].Id
        ];

        System.assertEquals('Level 1 Approved', updated.Approval_Status__c);
    }


    // -------------------- TEST rejectExpenses --------------------
    @isTest
    static void testRejectExpenses_Finance() {
        User finance = [SELECT Id FROM User WHERE Email = 'testuser@example.com' LIMIT 1];
        Expense__c exp = [SELECT Id FROM Expense__c LIMIT 1];
        List<Expenses_Line_Item__c> items = [
            SELECT Id FROM Expenses_Line_Item__c
        ];

        System.runAs(finance) {
            Test.startTest();
            ExpenseApprovalController.rejectExpenses(
                new List<Id>{ items[1].Id },
                exp.Id,
                'Rejected for testing'
            );
            Test.stopTest();
        }

        Expenses_Line_Item__c updated = [
            SELECT Approval_Status__c FROM Expenses_Line_Item__c WHERE Id = :items[1].Id
        ];

     //   System.assertEquals('Finance Dept. Rejected', updated.Approval_Status__c);
    }


   @isTest
    static void testAfterInsertHandler() {

        // Unique matching ID
        String uniqueLocalId = 'TEST-LOCAL-ID-123';

        // Step 1: Insert ContentVersion (auto creates ContentDocument)
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'testfile.pdf',
            VersionData = Blob.valueOf('Sample File Content'),
            Description = uniqueLocalId
        );
        insert cv;

        // Fetch ContentDocument
        ContentDocument cd = [
            SELECT Id, Description 
            FROM ContentDocument 
            WHERE Description = :uniqueLocalId
            LIMIT 1
        ];

        Expense__c expr = [SELECT Id FROM Expense__c LIMIT 1];

        // Create an Expense Line Item using same localId
        Expenses_Line_Item__c expItem = new Expenses_Line_Item__c(
            localId__c = uniqueLocalId,
            expense__c=expr.id
        );
//insert expItem;

        Test.startTest();
            insert expItem; // Trigger fires automatically
        Test.stopTest();

        // Step 3: Verify the Document Link was created
        ContentDocumentLink cdl = [
            SELECT Id, ContentDocumentId, LinkedEntityId, ShareType, Visibility
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :expItem.Id
            LIMIT 1
        ];

        System.assertEquals(cd.Id, cdl.ContentDocumentId);
        System.assertEquals('V', cdl.ShareType);
        System.assertEquals('AllUsers', cdl.Visibility);
    }
}