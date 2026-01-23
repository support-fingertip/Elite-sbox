public class TargetActualsChartController {
    // This will hold the chart data list
    public List<ChartData> chartDataList { get; set; }
    public class ChartData {
        public String userName;
        public String monthYear;
        public Decimal targetValue;
        public Decimal actualValue;
        public Decimal yetToAchieve;

        public ChartData(String userName, String monthYear, Decimal targetValue, Decimal actualValue) {
            this.userName = userName;
            this.monthYear = monthYear;
            this.targetValue = targetValue;
            this.actualValue = actualValue;
            this.yetToAchieve = targetValue - actualValue;  // Calculation for "Yet to Achieve"
        }
    }
    
    public TargetActualsChartController(){
        chartDataList = getChartData();
    }
    

    public List<ChartData> getChartData() {
        List<ChartData> chartDataList = new List<ChartData>();

        // Example query to get data grouped by user and month-year
        List<AggregateResult> results = [SELECT User__c, 
                                                CALENDAR_MONTH(End_Date__c) month, 
                                                CALENDAR_YEAR(End_Date__c) year,
                                                SUM(Target_Revenue__c) targetRevenue, 
                                                SUM(Actual_Revenue__c) actualRevenue
                                         FROM TargetActuals__c where Target_Revenue__c != null
                                         GROUP BY User__c, CALENDAR_MONTH(End_Date__c), CALENDAR_YEAR(End_Date__c)];

        for (AggregateResult result : results) {
            String userName = (String) result.get('User__c');
            Integer month = (Integer) result.get('month');
            Integer year = (Integer) result.get('year');
            Decimal targetRevenue = (Decimal) result.get('targetRevenue');
            Decimal actualRevenue = (Decimal) result.get('actualRevenue');
            String monthYear = month + '-' + year;

            chartDataList.add(new ChartData(userName, monthYear, targetRevenue, actualRevenue));
        }

        return chartDataList;
    }
}