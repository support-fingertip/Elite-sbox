public class newStockAdjustment {
    public class dataBox {
        @AuraEnabled public Decimal secondaryCustomerCount;
        @AuraEnabled public Decimal subStockiestCount;
        @AuraEnabled public Decimal totalCustomersCount;
    }

    public static dataBox getStockAdjustments()
    {
        dataBox dt = new dataBox();
        return dt;
    }
}