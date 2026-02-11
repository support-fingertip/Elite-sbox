@isTest
public class PJPTriggerTest {

    @testSetup
    static void setupData() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User approver = new User(
            FirstName = 'Approver',
            LastName = 'User',
            Email = 'approver@example.com',
            Username = 'approver@example.com' + System.currentTimeMillis(),
            ProfileId = p.Id,
            Alias = 'aprv',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            Employee_Code__c = 'EMP001'
        );
        insert approver;

        User employeeUser = new User(
            FirstName = 'Emp',
            LastName = 'User',
            Email = 'empuser@example.com',
            Username = 'empuser@example.com' + System.currentTimeMillis(),
            ProfileId = p.Id,
            Alias = 'empusr',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            Employee_Code__c = 'EMP002'
        );
        insert employeeUser;

     
        
        Employee__c emp = new Employee__c(
            OwnerId = employeeUser.Id,
            Payroll__c = 'No',
            Is_Active__c = false,
            Reporting_Manager__c = employeeUser.Id,
            Approval_Status__c = 'Pending',
            Mail_Id__c = 'mainuser@example.com',
            Aadhar_Number__c = '123456789012',
            Profile__c = 'TSE', // use a valid picklist value if applicable
            Sales_Channel__c = 'CPD', // use a valid picklist or reference value
            User_Name__c = employeeUser.Username,
            Working_District__c = 'Kolar',
            Pincode__c = '563101',
            Primary_Phone_Number__c = '9876543210',
            State__c = 'Karnataka',
            District__c = 'Kolar'
        );
        insert emp;
    }

    @isTest
    static void testBeforeInsertActivePJPErrorAndApproverSet() {
        User empUser = [SELECT Id FROM User WHERE Email = 'empuser@example.com' LIMIT 1];
        
        Calendar_beat__c existingBeat = new Calendar_beat__c(
            User__c = empUser.Id,
            Active__c = true
        );
        insert existingBeat;

        Calendar_beat__c newBeat = new Calendar_beat__c(
            User__c = empUser.Id
        );

        Test.startTest();
        try {
            insert newBeat; // This should fail due to existing active PJP
        } catch (DmlException e) {
            System.debug('Expected error: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testAfterInsertSetPJPTextField() {
        User empUser = [SELECT Id FROM User WHERE Email = 'empuser@example.com' LIMIT 1];

        Calendar_beat__c beat = new Calendar_beat__c(
            User__c = empUser.Id,
            Active__c = false
        );

        Test.startTest();
        insert beat;
        Test.stopTest();

        List<Calendar_beat__c> insertedBeats = [
            SELECT Id, PJP_Id_Text__c 
            FROM Calendar_beat__c 
            WHERE Id = :beat.Id
        ];
        for (Calendar_beat__c cb : insertedBeats) {
            System.debug('PJP Id Text = ' + cb.PJP_Id_Text__c);
        }
    }

    @isTest
    static void testAfterUpdateApprovalStatusChange() {
        User empUser = [SELECT Id FROM User WHERE Email = 'empuser@example.com' LIMIT 1];

        Calendar_beat__c beat = new Calendar_beat__c(
            User__c = empUser.Id,
            Active__c = false
        );
        insert beat;
        
        Child_beat__c  beat1 = new Child_beat__c(
            Active__c = false
        );
        insert beat1;

        PJP_Item__c item = new PJP_Item__c(
            PJP__c = beat.Id,
            Assigned_Beat__c = beat1.Id,
            Status__c = 'Submitted'
        );
        insert item;

        beat.Approval_Status__c = 'Approved';

        Test.startTest();
        update beat;
        Test.stopTest();

        List<PJP_Item__c> updatedItems = [
            SELECT Id, Status__c, Beat__c 
            FROM PJP_Item__c 
            WHERE Id = :item.Id
        ];

        for (PJP_Item__c i : updatedItems) {
            System.debug('Updated Status: ' + i.Status__c);
            System.debug('Beat set to: ' + i.Beat__c);
        }
    }
}