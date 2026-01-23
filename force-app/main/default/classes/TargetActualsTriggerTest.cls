@isTest
public class TargetActualsTriggerTest {

    // Helper method to create a User with required fields
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

    // Helper method to create a TargetActuals__c record
    private static TargetActuals__c createTargetActual(User user, Date startDate, Date endDate, Decimal quantity, Decimal revenue) {
        return new TargetActuals__c(
            User__c = user.Id,
            Month__c = String.valueOf(startDate.month()),
            Year__c = String.valueOf(endDate.year()),
            Target_Quantity_KG__c = quantity,
            Target_Revenue__c = revenue,
            Type__c = 'Primary'
        );
    }

    // Test insert scenario when User is blank
    @isTest
    static void testInsertUserBlank() {
        User u1 = createUser('user1','123243');
        insert u1;

        TargetActuals__c ta = new TargetActuals__c(
            Month__c = String.valueOf(Date.today().addMonths(1).month()),
            Year__c = String.valueOf(Date.today().year()),
            Target_Quantity_KG__c = 10,
            Target_Revenue__c = 100,
            Type__c = 'Primary'
        );

        Test.startTest();
        try {
            insert ta;
            System.assert(false, 'Expected exception due to blank User__c');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('User cannot be blank.'));
        }
        Test.stopTest();
    }

    // Test insert scenario when both Target_Quantity_KG__c and Target_Revenue__c are blank
    @isTest
    static void testInsertNoTargetValues() {
        User u1 = createUser('user1','256');
        insert u1;

        TargetActuals__c ta = new TargetActuals__c(
            User__c = u1.Id,
             Month__c = String.valueOf(Date.today().addMonths(1).month()),
            Year__c = String.valueOf(Date.today().year()),
            Type__c = 'Primary'
        );

        Test.startTest();
        try {
            insert ta;
            System.assert(false, 'Expected exception due to missing target values');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Enter atleast one target value for defining the target.'));
        }
        Test.stopTest();
    }

    // Test update scenario for past/current month restriction
    @isTest
    static void testUpdateForPastMonth() {
        User u1 = createUser('user1','267');
        insert u1;

        TargetActuals__c ta = createTargetActual(u1, Date.today().addMonths(1), Date.today().addMonths(1), 10, 100);
        insert ta;

        ta.Target_Quantity_KG__c = 20; // Trying to update it
        ta.Month__c =  String.valueOf(Date.today().addMonths(-1).month()); // Set start date to past month

        Test.startTest();
        try {
            update ta;
            System.assert(false, 'Expected exception for updating target in past month');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Target Update for Past or Current month is not permitted!'));
        }
        Test.stopTest();
    }

    // Test valid update scenario
    @isTest
    static void testValidUpdate() {
        User u1 = createUser('user1','632');
        insert u1;

        TargetActuals__c ta = createTargetActual(u1, Date.today().addMonths(1), Date.today().addMonths(1), 10, 100);
        insert ta;

        ta.Target_Quantity_KG__c = 20; // Valid update

        Test.startTest();
        update ta;
        Test.stopTest();

        // Verify the update was successful
        TargetActuals__c updatedTa = [SELECT Target_Quantity_KG__c FROM TargetActuals__c WHERE Id = :ta.Id];
        System.assertEquals(20, updatedTa.Target_Quantity_KG__c);
    }

    // Test update scenario where the user is transferred
    @isTest
    static void testUserTransfer() {
        User oldUser = createUser('olduser','6322');
        User newUser = createUser('newuser','1578');
        insert new List<User>{oldUser, newUser};

        TargetActuals__c ta = createTargetActual(oldUser, Date.today().addMonths(1), Date.today().addMonths(1), 10, 100);
        insert ta;

        ta.User__c = newUser.Id; // Transfer to new user
        Test.startTest();
        update ta;
        Test.stopTest();

        // Verify the user was transferred
        TargetActuals__c updatedTa = [SELECT User__c FROM TargetActuals__c WHERE Id = :ta.Id];
        System.assertEquals(newUser.Id, updatedTa.User__c);
    }
}