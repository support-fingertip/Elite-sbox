@isTest
public class SecondaryCustomerControllerTest {
    @TestSetup
    static void setup() {
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        UserRole testRole = [SELECT Id FROM UserRole LIMIT 1];
        // Create test users
        User testUser1 = new User(
            Alias = 'tuser',
            Employee_Code__c  = '123sfgg212231',
            Email = 'testusersss@example.com',
            EmailEncodingKey = 'UTF-8',
            userroleId = testRole.Id,
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testuser@example.com' + System.currentTimeMillis(),
            Sales_Channel__c = 'Cake'
        );
        insert testUser1;
        User testUser2 = new User(
            Alias = 'tuser12',
            Employee_Code__c  = '1232122DDD343',
            Email = 'testuser@example.com',
            userroleId = testRole.Id,
            ManagerId = testUser1.Id,
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testuser@example.com' + System.currentTimeMillis(),
            Sales_Channel__c = 'Cake'
        );
        insert testUser2 ;
        
        
        
    }
    
    
    @isTest
    static void testBeforeInsert() {
        
        Profile profile = [SELECT Id FROM Profile WHERE Name='TSE'];
        User testUser = new User(
            FirstName = 'Test123',
            LastName = 'User',
            Email = 'testuser@elite.com',
            Username = 'testuser@eliteproductmapping.com',
            ProfileId = profile.Id,
            Employee_Code__c = 'EMP12323121122',            
            Alias = 'tuser',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles'
        );
        insert testUser;
        
        User testUser2 = new User(
            FirstName = 'Test123',
            LastName = 'User',
            Email = 'testuser@elite2.com',
            Username = 'testuser@eliteproductmapping2.com',
            ProfileId = profile.Id,
            Alias = 'tuser',
            Employee_Code__c = 'EMP12323121122456',  
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles'
        );
        insert testUser2;
        
        Account acc = new Account(
            Name = 'Primary Customer',
            OwnerId = testUser.Id,
            Customer_Type__c = 'Primary Customer',
            Pincode__c = '123456',
            Primary_Phone_Number__c = '9876543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert acc;
        area__c tr = new area__c();
        tr.Name = 'test11121';
        tr.Sales_Channel__c = 'CPD';
        tr.Region__c =	'Kerala';
        tr.Area__c  = 'Central';
        insert tr;
        
        
        Profile p = [SELECT Id, Name FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        UserRole ur = [SELECT Id FROM UserRole LIMIT 1];
        
        
        Product_Mapping__c pm = new   Product_Mapping__c();
        pm.Customer__c = acc.Id;
        pm.Payment_Term__c = '0003';
        pm.Chanel__c = 'CPD';
        pm.Exectuive__c = testUser.Id;
        pm.Area__c = tr.Id;
        pm.Primary_Customer__c = acc.Id;
        insert pm;
        
        pm.Payment_Term__c = '0004';
        pm.Exectuive__c = testUser2.Id;
        update pm;
        
        
        SecondaryCustomerController.getProductMappings(acc.Id);
        
    }
    
}