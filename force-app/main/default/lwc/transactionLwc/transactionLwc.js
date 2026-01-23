import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getOrderItems from '@salesforce/apex/TransactionController.getOrderItems';

export default class OrderItems extends NavigationMixin(LightningElement) {
    @api recordId;
    @track allOrderItems = [];
    @track orderItems = [];
    @track groupedOrderItems = [];
    searchKey = '';
    isLoading = false;
    showOrderItems = false;

    get orderItemsCount() {
        return this.orderItems ? this.orderItems.length : 0;
    }

    connectedCallback() {
        this.loadOrderItems();
    }

    loadOrderItems() {
        this.isLoading = true;
        getOrderItems({ accountId: this.recordId })
        .then((data) => {
            this.allOrderItems = data;
            this.orderItems = data;
            this.groupedOrderItems = this.groupOrderItems() || [];
            this.showOrderItems = this.groupedOrderItems.length > 0 ? true : false;
            this.error = undefined;
            this.isLoading = false;
        })
        .catch((error) => {
            this.error = error;
            this.allOrderItems = [];
            this.orderItems = [];
            this.isLoading = false;
        });
    }
    groupOrderItems() {
        if (!this.orderItems || this.orderItems.length === 0) {
            return null;
        }

        let groups = {};
        this.orderItems.forEach(item => {
            let dateKey = item.OrderDate
                ? item.OrderDate
                : item.CreatedDate
                ? item.CreatedDate.split('T')[0]
                : 'No Date';

            if (!groups[dateKey]) {
                groups[dateKey] = [];
            }
            groups[dateKey].push(item);
        });

        return Object.keys(groups)
            .sort((a, b) => new Date(b) - new Date(a))
            .map(dateVal => {
                return { date: dateVal, items: groups[dateVal] };
            });
    }

    // Search by Product Name
    handleSearch(event) {
        this.searchKey = event.target.value.toLowerCase();
        if (this.searchKey) {
            this.orderItems = this.allOrderItems.filter(
                item =>
                    item.ProductName &&
                    item.ProductName.toLowerCase().includes(this.searchKey)
            );
            this.groupedOrderItems = this.groupOrderItems() || [];
            this.showOrderItems = this.groupedOrderItems.length > 0 ? true : false;

        } else {
            this.orderItems = [...this.allOrderItems];
            this.groupedOrderItems = this.groupOrderItems() || [];
            this.showOrderItems = this.groupedOrderItems.length > 0 ? true : false;
        }
        
    }

    
}