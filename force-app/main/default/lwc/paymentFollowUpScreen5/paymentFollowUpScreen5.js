import { LightningElement, api, track } from 'lwc';
import getPaymentData from '@salesforce/apex/beatPlannerlwc.getPaymentFollowup';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { deleteRecord } from 'lightning/uiRecordApi';
import savePaymentFollowup from '@salesforce/apex/beatPlannerlwc.savePaymentFollowup';

export default class PaymentFollowUpScreen5 extends LightningElement {
    @api recordId;
    @api visitId ;
    @api isDesktop;
    @api visitData;
    visitfor;

    @track paymentData = [];
    paymentDataExisted = true;
    isModalOpen = false;
    isDeleteModalOpen = false;
    isLoading = false;
    expectedAmount = '';
    expectedPaymentDate = new Date().toISOString().split('T')[0];
    comments = '';
    modalTitle = '';
    PaymentId = '';
    @track showPopup = false;
    @track selectedItem = {};
    containerClass;

    connectedCallback() {
        this.visitfor = this.visitData.visitTypes;
        this.containerClass = this.isDesktop ? 'slds-modal__container ' : '';
        this.getPaymentFollowUp();
    }

    getPaymentFollowUp() {
        this.isLoading = true;
        getPaymentData({ recordId: this.recordId, visitId: this.visitId })
            .then((result) => {
                console.log(result);
                this.paymentData = result.map(item => ({
                    id: item.Id,
                    name:item.Name,
                    expectedAmount: item.Expected_Amount__c,
                    expectedPaymentDate: item.Expected_Payment_Date__c,
                    comments: item.Comments__c,
                    openPopup: false
                }));
                this.paymentDataExisted = this.paymentData.length > 0;
                this.isLoading = false;
            })
            .catch((error) => {
                this.isLoading = false;
                console.error(error);
                this.showToast('Error', 'Error fetching Payment Follow-ups: ' + JSON.stringify(error), 'error');
            });
    }

    openMenu(event) {
        const index = parseInt(event.currentTarget.dataset.index, 10);
        this.paymentData = this.paymentData.map((item, i) => ({
            ...item,
            openPopup: i === index ? !item.openPopup : false
        }));
    }

    handleOnclickMenu(event) {
        const action = event.currentTarget.dataset.name;
        const itemId = event.currentTarget.dataset.id;
        const payment = this.paymentData.find(payment => payment.id === itemId);

        if (action === 'Edit') {
            this.modalTitle = 'Edit Payment FollowUp';
            this.expectedAmount = payment.expectedAmount;
            this.expectedPaymentDate = payment.expectedPaymentDate;
            this.comments = payment.comments;
            this.PaymentId = payment.id;
            this.isModalOpen = true;
        } else if (action === 'Add') {
            this.modalTitle = 'New Payment FollowUp';
            this.resetForm();
            this.PaymentId = null;
            this.isModalOpen = true;
        } else if (action === 'Delete') {
            this.PaymentId = payment.id;
            this.isDeleteModalOpen = true;
        }
    }

    closeModal() {
        this.isModalOpen = false;
        this.resetForm();
    }

    resetForm() {
        this.expectedPaymentDate = new Date().toISOString().split('T')[0];
        this.expectedAmount = '';
        this.comments = '';
    }

    handleInputChange(event) {
        const field = event.currentTarget.dataset.id;
        if (field === 'expectedAmount') {
            this.expectedAmount = event.currentTarget.value;
        } else if (field === 'expectedPaymentDate') {
            this.expectedPaymentDate = event.currentTarget.value;
        } else if (field === 'comments') {
            this.comments = event.currentTarget.value;
        }
    }

    savePaymentFollowup() {
        if (!this.expectedAmount) {
            this.showToast('Error', 'Please enter expected Amount', 'error');
            return;
        }
        if (!this.expectedPaymentDate) {
            this.showToast('Error', 'Please select an expected payment date', 'error');
            return;
        }
        if (!this.comments || this.comments.trim() === '') {
            this.showToast('Error', 'Please enter comments', 'error');
            return;
        }
    
        this.isLoading = true;
    
        const paymentRecord = {
            Id: this.PaymentId || null, // If editing, use existing ID; if new, it's null
            Expected_Payment_Date__c: this.expectedPaymentDate,
            Expected_Amount__c: this.expectedAmount,
            Comments__c: this.comments,
            Visit__c: this.visitId,
            Visit_for__c: this.visitfor,
            Account__c: this.recordId
        };
    
        savePaymentFollowup({ paymentFollowup: paymentRecord })
            .then((result) => {
                const newPaymentRecord = {
                    id: result.Id,
                    name: result.Name,
                    expectedAmount: result.Expected_Amount__c,
                    expectedPaymentDate: result.Expected_Payment_Date__c,
                    comments: result.Comments__c,
                    openPopup: false
                };
    
                if (this.PaymentId) {
                    // Update existing record
                    this.paymentData = this.paymentData.map(item => item.id === this.PaymentId ? newPaymentRecord : item);
                } else {
                    // Add new record
                    this.paymentData = [...this.paymentData, newPaymentRecord];
                }
                this.paymentData = this.paymentData.map((item) => ({
                    ...item,
                    openPopup: false
                }));
    
                this.paymentDataExisted = this.paymentData.length > 0;
                this.isModalOpen = false;
                this.isLoading = false;
                this.resetForm();
                this.showToast('Success', 'Payment Follow-up saved successfully', 'success');
            })
            .catch((error) => {
                this.isLoading = false;
                console.error('Save Error:', JSON.stringify(error));
                let message = 'Unknown error';
                if (error.body && error.body.message) {
                    message = error.body.message;
                }
                this.showToast('Error', 'Error while saving payment follow-up: ' + message, 'error');
            });
    }

    deleteCompetition() {
        const itemId = this.PaymentId;
        this.isDeleteModalOpen = false;
        this.isLoading = true;

        deleteRecord(itemId)
            .then(() => {
                this.paymentData = this.paymentData.filter(payment => payment.id !== itemId);
                this.paymentDataExisted = this.paymentData.length > 0;
                this.isLoading = false;
                this.showToast('Success', 'Payment Follow-up deleted successfully', 'success');
            })
            .catch(error => {
                this.isLoading = false;
                this.showToast('Error', 'Error deleting Payment Follow-up: ' + JSON.stringify(error), 'error');
            });
    }

    handleDeleteCancel() {
        this.isDeleteModalOpen = false;
    }

    openPopupDetails(event) {
        this.paymentData = this.paymentData.map((item) => ({
            ...item,
            openPopup: false
        }));
        const itemId = event.currentTarget.dataset.id;
        this.selectedItem = this.paymentData.find(item => item.id === itemId);
            // Manually truncate if needed
        /*if (this.selectedItem.comments.length >= 30) {
            this.selectedItem.comments = this.selectedItem.comments.substring(0, 27) + "...";
        }*/
        this.showPopup = true;
    }

    closePopup() {
        this.showPopup = false;
        this.selectedItem = {};
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}