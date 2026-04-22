public without sharing class GRNPdfController {

    public Goods_Received_Note__c grn { get; set; }
    public List<Goods_Received_Note_Item__c> items { get; set; }

    public GRNPdfController(ApexPages.StandardController controller) {
        Id grnId = ApexPages.currentPage().getParameters().get('id');
        items = new List<Goods_Received_Note_Item__c>();

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
    }
}
