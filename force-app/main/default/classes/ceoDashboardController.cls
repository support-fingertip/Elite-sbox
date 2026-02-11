public class ceoDashboardController {

    public class ResultWrapper {
        @AuraEnabled public list<Id> userIds = new list<Id>();
        @AuraEnabled public Integer activeOutletCount = 0;
        @AuraEnabled public Integer activationPendingOutletCount = 0;
        
        @AuraEnabled public Integer pjpOutlets = 0;
        @AuraEnabled public Integer pjpProductiveOutlets = 0;
        @AuraEnabled public decimal pjpProductiveOutletsPercent = 0;
        
        @AuraEnabled public Integer nonPJPOutlets = 0;
        @AuraEnabled public Integer nonPJPProductiveOutlets = 0;
        @AuraEnabled public decimal nonPJPProductiveOutletsPercent = 0;
        
        @AuraEnabled public Integer pjpCalls = 0;
        @AuraEnabled public Integer pjpProductiveCalls = 0;
        @AuraEnabled public Decimal pjpProductiveCallsPercent = 0;
        
        @AuraEnabled public Integer nonPJPCalls = 0;
        @AuraEnabled public Integer nonPJPProductiveCalls = 0;
        @AuraEnabled public Decimal nonPJPProductiveCallsPercent = 0;
        
        @AuraEnabled public Integer totalCalls = 0;
        @AuraEnabled public Integer totalProductiveCalls = 0;
        @AuraEnabled public Decimal totalProductiveCallsPercent = 0;
        
        @AuraEnabled public Decimal orderWeightinKG = 0; 
        @AuraEnabled public Decimal valueinLakhs = 0; 
        
        @AuraEnabled public List<Map<String, String>> salesChannelOptions = new List<Map<String, String>> ();
        @AuraEnabled public List<User> rsmUserList = new List<User> ();
        @AuraEnabled public List<User> asmUserList = new List<User> ();
        
    }
    

    @AuraEnabled(cacheable=true)
    public static ResultWrapper getFilteredData(String saleChannel, String rsmId, String asmId) {
        
        ResultWrapper res = new ResultWrapper();
        String userId;
        
        // Step 1: Determine base userId and get subordinates
        if (asmId != null && asmId.trim() != '') {
            userId = asmId;
        } else if (rsmId != null && rsmId.trim() != '') {
            userId = rsmId;
        } else {
            userId = UserInfo.getUserId();
            res.salesChannelOptions = GetPicklistValues.extractPicklistValues('Product_Mapping__c','Chanel__c');
        }
        
        // Get subordinate users 
        Set<Id> readOnlySubordinateIds = getRoleSubordinateUsers(userId);
        
        // Copy into a mutable set (due to sometimes readOnlySubordinateIds is getting is collection ready only)
        Set<Id> subordinateUserIds = new Set<Id>(readOnlySubordinateIds);

        // Ensure current user is included if no subordinates
        if (subordinateUserIds.isEmpty()) {
            subordinateUserIds = new Set<Id>(subordinateUserIds);
            subordinateUserIds.add(userId);
        }
        
        // Step 2: Filter subordinate users based on Sales_Channel__c if provided
        if (saleChannel != null && saleChannel.trim() != '') {
            List<User> filteredUsers = [SELECT Id FROM User
                                        WHERE Id IN :subordinateUserIds
                                        AND Sales_Channel__c INCLUDES (:saleChannel)
                                        ];
            subordinateUserIds.clear();
            for (User u : filteredUsers) {
                subordinateUserIds.add(u.Id);
            }
        }
        
        res.userIds = new List<Id>(subordinateUserIds);
        
        // Step 3: If saleChannel is provided, get RSM list
        if (saleChannel != null && saleChannel.trim() != '' && (asmId == null || asmId.trim() == '')) {
            res.rsmUserList = getUsersByProfileAndChannel(
                new List<String>{'RSM','Sr. RSM','Deputy RSM'},
                subordinateUserIds,
                saleChannel
            );
        }
        
        // Step 4: If rsmId is provided, get ASM list
        if (rsmId != null && rsmId.trim() != '') {
            res.asmUserList = getUsersByProfileAndChannel(
                new List<String>{'ASM','Sr. ASM','Deputy ASM'},
                subordinateUserIds,
                saleChannel
            );
        }
        
        return res;
    }
    
    // Existing helper method to fetch users by profile and channel
    public static List<User> getUsersByProfileAndChannel(List<String> profiles, Set<Id> userIds, String saleChannel) {
        List<String> channelList = new List<String>{saleChannel};
            String includesValue = '(\'' + String.join(channelList, '\',\'') + '\')';
        
        String queryString = 'SELECT Id, Name, Sales_Channel__c FROM User ' +
            'WHERE Profile.Name IN :profiles AND IsActive = true ' +
            'AND Sales_Channel__c INCLUDES ' + includesValue;
        
        if (userIds != null && !userIds.isEmpty()) {
            queryString += ' AND Id IN :userIds';
        }
        
        System.debug('SOQL ::: ' + queryString);
        return Database.query(queryString);
    }

    
    
    public static Set<ID> getRoleSubordinateUsers(Id userId) {
        
        Set<Id> allSubRoleIds = getAllSubRoleIds(New Set<ID>{userId});
        allSubRoleIds.add(userId);
        Map<Id, User> users = new Map<Id, User>([SELECT Id, Name From  User Where Id IN  :allSubRoleIds]);
        
        return users.keySet();
    }
    
    //Recursive function
    private static Set<ID> getAllSubRoleIds(Set<ID> userId) {
        
        Set<ID> currentRoleIds = new Set<ID>();
        
        for(User userRole :[SELECT Id, Name,ManagerId From  User Where ManagerId IN :userId AND ManagerId != null]){
            currentRoleIds.add(userRole.Id);
        }
        if(currentRoleIds.size() > 0){
            currentRoleIds.addAll(getAllSubRoleIds(currentRoleIds));
        }        
        return currentRoleIds;   
    }
    
    
    @AuraEnabled
    public static ResultWrapper getOutletCounts(List<Id> subordinateUserIds, Date fromDate, Date toDate) {
        ResultWrapper res = new ResultWrapper();
        
        List<String> whereConditions = new List<String>();
        whereConditions.add('Exectuive__c IN :subordinateUserIds');
        whereConditions.add('Customer__r.Customer_Type__c = \'Secondary Customer\'');
        whereConditions.add('Customer__r.Customer_Status__c IN (\'Active\', \'Activation Pending\')');
        
        // Calculate toDateInclusive outside the query
        Date toDateInclusive;
        if (fromDate != null && toDate != null) {
            toDateInclusive = toDate.addDays(1);
            whereConditions.add('Customer__r.CreatedDate >= :fromDate AND Customer__r.CreatedDate < :toDateInclusive');
        }
        
           
        
        
        String finalWhere = ' WHERE ' + String.join(whereConditions, ' AND ');
        
        String query = 'SELECT Customer__r.Customer_Status__c status, COUNT_DISTINCT(Customer__c) cnt ' +
            'FROM Product_Mapping__c ' + finalWhere +
            ' GROUP BY Customer__r.Customer_Status__c';
        
        System.debug('getOutletCounts query: ' + query);
        
        for (AggregateResult ar : Database.query(query)) {
            if ((String) ar.get('status') == 'Active') res.activeOutletCount = (Integer) ar.get('cnt');
            if ((String) ar.get('status') == 'Activation Pending') res.activationPendingOutletCount = (Integer) ar.get('cnt');
        }
        
        return res;
    }
    
    
    // Get PJP Outlets
    @AuraEnabled
    public static ResultWrapper getPJPOutlets(list<Id> subordinateUserIds, Date fromDate, Date toDate) {
        ResultWrapper res = new ResultWrapper();
        List<String> whereConditions = new List<String>();
        whereConditions.add('OwnerId IN :subordinateUserIds');
        whereConditions.add('Account1__r.Customer_Type__c = \'Secondary Customer\'');
        
        Date toDateInclusive;
        if (fromDate != null && toDate != null) {
            toDateInclusive = toDate.addDays(1);
            whereConditions.add('CreatedDate >= :fromDate AND CreatedDate < :toDateInclusive');
        }
        
        String finalWhere = ' WHERE ' + String.join(whereConditions, ' AND ');
        String query = 'SELECT COUNT_DISTINCT(Account1__c) cnt ' +
            'FROM Visit__c ' + finalWhere;
        
        system.debug('query'+query);
        
        for (AggregateResult ar : Database.query(query)) {
            Integer cnt = (Integer) ar.get('cnt');
            res.pjpOutlets = cnt != null ? cnt : 0;
        }
        
        return res;
    }
    // Get PJP Outlets
    @AuraEnabled
    public static ResultWrapper getPJPProductiveOutlets(list<Id> subordinateUserIds, Date fromDate, Date toDate) {
        ResultWrapper res = new ResultWrapper();
        List<String> whereConditions = new List<String>();
        whereConditions.add('OwnerId IN :subordinateUserIds');
        whereConditions.add('Account1__r.Customer_Type__c = \'Secondary Customer\'');
        whereConditions.add('Visit_Output__c = \'PJP Successful\'');

        Date toDateInclusive;
        if (fromDate != null && toDate != null) {
            toDateInclusive = toDate.addDays(1);
            whereConditions.add('CreatedDate >= :fromDate AND CreatedDate < :toDateInclusive');
        }
        

            
        String finalWhere = ' WHERE ' + String.join(whereConditions, ' AND ');
        String query = 'SELECT  COUNT_DISTINCT(Account1__c) cnt ' +
                       'FROM Visit__c ' + finalWhere;
        
        system.debug('query'+query);

        for (AggregateResult ar : Database.query(query)) {
             Integer cnt = (Integer) ar.get('cnt');
            res.pjpProductiveOutlets = cnt != null ? cnt : 0;
        }


        return res;
    }

    // Get Non-PJP Outlets
    @AuraEnabled
    public static ResultWrapper getNonPJPOutlets(list<Id> subordinateUserIds, Date fromDate, Date toDate) {
        ResultWrapper res = new ResultWrapper();
        List<String> whereConditions = new List<String>();
        whereConditions.add('OwnerId IN :subordinateUserIds');
        whereConditions.add('Visit__c = null');
        whereConditions.add('Account__r.Customer_Type__c = \'Secondary Customer\'');

 
        Date toDateInclusive;
        if (fromDate != null && toDate != null) {
            toDateInclusive = toDate.addDays(1);
            whereConditions.add('CreatedDate >= :fromDate AND CreatedDate < :toDateInclusive');
        }
        

          
        String finalWhere = ' WHERE ' + String.join(whereConditions, ' AND ');
        String query = 'SELECT COUNT_DISTINCT(Account__c) cnt FROM Order__c ' + finalWhere;

        List<AggregateResult> results = Database.query(query);
        if (!results.isEmpty()) {
            Integer cnt = (Integer) results[0].get('cnt');
            res.nonPJPOutlets = cnt;
            res.nonPJPProductiveOutlets = cnt;
            res.nonPJPProductiveOutletsPercent = cnt > 0 ? 100 : 0;
        }

        return res;
    }

    
    
    // -------------------------------
    // Get PJP Calls
    // -------------------------------
    @AuraEnabled
    public static ResultWrapper getPJPCalls(list<Id> subordinateUserIds, Date fromDate, Date toDate) {
        ResultWrapper res = new ResultWrapper();
        Integer pjpCalls = 0;
        Integer pjpProductiveCalls = 0;

        List<String> whereClauses = new List<String>();
        whereClauses.add('OwnerId IN :subordinateUserIds');
        whereClauses.add('Account1__r.Customer_Type__c = \'Secondary Customer\'');

        if (fromDate != null && toDate != null) {
            Date toDateInclusive = toDate.addDays(1);
            whereClauses.add('CreatedDate >= :fromDate AND CreatedDate < :toDateInclusive');
        }
        
  

        String finalWhere = whereClauses.isEmpty() ? '' : ' WHERE ' + String.join(whereClauses, ' AND ');
        String queryStr = 'SELECT Visit_Output__c visitOutput, COUNT(Id) cnt FROM Visit__c ' +
                          finalWhere + ' GROUP BY Visit_Output__c';

        for (AggregateResult ar : Database.query(queryStr)) {
            Integer cnt = (Integer) ar.get('cnt');
            String out = (String) ar.get('visitOutput');
            pjpCalls += (cnt != null ? cnt : 0);
            if (out == 'PJP Successful') pjpProductiveCalls += (cnt != null ? cnt : 0);
        }

        res.pjpCalls = pjpCalls;
        res.pjpProductiveCalls = pjpProductiveCalls;
        res.pjpProductiveCallsPercent = (pjpCalls > 0) ? ((Decimal.valueOf(pjpProductiveCalls)/pjpCalls)*100).setScale(2) : 0;
        return res;
    }

    // -------------------------------
    //  Get Non-PJP Calls
    // -------------------------------
    @AuraEnabled
    public static ResultWrapper getNonPJPCalls(list<Id> subordinateUserIds, Date fromDate, Date toDate) {
        ResultWrapper res = new ResultWrapper();
        Integer nonPJPCalls = 0;
        Integer nonPJPProductiveCalls = 0;

        List<String> whereClauses = new List<String>();
        whereClauses.add('OwnerId IN :subordinateUserIds');
        whereClauses.add('Account__r.Customer_Type__c = \'Secondary Customer\'');
        whereClauses.add('Visit__c = null');

        if (fromDate != null && toDate != null) {
            Date toDateInclusive = toDate.addDays(1);
            whereClauses.add('CreatedDate >= :fromDate AND CreatedDate < :toDateInclusive');
        }
  

        String finalWhere = whereClauses.isEmpty() ? '' : ' WHERE ' + String.join(whereClauses, ' AND ');
        String queryStr = 'SELECT COUNT(Id) cnt FROM Order__c ' + finalWhere;

        for (AggregateResult ar : Database.query(queryStr)) {
            Integer cnt = (Integer) ar.get('cnt');
            nonPJPCalls = cnt != null ? cnt : 0;
            nonPJPProductiveCalls = cnt != null ? cnt : 0;
        }

        res.nonPJPCalls = nonPJPCalls;
        res.nonPJPProductiveCalls = nonPJPProductiveCalls;
        res.nonPJPProductiveCallsPercent = (nonPJPCalls > 0) ? ((Decimal.valueOf(nonPJPProductiveCalls)/nonPJPCalls)*100).setScale(2) : 0;
        return res;
    }

    
    
    
    // Get Order Metrics
    @AuraEnabled
    public static ResultWrapper getOrderMetrics(list<Id> subordinateUserIds, Date fromDate, Date toDate) {
        ResultWrapper res = new ResultWrapper();
        List<String> whereConditions = new List<String>();
        whereConditions.add('Order__r.OwnerId IN :subordinateUserIds');
        whereConditions.add('Order__r.Account__r.Customer_Type__c = \'Secondary Customer\'');
        
        Date toDateInclusive;
        if (fromDate != null && toDate != null)
        {
            toDateInclusive = toDate.addDays(1);
            whereConditions.add('Order__r.CreatedDate >= :fromDate AND Order__r.CreatedDate < :toDateInclusive');
        }
                   

        String finalWhere = ' WHERE ' + String.join(whereConditions, ' AND ');
        String query = 'SELECT SUM(Net_Weight__c) sumWeight, SUM(Total_Amount__c) sumAmount FROM Order_Item__c ' + finalWhere;

        List<AggregateResult> results = Database.query(query);
        if (!results.isEmpty()) {
            AggregateResult ar = results[0];
            Decimal weight = (Decimal) ar.get('sumWeight');
            Decimal amount = (Decimal) ar.get('sumAmount');

            res.orderWeightinKG = (weight != null ? (weight / 1000) : 0).setScale(2, RoundingMode.HALF_UP);
            res.valueinLakhs = (amount != null ? (amount / 100000) : 0).setScale(2, RoundingMode.HALF_UP);
        }

        return res;
    }
}