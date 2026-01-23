public with sharing class SalesStrategyController {
    @AuraEnabled
    public static List<Sales_Strategy__c> saveStrategies(List<Sales_Strategy__c> strategies) {
        upsert strategies;
        return strategies;
    }

    @AuraEnabled
    public static Map<String, Object> getInitialData() {
        Map<String, Object> result = new Map<String, Object>();
        
        // Fetch Sales Channels
        List<String> channels = new List<String>();
        Schema.DescribeFieldResult fieldResult = Sales_Strategy__c.Sales_Channel__c.getDescribe();
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            channels.add(entry.getValue());
        }
        List<Map<String, String>> options = new List<Map<String, String>>();
        for (String ch : channels) {
            options.add(new Map<String, String>{ 'label' => ch, 'value' => ch });
        }
        result.put('salesChannels', options);
        
        // Fetch Area picklist values
        List<Map<String, String>> areaOptions = new List<Map<String, String>>();
        fieldResult = Sales_Strategy__c.Area__c.getDescribe();
        system.debug(fieldResult.getPicklistValues());
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            areaOptions.add(new Map<String, String>{ 'label' => entry.getLabel(), 'value' => entry.getValue() });
        }
        result.put('areaOptions', areaOptions);
        
        // Fetch Customer Category picklist values
        List<Map<String, String>> customerCategoryOptions = new List<Map<String, String>>();
        fieldResult = Sales_Strategy__c.Customer_Category__c.getDescribe();
        system.debug(fieldResult.getPicklistValues());
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            customerCategoryOptions.add(new Map<String, String>{ 'label' => entry.getLabel(), 'value' => entry.getValue() });
        }
        result.put('customerCategories', customerCategoryOptions);
        
        // Fetch Focus Type options (hardcoded for now)
        result.put('focusTypes', new List<Map<String, String>>{
            new Map<String, String>{'label' => 'Focused Sell', 'value' => 'Focused Sell'},
                new Map<String, String>{'label' => 'Must Sell', 'value' => 'Must Sell'}
        });
        
        // Fetch Type options (hardcoded for now)
        result.put('typeOptions', new List<Map<String, String>>{
            new Map<String, String>{'label' => 'Area', 'value' => 'Area'},
                new Map<String, String>{'label' => 'Region', 'value' => 'Region'},
                    new Map<String, String>{'label' => 'User', 'value' => 'User'},
                        new Map<String, String>{'label' => 'Customer', 'value' => 'Customer'},
                            new Map<String, String>{'label' => 'Customer Category', 'value' => 'Customer Category'}
        });
        
        return result;
    }
    
}