import { LightningElement, api, track } from 'lwc';

export default class LwcMultiSelectLookup extends LightningElement {
    @api labelName; // Label for the input
    @api iconName = 'standard:account'; // Default icon
    @api pdpOptions = []; // List of PDP values passed from the parent
    @api pdpDayValues = ''; // Previously selected values (comma-separated)

    @track selectedItems = []; // Stores selected PDP values
    @track filteredOptions = []; // Stores filtered search results
    searchInput = ''; // Search input text
    isDisplayMessage = false; // Flag to show 'No Records Found'

    connectedCallback() {
        // Convert comma-separated values to array of objects
        if (this.pdpDayValues) {
            const selectedValuesArray = this.pdpDayValues.split(',').map(value => value.trim());
            this.selectedItems = this.pdpOptions.filter(option => selectedValuesArray.includes(option.value));
        }
    }

    onchangeSearchInput(event) {
        this.searchInput = event.target.value.toLowerCase();
        if (this.searchInput.length > 0) {
            this.filteredOptions = this.pdpOptions.filter(option =>
                option.label.toLowerCase().includes(this.searchInput)
            );
            this.isDisplayMessage = this.filteredOptions.length === 0;
        } else {
            this.filteredOptions = [];
            this.isDisplayMessage = false;
        }
    }

    handleSelect(event) {
        const selectedValue = event.currentTarget.dataset.value;
        const selectedOption = this.pdpOptions.find(option => option.value === selectedValue);
        if (selectedOption && !this.selectedItems.some(item => item.value === selectedValue)) {
            this.selectedItems = [...this.selectedItems, selectedOption];
            this.updateParent();
        }
        this.searchInput = '';
        this.filteredOptions = [];
    }

    handleRemoveRecord(event) {
        const removeValue = event.target.dataset.item;
        this.selectedItems = this.selectedItems.filter(item => item.value !== removeValue);
        this.updateParent();
    }

    updateParent() {
        const selectedValuesString = this.selectedItems.map(item => item.value).join(',');
        this.dispatchEvent(new CustomEvent('updatepdpdays', { detail: selectedValuesString }));
    }
}