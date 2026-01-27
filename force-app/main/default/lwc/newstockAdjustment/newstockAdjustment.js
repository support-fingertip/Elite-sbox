import { LightningElement, track } from 'lwc';
import getStockAdjustments from '@salesforce/apex/DMSPortalLwc.getStockData';
import saveSecondaryReturn from '@salesforce/apex/DMSPortalLwc.saveSecondaryReturn';
import saveStockAdjustments from '@salesforce/apex/DMSPortalLwc.saveStockAdjustments';
export default class NewStockAdjustment extends LightningElement {

    @track stockAdjustments = [];
    adjustmentTypeOptions = [];
    productsList = [];
    distributorId;

    totalQuantity = 0;
    totalAmount = 0;
    isPageLoaded = false;

    connectedCallback() {
        this.isPageLoaded = true;
        this.addRow();

        getStockAdjustments()
            .then(result => {
                this.adjustmentTypeOptions = result.adjustmentTypes;
                this.productsList = result.distributorStocks;
                this.distributorId = result.distributorId;
                this.isPageLoaded = false;
            })
            .catch(error => {
                this.isPageLoaded = false;
                this.showToast('Error', error.body?.message, 'error');
            });
    }

    addRow() {
        this.stockAdjustments.push({
            id: Date.now(),
            rowIndex: this.stockAdjustments.length + 1,
            productId: '',
            productName: '',
            adjustmentType: '',
            availableQuantity: 0,
            quantity: 0,
            reason: '',
            unitPrice: 0,
            amount: 0,
            showSuggestions: false,
            filteredProducts: [],
            disableProductSelection: true
        });
        this.refreshIndexes();
    }

    removeRow(event) {
        const index = Number(event.currentTarget.dataset.index);
        if (this.stockAdjustments.length > 1) {
            this.stockAdjustments.splice(index, 1);
        }
        this.refreshIndexes();
    }

    refreshIndexes() {
        this.stockAdjustments = this.stockAdjustments.map((item, i) => ({
            ...item,
            rowIndex: i + 1
        }));
        this.calculateTotals();
    }

    handleAdjustmentTypeChange(event) {
        const index = event.currentTarget.dataset.index;
        var adjustmentvalue = event.detail.value;
        this.stockAdjustments[index].adjustmentType = adjustmentvalue;
        this.stockAdjustments[index].productName = '';
        this.stockAdjustments[index].productId = '';
        this.stockAdjustments[index].quantity = 0;
        this.stockAdjustments[index].availablequantity = 0;

        if (adjustmentvalue != '') {
            this.stockAdjustments[index].disableProductSelection = false;
        }
        else {
            this.stockAdjustments[index].disableProductSelection = true;
        }
        this.stockAdjustments = [...this.stockAdjustments];
    }

    handleProductSearch(event) {
        const index = event.currentTarget.dataset.index;
        const searchKey = event.target.value.toLowerCase();
        const item = this.stockAdjustments[index];

        item.productName = event.target.value;

        if (searchKey) {
            item.filteredProducts = this.productsList.filter(
                p => p.Product_Name__c.toLowerCase().includes(searchKey)
            );
            item.showSuggestions = true;
        } else {
            item.showSuggestions = false;
            item.filteredProducts = [];
        }

        this.stockAdjustments = [...this.stockAdjustments];
    }

    selectProduct(event) {
        const index = event.currentTarget.dataset.index;
        const productId = event.currentTarget.dataset.id;
        const saleableQty = event.currentTarget.dataset.saleableqty || 0;
        const nonSaleableQty = event.currentTarget.dataset.nonsaleableqty || 0;

        const product = this.productsList.find(p => p.Product__c === productId);

        const duplicate = this.stockAdjustments.some(
            (i, idx) => idx !== Number(index) && i.productId === productId
        );
        if (duplicate) {
            this.showToast('Error', 'Product already selected', 'error');
            return;
        }

        const item = this.stockAdjustments[index];

        item.productId = product.Product__c;
        item.productName = product.Product_Name__c;
        if (item.adjustmentType == 'Saleable to Non-Saleable Quantity') {
            item.availablequantity = saleableQty;
        }
        else if (item.adjustmentType == 'Non-Saleable to Saleable Quantity' || item.adjustmentType == 'Written Off Quantity') {
            item.availablequantity = nonSaleableQty;
        }
        item.showSuggestions = false;
        item.filteredProducts = [];
    }

    handleQuantityChange(event) {
        const index = event.currentTarget.dataset.index;
        const qty = Number(event.detail.value) || 0;

        const item = this.stockAdjustments[index];
        item.quantity = qty;
        item.amount = qty * item.unitPrice;

        this.stockAdjustments = [...this.stockAdjustments];
        this.calculateTotals();
    }

    handleReasonChange(event) {
        const index = event.currentTarget.dataset.index;
        this.stockAdjustments[index].reason = event.detail.value;
        this.stockAdjustments = [...this.stockAdjustments];
    }


    calculateTotals() {
        this.totalQuantity = this.stockAdjustments.reduce(
            (sum, i) => sum + (i.quantity || 0), 0
        );
        this.totalAmount = this.stockAdjustments.reduce(
            (sum, i) => sum + (i.amount || 0), 0
        );
    }

    handleSave() {
        const payload = [];
        let validationPassed = true;

        for (let item of this.stockAdjustments) {
            // Add this line to inspect the data
            if (!item.adjustmentType) {
                this.showToast(
                    'Validation Error',
                    `Row ${item.rowIndex}: Please select Adjustment Type.`,
                    'error'
                );
                return;
            }
            if (!item.productId) {
                this.showToast(
                    'Validation Error',
                    `Row ${item.rowIndex}: Please select a Product.`,
                    'error'
                );
                return;
            }

            if (!item.quantity || item.quantity <= 0) {
                this.showToast(
                    'Validation Error',
                    `Row ${item.rowIndex}: Please add a valid Quantity.`,
                    'error'
                );
                return;
            }
            if (item.quantity && item.quantity > 0 && item.availablequantity < item.quantity) {
                this.showToast(
                    'Validation Error',
                    `Row ${item.rowIndex}: Entered Quantity is more than Available Quantity`,
                    'error'
                );
                return;
            }
 

            payload.push({
                sobjectType: 'Stock_Adjustment__c',
                Distributor__c: this.distributorId,
                Product__c: item.productId,
                Product_Name__c :  item.productName,
                Quantity__c: item.quantity,
                Reason__c: item.reason,
                Adjustment_Type__c: item.adjustmentType,
            });
        }

        if (!validationPassed) {
            return; // Skip further code execution if validation failed
        }
        saveStockAdjustments({
            stockAdjustments: payload,
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