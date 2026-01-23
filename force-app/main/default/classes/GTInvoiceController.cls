public with sharing class GTInvoiceController {
    public Id recordId { get; set; }

    public GTInvoiceController() {
        recordId = ApexPages.currentPage().getParameters().get('id');
    }
}