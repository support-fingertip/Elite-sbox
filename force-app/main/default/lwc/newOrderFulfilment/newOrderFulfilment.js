import { LightningElement,wire,track,api } from 'lwc';
import getUnfulfilledOrders from '@salesforce/apex/OrderFulfilmentController.getUnfulfilledOrders';
import GOOGLE_ICONS from '@salesforce/resourceUrl/googleIcons';
import FORM_FACTOR from '@salesforce/client/formFactor';


export default class NewOrderFulfilment extends LightningElement {
    @api isProgressVisit;
    @track orders = [];
    @track allOrders = [];
    @api recordId;
    @api visitId;
    @track expandedOrderId = null;
    isPageLoaded = false;
    @track searchKey = '';
    @track filterDate = '';
    isDesktop = false;
    isPhone = false;
    customClass = 'slds-col slds-size_1-of-2 slds-p-right_small';
    isShowBackButton = false;
    isOrderItemsScreen = false;
    header = 'Order Fulfilments';
    orderFilfilmemtScreem = true;
    OrderItemScreen = false;
    currentOrderId ='';
    pageSize = 150;      // fetch 50 at a time
    offsetSize = 0;     // starting point
    hasMoreData = true; // flag

   

    googleIcons = {
        order : GOOGLE_ICONS + "/googleIcons/order.png",
        sort : GOOGLE_ICONS + "/googleIcons/sort.png",
        progress : GOOGLE_ICONS + "/googleIcons/progress.png",
        play : GOOGLE_ICONS + "/googleIcons/play.png",
        forward : GOOGLE_ICONS + "/googleIcons/forward.png"
    }

    connectedCallback() {
        this.isDesktop = FORM_FACTOR === 'Large'? true : false;
        this.isPhone = FORM_FACTOR === 'Small'? true : false;
        if (FORM_FACTOR === 'Medium') this.isDesktop = true;
        this.customClass = this.isDesktop ? 'slds-col slds-size_1-of-2 slds-p-right_small' : 'slds-size_1-of-1';
        this.isPageLoaded = false;
        this.disablePullToRefresh();
        this.fetchOrders();
    }

    get customHeaderClass() {
        return this.orderFilfilmemtScreem 
        ?   'screenWithOutHeight': 'screen-1';
    }
    refreshData()
    {
        this.OrderItemScreen = false;
        this.orderFilfilmemtScreem = true;
        this.header = 'Order Fulfilments';
        this.orders = [];
        this.offsetSize = 0;
        this.hasMoreData = true;
        this.fetchOrders();
    }
    goBackScreen()
    {
        this.currentOrderId = ''; 
        this.OrderItemScreen = false;
        this.orderFilfilmemtScreem = true;
        this.header = 'Order Fulfilments';
        this.orders = [];
        this.offsetSize = 0;
        this.hasMoreData = true;
        this.fetchOrders();
    }

    fetchOrders() {
        if (!this.hasMoreData) return;

        this.isPageLoaded = true;
        getUnfulfilledOrders({ pageSize: this.pageSize, offsetSize: this.offsetSize })
        .then(result => {
             if (result.length === 0) {
                this.hasMoreData = false; // no more data
            } else {
                this.orders = [...this.orders, ...result];
                this.allOrders = this.orders;
                this.offsetSize += this.pageSize;

                // only stop if fewer than requested page size
                if (result.length < this.pageSize) {
                    this.hasMoreData = false;
                }
            }
            this.isPageLoaded = false;
        })
        .catch(error => {
            console.error('Error fetching orders:', error);
            this.isPageLoaded = false;
        });
    }

    // on scroll end or "Load More" button
    handleLoadMore() {
        this.fetchOrders();
    }


    isExpanded(orderId) {
        return this.expandedOrderId === orderId;
    }

    handleShowItems(event) {
        const orderId = event.currentTarget.dataset.id;
        const accountname = event.currentTarget.dataset.accountname;
        const orderName  = event.currentTarget.dataset.ordername;

        this.currentOrderId = orderId; 
        this.OrderItemScreen = true;
        this.orderFilfilmemtScreem = false;
        this.header = orderName+'/'+accountname;
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

    handleOrderScreen(event)
    {
        const msg = event.detail;
        if(msg.message == 'executeScreen'){
            this.goBackScreen();
        }
    }


    // --- Search & Date filter applied directly to orders ---
    handleSearchChange(event) {
        this.searchKey = event.target.value.toLowerCase();
        this.applyFilters();
    }

    handleDateChange(event) {
        this.filterDate = event.target.value;
        this.applyFilters();
    }

    applyFilters() {
        let filtered = [...this.allOrders];

        // text search
        if (this.searchKey) {
            filtered = filtered.filter(order =>
                (order.orderName && order.orderName.toLowerCase().includes(this.searchKey)) ||
                (order.accountName && order.accountName.toLowerCase().includes(this.searchKey)) ||
                (order.outletId && order.outletId.toLowerCase().includes(this.searchKey)) ||
                (order.customerCode && order.customerCode.toLowerCase().includes(this.searchKey)) ||
                (order.executiveName && order.executiveName.toLowerCase().includes(this.searchKey)) ||
                (order.executiveEmployeeCode && order.executiveEmployeeCode.toLowerCase().includes(this.searchKey))
            );
        }

        // date filter
        if (this.filterDate) {
            filtered = filtered.filter(order =>
                order.orderDate && order.orderDate.startsWith(this.filterDate)
            );
        }

        this.orders = filtered;
    }
      //disable pull to refesh
    disablePullToRefresh() {
        const disableRefresh = new CustomEvent("updateScrollSettings", {
            detail: {
            isPullToRefreshEnabled: false
            },
            bubbles: true,
            composed: true
        });
        this.dispatchEvent(disableRefresh);
    }
}