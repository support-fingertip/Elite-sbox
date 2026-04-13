import { LightningElement, api } from 'lwc';
import getProductMappings from '@salesforce/apex/SecondaryCustomerController.getProductMappings';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const PAGE_SIZE = 100;
const SEARCH_DEBOUNCE_MS = 300;

export default class SecondaryCustomers extends LightningElement {
    @api recordId;
    productMappings = [];
    filteredMappings = [];
    visibleMappings = [];
    searchKey = '';
    isLoading = false;
    fileName = '';
    totalCustomersCount = 0;
    subStockiestCount = 0;
    secondaryCustomerCount = 0;
    label='Secondary Customers'

    _visibleCount = PAGE_SIZE;
    _searchDebounceId;

    get showNoRecords() {
        return this.filteredMappings.length === 0;
    }

    get hasMore() {
        return this.visibleMappings.length < this.filteredMappings.length;
    }

    get loadMoreLabel() {
        const remaining = this.filteredMappings.length - this.visibleMappings.length;
        const next = Math.min(PAGE_SIZE, remaining);
        return `Load More (${next} of ${remaining} remaining)`;
    }

    connectedCallback() {
        this.fetchProductMappings();
    }

    fetchProductMappings() {
        this.isLoading = true;
        getProductMappings({ recordId: this.recordId })
            .then((data) => {
                this.productMappings = data.customerData || [];
                this.fileName = data.fileName || '';
                this.totalCustomersCount =  data.totalCustomersCount || 0;
                this.subStockiestCount = data.subStockiestCount || 0;
                this.secondaryCustomerCount = data.secondaryCustomerCount || 0;
                this.label = 'Secondary Customers'+' ( '+ this.totalCustomersCount +' )';
                this._applyFilterAndPaginate();
                this.isLoading = false;
            })
            .catch((error) => {
                this.isLoading = false;
                console.error('Error fetching secondary customers:', error);
            });
    }

    handleSearch(event) {
        const value = event.target.value;
        // Debounce so each keystroke doesn't re-filter a large list
        if (this._searchDebounceId) {
            clearTimeout(this._searchDebounceId);
        }
        this._searchDebounceId = setTimeout(() => {
            this.searchKey = value;
            this._visibleCount = PAGE_SIZE;
            this._applyFilterAndPaginate();
        }, SEARCH_DEBOUNCE_MS);
    }

    handleLoadMore() {
        this._visibleCount += PAGE_SIZE;
        this.visibleMappings = this.filteredMappings.slice(0, this._visibleCount);
    }

    _applyFilterAndPaginate() {
        const key = (this.searchKey || '').toLowerCase();
        if (!key) {
            this.filteredMappings = this.productMappings;
        } else {
            this.filteredMappings = this.productMappings.filter(item =>
                (item.secondaryCustomerName && item.secondaryCustomerName.toLowerCase().includes(key)) ||
                (item.secondaryCustomerOutletId && item.secondaryCustomerOutletId.toLowerCase().includes(key)) ||
                (item.secondaryCustomerCode && item.secondaryCustomerCode.toLowerCase().includes(key))
            );
        }
        this.visibleMappings = this.filteredMappings.slice(0, this._visibleCount);
    }

    downloadCSV() {
        if (!this.productMappings || this.productMappings.length === 0) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Warning',
                    message: 'No data available to download.',
                    variant: 'warning'
                })
            );
            return;
        }

        try {
            const bom = '\uFEFF'; // Excel-compatible BOM
            let csv = bom + 'Salesforce.com Id,Secondary Customer,Outlet ID,Customer Code,Primary Phone Number,State,Disrict,Executive Name,Executive Code,Beat Id\n';

            this.productMappings.forEach(item => {
                const row = [
                    item.recordId || '',
                    item.secondaryCustomerName || '',
                    item.secondaryCustomerOutletId || '',
                    item.secondaryCustomerCode || '',
                    item.primaryPhoneNumber || '',
                    item.state || '',
                    item.disrict || '',
                    item.executiveName || '',
                    item.executiveCode || '',
                    item.beatId || '',
                ].map(value =>
                    `"${String(value).replace(/"/g, '""').replace(/\n/g, ' ')}"`
                ).join(',');
                csv += row + '\n';
            });

            const blob = new Blob([csv], { type: 'application/octet-stream' });
            const link = document.createElement('a');
            link.href = URL.createObjectURL(blob);
            link.download = this.fileName+'_Secondary_Customers.csv';
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            URL.revokeObjectURL(link.href);
        } catch (error) {
            console.error('Error generating CSV:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Failed to download CSV. Please try again.',
                    variant: 'error'
                })
            );
        }
    }

    navigateToCustomer(event) {
        const empId = event.currentTarget.dataset.id;
        if (empId) {
            const url = `/lightning/r/Account/${empId}/view`;
            window.open(url, '_blank');
        }
    }
}
