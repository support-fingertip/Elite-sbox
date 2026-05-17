@isTest
private class ForecastActualsBatchTest {

    private static String currentMonthName() {
        return Datetime.now().format('MMMM');
    }

    private static String currentYearString() {
        return String.valueOf(Date.today().year());
    }

    private static String firstSubGroupValue() {
        List<Schema.PicklistEntry> entries =
            Product_Forecast__c.Product_Sub_Group__c.getDescribe().getPicklistValues();
        for (Schema.PicklistEntry e : entries) {
            if (e.isActive()) return e.getValue();
        }
        return null;
    }

    private static Boolean picklistHas(Schema.SObjectField field, String value) {
        if (String.isBlank(value)) return false;
        for (Schema.PicklistEntry e : field.getDescribe().getPicklistValues()) {
            if (e.isActive() && e.getValue() == value) return true;
        }
        return false;
    }

    private static Boolean canSeedMonthlyForecast(String subGroup) {
        return picklistHas(Product_Forecast__c.Forecast_Month__c, currentMonthName())
            && picklistHas(Product_Forecast__c.Forecast_Year__c, currentYearString())
            && String.isNotBlank(subGroup);
    }

    private static Account makeDistributor(String name) {
        Account a = new Account(Name = name);
        insert a;
        return a;
    }

    private static Product__c makeProduct(String name, String subGroup, Decimal netWeight) {
        Product__c p = new Product__c(
            Name = name,
            SKU_Code__c = name,
            Net_Weight__c = netWeight,
            Product_Sub_Group__c = subGroup,
            Is_Active__c = true
        );
        insert p;
        return p;
    }

    private static Invoice__c makeInvoice(Account dist, Date invoiceDate, String invNo) {
        Invoice__c inv = new Invoice__c(
            Invoice_No__c = invNo,
            Store__c = dist.Id,
            Invoice_Date__c = invoiceDate,
            Customer_Name__c = dist.Name,
            Customer_SAP_Code__c = 'SAP-' + invNo,
            Delivery_Plant__c = '1480',
            Status__c = 'Raised'
        );
        insert inv;
        return inv;
    }

    private static Invoice_Item__c makeItem(Invoice__c inv, Product__c prod, Decimal qty) {
        Invoice_Item__c item = new Invoice_Item__c(
            Invoice__c = inv.Id,
            Product__c = prod.Id,
            SKU__c = prod.Id,
            Qyt_in_Each__c = qty,
            Bill_Number__c = inv.Invoice_No__c
        );
        insert item;
        return item;
    }

    private static Product_Forecast__c makeForecast(Account dist, Product__c prod, String subGroup) {
        Product_Forecast__c f = new Product_Forecast__c(
            Distributor__c = dist.Id,
            Product__c = prod == null ? null : prod.Id,
            Product_Sub_Group__c = subGroup,
            Forecast_Month__c = currentMonthName(),
            Forecast_Year__c = currentYearString(),
            Forecast_UOM__c = 'KG',
            Forecast__c = 100,
            Is_Monthly_Forecast__c = true,
            Approval_Status__c = 'Approved'
        );
        insert f;
        return f;
    }

    @isTest
    static void productForecast_sumsMatchingInvoiceLines() {
        String subGroup = firstSubGroupValue();
        if (!canSeedMonthlyForecast(subGroup)) return;

        Account dist = makeDistributor('Dist Prod');
        Product__c prod = makeProduct('SKU-P', subGroup, 5);
        Invoice__c inv = makeInvoice(dist, Date.today(), 'INV-P-1');
        makeItem(inv, prod, 4);     // 4 * 5 = 20 KG
        makeItem(inv, prod, 6);     // 6 * 5 = 30 KG

        Product_Forecast__c f = makeForecast(dist, prod, subGroup);

        Test.startTest();
        Database.executeBatch(new ForecastActualsBatch(), 200);
        Test.stopTest();

        Product_Forecast__c reloaded = [
            SELECT Actual_Quantity_KG__c
            FROM Product_Forecast__c
            WHERE Id = :f.Id
        ];
        System.assertEquals(50, reloaded.Actual_Quantity_KG__c,
            'Actual should sum to 4*5 + 6*5 = 50 KG.');
    }

    @isTest
    static void subGroupForecast_sumsAllSKUsInGroup() {
        String subGroup = firstSubGroupValue();
        if (!canSeedMonthlyForecast(subGroup)) return;

        Account dist = makeDistributor('Dist SubGrp');
        Product__c prodA = makeProduct('SKU-A', subGroup, 2);
        Product__c prodB = makeProduct('SKU-B', subGroup, 3);
        Invoice__c inv = makeInvoice(dist, Date.today(), 'INV-SG-1');
        makeItem(inv, prodA, 10);   // 10 * 2 = 20 KG
        makeItem(inv, prodB, 5);    // 5  * 3 = 15 KG

        Product_Forecast__c f = makeForecast(dist, null, subGroup);

        Test.startTest();
        Database.executeBatch(new ForecastActualsBatch(), 200);
        Test.stopTest();

        Product_Forecast__c reloaded = [
            SELECT Actual_Quantity_KG__c
            FROM Product_Forecast__c
            WHERE Id = :f.Id
        ];
        System.assertEquals(35, reloaded.Actual_Quantity_KG__c,
            'Sub group forecast should sum across both SKUs in the group.');
    }

    @isTest
    static void differentDistributor_isExcluded() {
        String subGroup = firstSubGroupValue();
        if (!canSeedMonthlyForecast(subGroup)) return;

        Account forecastDist = makeDistributor('Forecast Dist');
        Account otherDist    = makeDistributor('Other Dist');
        Product__c prod = makeProduct('SKU-D', subGroup, 2);
        Invoice__c inv = makeInvoice(otherDist, Date.today(), 'INV-D-1');
        makeItem(inv, prod, 7);

        Product_Forecast__c f = makeForecast(forecastDist, prod, subGroup);

        Test.startTest();
        Database.executeBatch(new ForecastActualsBatch(), 200);
        Test.stopTest();

        Product_Forecast__c reloaded = [
            SELECT Actual_Quantity_KG__c
            FROM Product_Forecast__c
            WHERE Id = :f.Id
        ];
        System.assertEquals(0, reloaded.Actual_Quantity_KG__c,
            'Invoices for a different distributor must not contribute.');
    }

    @isTest
    static void priorMonthInvoice_isExcluded() {
        String subGroup = firstSubGroupValue();
        if (!canSeedMonthlyForecast(subGroup)) return;

        Account dist = makeDistributor('Dist Month');
        Product__c prod = makeProduct('SKU-M', subGroup, 4);
        // 35 days back guarantees we cross a month boundary regardless of run date.
        Invoice__c lastMonthInv = makeInvoice(dist, Date.today().addDays(-35), 'INV-M-OLD');
        makeItem(lastMonthInv, prod, 8);
        Invoice__c currentMonthInv = makeInvoice(dist, Date.today(), 'INV-M-NEW');
        makeItem(currentMonthInv, prod, 3);   // 3 * 4 = 12 KG

        Product_Forecast__c f = makeForecast(dist, prod, subGroup);

        Test.startTest();
        Database.executeBatch(new ForecastActualsBatch(), 200);
        Test.stopTest();

        Product_Forecast__c reloaded = [
            SELECT Actual_Quantity_KG__c
            FROM Product_Forecast__c
            WHERE Id = :f.Id
        ];
        System.assertEquals(12, reloaded.Actual_Quantity_KG__c,
            'Only invoices in the current calendar month should be counted.');
    }
}
