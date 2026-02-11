import { LightningElement, track } from 'lwc';
import saveClaims from '@salesforce/apex/DMSPortalLwc.saveClaims';

export default class ClaimScreen extends LightningElement {
    @track claims = [
        {
            id: Date.now(),
            amount: '',
            description: ''
        }
    ];

    @track totalAmount = 0;
    isPageLoaded = false; // Set to true if loading screen used

    // Add new claim row
    addRow() {
        this.claims = [
            ...this.claims,
            {
                id: Date.now(),
                amount:'',
                description: ''
            }
        ];
        this.calculateTotals();
    }

    // Remove claim row
    removeRow(event) {
        const index = Number(event.currentTarget.dataset.index);
     
        if (this.claims.length === 1) {
            // Reset the only remaining row instead of removing it
            this.claims = [{
                id: Date.now(),
                amount: '',
                description: ''
            }];
        } else {
            this.claims.splice(index, 1);
            this.claims = [...this.claims];
        }
    }

    // Update claim amount and recalculate total
    handleAmountChange(event) {
        const index = event.target.dataset.index;
        const value = parseFloat(event.detail.value) || 0;
        this.claims[index].amount = value;
        this.calculateTotals();
    }

    // Update claim description
    handleDescriptionChange(event) {
        const index = event.target.dataset.index;
        this.claims[index].description = event.detail.value;
    }



   handleSave() {
    const payload = [];
    let validationPassed = true;  // Flag to track validation status

    // Loop through each claim item to validate
    for (const claim of this.claims) {
        // Validate that amount is filled
        if (!claim.amount) {
            this.showToast('Validation Error', 'Please Enter Amount for all rows.', 'error');
            validationPassed = false;  // Set validation flag to false
           // Set custom error flag for highlighting the field
        } 
       
        // Validate that description is filled
        if (!claim.description) {
            this.showToast('Validation Error', 'Please provide a description for all rows', 'error');
            validationPassed = false;  // Set validation flag to false
            
        }

        // Proceed with adding the valid claim to payload
        if (validationPassed) {
            payload.push({
                sobjectType: 'Claim__c',
                Status__c: claim.status,
                Claim_Date__c: claim.date,
                Claim_Amount__c: claim.amount,
                Description__c: claim.description
            });
        }
    }

    // If validation failed, stop the save process
    if (!validationPassed) {
        return;  // Prevent saving if validation fails
    }

    saveClaims({ claimData: payload })
        .then(() => {
            this.showToast('Success', 'Claims saved successfully', 'success');
            setTimeout(() => {
                this.dispatchEvent(new CustomEvent('claimcreated'));
                this.resetForm();
            }, 1000);
        })
        .catch((error) => {
            this.showToast('Error', error.body?.message || 'Failed to save claims', 'error');
        });
}

    // Cancel action (can be extended to navigate away)
    handleCancel() {
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    // Calculate total amount
    calculateTotals() {
        this.totalAmount = this.claims.reduce((sum, item) => {
            return sum + (item.amount || 0);
        }, 0);
    }

    // Show custom toast using the customToast component
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