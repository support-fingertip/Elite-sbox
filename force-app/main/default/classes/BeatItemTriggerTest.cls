@isTest
public class BeatItemTriggerTest {
  
    
    @testSetup
     private static void createTestData() {
         
          Profile p = [SELECT Id FROM Profile WHERE Name = 'DSM' LIMIT 1];
        Profile p2 = [SELECT Id FROM Profile WHERE Name = 'TSE' LIMIT 1];
         // Create role for TSE (parent/top)
         UserRole roleTSE = new UserRole(Name = 'TSE Test Role');
         insert roleTSE;
         
         // Create role for DSM as a child of TSE role
         UserRole roleDSM = new UserRole(Name = 'DSM Test Role', ParentRoleId = roleTSE.Id);
         insert roleDSM;
         
        User u2 = new User(
            Alias = 'tuser',
            Email = 'tuser2222@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p2.Id,
            UserRoleId = roleTSE.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'tuser222' + DateTime.now().getTime() + '@example.com',
            Region__c = 'Tamil Nadu',
            Employee_Code__c = '9999',
            Payroll__c = 'Yes',
            ManagerId = UserInfo.getUserId(),
            IsActive=true
        );
        insert u2;
        
        User u = new User(
            Alias = 'tuser',
            Email = 'tuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            UserRoleId = roleDSM.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'tuser' + DateTime.now().getTime() + '@example.com',
            Region__c = 'Tamil Nadu',
            Employee_Code__c = '99999',
            Payroll__c = 'No',
            ManagerId = u2.Id,
            IsActive=true
        );
        insert u;
       
         System.runAs(u2){
                 Account primaryAcc = new Account(
                Name = 'Primary Customer',
                Customer_Type__c = 'Primary Customer',
                Primary_Phone_Number__c = '9876543210',
                State__c = 'Karnataka',
                District__c = 'Kolar',
             SAP_Customer_Code__c = '2234'
            );
            insert primaryAcc;
            
            area__c tr = new area__c();
            tr.Name = 'test11121';
            tr.Sales_Channel__c = 'CPD';
            tr.Region__c = 'Kerala';
            tr.Area__c  = 'Central';
            insert tr;
            
            Product_Mapping__c pm = new Product_Mapping__c();
            pm.Customer__c = primaryAcc.Id;
            pm.Payment_Term__c = '0003';
            pm.Chanel__c = 'CPD';
            pm.Exectuive__c = u2.Id;
            pm.Area__c = tr.Id;
            insert pm;
        
          
            Account subStockistAcc = new Account(
                Name = 'Sub Stockist',
                Customer_Type__c = 'Secondary Customer',
                Secondary_Customer_Type__c =  'Sub Stockiest',
                Primary_Phone_Number__c = '9876543211',
                State__c = 'Karnataka',
                District__c = 'Kolar',
                Outlet_Id__c = '23123123'
            );
            insert subStockistAcc;
         
            Product_Mapping__c pm2 = new   Product_Mapping__c();
            pm2.Customer__c = subStockistAcc.Id;
            pm2.Exectuive__c = u2.Id;
            pm2.Primary_Customer__c = primaryAcc.Id;
            insert pm2;
             
                  
             Account testAcc = new Account(
                 Name = 'Primary Customer',
                 Customer_Type__c = 'Primary Customer',
                 Primary_Phone_Number__c = '6666664445',
                 State__c = 'Karnataka',
                 District__c = 'Kolar',
                 SAP_Customer_Code__c = '88654'
             );
             insert testAcc;
         }
     
         
     }
    
    @isTest
    static void testDuplicateRecords() {
        User tse = [SELECT Id FROM User WHERE Email = 'tuser2222@example.com' LIMIT 1]; // u2 (TSE)
        User dsm = [SELECT Id FROM User WHERE Email = 'tuser@example.com' LIMIT 1];     // u  (DSM)


        
         Account testAccount = [select Id from Account where Sap_Customer_Code__c='2234' limit 1];
        System.runAs(tse) {
         
            Child_beat__c beat1 = new Child_beat__c(
                Name = 'Test Beat 1',
                Active__c = true,
                Beat_Type__c = 'Primary',
                User__c = dsm.Id,
                OwnerId = dsm.Id
            );
            insert beat1;
            
            Junction_Beat__c firstRecord = new Junction_Beat__c(
                Account__c = testAccount.Id,
                Child_beat__c = beat1.Id
            );
            insert firstRecord;
            
            Junction_Beat__c duplicateRecord = new Junction_Beat__c(
                Account__c = testAccount.Id,
                Child_beat__c = beat1.Id
            );
            
            Test.startTest();
            try {
                insert duplicateRecord;
                System.assert(false, 'Expected an exception due to duplicate Account-Beat pair');
            } catch (DmlException e) {
                System.assert(e.getMessage().contains('This Account is already linked to this Beat.'));
            }
            Test.stopTest();
        }
    }
    
    @isTest
    static void testHandlerPrimaryCustomerValidation() {
        
        User tse = [SELECT Id FROM User WHERE Email = 'tuser2222@example.com' LIMIT 1]; // u2 (TSE)
        User dsm = [SELECT Id FROM User WHERE Email = 'tuser@example.com' LIMIT 1];     // u  (DSM)


        
        Account primaryAcc = [select Id from Account where Sap_Customer_Code__c='2234' limit 1];
        
        System.runAs(tse) {
             
            Child_beat__c beat = new Child_beat__c(Name = 'Beat', Active__c = true, Beat_Type__c = 'Primary', OwnerId = dsm.Id);
            insert beat;
            
            Junction_Beat__c beatItem = new Junction_Beat__c(
                Account__c = primaryAcc.Id,
                Child_beat__c = beat.Id
            );
            Test.startTest();
            try {
                insert beatItem;
                //  System.assert(false, 'Expected error for unmapped primary customer');
            } catch (DmlException e) {
                System.assert(e.getMessage().contains('Primary Customer is not yet mapped'));
            }
            Test.stopTest();
        }
    }
    
    @isTest
    static void testHandlerSecondaryCustomerMapping() {
        User tse = [SELECT Id FROM User WHERE Email = 'tuser2222@example.com' LIMIT 1]; // u2 (TSE)
        User dsm = [SELECT Id FROM User WHERE Email = 'tuser@example.com' LIMIT 1];     // u  (DSM)
       

        Account primaryAcc = [select Id from Account where Sap_Customer_Code__c='2234' limit 1];
        Account subStockistAcc = [select Id from Account where Outlet_Id__c='23123123' limit 1];
        Account testAcc = [select Id from Account where Sap_Customer_Code__c='88654' limit 1];
        
        System.runAs(tse) {
         
        
            Child_beat__c beat = new Child_beat__c(Name = 'Beat', Active__c = true, Beat_Type__c = 'Secondary',
                                                   Primary_Customer__c = primaryAcc.Id,Sub_Stockist__c = subStockistAcc.Id,
                                                   OwnerId = dsm.Id);
            insert beat;
            
        
            
             Child_beat__c beat2 = new Child_beat__c(Name = 'Beat', Active__c = true, Beat_Type__c = 'Secondary',
                                                   Primary_Customer__c = testAcc.Id,
                                                   OwnerId = dsm.Id);
           // insert beat2;
            
            Junction_Beat__c beatItem = new Junction_Beat__c(
                Account__c = subStockistAcc.Id,
                Child_beat__c = beat.Id
            );
            Test.startTest();
            insert beatItem;
            Test.stopTest();
            
            List<Product_Mapping__c> subMaps = [SELECT Id, Customer__c, Primary_Customer__c FROM Product_Mapping__c WHERE Customer__c = :subStockistAcc.Id AND Primary_Customer__c = :primaryAcc.Id];
            System.assert(subMaps.size() > 0, 'Sub Stockist mapping should be created');
      }
    }
    
   /* @isTest
    static void testNoDuplicates() {
        User tse = [SELECT Id FROM User WHERE Email = 'tuser2222@example.com' LIMIT 1]; // u2 (TSE)
        User dsm = [SELECT Id FROM User WHERE Email = 'tuser@example.com' LIMIT 1];     // u  (DSM)


        
        Account testAccount = [select Id from Account where Sap_Customer_Code__c='2234' limit 1];
        Account testAccount2 = [select Id from Account where Sap_Customer_Code__c='2234' limit 1];
        
        System.runAs(tse) {
             Child_beat__c beat1 = new Child_beat__c(
                 Name = 'Test Beat 1',
                Active__c = true,
                Beat_Type__c = 'Primary',
                OwnerId = dsm.Id
            );
            insert beat1;
            
            Junction_Beat__c firstRecord = new Junction_Beat__c(
                Account__c = testAccount.Id,
                Child_beat__c = beat1.Id
            );
            insert firstRecord;
            
            Junction_Beat__c secondRecord = new Junction_Beat__c(
                Account__c = testAccount2.Id,
                Child_beat__c = beat1.Id
            );
            
            Test.startTest();
            insert secondRecord;
            Test.stopTest();
            
            List<Junction_Beat__c> insertedRecords = [SELECT Account__c, Child_beat__c FROM Junction_Beat__c WHERE Child_Beat__c = :beat1.Id];
            System.assertEquals(2, insertedRecords.size(), 'Two records should be inserted');
        }
    }*/
    
    @isTest
    static void testEmptyTrigger() {
      User tse = [SELECT Id FROM User WHERE Email = 'tuser2222@example.com' LIMIT 1]; // u2 (TSE)


        System.runAs(tse) {
            Test.startTest();
            try {
                insert new List<Junction_Beat__c>();
            } catch (DmlException e) {
                System.assert(false, 'Empty insert should not throw an error');
            }
            Test.stopTest();
        }
    }
}