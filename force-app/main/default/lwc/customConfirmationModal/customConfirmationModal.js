// customConfirmationModal.js
import { LightningElement, api } from 'lwc';

export default class CustomConfirmationModal extends LightningElement {
    @api message = 'Are you sure you want to proceed?';
    @api isModalOpen = false;

    @api
    openModal(message) {
        this.message = message;
        this.isModalOpen = true;
    }

    handleYes() {
        this.isModalOpen = false;
        // Dispatch event to handle Yes action
        const event = new CustomEvent('confirm', { detail: true });
        this.dispatchEvent(event);
    }

    handleNo() {
        this.isModalOpen = false;
        // Dispatch event to handle No action
        const event = new CustomEvent('confirm', { detail: false });
        this.dispatchEvent(event);
    }

    closeModal() {
        this.isModalOpen = false;
    }
}