@isTest
public class VisitMapController_Test {

    @testSetup
    static void setupTestData() {
        // Create Accounts
        List<Account> accList = new List<Account>{
            new Account(
                Name = 'Primary Cust',
                City__c = 'Delhi',
                State__c = 'Delhi',
                District__c = 'New Delhi',
                Primary_Phone_Number__c = '9999999999',
                Aadhaar_No__c = '123412341234',
                Pincode__c = '110001',
                Customer_Type__c = 'Primary Customer',
                Customer_Status__c = 'Active',
                GeoLocation__Latitude__s =  28.6139,
                GeoLocation__Longitude__s = 77.2090,
                Secondary_Customer_Category__c = 'TN_Elite Club',
                Secondary_Customer_Type__c = 'Retailer',
                Approval_Status__c = 'Credit Dept. Approved',
                Email_ID__c = 'test@gmail.com',
                SAP_Customer_Code__c ='19810121'
            ),
            new Account(
                Name = 'Secondary Cust',
                City__c = 'Mumbai',
                State__c = 'Andhra Pradesh',
                District__c = 'East Godavari',
                Primary_Phone_Number__c = '8888888888',
                Aadhaar_No__c = '567856785678',
                Pincode__c = '575444',
                Customer_Type__c = 'Secondary Customer',
                Customer_Status__c = 'Active',
                Email_ID__c = 'test@gmail.com',
                SAP_Customer_Code__c ='198101'
            )
        };
        insert accList;

        Visit__c visit = new Visit__c(Account1__c = accList[0].Id);
        insert visit;

        Competition__c comp = new Competition__c(Visit__c = visit.Id);
        insert comp;

        Product__c prod = new Product__c(Name='Test Product', SKU_Code__c ='testsksk');
        insert prod;

        Display_Format__c displayFormat = new Display_Format__c(
            SKU__c = prod.Id,
            Display__c = 'Test Display'
        );
        insert displayFormat;

        Account acc = new Account(
            Name = 'Primary Cust1',
            City__c = 'Delhi',
            State__c = 'Delhi',
            District__c = 'New Delhi',
            Primary_Phone_Number__c = '9999999998',
            Aadhaar_No__c = '123412341236',
            Pincode__c = '110003',
            Customer_Type__c = 'Primary Customer',
            Customer_Status__c = 'Active',
            SAP_Customer_Code__c ='12211198101',
            Secondary_Customer_Category__c = 'TN_Elite Club',
            Email_ID__c  ='test@gmail.com',
            Secondary_Customer_Type__c = 'Retailer'
        );
        insert acc;

        Shelf_Stock__c shelfStock = new Shelf_Stock__c(
            Visit__c = visit.Id,
            SKU__c = prod.Id,
            Stock_Level__c = 20,
            Sales_Quantity__c = 5,
            Comments_Compition_Remarks__c = 'Well positioned'
        );
        insert shelfStock;

        invoice__c inv = new invoice__c(
            Store__c = accList[0].Id,
            Invoice_Date__c = Date.today(),
            Customer_Name__c = 'test',
            Invoice_No__c = '12345432'
        );
        insert inv;

        Sale__c sale = new Sale__c(Account__c = accList[0].Id, Invoice__c = inv.Id);
        insert sale;

        Order__c ord = new Order__c(Account__c = accList[0].Id, Order_Date__c = Date.today());
        insert ord;

        area__c testArea = new area__c();
        testArea.Name = 'test11121';
        testArea.Sales_Channel__c = 'CPD';
        testArea.Region__c = 'Kerala';
        testArea.Area__c  = 'Central';
        insert testArea;

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

        User hr = new User(
            Alias = 'tuser',
            Employee_Code__c  = 'TestSSISOOSO',
            Email = 'testuser@esksksksxample.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'TestSSISOOSO',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'HR' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testuseskskskksr@example.com' + System.currentTimeMillis(),
            Sales_Channel__c = 'Cake'
        );
        insert hr;

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

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        UserRole ur = [SELECT Id FROM UserRole LIMIT 1];

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
            User__c = testUser1.Id,
            Cloning_is_Completed__c = false
        );
        insert emp;
    }

    // -----------------------------------------------
    // Shared helper: build full Daily Log + Visit + Order + Account + VisitForm
    // for a given user on today
    // -----------------------------------------------
    static Daily_Log__c buildDailyLog(Id ownerId) {
        Child_beat__c cb = new Child_beat__c(Active__c = true, Beat_type__c = 'Secondary');
        insert cb;

        Calendar_beat__c pj = new Calendar_beat__c();
        insert pj;

        PJP_Item__c pl = new PJP_Item__c(beat__c = cb.Id, PJP__c = pj.Id);
        insert pl;

        Daily_Log__c dailyLog = new Daily_Log__c(
            User__c = ownerId,
            Sales_App_id__c = 'TestApp123',
            Day_started_time__c = System.now(),
            Clock_In_Location__Latitude__s  = 21.121,
            Clock_In_Location__Longitude__s = 21.1212,
            Clock_Out_Location__Longitude__s = 23.323,
            Clock_Out_Location__Latitude__s  = 23.323,
            OwnerId = ownerId,
            Day_ended_time__c = System.now(),
            PJP_Item__c = pl.Id
        );
        insert dailyLog;
        return dailyLog;
    }

    static Visit__c buildVisit(Id ownerId) {
        Visit__c visit = new Visit__c(
            OwnerId = ownerId,
            Status__c = 'Completed',
            Approval_Status__c = 'Approved',
            Visit_for__c = 'Primary Customer',
            Planned_Start_Time__c = System.now(),
            Actual_Start_Time__c  = System.now(),
            Actual_End_Time__c    = System.now().addHours(1),
            ClockIn_Latitude__c   = 11.2212,
            Clockin_Longitude__c  = 21.12
        );
        insert visit;
        return visit;
    }

    static Order__c buildOrder(Id ownerId, Id accId) {
        Order__c ord = new Order__c(
            Account__c   = accId,
            Order_Date__c = Date.today(),
            OwnerId = ownerId,
            Clock_In_Location__latitude__s  = 28.61,
            Clock_In_Location__longitude__s = 77.20,
            Visit__c = null
        );
        insert ord;
        return ord;
    }

    static Visit_Form__c buildVisitForm(Id ownerId) {
        Visit_Form__c vf = new Visit_Form__c(
            OwnerId = ownerId,
            Geo_Location__Latitude__s  = 28.61,
            Geo_Location__Longitude__s = 77.20,
            Visit__c = null
        );
        insert vf;
        return vf;
    }

    // -----------------------------------------------
    // TEST 1: Original — recId provided, Daily Log exists (covers employee branch)
    // -----------------------------------------------
    @isTest
    static void testGetVisits_WithRecId_DailyLogExists() {
        User tuser = [SELECT Id FROM User WHERE Employee_Code__c = '123212231'];
        Employee__c emp = [SELECT Id FROM Employee__c LIMIT 1];

        System.runAs(tuser) {
            buildDailyLog(tuser.Id);
            buildVisit(tuser.Id);
        }

        Test.startTest();
        VisitMapController.getVisits(tuser.Id, Date.today(), emp.Id);
        Test.stopTest();
    }

    // -----------------------------------------------
    // TEST 2: recId = null, userId provided — covers the User query branch
    // -----------------------------------------------
    @isTest
    static void testGetVisits_NoRecId_UserIdProvided() {
        User tuser = [SELECT Id FROM User WHERE Employee_Code__c = '123212231'];

        System.runAs(tuser) {
            buildDailyLog(tuser.Id);
            buildVisit(tuser.Id);
        }

        Test.startTest();
        VisitMapController.getVisits(tuser.Id, Date.today(), null);
        Test.stopTest();
    }

    // -----------------------------------------------
    // TEST 3: userId = null — covers the UserInfo.getUserId() fallback
    // -----------------------------------------------
    @isTest
    static void testGetVisits_NullUserId_FallsBackToCurrentUser() {
        User tuser = [SELECT Id FROM User WHERE Employee_Code__c = '123212231'];

        System.runAs(tuser) {
            buildDailyLog(tuser.Id);
        }

        Test.startTest();
        VisitMapController.getVisits(null, Date.today(), null);
        Test.stopTest();
    }

    // -----------------------------------------------
    // TEST 4: selectedDate = null — covers the addDays(-10) fallback
    // -----------------------------------------------
    @isTest
    static void testGetVisits_NullDate_FallsBackToDefaultDate() {
        User tuser = [SELECT Id FROM User WHERE Employee_Code__c = '123212231'];

        Test.startTest();
        VisitMapController.getVisits(tuser.Id, null, null);
        Test.stopTest();
    }

    // -----------------------------------------------
    // TEST 5: No Daily Log exists — covers the catch block + null dl guards
    //         (Starting Point & Ending Point blocks are skipped)
    // -----------------------------------------------
    @isTest
    static void testGetVisits_NoDailyLog_NoCrash() {
        User tuser = [SELECT Id FROM User WHERE Employee_Code__c = '123212231'];

        Test.startTest();
        VisitMapController.getVisits(tuser.Id, Date.today(), null);
        Test.stopTest();
    }

    // -----------------------------------------------
    // TEST 6: Visit Forms present (Visit__c = null) — covers visitForms loop
    // -----------------------------------------------
    @isTest
    static void testGetVisits_WithVisitForms() {
        User tuser = [SELECT Id FROM User WHERE Employee_Code__c = '123212231'];

        System.runAs(tuser) {
            buildDailyLog(tuser.Id);
            buildVisitForm(tuser.Id);
        }

        Test.startTest();
        VisitMapController.getVisits(tuser.Id, Date.today(), null);
        Test.stopTest();
    }

   

    


    // -----------------------------------------------
    // TEST 10: Visit with null Actual_Start_Time__c — covers 'N/A' markerText branch
    // -----------------------------------------------
    @isTest
    static void testGetVisits_VisitWithNullStartTime() {
        User tuser = [SELECT Id FROM User WHERE Employee_Code__c = '123212231'];

        System.runAs(tuser) {
            buildDailyLog(tuser.Id);
            Visit__c visit = new Visit__c(
                OwnerId = tuser.Id,
                Status__c = 'Completed',
                Approval_Status__c = 'Approved',
                Visit_for__c = 'Primary Customer',
                Planned_Start_Time__c = System.now(),
                Actual_Start_Time__c  = null,    // null → triggers 'N/A' branch
                Actual_End_Time__c    = null,    // null → triggers 'In Progress' branch
                ClockIn_Latitude__c   = 11.22,
                Clockin_Longitude__c  = 21.12
            );
            insert visit;
        }

        Test.startTest();
        VisitMapController.getVisits(tuser.Id, Date.today(), null);
        Test.stopTest();
    }

    // -----------------------------------------------
    // TEST 11: VisitForm with null Customer_Name__c — covers 'Visit Form' fallback
    // -----------------------------------------------
    @isTest
    static void testGetVisits_VisitFormNullCustomerName() {
        User tuser = [SELECT Id FROM User WHERE Employee_Code__c = '123212231'];

        System.runAs(tuser) {
            buildDailyLog(tuser.Id);
            Visit_Form__c vf = new Visit_Form__c(
                OwnerId = tuser.Id,
                Geo_Location__Latitude__s  = 28.61,
                Geo_Location__Longitude__s = 77.20,
                Visit__c = null
            );
            insert vf;
        }

        Test.startTest();
        VisitMapController.getVisits(tuser.Id, Date.today(), null);
        Test.stopTest();
    }

    // -----------------------------------------------
    // TEST 12: VisitTimeComparator — all null branches directly
    // -----------------------------------------------
    @isTest
    static void testVisitTimeComparator_NullBranches() {
        VisitMapController.VisitTimeComparator comp = new VisitMapController.VisitTimeComparator();

        VisitMapController.VisitDTO a = new VisitMapController.VisitDTO();
        VisitMapController.VisitDTO b = new VisitMapController.VisitDTO();

        // Both null → 0
        a.visitTime = null;
        b.visitTime = null;
        comp.compare(a, b);

        // a null, b not null → 1
        b.visitTime = System.now();
        comp.compare(a, b);

        // a not null, b null → -1
        a.visitTime = System.now();
        b.visitTime = null;
        comp.compare(a, b);

        // a < b
        a.visitTime = System.now().addHours(-1);
        b.visitTime = System.now();
        comp.compare(a, b);

        // a > b
        a.visitTime = System.now();
        b.visitTime = System.now().addHours(-1);
        comp.compare(a, b);

        // a == b
        Datetime same = System.now();
        a.visitTime = same;
        b.visitTime = same;
        comp.compare(a, b);
    }

    // -----------------------------------------------
    // TEST 13: Original test preserved
    // -----------------------------------------------
    @isTest
    static void testGetProductData() {
        User tuser = [SELECT Id FROM User WHERE Employee_Code__c = '123212231'];

        Child_beat__c cb = new Child_beat__c(Active__c = true, Beat_type__c = 'Secondary');
        insert cb;

        Calendar_beat__c pj = new Calendar_beat__c();
        insert pj;

        PJP_Item__c pl = new PJP_Item__c(beat__c = cb.Id, PJP__c = pj.Id);
        insert pl;

        Daily_Log__c dailyLog = new Daily_Log__c(
            User__c = tuser.Id,
            Sales_App_id__c = 'TestApp123',
            Day_started_time__c = System.now(),
            Clock_In_Location__Latitude__s  = 21.121,
            Clock_In_Location__Longitude__s = 21.1212,
            Clock_Out_Location__Longitude__s = 23.323,
            Clock_Out_Location__Latitude__s  = 23.323,
            OwnerId = tuser.Id,
            Day_ended_time__c = System.now(),
            PJP_Item__c = pl.Id
        );
        insert dailyLog;

        Visit__c visit = new Visit__c(
            OwnerId = tuser.Id,
            Status__c = 'Completed',
            Approval_Status__c = 'Approved',
            Visit_for__c = 'Primary Customer',
            Planned_Start_Time__c = System.now(),
            Actual_Start_Time__c  = System.now(),
            ClockIn_Latitude__c   = 11.2212,
            Clockin_Longitude__c  = 21.12
        );
        insert visit;

        Employee__c emp2 = [SELECT Id FROM Employee__c LIMIT 1];

        Test.startTest();
        VisitMapController.getVisits(tuser.Id, Date.today(), emp2.Id);
        Test.stopTest();
    }
}