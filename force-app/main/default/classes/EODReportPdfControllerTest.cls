@isTest
public class EODReportPdfControllerTest {

    @testSetup
    static void setupData() {
        // Create test User
        Profile p = [SELECT Id FROM Profile WHERE Name = 'TSE' LIMIT 1];
        User u = new User(
            Alias = 'tuser',
            Email='durgaprasad@fingertipplus.com',
            EmailEncodingKey='UTF-8',
            LastName='Test',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ProfileId=p.Id,
            Employee_Code__c = '1191010',
            TimeZoneSidKey='America/Los_Angeles',
            Username='testuser' + System.currentTimeMillis() + '@test.com'
        );
        insert u;

        // Daily Log
        Daily_Log__c dlog = new Daily_Log__c(
            OwnerId = u.Id,
            Is_System_Ended__c = true,
            Total_Visits__c = 5,
            Total_Productive_Calls__c = 3,
            New_Calls__c = 2,
            Total_Order_Amount__c = 1000
        );
        insert dlog;

        
        
        // Account for Order
        Account acc =   new Account(
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
            
            
        );
        insert acc;

        // Product
        Product__c prod = new Product__c(Name = 'Test Prod');
        insert prod;

        // Order (Primary)
        Order__c ordPrimary = new Order__c(
            OwnerId = u.Id,
            Order_Type__c = 'Primary Order',
            Account__c = acc.Id,
            Order_Date__c = Date.today()
        );
        insert ordPrimary;

        // Order Item
        Order_Item__c oi1 = new Order_Item__c(
            Order__c = ordPrimary.Id,
            Product__c = prod.Id,
            Total_Amount__c = 500
        );
        insert oi1;

        // Secondary Order
        Order__c ordSecondary = new Order__c(
            OwnerId = u.Id,
            Order_Type__c = 'Secondary Order',
            Account__c = acc.Id,
            Order_Date__c = Date.today()
        );
        insert ordSecondary;

        Order_Item__c oi2 = new Order_Item__c(
            Order__c = ordSecondary.Id,
            Product__c = prod.Id,
            Total_Amount__c = 1000
        );
        insert oi2;

        // Collection Item
        Collection_Item__c coll = new Collection_Item__c(
            OwnerId = u.Id,
            Amount_Received__c = 300,
            Mode_of_Payment__c = 'Cash'
        );
        insert coll;

        // Order fulfilment
        ordPrimary.Orderfulfilment_Date__c = Date.today();
        update ordPrimary;

        Order_Item__c oi3 = new Order_Item__c(
            Order__c = ordPrimary.Id,
            Product__c = prod.Id
        );
        insert oi3;

        // PJP Item
        Calendar_beat__c pjp = new Calendar_beat__c(OwnerId = u.Id);
        insert pjp;
        
        Child_beat__c cb = new Child_beat__c();
        cb.Active__c = true;
        cb.Beat_type__c ='Secondary';
        //cb.Primary_Customer__c = acc.Id;
        //cb.Sub_Stockist__c = acc.id;
        insert cb;

        PJP_Item__c pjpItem = new PJP_Item__c(
            PJP__c = pjp.Id,
            Date__c = Date.today().addDays(1),
            Beat__c = cb.Id
        );
        insert pjpItem;
    }

    @isTest
    static void testControllerWithData() {
        User u = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];

        Test.startTest();
        ApexPages.currentPage().getParameters().put('id', u.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(new Daily_Log__c());
        EODReportPdfController ctrl = new EODReportPdfController(sc);
        Test.stopTest();

        // Assertions
     
    }

    @isTest
    static void testControllerWithoutData() {
        User u = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
		Daily_Log__c dl = [select id from Daily_Log__c limit 1];
        Test.startTest();
        ApexPages.currentPage().getParameters().put('id', u.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(new Daily_Log__c());
        EODReportPdfController ctrl = new EODReportPdfController(sc);
        System.enqueueJob(new EODReportQueueableMail(dl.Id));
        EODReportBatch ed = new EODReportBatch();
        database.executeBatch(ed,1);
        
        EODReportBatchScheduler scheduler = new EODReportBatchScheduler();
        String jobId = System.schedule('DailyLogNotificationBatchJob', '0 0 0 * * ?', scheduler);

        Test.stopTest();

    }
}