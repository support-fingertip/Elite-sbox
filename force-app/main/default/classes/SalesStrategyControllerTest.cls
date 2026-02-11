@isTest
public class SalesStrategyControllerTest {

    @isTest
    static void testSaveStrategies() {
        // Create sample Sales_Strategy__c records
        List<Sales_Strategy__c> strategies = new List<Sales_Strategy__c>{
            new Sales_Strategy__c(
                Name = 'Strategy 1',
                Sales_Channel__c = 'CPD'
            ),
            new Sales_Strategy__c(
                Name = 'Strategy 2',
                Sales_Channel__c = 'CPD'
            )
        };

        Test.startTest();
        List<Sales_Strategy__c> savedStrategies = SalesStrategyController.saveStrategies(strategies);
        Test.stopTest();

        
    }

    @isTest
    static void testGetInitialData() {
        Test.startTest();
        Map<String, Object> result = SalesStrategyController.getInitialData();
        Test.stopTest();

    }
}