import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getOrderItems from '@salesforce/apex/OrderViewForm.getOrderItems';

export default class OrderItems extends NavigationMixin(LightningElement) {
    @api recordId;
    orderItems;
    error;
    get orderItemsCount() {
        return this.orderItems ? this.orderItems.length : 0;
    }


    @wire(getOrderItems, { orderId: '$recordId' })
    wiredOrderItems({ error, data }) {
        if (data) {
            this.orderItems = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.orderItems = undefined;
        }
    }

    handleToggleChange(event) {
        this.showTableView = event.target.checked;
    }
    handleRowAction(event) {
        const row = event.detail.row;
        const actionName = event.detail.action.name;

        let recordId;
        if (actionName === 'viewRecord') {
            recordId = row.Id;
        } else if (actionName === 'viewProduct') {
            recordId = row.ProductId;
        }

        if (recordId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: recordId,
                    actionName: 'view'
                }
            });
        }
    }


    
    openRecord(event) {
        const recordId = event.target.dataset.id;

        if (this.isPhone) {

            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: recordId,
                    actionName: 'view' // or 'edit' if needed
                }
            });
        }
        else {
            this[NavigationMixin.GenerateUrl]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: recordId,
                    actionName: 'view'
                }
            }).then(url => {
                // Open the record in a new tab
                window.open(url, '_blank');
            });
        }

    }
}