import { LightningElement, api, track ,wire} from 'lwc';
import getOrderLineItems from '@salesforce/apex/beatPlannerlwc.getOrderLineItems';
import GOOGLE_ICONS from '@salesforce/resourceUrl/googleIcons';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import saveOrderLineItems from '@salesforce/apex/beatPlannerlwc.saveOrderLineItems';
import ORDER_OBJECT from '@salesforce/schema/Order_Item__c';
import STATUS_FIELD from '@salesforce/schema/Order_Item__c.Status__c';

export default class OderLineItemScreen extends LightningElement {
    @api orderId;
    @track totalDeliveredQuantity = 0;
   @track totalOrderedQuantity = 0;

    @api recordId;
    @api visitId;
    @track billNumber = '';
    @track billValue = '';
    @track billQuantity = '';
    @track billDate = '';
    @track isSummaryProduct = false;
    @track showAllProducts = true;
    @track openPopupModal = false;
    @track statusOptions = [];
    isPageLoaded = false;
    @track orderslineitems = [];
    googleIcons = {
        order: GOOGLE_ICONS + "/googleIcons/order.png",
        sort: GOOGLE_ICONS + "/googleIcons/sort.png",
        progress: GOOGLE_ICONS + "/googleIcons/progress.png",
        play: GOOGLE_ICONS + "/googleIcons/play.png",
        forward: GOOGLE_ICONS + "/googleIcons/forward.png"
    };

    
    @track fulfillmentType = 'None'; // default
    @track status = '';
    @track isEditing = false;

    connectedCallback() {
        this.isPageLoaded = false;
        this.fetchOrders();
        setTimeout(() => {
            window.scrollTo({
                top: 0,
                behavior: 'smooth'
            });
        }, 0);
    }

    fetchOrders() {
        this.isPageLoaded = true;
        getOrderLineItems({ orderId: this.orderId })
            .then(result => {
                this.orderslineitems = result.map(item => ({
                    ...item
                }));
            })
            .finally(() => {
                this.isPageLoaded = false;
            })
            .catch(error => {
                console.error('Error fetching ordersline items:', JSON.stringify(error, null, 2));
            });
    }

    handleInputChange(event) {
        const recordId = event.target.dataset.id;
        const field = event.target.dataset.field;
        const value = event.target.value;
    
        
        if (field === 'Delivered_Quantity__c') {
            const deliveredQuantity = parseFloat(value);
            
            // Show toast if negative
            if (isNaN(deliveredQuantity) || deliveredQuantity < 0) {
                event.target.value = null;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Invalid Input',
                        message: 'Enter a positive value',
                        variant: 'error'
                    })
                );
                return;
            }
        }
    
        
        this.orderslineitems = this.orderslineitems.map(item => {
            if (item.Id === recordId) {
                let updatedItem = {
                    ...item,
                    [field]: value
                };
    
                if (field === 'Delivered_Quantity__c') {
                    const deliveredQuantity = parseFloat(updatedItem.Delivered_Quantity__c);
                    const quantity = parseFloat(updatedItem.Quantity__c);
    
                    if (!isNaN(deliveredQuantity) && !isNaN(quantity)) {
                        if (deliveredQuantity > quantity) {
                            updatedItem.Status__c = 'Over-Fulfilled';
                        } else if (deliveredQuantity < quantity && deliveredQuantity > 0) {
                            updatedItem.Status__c = 'Under-Fulfilled';
                        } else if (deliveredQuantity === quantity) {
                            updatedItem.Status__c = 'Back-To-Back';
                        } else {
                            updatedItem.Status__c = 'Not Fulfilled';
                        }
                    } else {
                        updatedItem.Status__c = 'Not Fulfilled';
                    }
                }
    
                return updatedItem;
            }
            return item;
        });
    
        this.orderslineitems = [...this.orderslineitems]; 
    }
    

    handleFulfillmentTypeChange(event) {
        this.fulfillmentType = event.detail.value;
    
        if (this.fulfillmentType === 'Order Line item wise') {
            this.status = '';
        }
    
        if (this.isOrderWise) {
            this.status = 'Back-To-Back';
    
            // Auto-update all order line items
            this.orderslineitems = this.orderslineitems.map(item => {
                return {
                    ...item,
                    Status__c: 'Back-To-Back',
                    Delivered_Quantity__c: item.Quantity__c
                };
            });
        }
    
        this.orderslineitems = [...this.orderslineitems]; 
    }

    handleStatusChange(event) {
        this.status = event.detail.value;
        console.log('Status changed to:', this.status);
    
        if (this.isOrderWise) {
            this.orderslineitems = this.orderslineitems.map(item => {
                let updatedItem = { ...item, Status__c: this.status };
    
                
                if (this.status === 'Back-To-Back') {
                    console.log('Setting Delivered_Quantity__c to Quantity__c:', item.Quantity__c);
                    updatedItem.Delivered_Quantity__c = item.Quantity__c;  
                } else {
                    console.log('Retaining Delivered_Quantity__c:', item.Delivered_Quantity__c);
                    updatedItem.Delivered_Quantity__c = null;
                }
    
                return updatedItem;
            });
            
            console.log('Updated orderslineitems:', this.orderslineitems);
        }
    }
    

    get isOrderWise() {
        return this.fulfillmentType === 'Order wise';
    }

    get isLineItemWise() {
        return this.fulfillmentType === 'Order Line item wise';
    }
    get fulfillmentOptions() {
        return [
            { label: '--None--', value: 'None' },
            { label: 'Order wise', value: 'Order wise' },
            { label: 'Order Line item wise', value: 'Order Line item wise' }
        ];
    }
    
    @wire(getObjectInfo, { objectApiName: ORDER_OBJECT })
    objectInfo;

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: STATUS_FIELD
    })
    wiredPicklistValues({ data, error }) {
        if (data) {
            this.statusOptions = data.values;
        } else if (error) {
            console.error('Picklist fetch error: ', error);
        }
    }

    get disableInputs() {
       
        return this.fulfillmentType === 'Order wise' || this.fulfillmentType === 'None';
    }
    save() {
        console.log('this.billNumber'+ this.billNumber);
        console.log('this.billValue'+ this.billValue);
        console.log('this.billQuantity'+ this.billQuantity);
        console.log('this.billDate'+ this.billDate);
        if (!this.billNumber || !this.billValue || !this.billQuantity || !this.billDate) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Missing Fields',
                    message: 'Please fill in all mandatory fields: DB Bill Number, DB Bill Value, DB Bill Quantity, and DB Bill Date.',
                    variant: 'warning'
                })
            );
            return; 
        }
        if (isNaN(this.billValue) || isNaN(this.billQuantity)) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Missing Fields',
                    message: 'Bill Value and Bill Quantity must be numbers.',
                    variant: 'error'
                })
            );
            return; 
        }
        if (Number(this.billValue) < 0 || Number(this.billQuantity) < 0) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Invalid Values',
                    message: 'Bill Value and Bill Quantity cannot be negative.',
                    variant: 'error'
                })
            );
            return;
        }
        this.calculateTotalDeliveredQuantity();

        if (Number(this.billQuantity) !== this.totalDeliveredQuantity) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Your Bill Quantity does not match the total Delivered Quantity. Please use Order Line Item Wise mode.',
                    variant: 'error'
                })
            );
            return;
        }
        const fulfillmentStatus = this.getFulfillmentStatus();
        
       

        this.isPageLoaded = true;
        saveOrderLineItems({ updatedItems: this.orderslineitems,billNumber :this.billNumber,billValue:this.billValue,billQuantity:this.billQuantity,billDate:this.billDate,orderId:this.orderId,visitId:this.visitId,status:fulfillmentStatus})
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Order fulfillment saved successfully.',
                        variant: 'success'
                    })

                );
                let message = { 
                    message: 'executeScreen' ,
                    screen : 3.2
                };
                this.genericDispatchEvent(message);
    
                this.fetchOrders(); 
                 this.billNumber = '';
                 this.billValue = '';
                 this.billQuantity = '';
                 this.billDate = '';


            })
            .catch(error => {
                console.error('Error saving order line items:', JSON.stringify(error, null, 2));
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Failed to save order line items.',
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
                this.isPageLoaded = false;
            });
            
    }
    selectedProduct(event){
        console.log('entered ===>')
        const selectedName = event.target.dataset.name;
        console.log('selectedName==>'+selectedName);
        if(selectedName == 'SelectedItems'){
            this.showAllProducts = true;
            this.isSummaryProduct = false;
        }
        else if(selectedName == 'Summary'){
           
                    this.showAllProducts = false;
                    this.isSummaryProduct = true;
            
        }
    }
    handleInputChange1(event) {
        const field = event.target.name;
        const value = event.target.value;
        
        if (field === 'DB Bill Number') {
            this.billNumber = value;
        } else if (field === 'DB Bill Value') {
            this.billValue = value;
        } else if (field === 'DB Bill Quantity') {
            this.billQuantity = value;
        } else if (field === 'DB Bill Date') {
            this.billDate = value;
        }
    }

    genericDispatchEvent(message) {
        
        const event = new CustomEvent('screen4', {
            detail: message
        });

        // Dispatching the event
        this.dispatchEvent(event);
    }
    
    calculateTotalDeliveredQuantity() {
        let deliveredTotal = 0;
        let orderedTotal = 0;
    
        this.orderslineitems.forEach(item => {
            const deliveredQty = parseFloat(item.Delivered_Quantity__c);
            const orderedQty = parseFloat(item.Quantity__c);
    
            if (!isNaN(deliveredQty)) {
                deliveredTotal += deliveredQty;
            }
            if (!isNaN(orderedQty)) {
                orderedTotal += orderedQty;
            }
        });
    
        this.totalDeliveredQuantity = deliveredTotal;
        this.totalOrderedQuantity = orderedTotal; // Add this to your tracked variables if needed
    }
    getFulfillmentStatus() {
        if (this.totalDeliveredQuantity > this.totalOrderedQuantity) {
            return 'Over-Fulfilled';
        } else if (this.totalDeliveredQuantity < this.totalOrderedQuantity) {
            return 'Under-Fulfilled';
        } else {
            return 'Back-To-Back';
        }
    }
    
    
}