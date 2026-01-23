import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getEditPermission from '@salesforce/apex/AccountEditAccessController.getEditPermission';
import USER_ID from '@salesforce/user/Id';

export default class AccountEditAccess extends NavigationMixin(LightningElement) {
    @api recordId;
    showWarning = false;

    connectedCallback() {
        getEditPermission({ userId: USER_ID })
        .then(result => {
            if (result) {
        
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: this.recordId,
                        objectApiName: 'Account',
                        actionName: 'edit'
                    }
                });
                
            } else {
                this.showWarning = true;
            }
        })
        .catch(error => {
            console.error('Permission check failed', error);
            this.showWarning = true;
        });
    }

    closeModal() {
        this.showWarning = false;
        // Optionally navigate back to view page here
    }
}