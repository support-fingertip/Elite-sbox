@isTest
private class ChildBeatOrderComparatorTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test Child Beats
        List<Child_Beat__c> testBeats = new List<Child_Beat__c>{
            new Child_Beat__c(Name = 'Beat 1'),
            new Child_Beat__c(Name = 'Beat 2'),
            new Child_Beat__c(Name = 'Beat 3'),
            new Child_Beat__c(Name = 'Beat 4')
        };
        insert testBeats;
    }
    
    @isTest
    static void testCompareWithOrderedBeats() {
        // Get test beats
        List<Child_Beat__c> beats = [SELECT Id FROM Child_Beat__c ORDER BY Name];
        
        // Create order map (1, 2, 3, 4)
        Map<Id, Integer> beatOrderMap = new Map<Id, Integer>();
        for(Integer i = 0; i < beats.size(); i++) {
            beatOrderMap.put(beats[i].Id, i+1);
        }
        
        // Instantiate comparator
        ChildBeatOrderComparator comparator = new ChildBeatOrderComparator(beatOrderMap);
        
        // Test comparisons
        Test.startTest();
        System.assertEquals(-1, comparator.compare(beats[0], beats[1]), 'Beat 1 should come before Beat 2');
        System.assertEquals(1, comparator.compare(beats[1], beats[0]), 'Beat 2 should come after Beat 1');
        System.assertEquals(0, comparator.compare(beats[0], beats[0]), 'Same beat should be equal');
        System.assertEquals(-1, comparator.compare(beats[1], beats[2]), 'Beat 2 should come before Beat 3');
        System.assertEquals(1, comparator.compare(beats[3], beats[2]), 'Beat 4 should come after Beat 3');
        Test.stopTest();
    }
    
    @isTest
    static void testCompareWithNullOrders() {
        // Get test beats
        List<Child_Beat__c> beats = [SELECT Id FROM Child_Beat__c ORDER BY Name];
        
        // Create order map with some null values
        Map<Id, Integer> beatOrderMap = new Map<Id, Integer>{
            beats[0].Id => 1,
            beats[1].Id => null, // No order for Beat 2
            beats[2].Id => 3,
            beats[3].Id => null  // No order for Beat 4
        };
        
        // Instantiate comparator
        ChildBeatOrderComparator comparator = new ChildBeatOrderComparator(beatOrderMap);
        
        // Test comparisons
        Test.startTest();
        System.assertEquals(-1, comparator.compare(beats[0], beats[1]), 'Ordered beat should come before unordered');
        System.assertEquals(1, comparator.compare(beats[1], beats[0]), 'Unordered beat should come after ordered');
        System.assertEquals(0, comparator.compare(beats[1], beats[3]), 'Two unordered beats should be equal');
        System.assertEquals(1, comparator.compare(beats[3], beats[2]), 'Unordered beat should come after ordered');
        System.assertEquals(-1, comparator.compare(beats[2], beats[3]), 'Ordered beat should come before unordered');
        Test.stopTest();
    }
    
    @isTest
    static void testCompareWithAllNullOrders() {
        // Get test beats
        List<Child_Beat__c> beats = [SELECT Id FROM Child_Beat__c ORDER BY Name];
        
        // Create empty order map
        Map<Id, Integer> beatOrderMap = new Map<Id, Integer>();
        
        // Instantiate comparator
        ChildBeatOrderComparator comparator = new ChildBeatOrderComparator(beatOrderMap);
        
        // Test comparisons
        Test.startTest();
        System.assertEquals(0, comparator.compare(beats[0], beats[1]), 'All unordered beats should be equal');
        System.assertEquals(0, comparator.compare(beats[1], beats[2]), 'All unordered beats should be equal');
        System.assertEquals(0, comparator.compare(beats[2], beats[3]), 'All unordered beats should be equal');
        System.assertEquals(0, comparator.compare(beats[0], beats[0]), 'Same beat should be equal');
        Test.stopTest();
    }
    
    @isTest
    static void testCompareWithEqualOrders() {
        // Get test beats
        List<Child_Beat__c> beats = [SELECT Id FROM Child_Beat__c ORDER BY Name];
        
        // Create order map with some equal values
        Map<Id, Integer> beatOrderMap = new Map<Id, Integer>{
            beats[0].Id => 1,
            beats[1].Id => 2,
            beats[2].Id => 2, // Same order as Beat 2
            beats[3].Id => 3
        };
        
        // Instantiate comparator
        ChildBeatOrderComparator comparator = new ChildBeatOrderComparator(beatOrderMap);
        
        // Test comparisons
        Test.startTest();
        System.assertEquals(0, comparator.compare(beats[1], beats[2]), 'Beats with same order should be equal');
        System.assertEquals(-1, comparator.compare(beats[0], beats[1]), 'Beat 1 should come before Beat 2');
        System.assertEquals(1, comparator.compare(beats[3], beats[2]), 'Beat 4 should come after Beat 3');
        Test.stopTest();
    }
}