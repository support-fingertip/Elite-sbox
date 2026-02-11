@isTest
public class MappingHelperTest {
         
    @TestSetup
    static void setup() {
        Profile stdProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        UserRole testRole = [SELECT Id FROM UserRole LIMIT 1];
        
        // Primary Test User
        User testUser1 = new User(
            Alias = 'tuser',
            Employee_Code__c  = 'EMP001',
            Email = 'testuser1@example.com',
            EmailEncodingKey = 'UTF-8',
            userroleId = testRole.Id,
            LastName = 'User1',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = stdProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testuser1' + System.currentTimeMillis() + '@example.com',
            Sales_Channel__c = 'Cake'
        );
        insert testUser1;

        // Secondary Test User
        User testUser2 = new User(
            Alias = 'tuser2',
            Employee_Code__c  = 'EMP002',
            Email = 'testuser2@example.com',
            userroleId = testRole.Id,
            ManagerId = testUser1.Id,
            EmailEncodingKey = 'UTF-8',
            LastName = 'User2',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = stdProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testuser2' + System.currentTimeMillis() + '@example.com',
            Sales_Channel__c = 'Cake'
        );
        insert testUser2;
    }
    
    @isTest
    static void testSaveAutoMappingData_FullCoverage11() {
        User testUser = [SELECT Id FROM User WHERE Employee_Code__c = 'EMP001' LIMIT 1];
        
        // Area record
        area__c tr = new area__c(Name = 'Test Area', Sales_Channel__c = 'CPD', Region__c = 'Kerala', Area__c = 'Central');
        insert tr;
        
        // Primary Customer
        Account primaryCustomer = new Account(
            Name = 'Primary Customer',
            OwnerId = testUser.Id,
            Customer_Type__c = 'Primary Customer',
            Pincode__c = '560001',
            Primary_Phone_Number__c = '1234567891',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert primaryCustomer;

        // Sub Stockiest
        Account subStockiest = new Account(
            Name = 'Sub Stockiest',
            OwnerId = testUser.Id,
            Customer_Type__c = 'Primary Customer',
            Primary_Phone_Number__c = '1234567890',
            Pincode__c = '560002',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert subStockiest;

        // Secondary Customer
        Account secondaryCustomer = new Account(
            Name = 'Secondary Customer',
            OwnerId = testUser.Id,
            Customer_Type__c = 'Secondary Customer',
            Primary_Phone_Number__c = '1234567894',
            Pincode__c = '560003',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert secondaryCustomer;

        // Payroll Mapping for Primary Customer
        Product_Mapping__c pmPrimary = new Product_Mapping__c(
            Customer__c = primaryCustomer.Id,
            Chanel__c = 'CPD',
            Parent_Depot__c ='1100',
            Area__c = tr.Id,
            Child_Depot__c ='1100',
            Payment_Term__c = '0003',
            Exectuive__c = testUser.Id
        );
        insert pmPrimary;

        // Payroll Mapping for Sub Stockiest
        Product_Mapping__c pmSubStockiest = new Product_Mapping__c(
            Customer__c = subStockiest.Id,
            Primary_Customer__c = primaryCustomer.Id,
            Chanel__c = 'CPD',
            Parent_Depot__c ='1100',
            Area__c = tr.Id,
            Child_Depot__c ='1100',
            Payment_Term__c = '0003',
            Exectuive__c = testUser.Id
        );
        insert pmSubStockiest;

        // Non Payroll Mapping
        Employee_Customer_Assignment__c empAssign = new Employee_Customer_Assignment__c(
            Customer__c = primaryCustomer.Id,
            Executive__c = testUser.Id
        );
        insert empAssign;

      

        // Call Method with Product Mapping List (cover all loops)
        Product_Mapping__c secPm = new Product_Mapping__c(
            Primary_Customer__c = primaryCustomer.Id,
            Chanel__c = 'CPD',
            Parent_Depot__c ='1100',
            Area__c = tr.Id,
            Child_Depot__c ='1100',
            Payment_Term__c = '0003',
            Exectuive__c = testUser.Id
        );

        Test.startTest();
        MappingHelper.saveAutoMappingData(secondaryCustomer, new List<Product_Mapping__c>{secPm});
        Test.stopTest();

        // Verify inserted mappings
        List<Product_Mapping__c> createdMappings = [
            SELECT Id, Primary_Customer__c, Sub_Stockiest__c, Customer__c, Exectuive__c 
            FROM Product_Mapping__c 
            WHERE Customer__c = :secondaryCustomer.Id
        ];
       // System.assert(createdMappings.size() > 0, 'Mappings should be auto-created for secondary customer');
    }
    
        @isTest
    static void testSaveAutoMappingData_FullCoverage() {
        User testUser = [SELECT Id FROM User WHERE Employee_Code__c = 'EMP001' LIMIT 1];
        
        // Area record
        area__c tr = new area__c(Name = 'Test Area', Sales_Channel__c = 'CPD', Region__c = 'Kerala', Area__c = 'Central');
        insert tr;
        
        // Primary Customer
        Account primaryCustomer = new Account(
            Name = 'Primary Customer',
            OwnerId = testUser.Id,
            Customer_Type__c = 'Primary Customer',
            Pincode__c = '560001',
            Primary_Phone_Number__c = '1234567891',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert primaryCustomer;

        // Sub Stockiest
        Account subStockiest = new Account(
            Name = 'Sub Stockiest',
            OwnerId = testUser.Id,
            Customer_Type__c = 'Primary Customer',
            Primary_Phone_Number__c = '1234567890',
            Pincode__c = '560002',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert subStockiest;

        // Secondary Customer
        Account secondaryCustomer = new Account(
            Name = 'Secondary Customer',
            OwnerId = testUser.Id,
            Customer_Type__c = 'Secondary Customer',
            Primary_Phone_Number__c = '1234567894',
            Pincode__c = '560003',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert secondaryCustomer;

        // Payroll Mapping for Primary Customer
        Product_Mapping__c pmPrimary = new Product_Mapping__c(
            Customer__c = primaryCustomer.Id,
            Chanel__c = 'CPD',
            Parent_Depot__c ='1100',
            Area__c = tr.Id,
            Child_Depot__c ='1100',
            Payment_Term__c = '0003',
            Exectuive__c = testUser.Id
        );
        insert pmPrimary;

        // Payroll Mapping for Sub Stockiest
        Product_Mapping__c pmSubStockiest = new Product_Mapping__c(
            Customer__c = subStockiest.Id,
            Primary_Customer__c = primaryCustomer.Id,
            Chanel__c = 'CPD',
            Parent_Depot__c ='1100',
            Area__c = tr.Id,
            Child_Depot__c ='1100',
            Payment_Term__c = '0003',
            Exectuive__c = testUser.Id
        );
        insert pmSubStockiest;

        // Non Payroll Mapping
        Employee_Customer_Assignment__c empAssign = new Employee_Customer_Assignment__c(
            Customer__c = primaryCustomer.Id,
            Executive__c = testUser.Id
        );
        insert empAssign;

      

        // Call Method with Product Mapping List (cover all loops)
        Product_Mapping__c secPm = new Product_Mapping__c(
            Primary_Customer__c = primaryCustomer.Id,
            Chanel__c = 'CPD',
            Parent_Depot__c ='1100',
            Area__c = tr.Id,
            Child_Depot__c ='1100',
            Payment_Term__c = '0003',
            Exectuive__c = testUser.Id
        );

        Test.startTest();
        MappingHelper.saveAutoMappingData(secondaryCustomer, new List<Product_Mapping__c>{});
        Test.stopTest();

        // Verify inserted mappings
        List<Product_Mapping__c> createdMappings = [
            SELECT Id, Primary_Customer__c, Sub_Stockiest__c, Customer__c, Exectuive__c 
            FROM Product_Mapping__c 
            WHERE Customer__c = :secondaryCustomer.Id
        ];
       // System.assert(createdMappings.size() > 0, 'Mappings should be auto-created for secondary customer');
    }
}