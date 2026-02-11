import { LightningElement, track } from 'lwc';
import getAllProducts from '@salesforce/apex/DMSPortalLwc.getAllProducts';
import saveSecondaryReturn from '@salesforce/apex/DMSPortalLwc.saveSecondaryReturn';
import searchCustomers from '@salesforce/apex/DMSPortalLwc.searchCustomers';

export default class SecondaryReturns extends LightningElement {
    @track returnItems = [];
    @track productOptions = [];
    @track notes = '';
    @track customerSearch = '';
    @track customerOptions = [];
    @track filteredCustomers = [];
    @track selectedCustomerId = '';
    @track showCustomerSuggestions = false;
    resonForReturnOptions = [];
    uomOptions = [];

    returnReasonOptions = [
        { label: 'Damaged', value: 'Damaged' },
        { label: 'Expired', value: 'Expired' },
        { label: 'Non-moving', value: 'Non-moving' }
    ];

    @track totalQuantity = 0;
    @track totalAmount = 0;
    isPageLoaded = false;

    connectedCallback() {
        this.addRow();
        getAllProducts()
            .then(result => {
                this.resonForReturnOptions = result.resonForReturn;
                this.uomOptions = result.uom;
                this.productOptions = result.productsList.map(prod => ({
                    label: prod.Name,
                    value: prod.Id,
                    price: prod.List_Price__c,
                    uom: prod.UOM__c
                }));
            })
            .catch(error => {
                this.showToast('Error loading products', error.body.message, 'error');
            });
    }

    addRow() {
        this.returnItems.push({
            id: Date.now(),
            productId: '',
            productName: '',
            saleableQuantity: 0,
            nonSaleableQuantity: 0,
            quantity: 0,
            unitPrice: 0,
            amount: 0,
            uom: '',
            reason: '',
            showSuggestions: false,
            filteredProducts: []
        });
        this.returnItems = [...this.returnItems];
        this.updateRowIndex();
        this.calculateTotals();
    }

    removeRow(event) {
        const index = Number(event.currentTarget.dataset.index);
        if (this.returnItems.length === 1) {
            this.returnItems[0] = {
                id: Date.now(),
                productId: '',
                productName: '',
                quantity: 0,
                saleableQuantity: 0,
                nonSaleableQuantity: 0,
                unitPrice: 0,
                amount: 0,
                uom: '',
                reason: '',
                showSuggestions: false,
                filteredProducts: []
            };
        } else {
            this.returnItems.splice(index, 1);
        }
        this.returnItems = [...this.returnItems];
        this.updateRowIndex();
        this.calculateTotals();
    }

    updateRowIndex() {
        this.returnItems = this.returnItems.map((item, index) => ({
            ...item,
            rowIndex: index + 1
        }));
    }

    handleProductFocus(event) {
        const index = event.target.dataset.index;
        this.returnItems[index].showSuggestions = false;
        this.returnItems = [...this.returnItems];
    }

    handleProductSearch(event) {
        const index = event.target.dataset.index;  // Get the index of the current row
        const searchValue = event.target.value.toLowerCase();  // Get the search value
        const item = this.returnItems[index];  // Get the current row item
        item.productName = event.target.value;  // Update the product name

        if (searchValue.length > 0) {
            const filtered = this.productOptions.filter(prod =>
                prod.label.toLowerCase().includes(searchValue)  // Filter products based on search input
            );
            item.filteredProducts = filtered;
            item.showSuggestions = filtered.length > 0;
        } else {
            // If search is cleared (cross icon clicked), reset product-related fields
            item.filteredProducts = [];
            item.showSuggestions = false;
            item.productId = '';  // Clear the productId
            item.productName = '';  // Clear the productName
            item.unitPrice = 0;  // Reset unit price
            item.uom = '';  // Reset UOM
            item.amount = 0;  // Reset amount
        }

        this.returnItems = [...this.returnItems];  // Re-render the list
        this.calculateTotals();  // Recalculate totals after change
    }


    selectProduct(event) {
        const index = event.currentTarget.dataset.index;
        const selectedId = event.currentTarget.dataset.id;
        const selectedProduct = this.productOptions.find(p => p.value === selectedId);

        const isDuplicate = this.returnItems.some((item, i) => i !== parseInt(index) && item.productId === selectedId);
        if (isDuplicate) {
            const productLabel = selectedProduct.label || 'Unknown Product'; // Fallback value

            this.showToast('Error', 'Product "' + productLabel + '" already selected', 'error');
            this.returnItems[index].productName = '';
            this.returnItems[index].showSuggestions = false;
            return;
        }

        const item = this.returnItems[index];
        item.productId = selectedId;
        item.productName = selectedProduct.label;
        item.unitPrice = selectedProduct.price;
        item.uom = selectedProduct.uom;
        item.amount = item.quantity * item.unitPrice;
        item.showSuggestions = false;
        item.filteredProducts = [];

        this.returnItems = [...this.returnItems];
        this.calculateTotals();
    }

    handleSalableQuantityChange(event) {
        const index = Number(event.currentTarget.dataset.index);
        const qty = parseFloat(event.detail.value) || 0;

        this.returnItems[index].saleableQuantity = qty;
        this.recalculateQuantityAndAmount(index);
    }
    handleNonSalableQuantityChange(event) {
        const index = Number(event.currentTarget.dataset.index);
        const qty = parseFloat(event.detail.value) || 0;

        this.returnItems[index].nonSaleableQuantity = qty;
        this.recalculateQuantityAndAmount(index);
    }


    recalculateQuantityAndAmount(index) {
        const item = this.returnItems[index];

        const saleable = Number(item.saleableQuantity) || 0;
        const nonSaleable = Number(item.nonSaleableQuantity) || 0;

        const totalQty = saleable + nonSaleable;

        item.quantity = totalQty;
        item.amount = totalQty * (Number(item.unitPrice) || 0);

        this.returnItems = [...this.returnItems];
        this.calculateTotals();
    }

    handleReasonChange(event) {
        const index = event.currentTarget.dataset.index;
        this.returnItems[index].reason = event.detail.value;
    }

    handleNotesChange(event) {
        this.notes = event.target.value;
    }

    calculateTotals() {
        this.totalQuantity = this.returnItems.reduce((acc, item) => acc + (item.quantity || 0), 0);
        this.totalAmount = this.returnItems.reduce((acc, item) => acc + (item.amount || 0), 0);
    }



    handleCustomerFocus() {
        this.showCustomerSuggestions = false;
    }

    handleCustomerSearch(event) {
        this.customerSearch = event.target.value;
        const searchVal = this.customerSearch?.trim();

        // Reset if empty or cleared
        if (!searchVal || searchVal.length < 2) {
            this.filteredCustomers = [];
            this.showCustomerSuggestions = false;
            this.selectedCustomerId = '';
            return;
        }

        // Call Apex search
        searchCustomers({ searchKey: searchVal })
            .then(result => {
                this.filteredCustomers = result.map(acc => ({
                    label: acc.Name,
                    value: acc.Id
                }));
                this.customerOptions = this.filteredCustomers;
                this.showCustomerSuggestions = this.filteredCustomers.length > 0;
            })
            .catch(error => {
                console.error('Customer search error', error);
                this.filteredCustomers = [];
                this.showCustomerSuggestions = false;
            });
    }


    selectCustomer(event) {
        const selectedId = event.currentTarget.dataset.id;
        const selected = this.customerOptions.find(acc => acc.value === selectedId);
        this.customerSearch = selected.label;
        this.selectedCustomerId = selected.value;
        this.showCustomerSuggestions = false;
    }


    handleSave() {

        if (!this.selectedCustomerId) {
            this.showToast('Validation Error', 'Please select a Secondary Customer.', 'error');
            return;
        }
        const payload = [];
        let validationPassed = true;

        for (let item of this.returnItems) {
            // Add this line to inspect the data

            if (!item.productId ) {
                this.showToast(
                    'Validation Error',
                    `Row ${item.rowIndex}: Please select a Product.`,
                    'error'
                );
                return;
            }

            if (!item.quantity ||  item.quantity <= 0 ) {
                this.showToast(
                    'Validation Error',
                    `Row ${item.rowIndex}: Please add a valid Salable Quantity Or Non-Salable Quantity.`,
                    'error'
                );
                return;
            }
            if (!item.reason) {
                this.showToast(
                    'Validation Error',
                    `Row ${item.rowIndex}: Please select a Reason.`,
                    'error'
                );
                return;
            }

            payload.push({
                sobjectType: 'Return_Item__c',
                SKU__c: item.productId,
                SKU_Name__c: item.productName,
                Quantity__c: item.quantity,
                Nonsaleable_Quantity__c: item.nonSaleableQuantity,
                Saleable_Quantity__c: item.saleableQuantity,
                Batch_Number__c: '',
                Invoice_Number__c: '',
                Reason_For_Return__c: item.reason,
                UOM__c: item.uom,
                Unit_Price__c: item.unitPrice,
                Total_Amount__c: item.amount
            });
        }


        if (!validationPassed) {
            return; // Skip further code execution if validation failed
        }
        this.isPageLoaded = true;
        saveSecondaryReturn({
            items: payload,
            totalAmount: this.totalAmount,
            totalQuantity: this.totalQuantity,
            customerId: this.selectedCustomerId
        })
            .then(() => {
                this.isPageLoaded = false;
                setTimeout(() => {
                    this.dispatchEvent(new CustomEvent('returncreated'));
                }, 0);
            })
            .catch(error => {
                this.showToast('Error', error.body?.message || error.message, 'error');
            });
    }


    handleCancel() {
        this.dispatchEvent(new CustomEvent('cancel'));
    }



    // Custom Toast method (to use c-custom-toast)
    showToast(title, message, variant) {
        const toast = this.template.querySelector('c-custom-toast');
        console.log('Custom Toast component:', toast);
        if (toast) {
            toast.showToast(variant, message);
        } else {
            console.error('Custom Toast component not found!');
        }
    }
}