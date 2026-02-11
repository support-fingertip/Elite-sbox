public class DashboardService {
    public class ResultWrapper {
        @AuraEnabled public Integer activeOutletCount;
        @AuraEnabled public Integer pendingOutletCount;
        @AuraEnabled public Integer totalVisitedOutlets;
        @AuraEnabled public Integer totalProductiveOutlets;
        @AuraEnabled public Integer totalVisits;
        @AuraEnabled public Integer totalProductiveVisits;
    }

    @AuraEnabled(cacheable=true)
    public static ResultWrapper getData(Date fromDate, Date toDate, String state, String rsmId,String asmId) {
        ResultWrapper res = new ResultWrapper();

        // 1) Get subordinate users for RSM (ensure your utility returns Set<Id>)
        Set<Id> subordinateUserIds = RoleHeirarchyUtility.getRoleSubordinateUsers(rsmId);
        if (subordinateUserIds == null || subordinateUserIds.isEmpty()) {
            subordinateUserIds = new Set<Id>{ (Id) rsmId }; // fallback if desired
        }

        // OPTIONAL: build date filter expressions if fromDate/toDate provided
        // We'll assume Visit__c has a Visit_Date__c field. If not, replace with correct date field.
        String visitDateFilter = '';
        // We'll apply dates using bind variables in queries below.

        // ============================
        // 2) Active / Pending Outlets (distinct customers from Product_Mapping__c)
        // ============================
        List<AggregateResult> outletAgg = [
            SELECT Customer__r.Customer_Status__c status, COUNT_DISTINCT(Customer__c) cnt
            FROM Product_Mapping__c
            WHERE Exectuive__c IN :subordinateUserIds
            AND Customer__r.Customer_Type__c = 'Secondary Customer'
            AND Customer__r.Customer_Status__c IN ('Active', 'Activation Pending')
            
            GROUP BY Customer__r.Customer_Status__c
        ];

        for (AggregateResult ar : outletAgg) {
            String status = (String) ar.get('status');
            Integer cnt = (Integer) ar.get('cnt');
            if (status == 'Active') {
                res.activeOutletCount = cnt;
            } else if (status == 'Activation Pending') {
                res.pendingOutletCount = cnt;
            }
        }
        // ensure non-null zeros
        if (res.activeOutletCount == null) res.activeOutletCount = 0;
        if (res.pendingOutletCount == null) res.pendingOutletCount = 0;

        // ============================
        // 3) Visits: total visits and productive visits (record counts)
        //    -> aggregate grouped by Visit_Output__c and COUNT(Id)
        // ============================
        List<AggregateResult> visitCountAgg = [
            SELECT Visit_Output__c visitOutput, COUNT(Id) cnt
            FROM Visit__c
            WHERE OwnerId IN :subordinateUserIds
              AND Account1__r.Customer_Type__c = 'Secondary Customer'
             
            GROUP BY Visit_Output__c
        ];

        Integer totalVisits = 0;
        Integer totalProductiveVisits = 0;
        for (AggregateResult ar : visitCountAgg) {
            String visitOutput = (String) ar.get('visitOutput');
            Integer cnt = (Integer) ar.get('cnt');
            totalVisits += (cnt == null ? 0 : cnt);
            if (visitOutput == 'PJP Successful') {
                totalProductiveVisits = (cnt == null ? 0 : cnt);
            }
        }
        res.totalVisits = totalVisits;
        res.totalProductiveVisits = totalProductiveVisits;

        // ============================
        // 4) Distinct visited outlets and productive distinct outlets (COUNT_DISTINCT Customer)
        //    -> group by Visit_Output__c, COUNT_DISTINCT(Customer__c)
        // ============================
        List<AggregateResult> outletVisitAgg = [
            SELECT Visit_Output__c visitOutput, COUNT_DISTINCT(Account1__c) cnt
            FROM Visit__c
            WHERE OwnerId IN :subordinateUserIds
            AND Account1__r.Customer_Type__c = 'Secondary Customer'
            
            GROUP BY Visit_Output__c
        ];

        Integer visitedOutlets = 0;
        Integer productiveOutlets = 0;
        for (AggregateResult ar : outletVisitAgg) {
            String visitOutput = (String) ar.get('visitOutput');
            Integer cnt = (Integer) ar.get('cnt');
            visitedOutlets += (cnt == null ? 0 : cnt);
            if (visitOutput == 'PJP Successful') {
                productiveOutlets = (cnt == null ? 0 : cnt);
            }
        }
        res.totalVisitedOutlets = visitedOutlets;
        res.totalProductiveOutlets = productiveOutlets;

        // Final null-safety
        if (res.totalVisits == null) res.totalVisits = 0;
        if (res.totalProductiveVisits == null) res.totalProductiveVisits = 0;
        if (res.totalVisitedOutlets == null) res.totalVisitedOutlets = 0;
        if (res.totalProductiveOutlets == null) res.totalProductiveOutlets = 0;

        return res;
    }
}