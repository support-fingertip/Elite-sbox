import { LightningElement, track, api } from 'lwc';
import getSecondaryOrders from '@salesforce/apex/DMSPortalLwc.getSecondaryOrders';
import getOrderItems from '@salesforce/apex/DMSPortalLwc.getOrderItems';
import saveSecondaryInvoice from '@salesforce/apex/DMSPortalLwc.saveSecondaryInvoice';


export default class DmsPortal extends LightningElement {
    @api selectedOrderIds;
    @api selectedCustomerName;
    @api selectedCustomerId;
    @track orderList = [];
    @track selectedOrders = [];
    @track invoiceItems = [];
    remarks = '';
    customerName = '';
    invoiceDate = new Date().toISOString().split('T')[0];

    // Replaced this.showInvoiceScreen with this.isGenerateInvoice
    isSubPartLoad = false;

    connectedCallback() {
        this.getorderItems()
    }




    getorderItems() {
        getOrderItems({ orderIds: this.selectedOrderIds })
            .then(data => {
                const aggregatedMap = new Map();

                data.forEach(item => {
                    const key = item.ProductId;

                    if (aggregatedMap.has(key)) {
                        const existing = aggregatedMap.get(key);

                        existing.Quantity += Number(item.Quantity);
                        existing.TaxAmount += Number(item.TaxAmount);
                        existing.TotalAmount += Number(item.TotalAmount);
                        // Available qty should NOT be summed (same stock)
                    } else {
                        aggregatedMap.set(key, {
                            ...item,
                            Quantity: Number(item.Quantity),
                            TaxAmount: Number(item.TaxAmount),
                            TotalAmount: Number(item.TotalAmount),
                            availableQuantity: Number(item.availableQuantity)
                        });
                    }
                });

                this.invoiceItems = Array.from(aggregatedMap.values()).map(item => ({
                    ...item,
                    TaxAmount: item.TaxAmount.toFixed(2),
                    TotalAmount: item.TotalAmount.toFixed(2)
                }));

                this.customerName = this.invoiceItems[0]?.CustomerName || '';
                this.isGenerateInvoice = true;
            })
            .catch(error => {
                console.error('Error fetching order items:', error);
                this.showToast('Error', 'Failed to load order items', 'error');
            });
    }



    handleQuantityChange(event) {
        const itemId = event.target.dataset.id;
        const newQty = Number(event.target.value);

        this.invoiceItems = this.invoiceItems.map(item => {
            if (item.OrderItemId === itemId) {

                //  Validation: Qty should not exceed Available Qty
                if (newQty > item.availableQuantity) {
                    this.showToast(
                        'Validation Error',
                        "Invoice Qty can't be more than Available Qty.",
                        'error'
                    );
                    return item;
                }

                //  Valid quantity → update values
                item.Quantity = newQty;
                item.TaxAmount = (
                    item.UnitPrice * newQty * item.TaxPercent / 100
                ).toFixed(2);
                item.TotalAmount = (
                    item.UnitPrice * newQty * (1 + item.TaxPercent / 100)
                ).toFixed(2);
            }
            return item;
        });
    }




    handleSave() {
        try {
            console.log('handleSave called');

            // Validate invoice items
            if (!this.invoiceItems || this.invoiceItems.length === 0) {
                this.showToast('Validation Error', 'No items to save.', 'error');
                return;
            }

            const payload = [];

            for (let item of this.invoiceItems) {

                // Quantity validation
                if (!item.Quantity || item.Quantity <= 0) {
                    this.showToast(
                        'Validation Error',
                        'Please add a valid Quantity.',
                        'error'
                    );
                    return;
                }

                //  Available Quantity validation
                if (item.availableQuantity !== undefined && item.Quantity > item.availableQuantity) {
                    this.showToast(
                        'Validation Error',
                        `Invoice Qty for ${item.ProductName} can't be more than Available Qty (${item.availableQuantity}).`,
                        'error'
                    );
                    return; //  Stop save
                }

                payload.push({
                    sobjectType: 'Secondary_Invoice_Item__c',
                    Product__c: item.ProductId,
                    Product_Name__c: item.ProductName,
                    Store__c: item.customerName,
                    Quantity__c: item.Quantity,
                    Unit_Price__c: item.UnitPrice,
                    Tax_Amount__c: item.TaxAmount,
                    Order_Item__c: item.OrderItemId,
                    Total_Amount__c: item.TotalAmount
                });
            }

            const secondaryInvoicePayload = {
                sobjectType: 'Secondary_Invoice__c',
                Store__c: this.selectedCustomerId,
                Invoice_Date__c: this.invoiceDate,
                Customer_Name__c: this.selectedCustomerName,
                Status__c: 'Raised',
                Remarks__c : this.remarks
            };

            if (!secondaryInvoicePayload.Store__c || !secondaryInvoicePayload.Invoice_Date__c) {
                this.showToast(
                    'Validation Error',
                    'Missing required fields: Store or Invoice Date.',
                    'error'
                );
                return;
            }

            saveSecondaryInvoice({
                invoices: [secondaryInvoicePayload],
                items: payload
            })
                .then(() => {
                    this.showToast(
                        'Success',
                        'Secondary Invoice saved successfully.',
                        'success'
                    );

                    setTimeout(() => {
                        this.dispatchEvent(new CustomEvent('returncreated'));
                        this.resetForm();
                    }, 1000);
                })
                .catch(error => {
                    console.error(error);
                    this.showToast(
                        'Error',
                        error.body?.message || error.message,
                        'error'
                    );
                });

        } catch (error) {
            console.error(error);
            this.showToast(
                'Error',
                'Failed to save. Please try again.',
                'error'
            );
        }
    }
    onUpdateRemakrs(event)
    {
        var remarks = event.target.value;
        this.remarks = remarks;
    }
    

    handleCancel() {
        // this.resetToOrderList();
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    resetToOrderList() {
        this.selectedOrders = [];
        this.selectedCustomerId = null;
        this.customerName = '';
        this.invoiceItems = [];
        this.isGenerateInvoice = false; // Reset to hide the invoice screen
    }
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