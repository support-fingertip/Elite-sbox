@isTest
private class PriceBookTriggerTest {

    @TestSetup
    static void setupTestData() {
        Account customer = new Account(
            Name = 'Test PBTrigger Customer',
            Customer_Type__c = 'Secondary Customer',
            State__c = 'Bihar',
            District__c = 'Patna'
        );
        insert customer;

        Account otherCustomer = new Account(
            Name = 'Test PBTrigger Other',
            Customer_Type__c = 'Secondary Customer',
            State__c = 'Bihar',
            District__c = 'Patna'
        );
        insert otherCustomer;
    }

    static Account getCustomer() {
        return [SELECT Id FROM Account WHERE Name = 'Test PBTrigger Customer' LIMIT 1];
    }

    static Account getOtherCustomer() {
        return [SELECT Id FROM Account WHERE Name = 'Test PBTrigger Other' LIMIT 1];
    }

    @isTest
    static void testAfterInsertFiresTrigger() {
        Account customer = getCustomer();

        Test.startTest();
        Price_Book__c pb = new Price_Book__c(
            Customer__c = customer.Id,
            MRP__c = 150
        );
        insert pb;
        Test.stopTest();

        Price_Book__c refreshed = [SELECT Id, Customer__c FROM Price_Book__c WHERE Id = :pb.Id];
        System.assertEquals(customer.Id, refreshed.Customer__c);
    }

    @isTest
    static void testAfterUpdateFiresTrigger() {
        Account customer = getCustomer();
        Account other = getOtherCustomer();

        Price_Book__c pb = new Price_Book__c(Customer__c = customer.Id);
        insert pb;

        Test.startTest();
        pb.Customer__c = other.Id;
        update pb;
        Test.stopTest();

        Price_Book__c refreshed = [SELECT Customer__c FROM Price_Book__c WHERE Id = :pb.Id];
        System.assertEquals(other.Id, refreshed.Customer__c);
    }

    @isTest
    static void testBulkInsertFiresTrigger() {
        Account customer = getCustomer();

        List<Price_Book__c> priceBooks = new List<Price_Book__c>();
        for (Integer i = 0; i < 10; i++) {
            priceBooks.add(new Price_Book__c(
                Customer__c = customer.Id,
                MRP__c = 50 * (i + 1)
            ));
        }

        Test.startTest();
        insert priceBooks;
        Test.stopTest();

        System.assertEquals(10, [SELECT COUNT() FROM Price_Book__c WHERE Customer__c = :customer.Id]);
    }
}