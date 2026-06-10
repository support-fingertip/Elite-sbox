@isTest
public class SecondaryKpiDashboard_ControllerTest {

    private static User makeUser(String alias) {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        return new User(
            FirstName = 'T', LastName = alias,
            Email = alias + '@example.com',
            Username = alias + System.currentTimeMillis() + '@example.com',
            Alias = alias.substring(0, Math.min(8, alias.length())),
            TimeZoneSidKey = 'Asia/Kolkata', LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', ProfileId = p.Id
        );
    }

    @TestSetup
    static void setup() {
        User u = makeUser('kpi');
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert u;
        }

        Target_Criteria__c crit = new Target_Criteria__c(
            Name = 'KPI Revenue', Object__c = 'Order_Item__c', Operator__c = 'SUM',
            Field__c = 'Total_Amount__c', Date_Field__c = 'Order_Date__c',
            User_Field__c = 'Order_Owner_Id__c', Active__c = true
        );
        insert crit;

        Date today = Date.today();
        Date monthStart = Date.newInstance(today.year(), today.month(), 1);
        Date monthEnd = monthStart.addMonths(1).addDays(-1);

        Secondary_Target__c t = new Secondary_Target__c(
            User__c = u.Id, Target_Criteria__c = crit.Id,
            Target_Value__c = 1000, Achievement_Value__c = 850,
            Achievement_Percent__c = 85.00,
            Is_Active__c = true,
            Start_Date__c = monthStart, End_Date__c = monthEnd
        );
        insert t;

        Incentive_Credit__c ic = new Incentive_Credit__c(
            Executive__c = u.Id, Credit_Amount__c = 500,
            Source__c = 'Secondary PBIS',
            Year__c = today.year(), Month__c = today.month(),
            Target_Criteria__c = crit.Id
        );
        insert ic;
    }

    @isTest
    static void dashboardDefaultsToCurrentUserAndPeriod() {
        Test.startTest();
        SecondaryKpiDashboard_Controller.DashboardData d =
            SecondaryKpiDashboard_Controller.getDashboard(null, null, null);
        Test.stopTest();

        System.assertNotEquals(null, d, 'should return dashboard');
        System.assertEquals(UserInfo.getUserId(), d.rootUserId, 'root defaults to me');
        System.assertNotEquals(null, d.hero, 'hero present');
        System.assertNotEquals(null, d.periodLabel, 'period label set');
        // Channel + criteria lists may be empty (current user has no targets) — just confirm null-safety.
        System.assertNotEquals(null, d.channels);
        System.assertNotEquals(null, d.criteria);
        System.assertNotEquals(null, d.teams);
        System.assertNotEquals(null, d.topPerformers);
        System.assertNotEquals(null, d.bottomPerformers);
    }

    @isTest
    static void dashboardAggregatesForGivenUser() {
        User u = [SELECT Id FROM User WHERE LastName = 'kpi' LIMIT 1];
        Date today = Date.today();

        Test.startTest();
        SecondaryKpiDashboard_Controller.DashboardData d =
            SecondaryKpiDashboard_Controller.getDashboard(today.year(), today.month(), u.Id);
        Test.stopTest();

        System.assertEquals(u.Id, d.rootUserId);
        System.assertEquals(1000, d.hero.totalTarget, 'target sum');
        System.assertEquals(850, d.hero.totalAchievement, 'achievement sum');
        System.assertEquals(85, d.hero.achievementPct.setScale(0), 'ach pct');
        System.assertEquals(500, d.hero.totalIncentive, 'incentive sum');
        System.assertEquals(1, d.hero.activeTargets, 'one active target');
        // One criterion was used → criteria breakdown returns one row.
        System.assertEquals(1, d.criteria.size());
    }

    @isTest
    static void breadcrumbsReturnsCurrentUser() {
        Test.startTest();
        List<SecondaryKpiDashboard_Controller.Crumb> crumbs =
            SecondaryKpiDashboard_Controller.getBreadcrumbs(UserInfo.getUserId());
        Test.stopTest();

        System.assertNotEquals(null, crumbs);
        System.assert(!crumbs.isEmpty(), 'at least the user itself');
        System.assertEquals(UserInfo.getUserId(), crumbs[crumbs.size() - 1].userId,
            'last crumb is the requested user');
    }

    @isTest
    static void rejectsInvalidMonthGracefully() {
        Test.startTest();
        SecondaryKpiDashboard_Controller.DashboardData d =
            SecondaryKpiDashboard_Controller.getDashboard(2026, 99, null);
        Test.stopTest();

        // Invalid month falls back to current period — call should still succeed.
        System.assertNotEquals(null, d);
        System.assert(d.month >= 1 && d.month <= 12, 'month coerced to valid range');
    }
}
