@isTest
private class GRNNotificationQueueableTest {

    @testSetup
    static void setupData() {
        Account customer = new Account(
            Name = 'GRN Notify Customer',
            Customer_Type__c = 'Primary Customer',
            Pincode__c = '123456',
            Primary_Phone_Number__c = '9876500011',
            State__c = 'Karnataka',
            District__c = 'Kolar',
            SAP_Customer_Code__c = 'CUST-NOTIFY-1',
            Email_ID__c = 'customer@example.com',
            Land_Mark__c = 'Near Park',
            Street__c = '1st Main',
            Sales_Channel__c = 'CPD, MT'
        );
        insert customer;

        Invoice__c inv = new Invoice__c(
            Invoice_No__c = 'INV-NOTIFY-1',
            Store__c = customer.Id,
            Customer_SAP_Code__c = 'CUST-NOTIFY-1',
            Status__c = 'Raised',
            Customer_Name__c = 'GRN Notify Customer',
            Delivery_Plant__c = '1480'
        );
        insert inv;

        Goods_Received_Note__c grn = new Goods_Received_Note__c(
            Invoice__c = inv.Id,
            GRN_Date__c = Date.today()
        );
        insert grn;

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User exec = new User(
            Alias = 'grnexec',
            Email = 'grnexec@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Exec',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'grnexec-' + DateTime.now().getTime() + '@example.com.test',
            Sales_Channel__c = 'CPD;MT'
        );
        insert exec;

        area__c tr = new area__c(
            Name = 'Notify Area',
            Sales_Channel__c = 'CPD',
            Region__c = 'Kerala',
            Area__c = 'Central'
        );
        insert tr;

        Product_Mapping__c pm = new Product_Mapping__c(
            Customer__c = customer.Id,
            Payment_Type__c = 'Credit',
            Payment_Term__c = 'Z045',
            Chanel__c = 'CPD',
            Area__c = tr.Id,
            Exectuive__c = exec.Id,
            Inco_Terms__c = 'FOB'
        );
        insert pm;
    }

    @isTest
    static void testExecuteWithNullIds() {
        Test.startTest();
        System.enqueueJob(new GRNNotificationQueueable(null, null));
        Test.stopTest();
    }

    @isTest
    static void testExecuteWithValidIds() {
        Goods_Received_Note__c grn = [SELECT Id FROM Goods_Received_Note__c LIMIT 1];
        Account customer = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        System.enqueueJob(new GRNNotificationQueueable(grn.Id, customer.Id));
        Test.stopTest();
    }

    @isTest
    static void testExecuteWithNonExistentGrn() {
        Account customer = [SELECT Id FROM Account LIMIT 1];
        Id fakeGrnId = 'a00000000000000AAA';

        Test.startTest();
        System.enqueueJob(new GRNNotificationQueueable(fakeGrnId, customer.Id));
        Test.stopTest();
    }

    @isTest
    static void testExecuteWithCustomerWithoutSalesChannel() {
        Account customer = [SELECT Id FROM Account LIMIT 1];
        customer.Sales_Channel__c = null;
        update customer;

        Goods_Received_Note__c grn = [SELECT Id FROM Goods_Received_Note__c LIMIT 1];

        Test.startTest();
        System.enqueueJob(new GRNNotificationQueueable(grn.Id, customer.Id));
        Test.stopTest();
    }
}
