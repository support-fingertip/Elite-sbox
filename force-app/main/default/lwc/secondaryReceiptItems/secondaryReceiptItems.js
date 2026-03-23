import { LightningElement, api, track } from 'lwc';
import getSecondaryInvoiceItems from '@salesforce/apex/DMSPortalLwc.getSecondaryInvoiceItems';

export default class SecondaryReceiptItems extends LightningElement {
    @api receiptId;
    @api receiptNo;
    @track items = [];

    connectedCallback() {
        if (this.receiptId) {
            this.fetchItems();
        }
    }

    fetchItems() {
        getSecondaryInvoiceItems({ invoiceId: this.receiptId })
            .then(result => {
                // Map result to match table fields
                this.items = result.map((item) => ({
                    Product_Name__c: item.Product__r ? item.Product__r.Name : '',
                    Quantity__c: item.Quantity__c,
                    Unit_Price__c: item.Unit_Price__c,
                    Tax_Percent__c: item.Tax_Percent__c,
                    Tax_Amount__c: item.Tax_Amount__c,
                    Total_Amount__c: item.Total_Amount__c,
                    Store__c: item.Store__r ? item.Store__r.Name : '',
                    Id: item.Id
                }));
            })
            .catch(error => {
                this.items = null;
                // Optionally handle error
            });
    }

    handleBack() {
        // Dispatch event to parent to go back
        this.dispatchEvent(new CustomEvent('backtoreceipts'));
    }
}