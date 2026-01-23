import { LightningElement, api, track } from 'lwc';
import createGRN from '@salesforce/apex/DMSPortalLwc.createGRN';
import getInvoicesByIds from '@salesforce/apex/DMSPortalLwc.getInvoicesByIds';
import GOOGLE_ICONS from '@salesforce/resourceUrl/googleIcons';

export default class GenerateGRNpage extends LightningElement {
    @api invoiceIds; // expects a single-item list
    @track invoiceItems = [];
    isPageLoaded = false;
    loading = false;

    googleIcons = {
        order: GOOGLE_ICONS + "/googleIcons/order.png",
        sort: GOOGLE_ICONS + "/googleIcons/sort.png",
        progress: GOOGLE_ICONS + "/googleIcons/progress.png",
        play: GOOGLE_ICONS + "/googleIcons/play.png",
        forward: GOOGLE_ICONS + "/googleIcons/forward.png"
    };

    connectedCallback() {
        this.fetchInvoices();
    }

    fetchInvoices() {
        this.isPageLoaded = true;

        getInvoicesByIds({ invoiceIds: this.invoiceIds })
            .then(result => {
                this.invoiceItems = result.map(inv => ({
                    id: inv.Id,
                    name: inv.Name,
                    invoiceNo: inv.Invoice_No__c,
                    store: inv.Store__r?.Name,
                    lineItems: inv.Invoice_line_items__r?.map((item, index) => ({
                        rowIndex: index + 1, 
                        id: item.Id,
                        name: item.Name,
                        productId: item.SKU__c,
                        productName: item.SKU__r?.Name,
                        quantity: item.Quantity__c,
                        receivedSaleableQty: 0,
                        receivedNonSaleableQty: 0,
                        receivedQty: 0
                    })) || []
                }));
                this.isPageLoaded = false;
            })
            .catch(error => {
                this.showToast(
                    'Error',
                    error.body?.message || 'Unknown error',
                    'error'
                );
                this.isPageLoaded = false;
            });
    }


    handleReceivedSaleableQtyChange(event) {
        const invoiceId = event.target.dataset.invoice;
        const index = event.target.dataset.index;
        const value = parseFloat(event.detail.value);

        const invoice = this.invoiceItems.find(i => i.id === invoiceId);
        if (invoice) {
            invoice.lineItems[index].receivedSaleableQty = value;
            this.updateReceivedQty(invoiceId, index);
        }
    }

    handleReceivedNonSaleableQtyChange(event) {
        const invoiceId = event.target.dataset.invoice;
        const index = event.target.dataset.index;
        const value = parseFloat(event.detail.value);

        const invoice = this.invoiceItems.find(i => i.id === invoiceId);
        if (invoice) {
            invoice.lineItems[index].receivedNonSaleableQty = value;
            this.updateReceivedQty(invoiceId, index);
        }
    }

    updateReceivedQty(invoiceId, index) {
        const invoice = this.invoiceItems.find(i => i.id === invoiceId);
        if (!invoice) return;

        const line = invoice.lineItems[index];

        const saleable = parseFloat(line.receivedSaleableQty) || 0;
        const nonSaleable = parseFloat(line.receivedNonSaleableQty) || 0;

        line.receivedQty = saleable + nonSaleable;
    }



    handleSave() {
        if (!this.invoiceItems || this.invoiceItems.length === 0) {
            this.showToast('Error', 'No invoice data found', 'error');
            return;
        }

        const invoice = this.invoiceItems[0];
        const invoiceId = invoice.id;

        console.log('Sending invoiceId:', invoiceId);

        const payload = [];

        for (let item of invoice.lineItems) {
            // Check for invalid receivedQty
            if (
                item.receivedQty === undefined ||
                item.receivedQty === null ||
                item.receivedQty <= 0
            ) {
                this.showToast(
                    'Error',
                    `Received Quantity missing for item at row ${item.rowIndex}.`,
                    'error'
                );
                return; // Stop further execution
            }

            // Add valid items to the payload
            payload.push({
                sobjectType: 'Goods_Received_Note_Item__c',
                Invoice_Item__c: item.id,
                Product__c: item.productId,
                SKU_Name__c: item.productName,
                Invoiced_Quantity__c: item.quantity,
                Received_Nonsaleable_Quantity__c: item.receivedNonSaleableQty,
                Received_Saleable_Quantity__c: item.receivedSaleableQty,
                Received_Quantity__c : item.receivedQty
            });
        }


        console.log('Payload:', JSON.stringify(payload));

        if (payload.length === 0) {
            this.showToast('Error', 'No valid items to save.', 'error');
            return;
        }

        this.loading = true;

        createGRN({ invoiceId: invoiceId, items: payload })
            .then(() => {
                this.showToast('Success', 'GRN created successfully', 'success');
                setTimeout(() => {
                    this.dispatchEvent(new CustomEvent('grncreated', {
                        detail: {
                            message: 'GRN creation completed',
                            invoiceId: invoiceId
                        }
                    }));
                    this.loading = false;
                }, 1000);
            })
            .catch(error => {
                this.showToast('Error', error.body?.message || 'Unknown error', 'error');
                this.loading = false;
            });
    }




    handleCancel() {
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    // Custom Toast method (to use c-custom-toast)
    showToast(title, message, variant) {
        const toast = this.template.querySelector('c-custom-toast'); // Query the toast component
        console.log('Custom Toast component:', toast);  // Log the reference

        if (toast) {
            toast.showToast(variant, message); // Show the toast with the correct variant
        } else {
            console.error('Custom Toast component not found!');
        }
    }
}