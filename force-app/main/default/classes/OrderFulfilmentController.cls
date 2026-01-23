public with sharing class OrderFulfilmentController {
    @AuraEnabled
    public static List<OrderWrapper> getUnfulfilledOrders(Integer pageSize, Integer offsetSize) {
        
        system.debug(pageSize+'pageSize');
           system.debug(offsetSize+'offsetSize');
        List<OrderWrapper> result = new List<OrderWrapper>();

        for (Order__c ord : [
            SELECT Id, Name, Order_Type__c, Order_Fulfillment_Status__c, Order_Date__c,
                   Account__c, Account__r.Name, Account__r.Customer_Code__c, Account__r.Outlet_Id__c,
                   Grand_Total__c, Owner_Name__c, Executive_Employee_Code__c
            FROM Order__c
            WHERE Order_Fulfillment_Status__c = 'Not Fulfilled'
              AND Status__c != 'Closed'
              AND Order_Type__c = 'Secondary Order'
            ORDER BY CreatedDate DESC
            LIMIT :pageSize OFFSET :offsetSize
        ]) {
            result.add(new OrderWrapper(ord));
        }
        return result;
    }

    public class OrderWrapper {
        @AuraEnabled public String orderId;
        @AuraEnabled public String orderName;
        @AuraEnabled public String orderType;
        @AuraEnabled public String orderFulfillmentStatus;
        @AuraEnabled public Date orderDate;
        @AuraEnabled public String accountName;
        @AuraEnabled public String customerCode;
        @AuraEnabled public String outletId;
        @AuraEnabled public Decimal grandTotal;
        @AuraEnabled public String executiveName;
        @AuraEnabled public String executiveEmployeeCode;

        public OrderWrapper(Order__c ord) {
            orderId = ord.Id;
            orderName = ord.Name;
            orderType = ord.Order_Type__c;
            orderFulfillmentStatus = ord.Order_Fulfillment_Status__c;
            orderDate = ord.Order_Date__c;
            accountName = (ord.Account__r != null) ? ord.Account__r.Name : '';
            customerCode = (ord.Account__r != null) ? ord.Account__r.Customer_Code__c : '';
            outletId = (ord.Account__r != null) ? ord.Account__r.Outlet_Id__c : '';
            grandTotal = ord.Grand_Total__c;
            executiveName = ord.Owner_Name__c;
            executiveEmployeeCode = ord.Executive_Employee_Code__c;
        }
    }
}