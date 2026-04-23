public without sharing class GRNPdfController {

    // Hand-off from async callers (e.g. GRNNotificationQueueable) to avoid
    // replication-lag issues where getContentAsPDF() can't see freshly
    // committed records during the async PDF render.
    public static Goods_Received_Note__c preloadedGrn;
    public static List<Goods_Received_Note_Item__c> preloadedItems;
    public static Account preloadedCustomer;

    public Goods_Received_Note__c grn { get; set; }
    public List<Goods_Received_Note_Item__c> items { get; set; }
    public Account customer { get; set; }

    public GRNPdfController(ApexPages.StandardController controller) {
        items = new List<Goods_Received_Note_Item__c>();

        if (preloadedGrn != null) {
            grn = preloadedGrn;
            if (preloadedItems != null) items = preloadedItems;
            customer = preloadedCustomer;
            return;
        }

        Id grnId = ApexPages.currentPage().getParameters().get('id');
        if (grnId == null) return;

        List<Goods_Received_Note__c> grnList = [
            SELECT Id, Name, GRN_Date__c, Invoice__c, Invoice__r.Name
            FROM Goods_Received_Note__c
            WHERE Id = :grnId
            LIMIT 1
        ];
        if (grnList.isEmpty()) return;
        grn = grnList[0];

        items = [
            SELECT Product__r.Name, Invoiced_Quantity__c,
                   Received_Saleable_Quantity__c, Received_Nonsaleable_Quantity__c
            FROM Goods_Received_Note_Item__c
            WHERE Goods_Received_Note__c = :grnId
            ORDER BY Product__r.Name
        ];

        Id customerId = ApexPages.currentPage().getParameters().get('customerId');
        if (customerId != null) {
            List<Account> accs = [
                SELECT Id, Name, SAP_Customer_Code__c, GST_Number__c,
                       State__c, District__c, Land_Mark__c, Street__c
                FROM Account
                WHERE Id = :customerId
                LIMIT 1
            ];
            if (!accs.isEmpty()) customer = accs[0];
        }
    }
}
