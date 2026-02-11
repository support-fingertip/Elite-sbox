import { LightningElement, api } from 'lwc';

export default class MakePaymentPopup extends LightningElement {
    @api isOpen = false;
   
    @api invoiceCount = 0;
    @api totalAmount = 0;

    handlePay() {
        this.dispatchEvent(new CustomEvent('pay'));
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    

    get isPayDisabled() {
    return !this.invoiceCount || this.invoiceCount === 0;
}

}