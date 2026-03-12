import { LightningElement, track } from 'lwc';

export default class NewDebitNote extends LightningElement {
    @track isPageLoaded = false;
    @track customerSearch = '';
    @track showCustomerSuggestions = false;
    @track filteredCustomers = [];
    @track noteDate = new Date().toISOString().split('T')[0];
    @track reason = '';
    @track reasonOptions = [
        { label: 'Price Difference', value: 'Price Difference' },
        { label: 'Short Payment', value: 'Short Payment' },
        { label: 'Penalty', value: 'Penalty' },
        { label: 'Other', value: 'Other' }
    ];
    @track amount = '';
    @track description = '';

    handleCustomerSearch(event) {
        this.customerSearch = event.target.value;
    }

    selectCustomer(event) {
        // select customer logic
    }

    handleReasonChange(event) {
        this.reason = event.detail.value;
    }

    handleAmountChange(event) {
        this.amount = event.target.value;
    }

    handleDescriptionChange(event) {
        this.description = event.target.value;
    }

    handleSave() {
        // save logic - call Apex to create Debit Note
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('cancel'));
    }
}