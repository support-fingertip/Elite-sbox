@IsTest
public class ceoDashboardControllerTest {

    @TestSetup
    static void setupTestData() {
        // Create Profiles
        Profile asmProfile = [SELECT Id FROM Profile WHERE Name = 'ASM' LIMIT 1];
        Profile rsmProfile = [SELECT Id FROM Profile WHERE Name = 'RSM' LIMIT 1];

        // Create Users
        User asmUser = new User(
            Alias = 'asmuser',
            Email='asmuser@test.com',
            EmailEncodingKey='UTF-8',
            LastName='ASM',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ProfileId = asmProfile.Id,
            TimeZoneSidKey='Asia/Kolkata',
            UserName='asmuser@test.com',
            Sales_Channel__c='Cake',
            Employee_Code__c = '11355557263'
        );
        insert asmUser;

        User rsmUser = new User(
            Alias = 'rsmuser',
            Email='rsmuser@test.com',
            EmailEncodingKey='UTF-8',
            LastName='RSM',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ProfileId = rsmProfile.Id,
            TimeZoneSidKey='Asia/Kolkata',
            UserName='rsmuser@test.com',
            Sales_Channel__c='CPD',
            Employee_Code__c = '11355557163'
        );
        insert rsmUser;

        // Create Accounts
        List<Account> accounts = new List<Account>();
        for(Integer i=1;i<=5;i++){
            accounts.add(new Account(
                Name='Account '+i,
                Customer_Type__c='Secondary Customer',
                Customer_Status__c = (i / 2 == 0) ? 'Active' : 'Activation Pending',
                OwnerId = rsmUser.Id,
                Pincode__c = '123456',
                Primary_Phone_Number__c = '9876543210',
                State__c = 'Karnataka',
                District__c = 'Kolar'
            ));
        }
        insert accounts;
        
        Account acc1 = new Account(
            Name = 'Test Account with Customer Type',
            Customer_Type__c = 'Primary Customer',
            Pincode__c = '123456',
            Primary_Phone_Number__c = '9876543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert acc1;

        // Create Product_Mapping__c records
        List<Product_Mapping__c> pmList = new List<Product_Mapping__c>();
        for(Account acc : accounts){
            pmList.add(new Product_Mapping__c(
                Customer__c = acc.Id,
                Exectuive__c = asmUser.Id,
                Primary_Customer__c = acc1.Id,
                Cloned_From_Employee_Replacement__c = true
            ));
        }
        insert pmList;

        // Create Visit__c records
        List<Visit__c> visits = new List<Visit__c>();
        for(Account acc : accounts){
            visits.add(new Visit__c(
                Account1__c = acc.Id,
                OwnerId = asmUser.Id,
                Visit_Output__c = 'PJP Successful'
            ));
            visits.add(new Visit__c(
                Account1__c = acc.Id,
                OwnerId = asmUser.Id,
                Visit_Output__c = 'PJP Unsuccessful'
            ));
        }
        insert visits;

        // Create Order__c records
        List<Order__c> orders = new List<Order__c>();
        for(Account acc : accounts){
            orders.add(new Order__c(
                Account__c = acc.Id,
                OwnerId = asmUser.Id,
                Visit__c = null
            ));
        }
        insert orders;
    }

    @IsTest
    static void testInitialLoad() {
        Test.startTest();
        ceoDashboardController.ResultWrapper res = ceoDashboardController.getFilteredData(null, null, null);
        Test.stopTest();

    }

    @IsTest
    static void testWithASM() {
        User asmUser = [SELECT Id FROM User WHERE Alias='asmuser' LIMIT 1];
        Test.startTest();
        ceoDashboardController.ResultWrapper res = ceoDashboardController.getFilteredData('Modern Trade', null, asmUser.Id);
        Test.stopTest();

    }

    @IsTest
    static void testWithRSM() {
        User rsmUser = [SELECT Id FROM User WHERE Alias='rsmuser' LIMIT 1];
        Test.startTest();
        ceoDashboardController.ResultWrapper res = ceoDashboardController.getFilteredData('Modern Trade', rsmUser.Id, null);
        Test.stopTest();

    }

    @IsTest
    static void testWithDateRange() {
        Date fromDate = System.today().addDays(-1);
        Date toDate = System.today().addDays(1);

        User asmUser = [SELECT Id FROM User WHERE Alias='asmuser' LIMIT 1];
        Test.startTest();
        ceoDashboardController.ResultWrapper res = ceoDashboardController.getFilteredData('Modern Trade', null, asmUser.Id);
        
        list<Id> lstId = new list<Id>();
        lstId.add(asmUser.Id);
        
        ceoDashboardController.getOutletCounts(lstId, fromDate,toDate);
        ceoDashboardController.getPJPOutlets(lstId, fromDate,toDate);
        ceoDashboardController.getNonPJPOutlets(lstId, fromDate,toDate);
        ceoDashboardController.getPJPCalls(lstId, fromDate,toDate);
        ceoDashboardController.getNonPJPCalls(lstId, fromDate,toDate);
        ceoDashboardController.getOrderMetrics(lstId, fromDate,toDate);
        Test.stopTest();

    }
}