import { LightningElement,wire,track,api } from 'lwc';
import getUnfulfilledOrders from '@salesforce/apex/beatPlannerlwc.getUnfulfilledOrders';
import GOOGLE_ICONS from '@salesforce/resourceUrl/googleIcons';



export default class OrderFulFillmentscreen extends LightningElement {
    @api isProgressVisit;
    @track orders = [];
    @api recordId;
    @api visitId;
    @track expandedOrderId = null;
    isPageLoaded = false;

    googleIcons = {
        order : GOOGLE_ICONS + "/googleIcons/order.png",
        sort : GOOGLE_ICONS + "/googleIcons/sort.png",
        progress : GOOGLE_ICONS + "/googleIcons/progress.png",
        play : GOOGLE_ICONS + "/googleIcons/play.png",
        forward : GOOGLE_ICONS + "/googleIcons/forward.png"
    }

    connectedCallback() {

        this.isPageLoaded = false;
        this.fetchOrders();


    }

    fetchOrders() {
        this.isPageLoaded = true;
        getUnfulfilledOrders({accountid : this.recordId})
            .then(result => {
                this.orders = result.map(order => ({
                    ...order,
                    lineItems: null
                }));
            })
            .then(() => {
                this.isPageLoaded = false;
            })
            
            .catch(error => {
                console.error('Error fetching orders:', JSON.stringify(error, null, 2));
            });
    }

    isExpanded(orderId) {
        return this.expandedOrderId === orderId;
    }

    handleShowItems(event) {
        const orderId = event.currentTarget.dataset.id;
        console.log(
            'The button you clicked was ' + orderId);
            const message = { 
                message: 'OrderLineItemscreen',
                visitId:this.visitId,
                recordID : orderId,
                screen : 3.6,
                isProgressVisit : true
            };
            this.genericDispatchEvent(message);
        
    }
    genericDispatchEvent(message) {
        // Creating a custom event with a payload (optional)
        const event = new CustomEvent('orderfulfillment', {
            detail: message
        });

        // Dispatching the event
        this.dispatchEvent(event);
    }
    get hasOrders() {
        return this.orders && this.orders.length > 0;
    }
}