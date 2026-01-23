@isTest
public class LookupControllerTest {

    @isTest
    static void testSearchRecordsWithFilter() {
        // Create sample Account with specific Type for filtering
        
        Account primaryAcc = new Account(
            Name = 'Test Account 1',
            Customer_Type__c = 'Primary Customer',
            Pincode__c = '123456',
            Primary_Phone_Number__c = '0876543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert primaryAcc;
        
        Account acc2 = new Account(
            Name = 'Test Account 1',
            Customer_Type__c = 'Primary Customer',
            Pincode__c = '123456',
            Primary_Phone_Number__c = '9076543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert acc2;
        
        Area__c ar = new Area__c();
            ar.Sales_Channel__c = 'West';
            ar.Region__c = 'West';
			ar.Area__c = 'Mumbai';
insert ar;     
        
        Product_Mapping__c pm = new Product_Mapping__c();
        pm.Customer__c = acc2.Id;
        pm.Exectuive__c = UserInfo.getUserId();
        pm.Chanel__c = 'Cake';
        pm.Area__c = ar.Id;
        insert pm;
        
        Product__c pro = new product__c();
        pro.Name = '727272';
        insert pro;
        
        Sales_Channel_To_SKU__c sc = new Sales_Channel_To_SKU__c();
        sc.Sales_Channel__c = 'Cake';
        sc.SKU__c = pro.id;
        insert sc;


        Test.startTest();
        List<SObject> result = LookupController.searchRecords(
            'Test',              // searchKey
            'Account',           // objectApiName
            'Channel__c',              // filterField
            'Cake'           // filterValue
        );
        List<SObject> result1 = LookupController.searchRecords(
            'Test',              // searchKey
            'Account',           // objectApiName
            'Type',              // filterField
            'Cake'           // filterValue
        );
        
        List<SObject> result2 = LookupController.searchRecords(
            'Test',              // searchKey
            'Account',           // objectApiName
            'Order_Owner__c',              // filterField
            acc2.Id           // filterValue
        );
        Test.stopTest();
        

    }

}