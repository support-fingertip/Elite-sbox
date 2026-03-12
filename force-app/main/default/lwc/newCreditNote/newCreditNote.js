import { LightningElement, track } from 'lwc';
import searchCustomers from '@salesforce/apex/DMSPortalLwc.searchCustomers';
import saveCreditNote from '@salesforce/apex/DMSPortalLwc.saveCreditNote';

export default class NewCreditNote extends LightningElement {
    @track customerSearch = '';
    @track selectedCustomerId = '';
    @track filteredCustomers = [];
    @track showCustomerSuggestions = false;

    @track noteDate = '';
    @track reason = '';
    @track amount = null;
    @track description = '';

    isPageLoaded = false;

    reasonOptions = [
        { label: 'Price Difference', value: 'Price Difference' }
    ];

    connectedCallback() {
        const today = new Date();
        this.noteDate = today.toLocaleDateString('en-CA');
    }

    // Customer Search
    handleCustomerSearch(event) {
        this.customerSearch = event.target.value;
        const searchVal = this.customerSearch?.trim();

        if (!searchVal || searchVal.length < 2) {
            this.filteredCustomers = [];
            this.showCustomerSuggestions = false;
            this.selectedCustomerId = '';
            return;
        }

        searchCustomers({ searchKey: searchVal })
            .then(result => {
                this.filteredCustomers = result.map(acc => ({
                    label: acc.Name,
                    value: acc.Id
                }));
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
        const selected = this.filteredCustomers.find(acc => acc.value === selectedId);
        this.customerSearch = selected.label;
        this.selectedCustomerId = selected.value;
        this.showCustomerSuggestions = false;
    }

    handleReasonChange(event) {
        this.reason = event.detail.value;
    }

    handleAmountChange(event) {
        this.amount = parseFloat(event.detail.value) || 0;
    }

    handleDescriptionChange(event) {
        this.description = event.detail.value;
    }

    handleSave() {
        if (!this.selectedCustomerId) {
            this.showToast('Validation Error', 'Please select a Secondary Customer.', 'error');
            return;
        }
        if (!this.reason) {
            this.showToast('Validation Error', 'Please select a Reason.', 'error');
            return;
        }
        if (!this.amount || this.amount <= 0) {
            this.showToast('Validation Error', 'Please enter a valid Amount.', 'error');
            return;
        }

        this.isPageLoaded = true;

        const creditNoteData = {
            customerId: this.selectedCustomerId,
            noteDate: this.noteDate,
            reason: this.reason,
            amount: this.amount,
            description: this.description || ''
        };

        saveCreditNote({ creditNoteJson: JSON.stringify(creditNoteData) })
            .then(() => {
                this.showToast('Success', 'Credit Note created successfully.', 'success');
                this.isPageLoaded = false;
                this.dispatchEvent(new CustomEvent('creditnotecreated'));
            })
            .catch(error => {
                console.error('Save error', error);
                const msg = error.body?.message || 'An error occurred while saving.';
                this.showToast('Error', msg, 'error');
                this.isPageLoaded = false;
            });
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    showToast(title, message, variant) {
        const toastEl = this.template.querySelector('c-custom-toast');
        if (toastEl) {
            toastEl.showToast(title, message, variant);
        }
    }
}