import { LightningElement, api, track } from 'lwc';
import searchSecondaryCustomers from '@salesforce/apex/VisitFormController.searchSecondaryCustomers';

export default class SecondaryCustomerLookup extends LightningElement {

    @api primaryCustomerId;
    @api preselectedRecordId;
    @api preselectedRecordName;

    @track searchTerm = '';
    @track records = [];
    @track selectedRecord;

    showDropdown = false;
    delayTimeout;

    connectedCallback() {
        this.applyPreselection();
    }

    renderedCallback() {
        this.applyPreselection();
    }

    applyPreselection() {
        if (
            this.preselectedRecordId &&
            this.preselectedRecordName &&
            (!this.selectedRecord || this.selectedRecord.Id !== this.preselectedRecordId)
        ) {
            this.selectedRecord = {
                Id: this.preselectedRecordId,
                Name: this.preselectedRecordName
            };
            this.searchTerm = '';
            this.showDropdown = false;
        }
    }

    get comboboxClass() {
        return `slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click ${this.showDropdown ? 'slds-is-open' : ''}`;
    }

    handleInputChange(event) {
        this.searchTerm = event.target.value;

        if (!this.searchTerm || !this.primaryCustomerId) {
            this.records = [];
            this.showDropdown = false;
            return;
        }

        clearTimeout(this.delayTimeout);

        this.delayTimeout = setTimeout(() => {
            this.performSearch();
        }, 400);
    }

    handleFocus() {
        if (this.records.length > 0) {
            this.showDropdown = true;
        }
    }

    performSearch() {
        searchSecondaryCustomers({
            primaryCustomerId: this.primaryCustomerId,
            searchTerm: this.searchTerm
        })
        .then(result => {
            this.records = result;
            this.showDropdown = true;
        })
        .catch(error => {
            console.error('Search Error:', error);
        });
    }

    handleSelect(event) {
        const id = event.currentTarget.dataset.id;
        const name = event.currentTarget.dataset.name;

        this.selectedRecord = { Id: id, Name: name };
        this.searchTerm = '';
        this.showDropdown = false;

        this.dispatchEvent(new CustomEvent('select', {
            detail: this.selectedRecord
        }));
    }

    clearSelection() {
        this.selectedRecord = null;
        this.records = [];
        this.searchTerm = '';
        this.showDropdown = false;

        this.dispatchEvent(new CustomEvent('select', {
            detail: null
        }));
    }
}