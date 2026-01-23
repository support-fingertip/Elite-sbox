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

        // Create Visit and related Competition
        Visit__c visit = new Visit__c(Account1__c =accList[0].Id);
        insert visit;

        Competition__c comp = new Competition__c(Visit__c = visit.Id);
        insert comp;
        
        
         // Create SKU
        Product__c prod = new Product__c(Name='Test Product',SKU_Code__c ='testsksk');
        insert prod;

        // Create Display Format
        Display_Format__c displayFormat = new Display_Format__c(
            SKU__c = prod.Id,
            Display__c = 'Test Display'
        );
        insert displayFormat;

        // Create Account
        Account acc = new Account( Name = 'Primary Cust1',
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
                                  Secondary_Customer_Type__c = 'Retailer');
        insert acc;

     
        
        // Create Shelf Stock
        Shelf_Stock__c shelfStock = new Shelf_Stock__c(
            Visit__c = visit.Id,
            SKU__c = prod.Id,
            Stock_Level__c = 20,
            Sales_Quantity__c = 5,
            Comments_Compition_Remarks__c = 'Well positioned'
        );
        insert shelfStock;
        
        // Invoice for 'outstanding' and 'sales'
        invoice__c inv = new invoice__c(Store__c = accList[0].Id, Invoice_Date__c = Date.today(),Customer_Name__c='test',Invoice_No__c='12345432');
        insert inv;

        Sale__c sale = new Sale__c(Account__c = accList[0].Id, Invoice__c = inv.Id);
        insert sale;

        // Order for 'order'
        Order__c ord = new Order__c(Account__c = accList[0].Id, Order_Date__c = Date.today());
        insert ord;
        
        {
        // Create a dummy Area__c
        
        area__c testArea = new area__c();
        testArea.Name = 'test11121';
        testArea.Sales_Channel__c = 'CPD';
        testArea.Region__c =	'Kerala';
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
        
               // Create Order
      
            
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

     /*   Order__c order = new Order__c(
            Account__c = acc.Id,
            Order_Type__c = 'Primary Order',
            Order_Fulfillment_Status__c = 'Not Fulfilled',
            Order_Date__c = Date.today(),
            ownerId=testUser1.id,
            Clock_In_Location__latitude__s=21.212,
            Clock_In_Location__longitude__s=11.121
        );
        insert order;
            
system.debug(testUser1.id+'<<order'+[select id,createdbyId from Order__c where id=:order.id].createdbyId);
        // Create Order Items
        List<Order_Item__c> items = new List<Order_Item__c>();
        for (Integer i = 0; i < 2; i++) {
            items.add(new Order_Item__c(
                Order__c = order.Id,
                Product__c = prod.Id,
                Quantity__c = 10,
                Delivered_Quantity__c = 0,
                Unit_Price__c = 100,
                Total_Amount__c = 1000,
                Tax_Amount__c = 100,
                Status__c = 'Not Fulfilled'
            ));
        }
        insert items;*/

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
            User__c = testUser1.Id,
            Cloning_is_Completed__c = false
        );
        insert emp;
        
        
                
      
     
    }
    }

     @isTest 
    public static void testGetProductData() {
      user tuser=[select id from user where Employee_Code__c  = '123212231']; 
	 Child_beat__c cb = new Child_beat__c();
            cb.Active__c = true;
            //cb.Primary_Customer__c = acc.Id;
            //cb.Sub_Stockist__c = acc.id;
              cb.Beat_type__c ='Secondary';
            insert cb;
            
            Calendar_beat__c pj = new Calendar_beat__c();
            insert pj;
            
            
            PJP_Item__c pl = new PJP_Item__c();
            pl.beat__c = cb.Id;
            pl.PJP__c = pj.id;
            insert pl;
            
            // Create Daily Log
            Daily_Log__c dailyLog = new Daily_Log__c(
                User__c = tuser.Id,
                Sales_App_id__c = 'TestApp123',
                Day_started_time__c = system.Now(),
                Clock_In_Location__Latitude__s=21.121,
                Clock_In_Location__Longitude__s=21.1212,
                Clock_Out_Location__Longitude__s=23.323,
                Clock_Out_Location__Latitude__s=23.323,
                OwnerId = tuser.Id,
                Day_ended_time__c=system.now(),
                PJP_Item__c = pl.Id);
            insert dailyLog;
            
             system.debug('daily>>'+ [
                SELECT Id, Name,
                       Clock_In_Location__Latitude__s, Clock_In_Location__Longitude__s, 
                       Day_ended_time__c, Day_started_time__c,
                       Clock_Out_Location__Latitude__s, Clock_Out_Location__Longitude__s,
                       Total_Working_Hours__c, Distance_Travelled_Map__c, Distance_Travelled__c,
                       Total_Productive_Calls__c, Total_Non_Productive_Calls__c, New_Calls__c,
                       Non_PJP_Productive_Calls__c, Total_Calls__c, Total_Normal_Call__c
                FROM Daily_Log__c
                WHERE OwnerId = :tUser.Id
                AND Day_Started_Date__c = :system.today()
                LIMIT 1
            ]);
            
            // Create Visit__c records (mock for the visit data)
            Visit__c visit = new Visit__c(
                OwnerId = tuser.Id,
                Status__c = 'Completed',
                Approval_Status__c = 'Approved',
                Visit_for__c = 'Primary Customer',
                Planned_Start_Time__c = system.now(),
                Actual_Start_Time__c=system.now(),
                Child_beat__c = cb.Id,
                PJP_Item__c = pl.Id,
                ClockIn_Latitude__c=11.2212,
                Clockin_Longitude__c=21.12
            );
            insert visit;
            employee__c emp2=[select id from employee__c limit 1];
            VisitMapController.getVisits(tUser.Id,date.valueof(system.today()),emp2.id);
        
        
    }
    
}