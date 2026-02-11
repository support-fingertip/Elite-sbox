public class ForeCastController 
{
    public class DataBox{
        @AuraEnabled
        public  list<Product_Category__c> productCategory;
        @AuraEnabled
        public List<Forecast_Period__c> periodsList;
        @AuraEnabled
        public string period; 
        @AuraEnabled
        public string userProfileName;
        @AuraEnabled
        public List<Product__c> productList;
        @AuraEnabled
        public List<Product_Forecast__c> currentForecasts;
        @AuraEnabled
        public List<Product_Forecast__c> lastWeekForecasts;
        @AuraEnabled
        public List<Product_Forecast__c> lastThreeWeekForecasts;
    }
    @auraEnabled
    public static DataBox getAllData()
    {
        DataBox dx = new DataBox();
        dx.productCategory = [
            SELECT Id, Name, Selling_Category__c, Selling_Category__r.Name
            FROM Product_Category__c 
            WHERE Id IN (SELECT Product_Category1__c FROM Product__c) 
            ORDER BY Name ASC
        ];
        
        dx.periodsList = [select id, name,Start_Date__c,End_Date__c from Forecast_Period__c order by Createddate desc];
        dx.UserProfileName=[select name from profile where id=:userinfo.getprofileId()].name;
        
        dx.productList = [
            SELECT Id, Name, Product_Category_Name__c, List_Price__c, Tax_Percent__c, CreatedDate, Product_Code__c,  
            Product_Category1__c, Product_Category1__r.Name, CGST__c, Discount__c, Tax_Class__c,Selling_Category__c,Selling_Category__r.Name
            FROM Product__c
            WHERE Product_Category1__c != NULL order by Product_Category1__r.name asc
        ];
        
        
        // Get Current Forecast Period
        Map<Integer, String> weekNames = new Map<Integer, String>();
        weekNames.put(1, 'Week 1');
        weekNames.put(2, 'Week 2');
        weekNames.put(3, 'Week 3');
        weekNames.put(4, 'Week 4');
        weekNames.put(5, 'Week 5');
        weekNames.put(6, 'Week 6');
                    
        
        // Get Current Forecast Period
        Forecast_Period__c currentPeriod;
        try {
            currentPeriod = [
                SELECT Id, Start_Date__c 
                FROM Forecast_Period__c 
                WHERE Start_Date__c <= TODAY AND End_Date__c >= TODAY 
                LIMIT 1
            ];
        } 
        catch (Exception e) {
            currentPeriod = null;
        }
        
        if (currentPeriod == null) {
            // No current period exists – create new period
            
            Date today = Date.today();
            
            // Get the day of the week (1 = Monday, 7 = Sunday)
            Integer dayOfWeek = Integer.valueOf(
                Datetime.newInstance(today, Time.newInstance(0, 0, 0, 0)).format('u')
            );
            
            // Calculate start of the week (Monday)
            Date startDate = today.addDays(dayOfWeek == 1 ? 0 : -(dayOfWeek - 1));
            
            // Calculate end of the week (Sunday)
            Date endDate = startDate.addDays(6);
            
            // Format dates
            String startDateFormatted = Datetime.newInstance(startDate, Time.newInstance(0, 0, 0, 0)).format('MMM dd (EEE)');
            String endDateFormatted = Datetime.newInstance(endDate, Time.newInstance(0, 0, 0, 0)).format('MMM dd (EEE)');
            
            // Get week number within the month
            Integer weekOfMonth = (Math.floor((startDate.day() - 1) / 7) + 1).intValue();
            
            // Get week name from map
            String weekName = weekNames.containsKey(weekOfMonth) 
                ? weekNames.get(weekOfMonth) + ': ' + startDateFormatted + ' – ' + endDateFormatted 
                : 'Week ' + weekOfMonth + ': ' + startDateFormatted + ' – ' + endDateFormatted;
            
            // Create new Forecast Period
            currentPeriod = new Forecast_Period__c(
                Name = weekName,
                Start_Date__c = startDate,
                End_Date__c = endDate
            );
            
            insert currentPeriod;
        }
        
        dx.period = currentPeriod.Id;
        

        
        // Get Last Week Forecast Period
        List<Forecast_Period__c> lastWeekPeriods = [
            SELECT Id 
            FROM Forecast_Period__c 
            WHERE Start_Date__c < :currentPeriod.Start_Date__c 
            ORDER BY Start_Date__c DESC 
            LIMIT 1
        ];
        
        Id lastWeekPeriodId = lastWeekPeriods.isEmpty() ? null : lastWeekPeriods[0].Id;
        
        // Get Last Three Weeks Forecast Periods
        List<Forecast_Period__c> lastThreeWeekPeriods = [
            SELECT Id 
            FROM Forecast_Period__c 
            WHERE Start_Date__c < :currentPeriod.Start_Date__c 
            ORDER BY Start_Date__c DESC 
            LIMIT 3
        ];
        
        List<Id> lastThreeWeekPeriodIds = new List<Id>();
        for (Forecast_Period__c period : lastThreeWeekPeriods) {
            lastThreeWeekPeriodIds.add(period.Id);
        }
        
        // Get Product Forecasts for Current, Last Week, and Last Three Weeks
        dx.currentForecasts = [
            SELECT Id, Name, Product__c, Forecast__c, Forecast_Period__c 
            FROM Product_Forecast__c 
            WHERE Forecast_Period__c = :currentPeriod.Id
        ];
        
        dx.lastWeekForecasts = lastWeekPeriodId != null ? [
            SELECT Id, Product__c, Forecast__c 
            FROM Product_Forecast__c 
            WHERE Forecast_Period__c = :lastWeekPeriodId
        ] : new List<Product_Forecast__c>();
        
        dx.lastThreeWeekForecasts = lastThreeWeekPeriodIds.isEmpty() ? new List<Product_Forecast__c>() : [
            SELECT Id, Product__c, Forecast__c 
            FROM Product_Forecast__c 
            WHERE Forecast_Period__c IN :lastThreeWeekPeriodIds
        ];
            
            return dx;
    }
    
    @auraEnabled
    public static DataBox getForeCasts(String selectedPeriod)
    {
        DataBox dx = new DataBox();
        // Get Current Forecast Period
        Forecast_Period__c SelectedPeriodRec = [
            SELECT Id, Start_Date__c 
            FROM Forecast_Period__c 
            WHERE Id =:selectedPeriod
            LIMIT 1
        ];
        dx.period = selectedPeriod;
        
        // Get Last Week Forecast Period
        List<Forecast_Period__c> lastWeekPeriods = [
            SELECT Id 
            FROM Forecast_Period__c 
            WHERE Start_Date__c < :SelectedPeriodRec.Start_Date__c 
            ORDER BY Start_Date__c DESC 
            LIMIT 1
        ];
        
        Id lastWeekPeriodId = lastWeekPeriods.isEmpty() ? null : lastWeekPeriods[0].Id;
        
        // Get Last Three Weeks Forecast Periods
        List<Forecast_Period__c> lastThreeWeekPeriods = [
            SELECT Id 
            FROM Forecast_Period__c 
            WHERE Start_Date__c < :SelectedPeriodRec.Start_Date__c 
            ORDER BY Start_Date__c DESC 
            LIMIT 3
        ];
        
        List<Id> lastThreeWeekPeriodIds = new List<Id>();
        for (Forecast_Period__c period : lastThreeWeekPeriods) {
            lastThreeWeekPeriodIds.add(period.Id);
        }
        
        // Get Product Forecasts for Current, Last Week, and Last Three Weeks
        dx.currentForecasts = [
            SELECT Id, Name, Product__c, Forecast__c, Forecast_Period__c 
            FROM Product_Forecast__c 
            WHERE Forecast_Period__c = :SelectedPeriodRec.Id
        ];
        
        dx.lastWeekForecasts = lastWeekPeriodId != null ? [
            SELECT Id, Product__c, Forecast__c 
            FROM Product_Forecast__c 
            WHERE Forecast_Period__c = :lastWeekPeriodId
        ] : new List<Product_Forecast__c>();
        
        dx.lastThreeWeekForecasts = lastThreeWeekPeriodIds.isEmpty() ? new List<Product_Forecast__c>() : [
            SELECT Id, Product__c, Forecast__c 
            FROM Product_Forecast__c 
            WHERE Forecast_Period__c IN :lastThreeWeekPeriodIds
        ];
            
            return dx;
    }
    @auraEnabled
    public static list<Product_Forecast__c> saveForecastData(list<Product_Forecast__c> foreCastData, String selectedPeriod)
    {
        upsert foreCastData;
        system.debug('foreCastData'+foreCastData);
        system.debug('selectedPeriod'+selectedPeriod);
        list<Product_Forecast__c> currentForecasts = [
            SELECT Id, Name, Product__c, Forecast__c, Forecast_Period__c 
            FROM Product_Forecast__c 
            WHERE Forecast_Period__c = :selectedPeriod
        ];
        return currentForecasts;
        
    }
    
}