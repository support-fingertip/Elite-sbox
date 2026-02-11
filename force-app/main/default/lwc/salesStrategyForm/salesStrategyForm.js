import { LightningElement, track } from 'lwc';
import getInitialData from '@salesforce/apex/SalesStrategyController.getInitialData';
import saveStrategies from '@salesforce/apex/SalesStrategyController.saveStrategies';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';


export default class SalesStrategyForm extends LightningElement {
    @track strategyRows = [];
    @track salesChannelOptions = [];
    @track regionOptions = [
        { label: 'TN', value: 'TN' },
        { label: 'AP', value: 'AP' },
        { label: 'KAR', value: 'KAR' },
        { label: 'KL', value: 'KL' }
    ];

    @track areaOptions ;


    @track customerCategoryOptions ;


    selectedChannel = '';
    rowIndex = 0;

    connectedCallback() {
        this.addRow(); // Initial default row
        this.loadInitialData();
    }

    loadInitialData() {
        getInitialData()
            .then(result => {
                this.salesChannelOptions = result.salesChannels;
                this.areaOptions = result.areaOptions; // Dynamically loaded from Apex
                this.customerCategoryOptions = result.customerCategories;
            })
            .catch(error => {
                alert('Error loading initial data:', error);
            });
    }

    get typeOptions() {
        return [
            { label: 'Area', value: 'Area' },
            { label: 'User', value: 'User' },
            { label: 'Customer', value: 'Customer' },
            { label: 'Customer Category', value: 'Customer Category' }
        ];
    }

    handleChannelChange(event) {
        this.selectedChannel = event.detail.value;
    }

    addRow() {
    this.strategyRows = [
        ...this.strategyRows,
        {
            index: this.rowIndex++,
            Product__c: null,
            Sales_Channel__c: this.selectedChannel, // Optional default
            Focus_Type__c: null,
            Type__c: 'Area',
            Area__c: null,
            Customer_Category__c: null,
            Region__c: null,
            User__c: null,
            Account__c: null,
            From_Date__c: null,
            To_Date__c: null,
            Must_Focused__c: null,
            showRegion: true,
            showArea: true,
            showUser: false,
            showCustomer: false,
            canDelete: this.strategyRows.length > 0
        }
    ];
}


    deleteRow(event) {
        const index = parseInt(event.currentTarget.dataset.index, 10);
        this.strategyRows = this.strategyRows.filter(row => row.index !== index);
    }

    handleTypeChange(event) {
        const index = parseInt(event.target.dataset.index, 10);
        const value = event.detail.value;

        this.strategyRows = this.strategyRows.map(row => {
            if (row.index === index) {
                return {
                    ...row,
                    Type__c: value,
                    showRegion: value === 'Region',
                    showUser: value === 'User',
                    showCustomer: value === 'Customer',
                    showCustomerCategory: value === 'Customer Category',
                    showArea: value === 'Area',
                    Region__c: null,
                    User__c: null,
                    Account__c: null
                };
            }
            return row;
        });
    }

    handleInputChange(event) {
        const index = parseInt(event.target.dataset.index, 10);
        const field = event.target.name;
        const value = event.detail.value;

        this.strategyRows = this.strategyRows.map(row =>
            row.index === index ? { ...row, [field]: value } : row
        );
    }
get focusTypeOptions() {
    return [
        { label: 'Focused Sell', value: 'Focused Sell' },
        { label: 'Must Sell', value: 'Must Sell' }
    ];
}
    // Add both handlers
handleLookupChange(event) {
    const index = parseInt(event.detail.index, 10);
    const field = event.detail.field;
    const value = event.detail.value;
    const label = event.detail.label;

    this.strategyRows = this.strategyRows.map((row, i) => {
        if (i === index) {
            return {
                ...row,
                [field]: value,
                [`${field}_Name`]: label
            };
        }
        return row;
    });
}




    saveStrategies() {
    // First check if there are any rows
   

    let isValid = true;
    let errorMessage = '';
    let invalidRowIndex = -1;

    // Validate each row
    this.strategyRows.forEach((row, index) => {
        if (!isValid) return; // Exit early if already invalid

        // Basic required field validation
        if (!row.Sales_Channel__c) {
            isValid = false;
            errorMessage = `Row ${index + 1}: Sales Channel is required`;
            invalidRowIndex = index;
            return;
        }


        if (!row.Product__c) {
            isValid = false;
            errorMessage = `Row ${index + 1}: Product is required`;
            invalidRowIndex = index;
            return;
        }

        if (!row.Must_Focused__c) {
            isValid = false;
            errorMessage = `Row ${index + 1}: Must/Focused selection is required`;
            invalidRowIndex = index;
            return;
        }

        if (!row.Type__c) {
            isValid = false;
            errorMessage = `Row ${index + 1}: Type is required`;
            invalidRowIndex = index;
            return;
        }

        // Type-specific validation
        if (row.Type__c === 'Area' && !row.Area__c) {
            isValid = false;
            errorMessage = `Row ${index + 1}: Area is required when Type is "Area"`;
            invalidRowIndex = index;
            return;
        }

        if (row.Type__c === 'User' && !row.User__c) {
            isValid = false;
            errorMessage = `Row ${index + 1}: User is required when Type is "User"`;
            invalidRowIndex = index;
            return;
        }

        if (row.Type__c === 'Customer' && !row.Account__c) {
            isValid = false;
            errorMessage = `Row ${index + 1}: Customer is required when Type is "Customer"`;
            invalidRowIndex = index;
            return;
        }

        if (row.Type__c === 'Customer Category' && !row.Customer_Category__c) {
            isValid = false;
            errorMessage = `Row ${index + 1}: Customer Category is required when Type is "Customer Category"`;
            invalidRowIndex = index;
            return;
        }

        // Date validation
        if (!row.From_Date__c || !row.To_Date__c) {
            isValid = false;
            errorMessage = `Row ${index + 1}: Both From Date and To Date are required`;
            invalidRowIndex = index;
            return;
        }

        const fromDate = new Date(row.From_Date__c);
        const toDate = new Date(row.To_Date__c);

        if (fromDate > toDate) {
            isValid = false;
            errorMessage = `Row ${index + 1}: To Date must be after From Date`;
            invalidRowIndex = index;
            return;
        }

        // Add any additional business rule validations here
    });

    if (!isValid) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Validation Error',
                message: errorMessage,
                variant: 'error'
            })
        );
        
        // Optional: Scroll to the invalid row
        if (invalidRowIndex >= 0) {
            const invalidElement = this.template.querySelector(`[data-index="${invalidRowIndex}"]`);
            if (invalidElement) {
                invalidElement.scrollIntoView({ behavior: 'smooth', block: 'center' });
                invalidElement.focus();
            }
        }
        
        return;
    }

    // Prepare data for saving
    const payload = this.strategyRows.map(row => ({
        Name: row.Must_Focused__c === 'Must Sell' ? 'Must Sell Strategy' : 'Focused Sell Strategy',
        Sales_Channel__c: row.Sales_Channel__c,
        Product__c: row.Product__c,
        Must_Focused__c: row.Must_Focused__c,
        Type__c: row.Type__c,
        Region__c: row.Type__c === 'Region' ? row.Region__c : null,
        Area__c: row.Type__c === 'Area' ? row.Area__c : null,
        User__c: row.Type__c === 'User' ? row.User__c : null,
        Account__c: row.Type__c === 'Customer' ? row.Account__c : null,
        Customer_Category__c: row.Type__c === 'Customer Category' ? row.Customer_Category__c : null,
        From_Date__c: row.From_Date__c,
        To_Date__c: row.To_Date__c
    }));

    // Show loading indicator
    this.isLoading = true;

    // Call Apex method
    saveStrategies({ strategies: payload })
        .then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Sales strategies saved successfully',
                    variant: 'success'
                })
            );
            
            // Reset form
            this.strategyRows = [];
            this.addRow();
        const msg = {
    message: 'close',
    id: ''   
};
        // Close modal if needed
    const event = new CustomEvent('ClickAction', { 
            detail : msg
            });
            this.dispatchEvent(event);
    })
    .catch(error => {
            console.error('Error saving strategies:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error Saving Data',
                    message: this.getErrorMessage(error),
                    variant: 'error'
                })
            );
        })
        .finally(() => {
            this.isLoading = false;
        });
}

handleClickCancel(){
    const msg = {
        message: 'close',
        id: ''   
    };
    const event = new CustomEvent('ClickAction', { 
            detail : msg
        });
    this.dispatchEvent(event);

}

// Helper method to parse error messages
getErrorMessage(error) {
    if (Array.isArray(error.body)) {
        return error.body.map(e => e.message).join(', ');
    } else if (error.body && typeof error.body.message === 'string') {
        return error.body.message;
    }
    return 'Unknown error occurred while saving strategies';
}

}