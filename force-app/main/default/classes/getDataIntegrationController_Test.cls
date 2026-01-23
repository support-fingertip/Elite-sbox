@isTest
private class getDataIntegrationController_Test {

    // ---------------------------------------------------------
    // HELPER: Create Test Product
    // ---------------------------------------------------------
    private static Product__c createProduct(String sku, String uom, Decimal conv) {
        Product__c p = new Product__c(
            Name = 'Test Prod ' + sku,
            SKU_Code__c = sku,
            Uom_Conversion__c = conv
        );
        insert p;
        return p;
        

    }

    // ---------------------------------------------------------
    // TEST CASE: Invoice Integration
    // ---------------------------------------------------------
    @isTest
    static void testInvoicePost() {

        // Products used by line items
        createProduct('SKU100', 'EA', 1);
        createProduct('SKU200', 'CS', 12);

        // JSON Body for Invoice
        String body = '{'+
            '"Data": {'+
            '"Invoice":[{'+
                '"invoiceNumber":"INV001",'+
                '"invoiceDate":"2025-01-01",'+
                '"SAPOrderId":"SO123",'+
                '"sfOrderId":"ORD001",'+
                '"billToParty":"CUST01",'+
                '"shipToParty":"CUST02",'+
                '"companyCode":"1000",'+
                '"delivaryPlant":"PL01",'+
                '"gstAmount":10,'+
                '"igstAmount":5,'+
                '"billAmount":100,'+
                '"InvoiceItems":['+
                    '{'+
                        '"invoiceNumber":"INV001",'+
                        '"material":"SKU100",'+
             		'"serialNumber":"111",'+
                        '"materialDesc":"Desc1",'+
                        '"quantity":2,'+
                        '"pricePerUnit":50,'+
                        '"billAmount":100,'+
                        '"gstAmount":10,'+
                        '"igstAmount":5,'+
                        '"batch":"B1",'+
                        '"batchExpiry":"2025-12-31"'+
                    '}'+
                ']'+
            '}]'+
            '} }';

        // Setting Request Context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/api/Invoice';
        req.requestBody = Blob.valueOf(body);

        RestContext.request = req;
        RestContext.response = res;

        // Call Method
        List<getDataIntegrationController.responseData> responseList =
            getDataIntegrationController.doPost();



    }
     @isTest
    static void testInvoicePost2() {

        // Products used by line items
        createProduct('SKU100', 'EA', 1);
        createProduct('SKU200', 'CS', 12);

        // JSON Body for Invoice
        String body = '{'+
            '"Data": {'+
            '"Invoice":[{'+
                '"invoiceNumber":"INV001",'+
                '"invoiceDate":"2025-01-01",'+
                '"SAPOrderId":"SO123",'+
                '"sfOrderId":"ORD001",'+
                '"billToParty":"CUST01",'+
                '"shipToParty":"CUST02",'+
                '"companyCode":"1000",'+
                '"delivaryPlant":"PL01",'+
                '"gstAmount":10,'+
                '"igstAmount":5,'+
                '"billAmount":100,'+
                '"InvoiceItems":['+
                    '{'+
                        '"invoiceNumber":"",'+
                        '"material":"SKU100",'+
                        '"materialDesc":"Desc1",'+
                        '"quantity":2,'+
                        '"pricePerUnit":50,'+
                        '"billAmount":100,'+
                        '"gstAmount":10,'+
                        '"igstAmount":5,'+
                        '"batch":"B1",'+
                        '"batchExpiry":"2025-12-31"'+
                    '}'+
                ']'+
            '}]'+
            '} }';

        // Setting Request Context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/api/Invoice';
        req.requestBody = Blob.valueOf(body);

        RestContext.request = req;
        RestContext.response = res;

        // Call Method
        List<getDataIntegrationController.responseData> responseList =
            getDataIntegrationController.doPost();



    }
    
    @isTest
    static void testInvoicePost4() {

        // Products used by line items
        createProduct('SKU100', 'EA', 1);
        createProduct('SKU200', 'CS', 12);

        // JSON Body for Invoice
        String body = '{'+
            '"Data": {'+
            '"Invoice":[{'+
                '"invoiceNumber":"INV001",'+
                '"invoiceDate":"2025-01-01",'+
                '"SAPOrderId":"SO123",'+
                '"sfOrderId":"ORD001",'+
                '"billToParty":"CUST01",'+
                '"shipToParty":"CUST02",'+
                '"companyCode":"1000",'+
                '"delivaryPlant":"PL01",'+
                '"gstAmount":10,'+
                '"igstAmount":5,'+
                '"billAmount":100,'+
                '"InvoiceItems":['+
                    '{'+
                        '"invoiceNumber":"INV001",'+
                        '"material":"SKU100",'+
                        '"materialDesc":"Desc1",'+
                        '"quantity":2,'+
                        '"pricePerUnit":null,'+
                        '"billAmount":100,'+
                        '"gstAmount":10,'+
                        '"igstAmount":5,'+
                        '"batch":"B1",'+
                        '"batchExpiry":"2025-12-31"'+
                    '}'+
                ']'+
            '}]'+
            '} }';

        // Setting Request Context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/api/Invoice';
        req.requestBody = Blob.valueOf(body);

        RestContext.request = req;
        RestContext.response = res;

        // Call Method
        List<getDataIntegrationController.responseData> responseList =
            getDataIntegrationController.doPost();



    }
    
     
    @isTest
    static void testInvoicePost5() {

        // Products used by line items
        createProduct('SKU100', 'EA', 1);
        createProduct('SKU200', 'CS', 12);

        // JSON Body for Invoice
        String body = '{'+
            '"Data": {'+
            '"Invoice":[{'+
                '"invoiceNumber":"INV001",'+
                '"invoiceDate":"2025-01-01",'+
                '"SAPOrderId":"SO123",'+
                '"sfOrderId":"ORD001",'+
                '"billToParty":"CUST01",'+
                '"shipToParty":"CUST02",'+
                '"companyCode":"1000",'+
                '"delivaryPlant":"PL01",'+
                '"gstAmount":10,'+
                '"igstAmount":5,'+
                '"billAmount":100,'+
                '"InvoiceItems":['+
                    '{'+
                        '"invoiceNumber":"INV001",'+
                        '"material":"SKU100",'+
                        '"materialDesc":"Desc1",'+
                 		'"serialNumber":"",'+
                        '"quantity":2,'+
                        '"pricePerUnit":102,'+
                        '"billAmount":100,'+
                        '"gstAmount":10,'+
                        '"igstAmount":5,'+
                        '"batch":"B1",'+
                        '"batchExpiry":"2025-12-31"'+
                    '}'+
                ']'+
            '}]'+
            '} }';

        // Setting Request Context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/api/Invoice';
        req.requestBody = Blob.valueOf(body);

        RestContext.request = req;
        RestContext.response = res;

        // Call Method
        List<getDataIntegrationController.responseData> responseList =
            getDataIntegrationController.doPost();



    }
    
     @isTest
    static void testInvoicePost6() {

        // Products used by line items
        createProduct('SKU100', 'EA', 1);
        createProduct('SKU200', 'CS', 12);

        // JSON Body for Invoice
        String body = '{'+
            '"Data": {'+
            '"Invoice":[{'+
                '"invoiceNumber":"INV001",'+
                '"invoiceDate":"2025-01-01",'+
                '"SAPOrderId":"SO123",'+
                '"sfOrderId":"ORD001",'+
                '"billToParty":"CUST01",'+
                '"shipToParty":"CUST02",'+
                '"companyCode":"1000",'+
                '"delivaryPlant":"PL01",'+
                '"gstAmount":10,'+
                '"igstAmount":5,'+
                '"billAmount":100,'+
                '"InvoiceItems":['+
                    '{'+
                        '"invoiceNumber":"INV001",'+
                        '"material":"SKU10011",'+
                        '"materialDesc":"Desc1",'+
                 		'"serialNumber":"",'+
                        '"quantity":2,'+
                        '"pricePerUnit":102,'+
                        '"billAmount":100,'+
                        '"gstAmount":10,'+
                        '"igstAmount":5,'+
                        '"batch":"B1",'+
                        '"batchExpiry":"2025-12-31"'+
                    '}'+
                ']'+
            '}]'+
            '} }';

        // Setting Request Context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/api/Invoice';
        req.requestBody = Blob.valueOf(body);

        RestContext.request = req;
        RestContext.response = res;

        // Call Method
        List<getDataIntegrationController.responseData> responseList =
            getDataIntegrationController.doPost();



    }
    
        // ---------------------------------------------------------
    // TEST CASE: Invoice Integration
    // ---------------------------------------------------------
    @isTest
    static void testInvoicePost1() {
        
        // Products used by line items
        createProduct('SKU100', 'EA', 1);
        createProduct('SKU200', 'CS', 12);
        
        // JSON Body for Invoice
        String body = '{'+
            '"Data": {'+
            '"Invoice":[{'+
            '"invoiceNumber":"INV001",'+
            '"invoiceDate":"",'+
            '"SAPOrderId":"SO123",'+
            '"sfOrderId":"ORD001",'+
            '"billToParty":"CUST01",'+
            '"shipToParty":"CUST02",'+
            '"companyCode":"1000",'+
            '"delivaryPlant":"PL01",'+
            '"gstAmount":10,'+
            '"igstAmount":5,'+
            '"billAmount":100,'+
            '"InvoiceItems":['+
            '{'+
            '"invoiceNumber":"INV001",'+
            '"material":"SKU100",'+
            '"materialDesc":"Desc1",'+
            '"quantity":2,'+
            '"pricePerUnit":50,'+
            '"billAmount":100,'+
            '"gstAmount":10,'+
            '"igstAmount":5,'+
            '"batch":"B1",'+
            '"batchExpiry":"2025-12-31"'+
            '}'+
            ']'+
            '}]'+
            '} }';
        
        // Setting Request Context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/api/Invoice';
        req.requestBody = Blob.valueOf(body);
        
        RestContext.request = req;
        RestContext.response = res;
        
        // Call Method
        List<getDataIntegrationController.responseData> responseList =
            getDataIntegrationController.doPost();
        
        
        
    }
    

    // ---------------------------------------------------------
    // TEST CASE: Stock Integration
    // ---------------------------------------------------------
    @isTest
    static void testStockPost() {

        // Create product for stock mapping
        createProduct('SKU300', 'EA', 1);

        // JSON Body for Stock
        String body = '['+
            '{'+
                '"Delivery_Plant__c":"P1",'+
                '"SKU_Code__c":"SKU300",'+
                '"Quantity__c":20'+
            '}'+
        ']';

        // Set request context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/api/Stock';
        req.requestBody = Blob.valueOf(body);

        RestContext.request = req;
        RestContext.response = res;

        // Call method
        List<getDataIntegrationController.responseData> responseList =
            getDataIntegrationController.doPost();



    }
}