@isTest
public class PrimaryTargetsBatchTest {

    // Helper method to create a test User with a Standard profile
    private static User createUser(String alias,string empCode) {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'TSE' LIMIT 1];
        return new User(
            FirstName = 'Test',
            LastName  = alias,
            Email = alias + '@example.com',
            Username = alias + '@example.com.' + System.currentTimeMillis(),
            Alias = alias.substring(0, Math.min(8, alias.length())),
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            Employee_Code__c = empcode
        );
    }

    private static void setupData() {
        // Users
        User u1 = createUser('user1','12334');
        User u2 = createUser('user2','45611');
        insert new List<User>{ u1, u2 };

          Account cust = new Account(
            Name = 'Primary Customer',
            Customer_Type__c = 'Primary Customer',
            Pincode__c = '123456',
            Primary_Phone_Number__c = '9876543210',
            State__c = 'Karnataka',
            District__c = 'Kolar',
            SAP_Customer_Code__c = '2234'
        );
        insert cust;

        // Product
        Product__c prod = new Product__c(Name = 'Test SKU',
            List_Price__c = 100,Net_Weight__c =1);
        insert prod;

        // TargetActuals (SKU + User)
        TargetActuals__c taSku = new TargetActuals__c(
            User__c = u1.Id,
            SKU__c = prod.Id,
            Month__c = String.valueOf(Date.today().month()),
            Year__c = String.valueOf(Date.today().year()),
            Type__c = 'Primary',
            Target_Revenue__c = 1000,
            Target_Quantity_KG__c = 10
        );

        // Distributor Target
        TargetActuals__c taDist = new TargetActuals__c(
            User__c = u1.Id,
            Customer__c = cust.Id,
            Month__c = String.valueOf(Date.today().month()),
            Year__c = String.valueOf(Date.today().year()),
            Type__c = 'Primary',
            Target_Revenue__c = 500,
            Target_Quantity_KG__c = 5
        );

        // User-only Target
        TargetActuals__c taUser = new TargetActuals__c(
            User__c = u1.Id,
            Month__c = String.valueOf(Date.today().month()),
            Year__c = String.valueOf(Date.today().year()),
            Type__c = 'Primary',
            Target_Revenue__c = 200,
            Target_Quantity_KG__c = 2
        );

        insert new List<TargetActuals__c>{ taSku, taDist, taUser };

        // Order & Invoice
        Order__c ord = new Order__c( OwnerId = u1.Id);
        insert ord;

        Invoice__c inv = new Invoice__c(
            Store__c = cust.Id,
            Invoice_No__c ='14344'
        );
        insert inv;

        // Invoice Items
        Invoice_Item__c iiSku = new Invoice_Item__c(
            Invoice__c = inv.Id,
            Product__c = prod.Id,
            Order__c = ord.Id,
            Quantity__c = 2,
            Bill_Date__c = Date.today(),
            Bill_Amount__c = 200,
            Total_Amount__c = 200,
            Bill_Number__c = '14344',
            Bill_to_Party__c = '2234'
        );
        Invoice_Item__c iiDist = new Invoice_Item__c(
            Invoice__c = inv.Id,
            Order__c = ord.Id,
            Quantity__c = 3,
            Bill_Amount__c = 300,
            Total_Amount__c = 300,
            Bill_Date__c = Date.today(),
            Bill_Number__c = '14344',
            Bill_to_Party__c = '2234'
        );
        insert new List<Invoice_Item__c>{ iiSku, iiDist };
    }

    @isTest
    static void testBatchExecution() {
        setupData();
        Test.startTest();
        Database.executeBatch(new PrimaryTargetsBatch(), 50);
        Test.stopTest();

        for (TargetActuals__c ta : [
            SELECT Id, Actual_Revenue__c, Actual_Quantity_KG__c
            FROM TargetActuals__c
        ]) {
            System.assert(
                ta.Actual_Revenue__c != null || ta.Actual_Quantity_KG__c != null,
                'TargetActuals should have actuals updated'
            );
        }
    }

    @isTest
    static void testSchedulableExecution() {
        Test.startTest();
        String CRON_EXP = '0 0 0 15 5 ?'; // any valid cron
        System.schedule('PrimaryTargetsBatchJob', CRON_EXP, new PrimaryTargetsBatch());
        Test.stopTest();
    }

    @isTest
    static void testTransferTargets() {
        User oldU = createUser('olduser','345');
        User newU = createUser('newuser','56721312');
        insert new List<User>{ oldU, newU };

        Employee__c oldEmp = new Employee__c( Name = 'Test Employee',
            OwnerId = oldU.Id,
            IsDataUpload__c = true,
            Mail_Id__c = 'test@gmail.com', 
            Aadhar_Number__c = '119977663390', 
            Profile__c = 'ASM', 
            Sales_Channel__c = 'TN', 
            User_Name__c = 'my@tstasm.com',
            User__c = oldU.Id, DOJ__c = Date.today().addYears(-1));
        insert oldEmp;

        Employee__c newEmp = new Employee__c(Name = 'Test Employee2',
            OwnerId = newU.Id,
            IsDataUpload__c = true,
            Mail_Id__c = 'test2@gmail.com', 
            Aadhar_Number__c = '119227663390', 
            Profile__c = 'DSM', 
            Sales_Channel__c = 'TN', 
            User_Name__c = 'my@tstdsm.com',
            User__c = newU.Id,
            Replaced_For__c = oldEmp.Id,
            DOJ__c = Date.today().addDays(-1)
        );
        insert newEmp;
        
         TargetActuals__c t = new TargetActuals__c(
            User__c = oldU.Id,
            Month__c = String.valueOf(Date.today().addMonths(1).month()),
            Year__c = String.valueOf(Date.today().year()),
            Type__c = 'Primary',
            Target_Revenue__c = 100,
            Target_Quantity_KG__c = 10
        );
        insert t;

        TargetActuals__c t2 = new TargetActuals__c(
            User__c = oldU.Id,
            Month__c = String.valueOf(Date.today().month()),
            Year__c = String.valueOf(Date.today().year()),
            Type__c = 'Primary',
            Target_Revenue__c = 100,
            Target_Quantity_KG__c = 10
        );
        insert t2;

        Test.startTest();
        PrimaryTargetsBatch.transferTargets(new Set<Id>{ newEmp.Id });
        newEmp.DOJ__c = Date.today().addMonths(1);
        update newEmp;
        PrimaryTargetsBatch.transferTargets(new Set<Id>{ newEmp.Id });
        Test.stopTest();

        TargetActuals__c updated = [
            SELECT User__c
            FROM TargetActuals__c
            WHERE Id = :t.Id
            LIMIT 1
        ];
        System.assertEquals(newU.Id, updated.User__c, 'Target should be reassigned to new user');
    }
}